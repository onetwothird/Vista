import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:seelai_app/screens/role_selection_screen.dart';
import 'package:seelai_app/shared/widgets/auth_mascot_header.dart';
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

  /// True for full illustrations (pup plus props) that sit on a light card.
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

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
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

  final _pageController = PageController();
  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 9000),
  )..repeat();
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
    if (MediaQuery.of(context).disableAnimations) _float.stop();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _float.dispose();
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
    duration: const Duration(milliseconds: 450),
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
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Palette.violetDeep,
        body: LayoutBuilder(
          builder: (context, box) {
            // The white sheet stays put; slides swipe across it.
            final sheetTop = box.maxHeight * 0.58;
            return Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: sheetTop + 40,
                  child: RepaintBoundary(
                    child: AnimatedBuilder(
                      animation: Listenable.merge([_float, _pageController]),
                      builder: (context, _) => CustomPaint(
                        painter: VistaSkyPainter(
                          t: _float.value,
                          page:
                              _pageController.hasClients &&
                                  _pageController.position.haveDimensions
                              ? _pageController.page ?? 0
                              : _page.toDouble(),
                          horizon: sheetTop,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: sheetTop,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      color: Palette.paper,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(32),
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  child: Column(
                    children: [
                      _buildTopBar(),
                      Expanded(
                        child: Builder(
                          builder: (context) {
                            // Hero fills the navy area down to the sheet.
                            final visualH =
                                sheetTop -
                                MediaQuery.paddingOf(context).top -
                                60 -
                                8;
                            return PageView.builder(
                              controller: _pageController,
                              itemCount: _slides.length,
                              onPageChanged: (i) {
                                setState(() => _page = i);
                                _startTimer();
                              },
                              itemBuilder: (context, i) => _SlideView(
                                slide: _slides[i],
                                controller: _pageController,
                                float: _float,
                                index: i,
                                visualHeight: visualH,
                              ),
                            );
                          },
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
      height: 60,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            const SizedBox(width: 12),
            const Text(
              'Vista',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
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
                  foregroundColor: Colors.white,
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
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
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
                    margin: const EdgeInsets.only(right: 6),
                    height: 10,
                    width: active ? 32 : 10,
                    decoration: BoxDecoration(
                      color: active ? Palette.honeyDeep : Palette.lineStrong,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                );
              }),
            ),
          ),
          const Spacer(),
          SizedBox(
            height: 60,
            child: ElevatedButton(
              onPressed: _next,
              style: ElevatedButton.styleFrom(
                backgroundColor: Palette.honey,
                foregroundColor: Palette.violetDeep,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 32),
                shape: const StadiumBorder(),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _isLast ? 'Get started' : 'Next',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.pets_rounded, size: 20),
                ],
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
    required this.float,
    required this.index,
    required this.visualHeight,
  });

  final _Slide slide;
  final PageController controller;
  final Animation<double> float;
  final int index;
  final double visualHeight;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final scene = slide.scene;
    final mascotSize = scene
        ? math.min(visualHeight * 0.8, width * 0.78)
        : math.min(visualHeight * 0.86, width * 0.7);
    final lens = mascotSize * (scene ? 1.16 : 1.18);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: visualHeight,
          width: double.infinity,
          child: AnimatedBuilder(
            animation: controller,
            builder: (context, child) {
              double offset = 0;
              if (controller.hasClients && controller.position.haveDimensions) {
                offset = (controller.page ?? 0) - index;
              }
              // Parallax: the hero drifts slower than the page.
              return Transform.translate(
                offset: Offset(offset * -80, 0),
                child: Opacity(
                  opacity: (1 - offset.abs() * 1.2).clamp(0.0, 1.0),
                  child: child,
                ),
              );
            },
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                IgnorePointer(
                  child: SizedBox(
                    width: lens,
                    height: lens,
                    child: AnimatedBuilder(
                      animation: float,
                      builder: (context, _) =>
                          CustomPaint(painter: LensPainter(float.value)),
                    ),
                  ),
                ),
                // Scene illustrations have dark labels, so they sit on a
                // soft light window inside the lens.
                if (scene)
                  Container(
                    width: mascotSize * 1.04,
                    height: mascotSize * 1.04,
                    decoration: BoxDecoration(
                      color: Palette.honeyTint,
                      borderRadius: BorderRadius.circular(44),
                      border: Border.all(color: Palette.honey, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Palette.tealBright.withValues(alpha: 0.35),
                          blurRadius: 40,
                        ),
                      ],
                    ),
                  ),
                VistaMascot(
                  pose: slide.pose,
                  size: mascotSize,
                  lines: slide.lines,
                  bubbleColor: Palette.honey,
                  bubbleTextColor: Palette.violetDeep,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(
                  slide.title,
                  style: const TextStyle(
                    color: Palette.ink,
                    fontSize: 34,
                    height: 1.1,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 12),
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
