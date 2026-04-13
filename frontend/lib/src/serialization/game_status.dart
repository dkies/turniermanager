enum GameStatus {
  scheduled('SCHEDULED'),
  inProgress('IN_PROGRESS'),
  completed('COMPLETED'),
  completedAndStated('COMPLETED_AND_STATED'),
  canceled('CANCELED');

  final String value;
  const GameStatus(this.value);

  static GameStatus fromString(String value) {
    return GameStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => throw ArgumentError('Unknown GameStatus: $value'),
    );
  }
}
