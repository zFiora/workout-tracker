double estimate1RM({required double weight, required int reps}) {
  if (weight <= 0) return 0;
  if (reps <= 1) return weight;

  // Epley: 1RM = w * (1 + reps/30)
  return weight * (1 + reps / 30.0);
}

double round1(double v) => (v * 10).roundToDouble() / 10.0;
