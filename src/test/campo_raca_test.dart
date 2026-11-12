import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:petshop_app/data/catalogo_racas.dart';
import 'package:petshop_app/data/racas_api.dart';
import 'package:petshop_app/data/racas_repository.dart';
import 'package:petshop_app/utils/busca_racas.dart';
import 'package:petshop_app/widgets/campo_raca.dart';

import 'support/racas_fakes.dart';

http.Response catalogo(List<String> nomes) => http.Response(
  jsonEncode({
    'results': {
      'bindings': [
        for (final nome in nomes)
          {
            'nome': {'type': 'literal', 'xml:lang': 'pt', 'value': nome},
          },
      ],
    },
  }),
  200,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

void main() {
  const nomes = [
    'Pastor-alemão',
    'Pastor-australiano',
    'Dálmata',
    'Buldogue francês',
  ];
  final campo = find.byKey(const ValueKey('campo_raca'));
  final lista = find.byKey(const ValueKey('sugestoes_raca'));
  late TextEditingController texto;
  late RacasRepository repo;
  late ValueNotifier<bool> sugerir;
  late int consultas;

  setUp(() {
    texto = TextEditingController();
    sugerir = ValueNotifier(true);
    consultas = 0;
    repo = RacasRepository(
      cache: CacheRacasTeste(
        CatalogoRacas(nomes: nomes, atualizadoEm: DateTime.now()),
      ),
      api: RacasApi(
        client: MockClient((_) async {
          consultas++;
          return catalogo(nomes);
        }),
      ),
    );
  });

  tearDown(() async {
    await repo.fechar();
    repo.dispose();
    texto.dispose();
    sugerir.dispose();
  });

  Future<void> abrir(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const TextField(
                  decoration: InputDecoration(labelText: 'Outro campo'),
                ),
                ValueListenableBuilder<bool>(
                  valueListenable: sugerir,
                  builder: (_, ativo, _) => CampoRaca(
                    controller: texto,
                    repository: repo,
                    sugerir: ativo,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    addTearDown(() async => tester.pumpWidget(const SizedBox()));
  }

  test(
    'busca normaliza acentos, espaços e hífens e prioriza início do nome',
    () {
      expect(buscarRacas(nomes, 'ALEMAO'), ['Pastor-alemão']);
      expect(buscarRacas(nomes, 'pastor   alemao'), ['Pastor-alemão']);
      expect(buscarRacas(nomes, 'frances'), ['Buldogue francês']);
      expect(buscarRacas(nomes, 'da\u0301lmata'), ['Dálmata']);
      expect(buscarRacas(nomes, 'p'), isEmpty);
      expect(buscarRacas(nomes, 'inexistente'), isEmpty);
      expect(buscarRacas(['Poodle', 'poodle', 'Toy poodle'], 'po'), [
        'Poodle',
        'Toy poodle',
      ]);
    },
  );

  testWidgets(
    'duas letras abrem sugestões, seleção preenche e edição manual continua livre',
    (tester) async {
      await abrir(tester);
      await tester.enterText(campo, 'p');
      await tester.pumpAndSettle();
      expect(lista, findsNothing);
      await tester.enterText(campo, 'ALEMAO');
      await tester.pumpAndSettle();
      expect(find.text('Pastor-alemão'), findsOneWidget);
      await tester.tap(find.text('Pastor-alemão'));
      await tester.pumpAndSettle();
      expect(texto.text, 'Pastor-alemão');
      expect(lista, findsNothing);
      await tester.enterText(campo, 'Minha raça manual');
      await tester.pumpAndSettle();
      expect(texto.text, 'Minha raça manual');
      expect(lista, findsNothing);
      expect(consultas, 0);
    },
  );

  testWidgets('tocar fora fecha a lista sem apagar o texto', (tester) async {
    await abrir(tester);
    await tester.enterText(campo, 'pastor');
    await tester.pumpAndSettle();
    expect(lista, findsOneWidget);
    await tester.tap(find.byType(TextField).first);
    await tester.pumpAndSettle();
    expect(lista, findsNothing);
    expect(texto.text, 'pastor');
  });

  testWidgets('teclado pode navegar e selecionar uma sugestão', (tester) async {
    await abrir(tester);
    await tester.enterText(campo, 'pastor');
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(texto.text, 'Pastor-australiano');
    expect(lista, findsNothing);
  });

  testWidgets('trocar a espécie fecha sugestões e preserva o texto', (
    tester,
  ) async {
    await abrir(tester);
    await tester.enterText(campo, 'pastor');
    await tester.pumpAndSettle();
    sugerir.value = false;
    await tester.pumpAndSettle();
    expect(lista, findsNothing);
    expect(texto.text, 'pastor');
    await tester.enterText(campo, 'Gato sem raça definida');
    await tester.pumpAndSettle();
    expect(texto.text, 'Gato sem raça definida');
    expect(lista, findsNothing);
    expect(consultas, 0);
  });

  testWidgets(
    'resposta atrasada usa a digitação atual e não sobrescreve o campo',
    (tester) async {
      await repo.fechar();
      repo.dispose();
      final liberar = Completer<http.Response>();
      repo = RacasRepository(
        cache: CacheRacasTeste(null),
        api: RacasApi(
          client: MockClient((_) {
            consultas++;
            return liberar.future;
          }),
        ),
      );
      await abrir(tester);
      await tester.enterText(campo, 'alemao');
      await tester.pump();
      await tester.enterText(campo, 'dalmata');
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.textContaining('Carregando sugestões'), findsNothing);
      liberar.complete(catalogo(nomes));
      await tester.pumpAndSettle();
      expect(texto.text, 'dalmata');
      expect(find.text('Dálmata'), findsOneWidget);
      expect(find.text('Pastor-alemão'), findsNothing);
      expect(consultas, 1);
    },
  );

  for (final falha in [false, true]) {
    testWidgets(
      'consulta ${falha ? 'com erro' : 'vazia'} mantém campo limpo e não repete ao digitar',
      (tester) async {
        await repo.fechar();
        repo.dispose();
        repo = RacasRepository(
          cache: CacheRacasTeste(null),
          api: RacasApi(
            client: MockClient((_) async {
              consultas++;
              if (falha) throw http.ClientException('Sem rede');
              return catalogo([]);
            }),
          ),
        );
        await abrir(tester);
        for (final texto in ['al', 'outro', 'Sem raça definida']) {
          await tester.enterText(campo, texto);
          await tester.pumpAndSettle();
        }
        expect(lista, findsNothing);
        expect(find.byType(SnackBar), findsNothing);
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.textContaining('Sugestões indisponíveis'), findsNothing);
        expect(find.textContaining('Nenhuma sugestão'), findsNothing);
        expect(texto.text, 'Sem raça definida');
        expect(consultas, 1);
      },
    );
  }

  testWidgets(
    'cache vencido pode sugerir antes de terminar uma atualização com falha',
    (tester) async {
      await repo.fechar();
      repo.dispose();
      final liberar = Completer<http.Response>();
      repo = RacasRepository(
        cache: CacheRacasTeste(
          CatalogoRacas(
            nomes: nomes,
            atualizadoEm: DateTime.now().subtract(const Duration(days: 8)),
          ),
        ),
        api: RacasApi(client: MockClient((_) => liberar.future)),
      );
      await abrir(tester);
      await tester.enterText(campo, 'frances');
      await tester.pumpAndSettle();
      expect(find.text('Buldogue francês'), findsOneWidget);
      liberar.completeError(http.ClientException('Sem rede'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Buldogue francês'));
      await tester.pumpAndSettle();
      expect(texto.text, 'Buldogue francês');
    },
  );

  testWidgets(
    'fechar o formulário durante a consulta não deixa atualizações na tela',
    (tester) async {
      await repo.fechar();
      repo.dispose();
      final liberar = Completer<http.Response>();
      repo = RacasRepository(
        cache: CacheRacasTeste(null),
        api: RacasApi(client: MockClient((_) => liberar.future)),
      );
      await abrir(tester);
      await tester.enterText(campo, 'pastor');
      await tester.pump();
      await tester.pumpWidget(const SizedBox());
      liberar.complete(catalogo(nomes));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('lista tem altura limitada e rolagem para as demais sugestões', (
    tester,
  ) async {
    await repo.fechar();
    repo.dispose();
    repo = RacasRepository(
      cache: CacheRacasTeste(
        CatalogoRacas(
          nomes: List.generate(
            12,
            (i) => 'Pastor ${i.toString().padLeft(2, '0')}',
          ),
          atualizadoEm: DateTime.now(),
        ),
      ),
    );
    await abrir(tester);
    await tester.enterText(campo, 'pastor');
    await tester.pumpAndSettle();
    expect(tester.getSize(lista).height, lessThanOrEqualTo(240));
    final rolagem = find.descendant(
      of: lista,
      matching: find.byType(Scrollable),
    );
    await tester.scrollUntilVisible(
      find.text('Pastor 11'),
      150,
      scrollable: rolagem,
    );
    await tester.tap(find.text('Pastor 11'));
    await tester.pumpAndSettle();
    expect(texto.text, 'Pastor 11');
  });
}
