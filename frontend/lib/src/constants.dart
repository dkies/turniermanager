import 'package:flutter/material.dart';

class Constants {
  // Style related
  static const double largeHeaderTextSize = 26;
  static const double mediumHeaderTextSize = 22;
  static const double standardTextSize = 16;
  static const Color textColor = Colors.white;

  static const double headerIonSize = 40;

  static const largeHeaderTextStyle = TextStyle(
    fontSize: largeHeaderTextSize,
    color: textColor,
  );
  static const mediumHeaderTextStyle = TextStyle(
    fontSize: mediumHeaderTextSize,
    color: textColor,
  );
  static const standardTextStyle = TextStyle(
    fontSize: standardTextSize,
    color: textColor,
  );

  // miscellaneous
  static const int maxNumberOfTeamsDefault = 6;
  static const int refreshDurationInSeconds = 20;
}
