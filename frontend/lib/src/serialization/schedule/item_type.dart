enum ItemType {
  game('GAME'),
  break_('BREAK');

  final String value;
  const ItemType(this.value);

  static ItemType fromString(String value) {
    return ItemType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => throw ArgumentError('Unknown ItemType: $value'),
    );
  }
}
