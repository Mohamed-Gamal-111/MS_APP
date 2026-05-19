class FingerTapResult {
  final String hand; 
  final int taps;
  final double speed;
  final double irregularity;
  final String edss;
  final DateTime date;

  FingerTapResult({
    required this.hand,
    required this.taps,
    required this.speed,
    required this.irregularity,
    required this.edss,
    required this.date,
  });
}
