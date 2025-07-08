import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoSplashScreen extends StatefulWidget {
  @override
  _VideoSplashScreenState createState() => _VideoSplashScreenState();
}

class _VideoSplashScreenState extends State<VideoSplashScreen> {
  VideoPlayerController? _controller;
  bool _isVideoFinished = false;
  bool _hasError = false;
  bool _isLoading = true;
  int _currentVideoIndex = 0;

  // List of video formats to try (in order of preference)
  final List<String> _videoFormats = [
    'assets/splash_web.mp4',      // Web-optimized MP4
    'assets/splash_mobile.mp4',   // Mobile MP4
    'assets/splash_web.webm',     // WebM fallback
    'assets/VPG.mp4',             // Your original video
  ];

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    await _tryNextVideoFormat();
  }

  Future<void> _tryNextVideoFormat() async {
    if (_currentVideoIndex >= _videoFormats.length) {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
      _navigateToHomeAfterDelay();
      return;
    }

    try {
      _controller = VideoPlayerController.asset(_videoFormats[_currentVideoIndex]);
      await _controller!.initialize();
      
      setState(() {
        _isLoading = false;
        _hasError = false;
      });
      
      _controller!.play();
      _controller!.addListener(_videoListener);
      
      print('Successfully loaded video: ${_videoFormats[_currentVideoIndex]}');
    } catch (e) {
      print('Failed to load video ${_videoFormats[_currentVideoIndex]}: $e');
      _controller?.dispose();
      _currentVideoIndex++;
      await _tryNextVideoFormat();
    }
  }

  void _videoListener() {
    if (_controller != null && _controller!.value.isInitialized) {
      if (_controller!.value.position >= _controller!.value.duration) {
        if (!_isVideoFinished) {
          _isVideoFinished = true;
          _navigateToHome();
        }
      }
    }
  }

  void _navigateToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomePage()),
    );
  }

  void _navigateToHomeAfterDelay() {
    // If video fails, show fallback for 3 seconds then navigate
    Future.delayed(Duration(seconds: 3), _navigateToHome);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Video player or fallback
          if (_isLoading)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 20),
                  Text(
                    'Loading...',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            )
          else if (_hasError)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Your app logo as fallback
                  Icon(
                    Icons.play_circle_outline,
                    color: Colors.white,
                    size: 100,
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Your App Name',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Loading...',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            )
          else if (_controller != null && _controller!.value.isInitialized)
            Center(
              child: AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: VideoPlayer(_controller!),
              ),
            ),
          
          // Skip button (optional)
          if (!_isLoading)
            Positioned(
              top: 50,
              right: 20,
              child: TextButton(
                onPressed: _navigateToHome,
                child: Text(
                  'Skip',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 16,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller?.removeListener(_videoListener);
    _controller?.dispose();
    super.dispose();
  }
}

// Placeholder for your home page
class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Home')),
      body: Center(
        child: Text('Welcome to your app!'),
      ),
    );
  }
}