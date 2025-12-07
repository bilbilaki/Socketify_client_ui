import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import 'package:provider/provider.dart';
import 'package:path/path.dart' as p;

import 'services/local_file_playlist_service.dart';
import 'services/user_data_service.dart';


List<PlaylistMode> playModeOptions = [
  PlaylistMode.none,
  PlaylistMode.single,
  PlaylistMode.loop,
];
int currentPlayModeIndex = 0;
PlaylistMode get currentPlayMode => playModeOptions[currentPlayModeIndex];
final Map<PlaylistMode, IconData> _playModeIcons = {
  PlaylistMode.none: Icons.arrow_forward_ios,
  PlaylistMode.single: Icons.repeat_on,
  PlaylistMode.loop: Icons.loop,
};
void playlistMode(Player player) async {
  currentPlayModeIndex = (currentPlayModeIndex + 1) % playModeOptions.length;
  await player.setPlaylistMode(currentPlayMode);
}


// ignore: must_be_immutable
class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;
  final String videoName;
  final String source;
  String? exterSubtitle;
  String? exterAudio;
  List? playlistitem;
  VideoPlayerScreen({
    required this.videoUrl,
    this.playlistitem,
    super.key,
    required this.videoName,
    required this.source,
    this.exterSubtitle,
    this.exterAudio,
  });

  @override
  State<VideoPlayerScreen> createState() => VideoPlayerScreenState();
}

class VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late final Player player = Player();
  late final VideoController controller = VideoController(player);
  bool showControls = true;
  bool showEpisodeList = false;
  bool isFullScreen = false;
  bool isMuted = false;
  bool isPiPEnabled = false;
  Timer? _progressSaveTimer; // Timer to periodically save progress
  String urlToPlayQuality = '';
  double subtitleSize = 32.0;
  Color subtitleColor = const Color.fromARGB(255, 238, 230, 5);
  bool showSettings =
      false; // Renamed from showSubtitleControls to showSettings
  late int currentIndex;
  StreamSubscription? _completedSubscription;
  StreamSubscription? _errorSubscription;
  Timer? _hideTimer;
  String currentQuality = 'Auto';
  bool streamHasError = false;
  bool isFileSource = false;
  @override
  void initState() {
    super.initState();
    currentIndex = 0;
    _userDataService = Provider.of<UserDataService>(context, listen: false);

    _completedSubscription = player.stream.completed.listen((completed) {
      if (widget.source == "local") isFileSource = true;
      if (completed) {
        _clearPlaybackProgress();
        playNext();
      }
    });

    _progressSaveTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _savePlaybackProgress();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAndPlayEpisode(0, isInitialPlay: true);

      // Build playlist from local folder in background if it's a local file
    });
  }

  /// Initialize playlist from local folder in background

  Future<void> _loadAndPlayEpisode(
    int index, {
    bool isInitialPlay = true,
    String? specificUrl,
  }) async {
    setState(() {
      currentIndex = index;
    });

    String urlToPlay;

    if (specificUrl != null) {
      urlToPlay = specificUrl;
    } else {
      urlToPlay = widget.videoUrl;
    }
    String videoname = p.basenameWithoutExtension(urlToPlay);
    String parentfolder = p.dirname(urlToPlay);
    if (widget.source == "local") {
      final playlist = await LocalFilePlaylistService.buildPlaylistFromFolder(
        urlToPlay,
        "video",
      );

      if (playlist.isEmpty) {
        debugPrint('No video files found in folder');
        await player.open(Media(Uri.decodeComponent(urlToPlay)), play: false);
      }

      // Find current file index

      await player.open(Playlist(playlist), play: false);
    } else {
      await player.open(Media(Uri.decodeComponent(urlToPlay)), play: false);
    } // Set external subtitle if provided
    if (widget.exterSubtitle != null) {
      player.setSubtitleTrack(SubtitleTrack.uri(widget.exterSubtitle!));
    } else if (File('$parentfolder/$videoname.srt').existsSync() ||
        File('$parentfolder/$videoname.ass').existsSync() ||
        File('$parentfolder/$videoname.vtt').existsSync() ||
        File('$parentfolder/$videoname.sub').existsSync()) {
      await player.setSubtitleTrack(SubtitleTrack.uri(urlToPlay));
    }
    // Fixed condition: set audio if not null and not empty
    if (widget.exterAudio != null) {
      await player.setAudioTrack(AudioTrack.uri(widget.exterAudio!));
    }

    _userDataService.toggleIsWatchedLink(
      widget.videoName,
      widget.source,
      0,
      widget.videoUrl,
    );

    Duration? savedPosition = await _userDataService.getVideoProgress(
      widget.videoName,
      widget.source,
      '0',
      widget.videoUrl,
    );

    if (isInitialPlay) {
      if (savedPosition != null) {
        final shouldResume = await _showResumeDialog(savedPosition);
        if (shouldResume == true) {
          await player.seek(savedPosition);
          await player.play();
        } else if (shouldResume == false) {
          await _clearPlaybackProgress();
        }
      }
    }

    await player.play();
  }

  // New method to select and set external subtitle
  Future<void> _selectSubtitle() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['srt', 'ass', 'vtt', 'sub'],
    );
    if (result != null && result.files.single.path != null) {
      player.setSubtitleTrack(SubtitleTrack.uri(result.files.single.path!));
      // Optionally hide settings after selection
      setState(() {
        showSettings = false;
      });
    }
  }

  // New method to select and set external audio
  Future<void> _selectAudio() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'aac', 'm4a', 'wav'],
    );
    if (result != null && result.files.single.path != null) {
      player.setAudioTrack(AudioTrack.uri(result.files.single.path!));
      // Optionally hide settings after selection
      setState(() {
        showSettings = false;
      });
    }
  }

  void playNext() {
    _loadAndPlayEpisode(currentIndex + 1, isInitialPlay: true);
  }

  void playPrevious() {
    _loadAndPlayEpisode(currentIndex - 1, isInitialPlay: true);
  }

  void playEpisode(int index) {
    _loadAndPlayEpisode(index, isInitialPlay: true);
  }

  final List<String> qualityOptions = ['Auto', '1080p', '720p', '480p', '360p'];
  String formatDuration(Duration duration) {
    String hours = duration.inHours.toString().padLeft(2, '0');
    String minutes = duration.inMinutes
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    String seconds = duration.inSeconds
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    if (duration.inHours > 0) {
      return "$hours:$minutes:$seconds";
    }
    return "$minutes:$seconds";
  }

  List<BoxFit> fitOptions = [
    BoxFit.contain, // Standard
    BoxFit.cover, // Fill/Crop
    BoxFit.fill, // Stretch
    BoxFit.fitWidth,
    BoxFit.fitHeight,
  ];
  int currentFitIndex = 0;
  BoxFit get currentFit => fitOptions[currentFitIndex];
  final Map<BoxFit, IconData> _fitIcons = {
    BoxFit.contain: Icons.fullscreen_exit,
    BoxFit.cover: Icons.fullscreen,
    BoxFit.fill: Icons.photo_size_select_large,
    BoxFit.fitWidth: Icons.swap_horiz,
    BoxFit.fitHeight: Icons.swap_vert,
  };

  List<String> choicelist = ['Auto', '1080p', '720p', '540', '480p', 'DUBBED'];

  void _showSettings() {
    setState(() {
      showSettings = true;
    });

    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 5), () {
      // Increased timer slightly for usability
      if (mounted) {
        setState(() {
          showSettings = false;
        });
      }
    });
  }

  @override
  void dispose() {
    // Release PiP plugin resources
    _progressSaveTimer?.cancel();
    _completedSubscription?.cancel();
    _errorSubscription?.cancel();

    nimdispose(); // Your existing method is fine
    super.dispose();
  }

  void nimdispose() async {
    await _savePlaybackProgress();
    await player.dispose();
  }

  Future<void> _savePlaybackProgress() async {
    if (player.state.duration.inSeconds > 10) {
      Duration position = player.state.position; // Original commented line
      //  final duration = player.state.duration;

      await _userDataService.saveVideoProgress(
        widget.videoName,
        widget.source,
        '0',
        widget.videoUrl,
        position,
      );
    }
  }

  Future<void> _clearPlaybackProgress() async {
    await _userDataService.clearVideoProgress(
      widget.videoName,
      widget.source,
      '0',
      widget.videoUrl,
    );
  }

  Future<bool?> _showResumeDialog(Duration savedPosition) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false, // User must make a choice
      builder: (context) => AlertDialog(
        title: const Text('Resume Playback?'),
        content: Text(
          'You previously stopped watching at ${formatDuration(savedPosition)}. Would you like to resume?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false); // Return false
            },
            child: const Text('START OVER'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(true); // Return true
            },
            child: const Text('RESUME'),
          ),
        ],
      ),
    );
  }

  final List<BoxFit> _fitOptions = [
    BoxFit.contain, // Standard
    BoxFit.cover, // Fill/Crop
    BoxFit.fill, // Stretch
    BoxFit.fitWidth,
    BoxFit.fitHeight,
  ];
  late final UserDataService _userDataService;

  void _cycleBoxFit() {
    setState(() {
      currentFitIndex = (currentFitIndex + 1) % _fitOptions.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.black, actions: []),
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Video(
            controller: controller,
            controls: AdaptiveVideoControls,
            fit: currentFit,
            filterQuality: FilterQuality.high,
            wakelock: true,
            subtitleViewConfiguration: SubtitleViewConfiguration(
              visible: true,
              style: TextStyle(
                height: 1.4,
                fontSize: subtitleSize,
                letterSpacing: 0.0,
                wordSpacing: 0.0,
                color: subtitleColor,
                fontWeight: FontWeight.w700,
                backgroundColor: const Color(0xaa000000),
              ),
              padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 24.0),
            ),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showSettings)
                    Container(
                      width: 250, // Wider to accommodate buttons
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Subtitle size slider row
                          Row(
                            children: [
                              const Icon(
                                Icons.text_fields,
                                color: Colors.white,
                                size: 20,
                              ),
                              Expanded(
                                child: Slider(
                                  value: subtitleSize,
                                  min: 16.0,
                                  max: 48.0,
                                  onChanged: (value) {
                                    setState(() {
                                      subtitleSize = value;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          // Button for selecting external subtitle
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _selectSubtitle,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Select External Subtitle'),
                            ),
                          ),
                          const SizedBox(height: 5),
                          // Button for selecting external audio
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _selectAudio,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Select External Audio'),
                            ),
                          ),
                          const SizedBox(height: 5),
                          // Optional close button
                          TextButton(
                            onPressed: () {
                              setState(() {
                                showSettings = false;
                              });
                            },
                            child: const Text(
                              'Close',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                
                  IconButton(
                    icon: Icon(
                      _fitIcons[currentFit] ?? Icons.aspect_ratio,
                      color: Colors.white,
                    ),
                    tooltip: 'Change display mode',
                    onPressed: _cycleBoxFit,
                  ),
                  IconButton(
                    icon: Icon(
                      _playModeIcons[currentPlayMode] ?? Icons.aspect_ratio,
                      color: Colors.white,
                    ),
                    tooltip: 'Change playList mode',
                    onPressed: () async {
                      setState(() {
                        playlistMode(player);
                      });
                    },
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.picture_in_picture_outlined,
                      color: Colors.white,
                    ),
                    onPressed: () async {},
                  ),
                  IconButton(
                    icon: Icon(Icons.settings, color: Colors.white),
                    onPressed: _showSettings, // Updated to show settings panel
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
