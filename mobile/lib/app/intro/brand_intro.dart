import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
import '../theme/tokens.dart';
import 'brand_logo.dart';
import 'ride_scene.dart';

/// The animated intro shown over the app at start (≈3 s), a short ride:
///
/// 1. the deep-forest background fades in (the native launch window has its
///    darkest colour, so there is no jump);
/// 2. the rider rides in from the left on a hairline road and slows to the
///    centre; the camera then rides along (lane marks and wind keep streaming);
/// 3. the RiderOS wordmark rises in under the road;
/// 4. the rider accelerates off to the right and the intro fades over whatever
///    the router shows (the dashboard).
///
/// While [waiting] (the stored session is still being resumed) it keeps riding
/// at the centre, then leaves. The [child] is built underneath from the start
/// and keeps its place in the tree, so nothing is rebuilt at the hand-over.
class BrandIntro extends StatefulWidget {
  const BrandIntro({super.key, required this.waiting, required this.child});

  final bool waiting;
  final Widget child;

  @override
  State<BrandIntro> createState() => _BrandIntroState();
}

class _BrandIntroState extends State<BrandIntro> with TickerProviderStateMixin {
  /// Cruising speed of the camera, logo units per second.
  static const _roadSpeed = 1100.0;

  late final _reveal = AnimationController(
    vsync: this,
    duration: AppDurations.introReveal,
  )..addStatusListener((_) => _maybeExit());
  late final _exit = AnimationController(
    vsync: this,
    duration: AppDurations.introExit,
  );
  late final _backdrop = CurvedAnimation(
    parent: _reveal,
    curve: const Interval(0, 0.15, curve: Curves.easeOut),
  );
  late final _fadeOut = ReverseAnimation(
    CurvedAnimation(
      parent: _exit,
      curve: const Interval(0.35, 1, curve: Curves.easeInOutCubic),
    ),
  );

  /// Distance ridden, integrated each frame from the scene's cruise speed.
  final _road = ValueNotifier<double>(0);
  late final Ticker _ride = createTicker(_onRide);
  Duration _lastTick = Duration.zero;

  BrandLogo? _logo;
  RideScene? _scene;
  bool _loading = false;
  bool _gone = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loading) return;
    _loading = true;
    final motion = !(MediaQuery.maybeDisableAnimationsOf(context) ?? false);
    BrandLogo.load(DefaultAssetBundle.of(context)).then(
      (logo) {
        if (!mounted) return;
        setState(() {
          _logo = logo;
          _scene = RideScene.timeline(
            reveal: _reveal,
            exit: _exit,
            road: _road,
            motion: motion,
          );
        });
        if (motion) {
          _ride.start();
          _reveal.forward();
        } else {
          _reveal.value = 1;
        }
      },
      // Without its artwork the intro has nothing to show: hand over at once.
      onError: (Object _) {
        if (mounted) _reveal.value = 1;
      },
    );
  }

  void _onRide(Duration elapsed) {
    final dt = (elapsed - _lastTick).inMicroseconds / 1e6;
    _lastTick = elapsed;
    _road.value += dt * _roadSpeed * (_scene?.cruise ?? 0);
  }

  @override
  void didUpdateWidget(BrandIntro old) {
    super.didUpdateWidget(old);
    if (old.waiting != widget.waiting) _maybeExit();
  }

  void _maybeExit() {
    if (!_reveal.isCompleted || widget.waiting || _exit.isAnimating) return;
    if (_exit.isCompleted || !mounted) return;
    _exit.forward().whenCompleteOrCancel(() {
      if (!mounted) return;
      _ride.stop();
      setState(() => _gone = true);
    });
  }

  @override
  void dispose() {
    _ride.dispose();
    _road.dispose();
    _backdrop.dispose();
    _reveal.dispose();
    _exit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (!_gone)
          FadeTransition(
            opacity: _fadeOut,
            child: AbsorbPointer(
              child: BlockSemantics(child: _overlay(context)),
            ),
          ),
      ],
    );
  }

  Widget _overlay(BuildContext context) {
    final logo = _logo;
    final scene = _scene;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: ColoredBox(
        color: AppColors.darkBackground,
        child: FadeTransition(
          opacity: _backdrop,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.1),
                radius: 1.1,
                colors: [AppColors.forest, AppColors.darkBackground],
              ),
            ),
            child: Semantics(
              label: AppLocalizations.of(context).appTitle,
              child: logo == null || scene == null
                  ? const SizedBox.expand()
                  : RepaintBoundary(
                      child: CustomPaint(
                        size: Size.infinite,
                        painter: RideScenePainter(logo: logo, scene: scene),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
