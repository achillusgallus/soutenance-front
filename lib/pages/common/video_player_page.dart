import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:togoschool/services/token_storage.dart';
import 'package:togoschool/services/progress_service.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerPage extends StatefulWidget {
  final String videoUrl;
  final String title;
  final int? courseId;

  const VideoPlayerPage({
    super.key,
    required this.videoUrl,
    required this.title,
    this.courseId,
  });

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _error = false;
  DateTime? _startTime;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      final token = await TokenStorage.getToken();
      final headers = token != null
          ? {'Authorization': 'Bearer $token'}
          : <String, String>{};

      _videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
        httpHeaders: headers,
      );
      await _videoPlayerController.initialize();
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        autoPlay: true,
        looping: false,
        aspectRatio: _videoPlayerController.value.aspectRatio,
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Text(
              errorMessage,
              style: const TextStyle(color: Colors.white),
            ),
          );
        },
      );
      setState(() {});
    } catch (e) {
      setState(() => _error = true);
      debugPrint("Video Error: $e");
    }
  }

  Future<void> _saveProgress() async {
    if (_startTime != null && widget.courseId != null) {
      final timeSpent = DateTime.now().difference(_startTime!).inSeconds;
      try {
        final ProgressService progressService = ProgressService();
        await progressService.saveProgressLocally(
          widget.courseId!,
          100, // Mark as completed
          timeSpent,
        );
      } catch (e) {
        print('Erreur sauvegarde progression vidéo: $e');
      }
    }
  }

  @override
  void dispose() {
    _saveProgress();
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Center(
          child: _error
              ? const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, color: Colors.red, size: 48),
                    SizedBox(height: 16),
                    Text(
                      "Impossible de lire la vidéo",
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                )
              : _chewieController != null &&
                    _chewieController!.videoPlayerController.value.isInitialized
              ? Chewie(controller: _chewieController!)
              : const CircularProgressIndicator(color: Colors.white),
        ),
      ),
    );
  }
}
