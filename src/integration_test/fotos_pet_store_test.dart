import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:petshop_app/data/fotos_pet_store.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  // PNG de 1 pixel: arquivo de teste, sem imagens da galeria do usuário.
  final png = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR4nGNgYGBgAAAABQABpfZFQAAAAABJRU5ErkJggg==',
  );

  testWidgets('Android: cópia privada, separação por servidor e reabertura', (
    _,
  ) async {
    final suporte = await getApplicationSupportDirectory();
    expect(await suporte.exists(), isTrue);
    final pasta = await Directory.systemTemp.createTemp(
      'fotos_pet_persistencia_',
    );
    final original = await File(path.join(pasta.path, 'original.png'))
        .writeAsBytes(png);
    final store = FotosPetStoreLocal(diretorio: pasta.path);
    FotosPetStoreLocal? reaberto;
    try {
      final copia = await store.salvar('servidor-a', 7, original.path);
      expect(copia, isNot(original.path));
      expect(await File(copia).readAsBytes(), png);
      final codec = await ui.instantiateImageCodec(
        await File(copia).readAsBytes(),
      );
      final frame = await codec.getNextFrame();
      expect(frame.image.width, 1);
      frame.image.dispose();
      codec.dispose();
      expect(await store.carregar('servidor-b'), isEmpty);
      await original
          .delete(); // Simula o arquivo de origem deixando de existir.
      await store.fechar();
      reaberto = FotosPetStoreLocal(diretorio: pasta.path);
      expect((await reaberto.carregar('servidor-a'))[7], copia);
      expect(await File(copia).readAsBytes(), png);
    } finally {
      await store.fechar();
      await reaberto?.fechar();
      await pasta.delete(recursive: true);
    }
  });

  testWidgets(
    'Android: falha na gravação preserva foto e não remove arquivo original',
    (_) async {
      final pasta = await Directory.systemTemp.createTemp('fotos_pet_troca_');
      final original = await File(path.join(pasta.path, 'original.png'))
          .writeAsBytes(png);
      final store = FotosPetStoreLocal(diretorio: pasta.path);
      try {
        final anterior = await store.salvar('servidor', 1, original.path);
        final db = await openDatabase(
          path.join(pasta.path, 'fotos_pets', 'banho_tosa_fotos_pets.sqlite'),
        );
        // Força erro real do SQLite depois da cópia, antes de atualizar o índice.
        await db.execute(
          "CREATE TRIGGER falhar_foto BEFORE INSERT ON fotos BEGIN SELECT RAISE(ABORT, 'teste'); END",
        );
        await expectLater(
          store.salvar('servidor', 1, original.path),
          throwsA(isA<DatabaseException>()),
        );
        expect((await store.carregar('servidor'))[1], anterior);
        expect(await File(anterior).exists(), isTrue);
        expect(
          await Directory(path.dirname(anterior))
              .list()
              .where((e) => e.path.endsWith('.img'))
              .length,
          1,
        );
        await db.execute('DROP TRIGGER falhar_foto');
        final nova = await store.salvar('servidor', 1, original.path);
        expect(await File(anterior).exists(), isFalse);
        expect(await File(nova).exists(), isTrue);
        await store.remover('servidor', 1);
        expect(await File(nova).exists(), isFalse);
        expect(await store.carregar('servidor'), isEmpty);
        expect(await original.readAsBytes(), png);
      } finally {
        await store.fechar();
        await pasta.delete(recursive: true);
      }
    },
  );

  testWidgets(
    'Android: referência inválida não permite apagar arquivos fora da pasta privada',
    (_) async {
      final pasta = await Directory.systemTemp.createTemp(
        'fotos_pet_referencia_',
      );
      final original = await File(path.join(pasta.path, 'original.png'))
          .writeAsBytes(png);
      final store = FotosPetStoreLocal(diretorio: pasta.path);
      try {
        await store.carregar('servidor');
        final db = await openDatabase(
          path.join(pasta.path, 'fotos_pets', 'banho_tosa_fotos_pets.sqlite'),
        );
        await db.insert('fotos', {
          'servidor': 'servidor',
          'pet_id': 1,
          'arquivo': '../original.png',
        });
        expect(await store.carregar('servidor'), isEmpty);
        await store.remover('servidor', 1);
        expect(await original.readAsBytes(), png);
      } finally {
        await store.fechar();
        await pasta.delete(recursive: true);
      }
    },
  );
}
