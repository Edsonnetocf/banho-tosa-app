import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:petshop_app/main.dart';
import 'package:petshop_app/data/api_client.dart';
import 'package:petshop_app/data/app_repository.dart';

import 'support/fakes.dart';

void main() {
  testWidgets('Splash abre a navegação e apresenta dados retornados pela API', (
    tester,
  ) async {
    final repo = AppRepository(
      local: MemoriaLocal(),
      api: ApiClient(
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({'clientes': [], 'agendamentos': []}),
            200,
          ),
        ),
      ),
    );
    await repo.iniciar();
    await tester.pumpWidget(BanhoTosaApp(repository: repo));
    expect(find.text('Banho & Tosa App'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.text('Nenhum agendamento cadastrado.'), findsOneWidget);
    expect(find.textContaining('Servidor conectado'), findsNothing);
    expect(find.textContaining('Consulta offline'), findsNothing);
    await tester.tap(find.byTooltip('Mais opções'));
    await tester.pumpAndSettle();
    expect(find.text('Atualizar dados'), findsOneWidget);
    await tester.tap(find.text('Importar dados antigos'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(NavigationDestination).last);
    await tester.pumpAndSettle();
    expect(find.text('Nenhum cliente encontrado.'), findsOneWidget);
    expect(find.byTooltip('Mais opções'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await repo.fechar();
    repo.dispose();
  });
  testWidgets('Sem conexão e sem cache oferece nova tentativa', (tester) async {
    final repo = AppRepository(
      local: MemoriaLocal(),
      api: ApiClient(
        client: MockClient(
          (_) async => throw http.ClientException('Sem conexão'),
        ),
      ),
    );
    await repo.iniciar();
    await tester.pumpWidget(BanhoTosaApp(repository: repo));
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.text('Tentar novamente'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await repo.fechar();
    repo.dispose();
  });
  testWidgets(
    'reconecta pelo menu e preserva consulta offline sem faixa técnica',
    (tester) async {
      var conectado = false;
      var consultas = 0;
      final api = ApiClient(
        client: MockClient((_) async {
          consultas++;
          if (!conectado) throw http.ClientException('Sem conexão');
          return http.Response(
            jsonEncode({'clientes': [], 'agendamentos': []}),
            200,
          );
        }),
      );
      final local = MemoriaLocal();
      local.caches[api.baseUrl] = {'clientes': [], 'agendamentos': []};
      final repo = AppRepository(local: local, api: api);
      await repo.iniciar();
      await tester.pumpWidget(BanhoTosaApp(repository: repo));
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(repo.offline, isTrue);
      expect(find.text('Nenhum agendamento cadastrado.'), findsOneWidget);
      expect(find.textContaining('Consulta offline'), findsNothing);
      expect(find.textContaining('Sem conexão'), findsNothing);
      expect(
        tester
            .widget<FloatingActionButton>(find.byType(FloatingActionButton))
            .onPressed,
        isNull,
      );

      conectado = true;
      await tester.tap(find.byTooltip('Mais opções'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Atualizar dados'));
      await tester.pumpAndSettle();
      expect(consultas, 2);
      expect(repo.offline, isFalse);
      expect(
        tester
            .widget<FloatingActionButton>(find.byType(FloatingActionButton))
            .onPressed,
        isNotNull,
      );
      expect(find.textContaining('Servidor conectado'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await repo.fechar();
      repo.dispose();
    },
  );
}
