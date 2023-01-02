import 'dart:async';

class RatePerSecCalculator {
  int _lastProcessed = 0;
  int _currentProcessed = 0;

  void setCurrentProcessedIndex(int i) => _currentProcessed = i;

  RatePerSecCalculator(Function(int) onRate) {
    Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        final diff = _currentProcessed - _lastProcessed;
        _lastProcessed = _currentProcessed;
        onRate(diff);
      },
    );
  }
}
