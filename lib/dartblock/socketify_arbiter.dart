import 'package:dartblock_code/core/dartblock_executor.dart';
import 'package:dartblock_code/core/dartblock_program.dart';
import '../controlers/scene_controler.dart';

/// A custom Arbiter/Executor that holds the SceneController.
/// This allows Native Functions to access the UI state and scene manipulation.
///
/// This is the bridge between the dartblock execution environment and
/// the Socketify UI framework.
class SocketifyArbiter extends DartBlockExecutor {
  final SceneController sceneController;

  SocketifyArbiter({
    required DartBlockProgram program,
    required this.sceneController,
  }) : super(program);

  /// Convenience getter for accessing scene information
  String get currentSceneId => sceneController.currentSceneId ?? '';

  /// Convenience getter for accessing scene name
  String get currentSceneName => sceneController.currentSceneName;

  /// Convenience getter for top-level nodes count
  int get topLevelNodeCount => sceneController.topLevelNodes.length;
}
