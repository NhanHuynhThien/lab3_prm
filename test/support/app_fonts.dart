import 'package:flutter/services.dart';

/// Loads the bundled app fonts so layout audits measure real glyphs.
Future<void> loadAppFonts() async {
  final body = FontLoader('GoogleSans');
  for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
    body.addFont(rootBundle.load('assets/fonts/GoogleSans-$w.ttf'));
  }
  await body.load();
  final heading = FontLoader('Nunito');
  for (final w in ['SemiBold', 'Bold', 'ExtraBold']) {
    heading.addFont(rootBundle.load('assets/fonts/Nunito-$w.ttf'));
  }
  await heading.load();
}
