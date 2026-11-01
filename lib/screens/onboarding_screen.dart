import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:seelai_app/screens/role_selection_screen.dart';
import 'package:seelai_app/shared/widgets/vista_mascot.dart';
import 'package:seelai_app/shared/widgets/vista_sky.dart';
import 'package:seelai_app/themes/palette.dart';

class _Slide {
  const _Slide({
    required this.pose,
    required this.title,
    required this.body,
    this.lines = const [],
    this.scene = false,
  });

  /// True for wide illustrations (pup plus props); they take the full width
  /// and get no disc behind them.
  final bool scene;
  final String pose;
  final String title;
  final String body;
  final List<String> lines;
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _slides = [
    _Slide(
      pose: MascotPose.welcome,
      title: 'Meet Vista',
      body:
          'Your guide pup for everyday sight. Vista reads, spots and '
          'recognises things for you, out loud.',
      lines: ["Hi! I'm Vista.", 'Tap me anytime!', "Let's be friends."],
    ),
    _Slide(
      pose: MascotPose.pointListenGo,
      scene: true,
      title: 'Point, listen, go',
      body:
          'Aim your camera at a letter, a medicine label, a chair or a '
          "friend. Vista tells you what's there and where.",
      lines: ['A chair, on your left.', 'That is your medicine.', 'Hi, Ben!'],
    ),
    _Slide(
      pose: MascotPose.neverOnYourOwn,
      scene: true,
      title: 'Never on your own',
      body:
          'Your caretaker sees where you are and can call you. One tap on '
          'SOS alerts them and your MSWD office.',
      lines: ['Calling your caretaker...', 'MSWD is on it!'],
    ),
    _Slide(
      pose: MascotPose.celebrating,
      title: 'Ready when you are',
      body: 'Choose who is using Vista and sign in. It takes about a minute.',
      lines: ["Let's go!", 'Woohoo!', 'Best team ever.'],
    ),
  ];

  static const _topBarHeight = 56.0;

  final _pageController = PageController();
  int _page = 0;
  Timer? _timer;

  bool get _isLast => _page == _slides.length - 1;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    for (final s in _slides) {
      precacheImage(AssetImage(s.pose), context);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  /// Auto-advance, slow enough to read; any swipe restarts the clock.
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (_isLast) {
        _timer?.cancel();
      } else {
        _go(_page + 1);
      }
    });
  }

  void _go(int page) => _pageController.animateToPage(
    page,
    duration: const Duration(milliseconds: 420),
    curve: Curves.easeOutCubic,
  );

  void _next() {
    HapticFeedback.selectionClick();
    if (_isLast) {
      _finish();
    } else {
      _go(_page + 1);
      _startTimer();
    }
  }

  void _finish() {
    _timer?.cancel();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const RoleSelectionScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Palette.mist,
        body: LayoutBuilder(
          builder: (context, box) {
            final safeTop = MediaQuery.paddingOf(context).top;
            // The sheet stays put; slides swipe across it.
            final sheetTop = box.maxHeight * 0.6;
            final heroHeight = sheetTop - safeTop - _topBarHeight;
            return Stack(
              children: [
                Positioned(
                  top: sheetTop,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      color: Palette.surface,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  child: Column(
                    children: [
                      _buildTopBar(),
                      Expanded(
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: _slides.length,
                          onPageChanged: (i) {
                            setState(() => _page = i);
                            _startTimer();
                          },
                          itemBuilder: (context, i) => _SlideView(
                            slide: _slides[i],
                            controller: _pageController,
                            index: i,
                            heroHeight: heroHeight,
                          ),
                        ),
                      ),
                      _buildBottomBar(),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return SizedBox(
      height: _topBarHeight,
      child: Padding(
        padding: const EdgeInsets.only(left: 28, right: 12),
        child: Row(
          children: [
            const Text(
              'Vista',
              style: TextStyle(
                color: Palette.ink,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
            const Spacer(),
            AnimatedOpacity(
              opacity: _isLast ? 0 : 1,
              duration: const Duration(milliseconds: 200),
              child: TextButton(
                onPressed: _isLast ? null : _finish,
                style: TextButton.styleFrom(
                  foregroundColor: Palette.inkSoft,
                  minimumSize: const Size(64, 48),
                ),
                child: const Text(
                  'Skip',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 8, 24, 20),
      child: Row(
        children: [
          Semantics(
            label: 'Page ${_page + 1} of ${_slides.length}',
            child: Row(
              children: List.generate(_slides.length, (i) {
                final active = i == _page;
                return GestureDetector(
                  onTap: () {
                    _go(i);
                    _startTimer();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    margin: const EdgeInsets.only(right: 8),
                    height: 8,
                    width: active ? 28 : 8,
                    decoration: BoxDecoration(
                      color: active ? Palette.honeyDeep : Palette.lineStrong,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                );
              }),
            ),
          ),
          const Spacer(),
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _next,
              style: ElevatedButton.styleFrom(
                backgroundColor: Palette.violet,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 32),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                _isLast ? 'Get started' : 'Next',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SlideView extends StatelessWidget {
  const _SlideView({
    required this.slide,
    required this.controller,
    required this.index,
    required this.heroHeight,
  });

  final _Slide slide;
  final PageController controller;
  final int index;
  final double heroHeight;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final scene = slide.scene;
    // Scenes are wide and carry their own props; a lone pup sits on a disc.
    final artSize = scene
        ? (heroHeight * 0.96).clamp(0.0, width)
        : (heroHeight * 0.9).clamp(0.0, width * 0.86);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: heroHeight,
          width: double.infinity,
          child: AnimatedBuilder(
            animation: controller,
            builder: (context, child) {
              double offset = 0;
              if (controller.hasClients && controller.position.haveDimensions) {
                offset = (controller.page ?? 0) - index;
              }
              // Parallax: the art drifts slower than the page.
              return Transform.translate(
                offset: Offset(offset * -60, 0),
                child: Opacity(
                  opacity: (1 - offset.abs() * 1.2).clamp(0.0, 1.0),
                  child: child,
                ),
              );
            },
            child: Stack(
              alignment: Alignment.bottomCenter,
              clipBehavior: Clip.none,
              children: [
                if (!scene)
                  Positioned(
                    bottom: 8 + artSize * 0.07,
                    child: VistaLens(size: artSize * 0.84),
                  ),
                Positioned(
                  bottom: 8,
                  child: VistaMascot(
                    pose: slide.pose,
                    size: artSize,
                    lines: slide.lines,
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 28, 28, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(
                  slide.title,
                  style: const TextStyle(
                    color: Palette.ink,
                    fontSize: 32,
                    height: 1.15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                slide.body,
                style: const TextStyle(
                  color: Palette.inkMuted,
                  fontSize: 18,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
