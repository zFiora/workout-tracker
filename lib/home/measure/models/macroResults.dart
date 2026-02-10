class MacroResult {
  final int calories;
  final int proteinG;
  final int carbsG;
  final int fatG;

  const MacroResult({
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
  });
}

class MacroPack {
  final MacroResult maintenance;
  final MacroResult cutting;
  final MacroResult bulking;

  const MacroPack({
    required this.maintenance,
    required this.cutting,
    required this.bulking,
  });
}
