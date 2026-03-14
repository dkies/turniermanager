class ResultEntry {
  ResultEntry(
    this.teamName,
    this.totalPoints,
    this.victories,
    this.draws,
    this.defeats,
    this.ownScoredGoals,
    this.enemyScoredGoals,
    this.avgScore,
  );

  String teamName;
  int totalPoints;
  int victories;
  int draws;
  int defeats;
  int ownScoredGoals;
  int enemyScoredGoals;
  double? avgScore;
}
