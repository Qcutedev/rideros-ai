import 'package:decimal/decimal.dart';

/// Today's net profit against the rider's daily goal (exact decimals; the
/// double is only for drawing the ring).
class GoalProgress {
  const GoalProgress({required this.net, required this.goal});

  final Decimal net;

  /// Always > 0 (the API rejects 0 and negative goals).
  final Decimal goal;

  bool get reached => net >= goal;

  /// Still to earn; zero once reached.
  Decimal get remaining => reached ? Decimal.zero : goal - net;

  /// Earned above the goal; zero until reached.
  Decimal get surplus => reached ? net - goal : Decimal.zero;

  /// Ring fill 0–1. A loss shows an empty ring, never a negative one.
  double get fraction {
    if (net <= Decimal.zero) return 0;
    if (reached) return 1;
    return (net / goal).toDouble().clamp(0.0, 1.0);
  }

  /// Whole percent, rounded down so 99.6% never reads "100%" before the goal.
  /// Worked out in decimals: 29 of 100 is 29, not 28.999… as a double.
  int get percent {
    if (net <= Decimal.zero) return 0;
    if (reached) return 100;
    final ratio = (net * Decimal.fromInt(100)) / goal;
    return ratio.floor().toInt();
  }
}
