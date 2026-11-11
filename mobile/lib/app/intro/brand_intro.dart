import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
import '../theme/tokens.dart';
import 'brand_logo.dart';

/// The animated brand intro shown over the app at start (≈3 s):
///
/// 1. the deep-forest background fades in (the native launch window has its
///    darkest colour, so there is no jump);
/// 2. the emblem is drawn by a pen, then its fill sweeps in;
/// 3. the wordmark rises in with a slight scale, and the logo holds;
/// 4. the overlay fades away over whatever the router shows (the dashboard).
///
/// It waits on the finished logo while [waiting] (the stored session is still
/// being resumed), then hands over. The [child] is built underneath from the
/// start and keeps its place in the tree, so nothing is rebuilt at the hand-over.
class BrandIntro extends StatefulWidget {
  const BrandIntro({super.key, required this.waiting, required this.child});

  final bool waiting;
  final Widget child;

  @override
  State<BrandIntro> createState() => _BrandIntroState();
}

class _BrandIntroState extends State<BrandIntro> with TickerProviderStateMixin {
  late final _reveal = AnimationController(
    vsync: this,
    duration: AppDurations.introReveal,
  )..addStatusListener(_onRevealStatus);
  late final _exit = AnimationController(
    vsync: this,
    duration: AppDurations.introExit,
  );
  late final _stages = LogoReveal.timeline(_reveal);
  late final _backdrop = CurvedAnimation(
    parent: _reveal,
    curve: const Interval(0, 0.14, curve: Curves.easeOut),
  );
  late final _fadeOut = ReverseAnimation(
    CurvedAnimation(parent: _exit, curve: Curves.easeInOutCubic),
  );
  late final _settle = Tween<double>(
    begin: 1,
    end: 1.03,
  ).animate(CurvedAnimation(parent: _exit, curve: Curves.easeOutCubic));

  BrandLogo? _logo;
  bool _loading = false;
  bool _gone = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loading) return;
    _loading = true;
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    BrandLogo.load(DefaultAssetBundle.of(context)).then(
      (logo) {
        if (!mounted) return;
        setState(() => _logo = logo);
        reduceMotion ? _reveal.value = 1 : _reveal.forward();
      },
      // Without its artwork the intro has nothing to show: hand over at once.
      onError: (Object _) {
        if (mounted) _reveal.value = 1;
      },
    );
  }

  @override
  void didUpdateWidget(BrandIntro old) {
    super.didUpdateWidget(old);
    if (old.waiting != widget.waiting) _maybeExit();
  }

  void _onRevealStatus(AnimationStatus status) {
    // Rebuild once at the end: the "still loading" bar depends on it.
    if (status.isCompleted && mounted) setState(() {});
    _maybeExit();
  }

  void _maybeExit() {
    if (!_reveal.isCompleted || widget.waiting || _exit.isAnimating) return;
    if (_exit.isCompleted || !mounted) return;
    _exit.forward().whenCompleteOrCancel(() {
      if (mounted) setState(() => _gone = true);
    });
  }

  @override
  void dispose() {
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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: ColoredBox(
        color: AppColors.darkBackground,
        child: FadeTransition(
          opacity: _backdrop,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.16),
                radius: 1.1,
                colors: [AppColors.forest, AppColors.darkBackground],
              ),
            ),
            child: Semantics(
              label: AppLocalizations.of(context).appTitle,
              child: Center(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // ~62 % of the short side, capped for tablets and landscape.
                    final shortSide = constraints.biggest.shortestSide;
                    final width = (shortSide * 0.62).clamp(160.0, 340.0);
                    final height =
                        width *
                        BrandLogo.viewBox.height /
                        BrandLogo.viewBox.width;
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ScaleTransition(
                          scale: _settle,
                          child: RepaintBoundary(
                            child: SizedBox(
                              width: width,
                              height: height,
                              child: logo == null
                                  ? null
                                  : CustomPaint(
                                      painter: BrandLogoPainter(
                                        logo: logo,
                                        reveal: _stages,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                        _StillLoading(
                          visible: widget.waiting && _reveal.isCompleted,
                          width: width * 0.36,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A hairline progress bar under the logo, only if resuming the session takes
/// longer than the intro itself.
class _StillLoading extends StatelessWidget {
  const _StillLoading({required this.visible, required this.width});

  final bool visible;
  final double width;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: visible ? 1 : 0,
      duration: AppDurations.medium,
      child: SizedBox(
        width: width,
        child: visible
            ? ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: LinearProgressIndicator(
                  minHeight: 2,
                  color: AppColors.logoMint,
                  backgroundColor: AppColors.logoIvory.withValues(alpha: 0.12),
                ),
              )
            : const SizedBox(height: 2),
      ),
    );
  }
}
