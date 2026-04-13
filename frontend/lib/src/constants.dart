import 'package:flutter/material.dart';

class Constants {
  // Style related
  static const double largeHeaderTextSize = 26;
  static const double mediumHeaderTextSize = 22;
  static const double standardTextSize = 16;
  static const Color textColor = Colors.white;

  static const double headerIonSize = 40;

  /// Schrift mit Unterstützung für deutsche Sonderzeichen (ß, ä, ö, ü).
  static const String _fontFamily = 'NotoSans';

  static const largeHeaderTextStyle = TextStyle(
    fontSize: largeHeaderTextSize,
    color: textColor,
    fontFamily: _fontFamily,
  );
  static const mediumHeaderTextStyle = TextStyle(
    fontSize: mediumHeaderTextSize,
    color: textColor,
    fontFamily: _fontFamily,
  );
  static const standardTextStyle = TextStyle(
    fontSize: standardTextSize,
    color: textColor,
    fontFamily: _fontFamily,
  );

  // miscellaneous
  static const int maxNumberOfTeamsDefault = 6;
  static const int refreshDurationInSeconds = 20;
}
