// ignore_for_file: avoid_print
import 'dart:io';

void main() {
  final directories = ['lib', 'test'];
  var failed = false;
  var totalFiles = 0;
  final overLimit = <MapEntry<String, int>>[];

  for (final dir in directories) {
    final d = Directory(dir);
    if (!d.existsSync()) continue;
    final files = d
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));

    for (final file in files) {
      totalFiles++;
      final lines = file.readAsLinesSync().length;
      if (lines > 300) {
        overLimit.add(MapEntry(file.path, lines));
        failed = true;
      }
    }
  }

  overLimit.sort((a, b) => b.value.compareTo(a.value));

  if (overLimit.isNotEmpty) {
    print('FAILED: ${overLimit.length} file(s) exceed 300 physical lines:');
    for (final entry in overLimit) {
      print('  ${entry.key.padRight(50)}: ${entry.value} lines');
    }
  } else {
    print('PASSED: All $totalFiles Dart files in lib/ and test/ are <= 300 lines.');
  }

  if (failed) {
    exit(1);
  }
}
