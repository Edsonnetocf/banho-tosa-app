import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  await integrationDriver(
    responseDataCallback: null,
    onScreenshot: (nome, bytes, [args]) async {
      final arquivo = File('build/integration_screenshots/$nome.png');
      await arquivo.parent.create(recursive: true);
      await arquivo.writeAsBytes(bytes);
      return true;
    },
  );
}
