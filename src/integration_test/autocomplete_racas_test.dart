import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:integration_test/integration_test.dart';
import 'package:petshop_app/data/racas_api.dart';
import 'package:petshop_app/data/racas_cache.dart';
import 'package:petshop_app/data/racas_repository.dart';
import 'package:petshop_app/data/app_scope.dart';
import 'package:petshop_app/data/app_repository.dart';
import 'package:petshop_app/data/api_client.dart';
import 'package:petshop_app/screens/cliente_form_screen.dart';

import '../test/support/fakes.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Android: autocomplete com Wikidata real e cache reaberto sem rede',
    (tester) async {
      final pasta = await Directory.systemTemp.createTemp(
        'autocomplete_racas_teste_',
      );
      final primeira = RacasRepository(
        cache: RacasCacheSqlite(diretorio: pasta.path),
      );
      RacasRepository? reaberta;

      final cadastros = AppRepository(
        local: MemoriaLocal(),
        api: ApiClient(
          client: MockClient(
            (_) async => http.Response(
              jsonEncode({'clientes': [], 'agendamentos': []}),
              200,
              headers: {'content-type': 'application/json; charset=utf-8'},
            ),
          ),
        ),
      );
      await cadastros.iniciar();

      Future<void> abrir(RacasRepository repo) async {
        await tester.pumpWidget(
          AppScope(
            repository: cadastros,
            child: MaterialApp(
              theme: ThemeData(
                colorScheme: ColorScheme.fromSeed(
                  seedColor: const Color(0xFF0B6374),
                ),
                useMaterial3: true,
                inputDecorationTheme: const InputDecorationTheme(
                  filled: true,
                  border: OutlineInputBorder(),
                ),
              ),
              home: ClienteFormScreen(racasRepository: repo),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('campo_raca')),
          150,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(find.byKey(const ValueKey('campo_raca')));
        await tester.pumpAndSettle();
      }

      final campo = find.byKey(const ValueKey('campo_raca'));
      try {
        // Banco de teste próprio, sem acessar clientes ou agendamentos.
        await primeira.carregar();
        expect(
          primeira.estado,
          EstadoRacas.sucesso,
          reason: primeira.erroConsulta,
        );
        expect(primeira.falhaCache, isFalse);
        await abrir(primeira);
        await tester.enterText(campo, 'alemao');
        await tester.pumpAndSettle(const Duration(milliseconds: 200));
        expect(textoDoCampo(tester), 'alemao');
        // A consulta real tem várias raças com "alemão". Percorre a lista,
        // incluindo os itens que o ListView só constrói ao rolar.
        await tester.scrollUntilVisible(
          find.text('Pastor-alemão'),
          96,
          scrollable: find.descendant(
            of: find.byKey(const ValueKey('sugestoes_raca')),
            matching: find.byType(Scrollable),
          ),
        );
        expect(find.text('Pastor-alemão'), findsOneWidget);
        await tester.tap(find.text('Pastor-alemão'));
        await tester.pumpAndSettle();
        expect(textoDoCampo(tester), 'Pastor-alemão');
        expect(find.byKey(const ValueKey('sugestoes_raca')), findsNothing);

        await tester.enterText(campo, 'pastor');
        await tester.pumpAndSettle();
        await binding.convertFlutterSurfaceToImage();
        await tester.pumpAndSettle();
        await binding.takeScreenshot('autocomplete-racas');

        await tester.pumpWidget(const SizedBox());
        await primeira.fechar();
        reaberta = RacasRepository(
          agora: () => DateTime.now().add(const Duration(days: 8)),
          cache: RacasCacheSqlite(diretorio: pasta.path),
          api: RacasApi(
            client: MockClient(
              (_) async => throw http.ClientException('Sem rede de teste'),
            ),
          ),
        );
        await reaberta.carregar();
        expect(reaberta.estado, EstadoRacas.erro);
        expect(reaberta.nomes, contains('Buldogue francês'));
        await abrir(reaberta);
        await tester.enterText(campo, 'frances');
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text('Buldogue francês'),
          96,
          scrollable: find.descendant(
            of: find.byKey(const ValueKey('sugestoes_raca')),
            matching: find.byType(Scrollable),
          ),
        );
        await tester.tap(find.text('Buldogue francês'));
        await tester.pumpAndSettle();
        expect(textoDoCampo(tester), 'Buldogue francês');
        expect(find.textContaining('Sugestões indisponíveis'), findsNothing);
      } finally {
        await tester.pumpWidget(const SizedBox());
        await primeira.fechar();
        primeira.dispose();
        await reaberta?.fechar();
        reaberta?.dispose();
        await cadastros.fechar();
        cadastros.dispose();
        await pasta.delete(recursive: true);
      }
    },
  );
}

String textoDoCampo(WidgetTester tester) => tester
    .widget<TextFormField>(
      find.byKey(const ValueKey('campo_raca')),
    )
    .controller!
    .text;
