import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import '../../presentation/controllers/auth_controller.dart';
import '../../../../core/utils/gps_helper.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AuthController _authController;

  // Fallback animation
  late final AnimationController _animController;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _glowAnim;

  // Video
  late VideoPlayerController _videoController;
  bool _isVideoInitialized = false;
  bool _hasVideoError = false;

  // Navigation guards — all three must be true before navigating
  bool _minTimerElapsed = false;  // ≥ 5 seconds minimum
  bool _servicesReady   = false;  // auth + GPS done
  bool _videoFinished   = false;  // video played to end (or errored)
  bool _hasNavigated    = false;  // prevent double navigation
  bool _isAuthenticated = false;

  static const _kMinSplash    = Duration(seconds: 5);
  // Hard ceiling — no matter what happens, navigate after this
  static const _kHardTimeout  = Duration(seconds: 9);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _authController = Get.find<AuthController>();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _scaleAnim = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.1, 0.8, curve: Curves.easeOut),
    );
    _glowAnim = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.4, 1.0, curve: Curves.easeInOut),
    );
    _animController.forward();

    // ── 1. Minimum timer — runs independently ──────────────────
    Future.delayed(_kMinSplash).then((_) {
      if (!mounted) return;
      _minTimerElapsed = true;
      _tryNavigate();
    });

    // ── Hard timeout — guarantees navigation no matter what ────
    Future.delayed(_kHardTimeout).then((_) {
      if (!mounted || _hasNavigated) return;
      _minTimerElapsed = true;
      _servicesReady   = true;
      _videoFinished   = true;
      _tryNavigate();
    });

    // ── 2. Services ────────────────────────────────────────────
    _runServices();

    // ── 3. Video ───────────────────────────────────────────────
    _initVideo();
  }

  // ── Services (auth + GPS) ─────────────────────────────────────
  Future<void> _runServices() async {
    try {
      final results = await Future.wait([
        _authController.checkAuth(),
        GpsHelper.requestPermission()
            .timeout(const Duration(seconds: 3), onTimeout: () => false)
            .catchError((_) => false),
      ]);
      _isAuthenticated = results.first;
    } catch (e) {
      debugPrint('Services init error: $e');
      _isAuthenticated = false;
    }
    _servicesReady = true;
    _tryNavigate();
  }

  // ── Video ─────────────────────────────────────────────────────
  Future<void> _initVideo() async {
    _videoController = VideoPlayerController.asset('assets/splsh.mp4');
    try {
      await _videoController.initialize();
      _videoController.setLooping(false);
      _videoController.setVolume(1.0);
      _videoController.addListener(_onVideoProgress);
      if (mounted) setState(() => _isVideoInitialized = true);
      await _videoController.play();
    } catch (e) {
      debugPrint('Video Splash error: $e');
      if (mounted) setState(() => _hasVideoError = true);
      _videoFinished = true;
      _tryNavigate();
    }
  }

  void _onVideoProgress() {
    if (!mounted) return;
    final v = _videoController.value;
    final pos = v.position;

    // Audio fade 2s → 3s
    if (pos.inMilliseconds >= 2000 && pos.inMilliseconds < 3000) {
      final vol = (3000 - pos.inMilliseconds) / 1000.0;
      _videoController.setVolume(vol.clamp(0.0, 1.0));
    } else if (pos.inMilliseconds >= 3000) {
      _videoController.setVolume(0.0);
    }

    // Video end — detect when position is within last 200ms OR past duration
    if (v.isInitialized && v.duration.inMilliseconds > 0) {
      final nearEnd = pos.inMilliseconds >= (v.duration.inMilliseconds - 200);
      final pastEnd = !v.isPlaying && pos.inMilliseconds > 0;
      if ((nearEnd || pastEnd) && !_videoFinished) {
        _videoFinished = true;
        _tryNavigate();
      }
    }
  }

  // ── Central navigation gate ───────────────────────────────────
  void _tryNavigate() {
    if (_hasNavigated || !mounted) return;
    if (!_minTimerElapsed || !_servicesReady || !_videoFinished) return;

    _hasNavigated = true;
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    if (_isAuthenticated) {
      Get.offAllNamed('/dashboard');
    } else {
      Get.offAllNamed('/login');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_isVideoInitialized || _hasVideoError) return;
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        _videoController.pause();
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
        break;
      case AppLifecycleState.resumed:
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
        if (!_videoFinished && !_hasNavigated) {
          _videoController.play();
        }
        break;
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _animController.dispose();
    if (_isVideoInitialized) {
      _videoController.removeListener(_onVideoProgress);
      _videoController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ── Fallback static splash ────────────────────────────────
    if (_hasVideoError || !_isVideoInitialized) {
      return Scaffold(
        backgroundColor: const Color(0xFF020617),
        body: Stack(
          children: [
            // Glows
            Align(
              alignment: const Alignment(-1.2, -1.2),
              child: Container(
                width: 260, height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    Colors.tealAccent.withValues(alpha: 0.16),
                    Colors.transparent,
                  ]),
                ),
              ),
            ),
            Align(
              alignment: const Alignment(1.1, 1.2),
              child: Container(
                width: 220, height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    Colors.amberAccent.withValues(alpha: 0.18),
                    Colors.transparent,
                  ]),
                ),
              ),
            ),
            // Logo
            Center(
              child: AnimatedBuilder(
                animation: _animController,
                builder: (context, _) {
                  final scale = 0.4 + (_scaleAnim.value * 0.6);
                  final glow  = 10 + (_glowAnim.value * 25);
                  return Opacity(
                    opacity: _fadeAnim.value,
                    child: Transform.scale(
                      scale: scale,
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.tealAccent.withValues(alpha: 0.5),
                              blurRadius: glow, spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            'assets/images/rassco_logo.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            // Bottom text + progress
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 48),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'RASSCO',
                      style: TextStyle(
                        fontFamily: 'BeIN',
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'إدارة مخزون ذكية وسهلة',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: 120,
                      child: LinearProgressIndicator(
                        minHeight: 3,
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF40E0D0),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    // ── Full-screen video splash (BoxFit.cover) ───────────────
    // We wrap in a ClipRect and scale by 1.15x to crop the edges and hide the Gemini watermark
    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      body: Stack(
        children: [
          Positioned.fill(
            child: ClipRect(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _videoController.value.size.width,
                  height: _videoController.value.size.height,
                  child: VideoPlayer(_videoController),
                ),
              ),
            ),
          ),
          // Gradient overlays to blend screen top and bottom
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0x99020617), // Dark top blend
                    Colors.transparent,
                    Colors.transparent,
                    Color(0xCC020617), // Dark bottom blend to highlight the loading indicators
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.0, 0.2, 0.7, 1.0],
                ),
              ),
            ),
          ),
          // Beautiful interactive progress indicator and brand label
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 40.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Glowing loading bar
                    Container(
                      width: 140,
                      height: 4,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF40E0D0).withValues(alpha: 0.5),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: const LinearProgressIndicator(
                          backgroundColor: Colors.white10,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF40E0D0),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
