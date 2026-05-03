/// Incremental (running) average.
///
/// Returns the new average after incorporating a new sample.
///
/// [oldAverage]  : current average value
/// [newValue]    : the newly observed value
/// [currentCount]: number of samples already averaged (≥ 0)
double runningAverage(double oldAverage, double newValue, int currentCount) {
  final n = currentCount + 1;
  return oldAverage + (newValue - oldAverage) / n;
}