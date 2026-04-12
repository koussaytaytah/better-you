import 'dart:io' show File;
import 'package:path_provider/path_provider.dart';

Future<String?> exportPlatformCsv(String csvString) async {
  final directory = await getApplicationDocumentsDirectory();
  final path =
      "${directory.path}/better_you_logs_${DateTime.now().millisecondsSinceEpoch}.csv";
  final file = File(path);

  await file.writeAsString(csvString);
  return path;
}
