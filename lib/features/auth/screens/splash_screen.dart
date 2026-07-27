import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../../routes/app_routes.dart';
import '../controllers/auth_controller.dart';


class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _dotsController;

  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  int _activeDot = 0;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _scaleAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _fadeController.forward();
    _scaleController.forward();

    _dotsController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 700),
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed) {
            if (mounted) setState(() => _activeDot = (_activeDot + 1) % 3);
            _dotsController.forward(from: 0);
          }
        });
    _dotsController.forward();

    _checkAuth();
  }

  void _checkAuth() async {
    final authController = Get.find<AuthController>();
    final isAuthenticated = await authController.checkAuthStatus();

    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) {
      if (isAuthenticated) {
        authController.goToPostAuthDestination();
      } else {
        Get.offNamed(Routes.onboarding);
      }
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _dotsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _scaleAnim,
                child: Image.asset(
                  'assets/images/minifoot.png',
                  width: 350,
                  height: 350,
                  fit: BoxFit.contain,
                ),
              ),

              Transform.translate(
                offset: const Offset(0, -70),
                child: Text(
                  'MINIFOOT',
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    color: kGreen,
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    letterSpacing: 3.0,
                  ),
                ),
              ),

              Transform.translate(
                offset: const Offset(0, -70),
                child: Text(
                  'Espace propriétaire.',
                  style: TextStyle(
                    color: kGreen.withValues(alpha: 0.65),
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 1.4,
                  ),
                ),
              ),

              const SizedBox(height: 64),

              _BouncingDots(activeDot: _activeDot),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Bouncing dots loader ───────────────────────────────────────────────────

class _BouncingDots extends StatefulWidget {
  final int activeDot;
  const _BouncingDots({required this.activeDot});

  @override
  State<_BouncingDots> createState() => _BouncingDotsState();
}

class _BouncingDotsState extends State<_BouncingDots>
    with TickerProviderStateMixin {
  final List<AnimationController> _controllers = [];
  final List<Animation<double>> _anims = [];

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 3; i++) {
      final ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 650),
      );
      _anims.add(
        Tween<double>(
          begin: 0,
          end: -16,
        ).animate(CurvedAnimation(parent: ctrl, curve: Curves.easeInOut)),
      );
      _controllers.add(ctrl);
    }
    _bounce(widget.activeDot);
  }

  @override
  void didUpdateWidget(_BouncingDots old) {
    super.didUpdateWidget(old);
    if (old.activeDot != widget.activeDot) _bounce(widget.activeDot);
  }

  void _bounce(int i) {
    _controllers[i].forward(from: 0).then((_) => _controllers[i].reverse());
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final isActive = i == widget.activeDot;
        return AnimatedBuilder(
          animation: _anims[i],
          builder: (_, _) => Transform.translate(
            offset: Offset(0, _anims[i].value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 7),
              width: isActive ? 15 : 10,
              height: isActive ? 15 : 10,
              decoration: BoxDecoration(
                color: isActive ? kGreen : kGreen.withValues(alpha: 0.35),
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      }),
    );
  }
}
