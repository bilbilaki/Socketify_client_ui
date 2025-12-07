import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Minimal UserDataService for video player functionality.
/// Only includes watched status and video progress management used by VideoPlayerScreen.
class UserDataService extends ChangeNotifier {
  // Keys used by the player
  static const String _isWatchedEpisodeKey = 'isWatchedEpisode';
  static const String _customBaseUrlKey = 'custoombaseurl';  // Minimal for clearAll, if needed

  SharedPreferences? _prefs;
  late SharedPreferences perfs;

  UserDataService() {
    _init();
  }

  Future<void> _init() async {
    _prefs ??= await SharedPreferences.getInstance();
    perfs = _prefs ?? await SharedPreferences.getInstance();
    // No additional loading needed for minimal usage
  }

  /// Helper to get list of strings from SharedPreferences
  List<String> _getStringList(String key) {
    return List<String>.from(_prefs?.getStringList(key) ?? const []);
  }

  /// Helper to set list of strings to SharedPreferences
  Future<void> _setStringList(String key, List<String> list) async {
    await _prefs?.setStringList(key, list);
  }

  /// Generate unique key for video progress
  String _getVideoProgressKey(String videoId, String videoName, String source, String url) {
    return 'video_progress_${videoId}_${videoName}_${source}_${url.hashCode}';
  }

  /// Save playback position for a video
  Future<void> saveVideoProgress(String videoId, String videoName, String source, String url, Duration position) async {
    final key = _getVideoProgressKey(videoId, videoName, source, url);
    await _prefs?.setInt(key, position.inSeconds);
  }

  /// Retrieve saved playback position for a video
  Future<Duration?> getVideoProgress(String videoId, String videoName, String source, String url) async {
    final key = _getVideoProgressKey(videoId, videoName, source, url);
    final seconds = _prefs?.getInt(key);
    if (seconds != null && seconds != 0) {
      return Duration(seconds: seconds);
    }
    return null;
  }

  /// Clear saved progress for a video
  Future<void> clearVideoProgress(String videoId, String videoName, String source, String url) async {
    final key = _getVideoProgressKey(videoId, videoName, source, url);
    await _prefs?.remove(key);
  }

  /// Toggle watched state for a link (used for marking as watched)
  Future<void> toggleIsWatchedLink(dynamic seriesId, dynamic seasonNumber, dynamic episodeNumber, dynamic url) async {
    final String watchedKey = [seriesId, seasonNumber, episodeNumber, url].where((e) => e != null).join(":");
    final List<String> watchedList = _prefs?.getStringList(_isWatchedEpisodeKey) ?? [];
    watchedList.add(watchedKey);
    await _prefs?.setStringList(_isWatchedEpisodeKey, watchedList);
    notifyListeners();
  }

  /// Clear all user data (minimal version for watched and progress)
  Future<void> clearAllUserData() async {
    // Clear watched and progress keys
    final keysToRemove = [_isWatchedEpisodeKey, _customBaseUrlKey];
    for (final key in keysToRemove) {
      await _prefs?.remove(key);
    }
    // Note: Progress keys are dynamically named, so this removes known ones; full clearing would require iterating all prefs (not implemented here for minimalism)
    notifyListeners();
  }
}