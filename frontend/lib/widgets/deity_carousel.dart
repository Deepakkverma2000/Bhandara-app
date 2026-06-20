import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class DeitySlide {
  final String name;
  final String imageAsset;

  const DeitySlide({required this.name, required this.imageAsset});
}

class DeityCarousel extends StatefulWidget {
  const DeityCarousel({super.key});

  static const slides = [
    DeitySlide(
      name: 'Shri Krishna',
      imageAsset: 'assets/images/Krishna ji.png',
    ),
    DeitySlide(
      name: 'Shiv Ji',
      imageAsset: 'assets/images/Shivji.png',
    ),
    DeitySlide(
      name: 'Maa Durga',
      imageAsset: 'assets/images/Durga mata.png',
    ),
    DeitySlide(
      name: 'Ganesh Ji',
      imageAsset: 'assets/images/Ganesh ji.png',
    ),
    DeitySlide(
      name: 'Vishnu Ji',
      imageAsset: 'assets/images/Vishnu ji.png',
    ),
    DeitySlide(
      name: 'Shani Dev Ji',
      imageAsset: 'assets/images/Shanidev ji.png',
    ),
  ];

  @override
  State<DeityCarousel> createState() => _DeityCarouselState();
}

class _DeityCarouselState extends State<DeityCarousel> {
  final _pageController = PageController(viewportFraction: 0.88);
  int _currentPage = 0;
  Timer? _autoTimer;

  @override
  void initState() {
    super.initState();
    _autoTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_pageController.hasClients) return;
      final next = (_currentPage + 1) % DeityCarousel.slides.length;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 148,
          child: PageView.builder(
            controller: _pageController,
            itemCount: DeityCarousel.slides.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) {
              final slide = DeityCarousel.slides[index];
              final isActive = index == _currentPage;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: isActive ? 0 : 8,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isActive ? AppColors.gold : AppColors.gold.withValues(alpha: 0.4),
                    width: isActive ? 2.5 : 1,
                  ),
                  boxShadow: [
                    if (isActive)
                      BoxShadow(
                        color: AppColors.maroon.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        slide.imageAsset,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: AppColors.maroon,
                          child: const Icon(
                            Icons.temple_hindu_rounded,
                            size: 56,
                            color: AppColors.gold,
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.65),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 12,
                        bottom: 10,
                        child: Row(
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              color: AppColors.lightGold,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              slide.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(DeityCarousel.slides.length, (index) {
            final active = index == _currentPage;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 18 : 7,
              height: 7,
              decoration: BoxDecoration(
                color: active ? AppColors.gold : Colors.white.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
      ],
    );
  }
}
