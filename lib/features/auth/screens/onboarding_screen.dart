import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../../routes/app_routes.dart';


class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;
  double _pageOffset = 0;

  final List<_OnboardingData> _pages = const [
    // Slide 1 — même photo terrain que minifoot_mobile slide 1
    _OnboardingData(
      imageUrl: 'assets/images/terrain.jpeg',
      fallbackAsset: 'assets/images/terrain.webp',
      title: 'Gérez vos\nterrains',
      subtitle:
          'Ajoutez vos terrains, configurez les créneaux et les tarifs. Tout est centralisé en un seul endroit.',
    ),
    // Slide 2 — photo joueurs / match (minifoot_mobile slide 2)
    _OnboardingData(
      imageUrl: 'assets/images/equipe.jpg',
      fallbackAsset: 'assets/images/ballon.png',
      title: 'Suivez vos\nrevenus',
      subtitle:
          'Visualisez vos performances financières en temps réel. Paiements, réservations, statistiques — tout est clair.',
    ),
    // Slide 3 — même photo match que minifoot_mobile slide 3
    _OnboardingData(
      imageUrl: 'assets/images/match.jpg',
      fallbackAsset: 'assets/images/minifoot.png',
      title: 'Organisez des\ntournois',
      subtitle:
          'Créez et gérez des tournois sur vos terrains. Attirez plus de joueurs et boostez votre activité.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() => _pageOffset = _controller.page ?? 0);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _skip() {
    _controller.animateToPage(
      _pages.length - 1,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOutCubic,
    );
  }

  void _next() {
    if (_currentPage < _pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    } else {
      Get.offNamed(Routes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Backgrounds avec parallax ──
          ...List.generate(_pages.length, (i) {
            final delta = _pageOffset - i;
            final parallax = delta * 80.0;
            final opacity = (1.0 - delta.abs()).clamp(0.0, 1.0);

            return Opacity(
              opacity: opacity,
              child: Transform.translate(
                offset: Offset(parallax, 0),
                child: Image.asset(
                  _pages[i].imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
            );
          }),

          // ── Overlay sombre dégradé ──
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.20),
                  Colors.black.withValues(alpha: 0.65),
                  Colors.black.withValues(alpha: 0.97),
                ],
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
          ),

          // ── PageView invisible pour capturer le swipe ──
          PageView.builder(
            controller: _controller,
            itemCount: _pages.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (_, _) => const SizedBox.expand(),
          ),

          // ── Bouton Passer ──
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 8, right: 16),
                child: AnimatedOpacity(
                  opacity: _currentPage < _pages.length - 1 ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: TextButton(
                    onPressed: _skip,
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.15),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 8),
                    ),
                    child: const Text(
                      'Passer',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Bas : texte + dots + bouton ──
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(28, 40, 28, 50),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.95),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Titre ──
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.15),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                            parent: anim, curve: Curves.easeOut)),
                        child: child,
                      ),
                    ),
                    child: Align(
                      key: ValueKey(_currentPage),
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _pages[_currentPage].title,
                        style: const TextStyle(
                          fontFamily: 'Orbitron',
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── Sous-titre ──
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 450),
                    transitionBuilder: (child, anim) =>
                        FadeTransition(opacity: anim, child: child),
                    child: Align(
                      key: ValueKey('sub_$_currentPage'),
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _pages[_currentPage].subtitle,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.70),
                          fontSize: 14,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── Dots + bouton ──
                  Row(
                    children: [
                      // Dots
                      Row(
                        children: List.generate(_pages.length, (i) {
                          final active = i == _currentPage;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            margin: const EdgeInsets.only(right: 8),
                            width: active ? 28 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: active
                                  ? kGreen
                                  : Colors.white.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        }),
                      ),
                      const Spacer(),
                      // Bouton Suivant / Commencer
                      GestureDetector(
                        onTap: _next,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: 54,
                          padding:
                              const EdgeInsets.symmetric(horizontal: 28),
                          decoration: BoxDecoration(
                            color: kGreen,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _currentPage < _pages.length - 1
                                    ? 'Suivant'
                                    : 'Commencer',
                                style: const TextStyle(
                                  fontFamily: 'Orbitron',
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(PhosphorIconsRegular.caretRight,
                                  color: Colors.white, size: 22),
                            ],
                          ),
                        ),
                      ),
                    ],
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

// ── Data model ────────────────────────────────────────────────────────────────

class _OnboardingData {
  final String imageUrl;
  final String fallbackAsset;
  final String title;
  final String subtitle;

  const _OnboardingData({
    required this.imageUrl,
    required this.fallbackAsset,
    required this.title,
    required this.subtitle,
  });
}
