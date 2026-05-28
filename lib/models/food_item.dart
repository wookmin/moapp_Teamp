class FoodItem {
  const FoodItem({
    required this.name,
    required this.expiryLabel,
    required this.statusLabel,
    this.isUrgent = false,
  });

  final String name;
  final String expiryLabel;
  final String statusLabel;
  final bool isUrgent;
}
