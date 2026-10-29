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
    await tester.tap(find.byType(NavigationDestination).last);
    await tester.pumpAndSettle();
    expect(find.text('Nenhum cliente encontrado.'), findsOneWidget);
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
}
