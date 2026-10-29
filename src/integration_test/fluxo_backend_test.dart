import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';
import 'package:petshop_app/main.dart';
import 'package:petshop_app/data/api_client.dart';
import 'package:petshop_app/data/app_repository.dart';
import 'package:petshop_app/data/local_store.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Android: importação, formulário, HTTP CRUD e cache SQLite offline',
    (tester) async {
      // Execute apenas contra um backend exclusivo de teste (ver docs/etapa-05.md).
      final pasta = await Directory.systemTemp.createTemp(
        'banho-tosa-integracao-',
      );
      final local = LocalStore(diretorio: pasta.path);
      final api = ApiClient();
      final repo = AppRepository(api: api, local: local);
      AppRepository? offline;
      try {
        final legado = await openDatabase(
          path.join(pasta.path, 'banho_tosa.db'),
        );
        await legado.execute(
          'CREATE TABLE clientes (id INTEGER PRIMARY KEY, nome TEXT, telefone TEXT)',
        );
        await legado.execute(
          'CREATE TABLE pets (id INTEGER PRIMARY KEY, cliente_id INTEGER, nome TEXT, especie TEXT, raca TEXT, porte TEXT)',
        );
        await legado.execute(
          'CREATE TABLE agendamentos (id INTEGER PRIMARY KEY, pet_id INTEGER, data_hora TEXT, servico TEXT)',
        );
        await legado.insert('clientes', {
          'id': 71,
          'nome': 'Tutor Legado Teste',
          'telefone': '',
        });
        await legado.insert('pets', {
          'id': 82,
          'cliente_id': 71,
          'nome': 'Pet Legado',
          'especie': 'Gato',
          'raca': '',
          'porte': 'Pequeno',
        });
        await legado.insert('agendamentos', {
          'id': 93,
          'pet_id': 82,
          'data_hora': '2035-04-10T09:00:00.000',
          'servico': 'Banho',
        });
        await legado.close();

        await repo.iniciar();
        expect(repo.offline, isFalse, reason: repo.erro);
        expect(
          repo.clientes,
          isEmpty,
          reason: 'Use um banco de backend novo e exclusivo para o teste.',
        );
        await tester.pumpWidget(BanhoTosaApp(repository: repo));
        await tester.pumpAndSettle(const Duration(seconds: 3));
        await tester.tap(find.byTooltip('Importar dados da Etapa 4'));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(TextButton, 'Importar'));
        await aguardar(tester, () => repo.clientes.isNotEmpty);
        expect(repo.agendamentos.single.petNome, 'Pet Legado');
        expect((await repo.importarLegado())['repetida'], isTrue);
        expect((await local.lerLegado())['clientes'], hasLength(1));

        await tester.tap(find.byType(NavigationDestination).last);
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Adicionar novo cliente'));
        await tester.pumpAndSettle();
        final campos = find.byType(TextFormField);
        await tester.enterText(campos.at(0), 'Tutor Formulario Android');
        await tester.ensureVisible(campos.at(2));
        await tester.enterText(campos.at(2), 'Pet Android');
        final salvar = find.widgetWithText(ElevatedButton, 'Salvar');
        await tester.ensureVisible(salvar);
        await tester.tap(salvar);
        await aguardar(tester, () => repo.clientes.length == 2);
        await tester.pumpAndSettle();
        expect(find.text('Tutor Formulario Android'), findsOneWidget);
        final cliente = repo.clientes.singleWhere(
          (c) => c.nome == 'Tutor Formulario Android',
        );
        final pet = cliente.pets.single;

        await repo.salvarAgendamento(
          petId: pet.id!,
          dataHora: DateTime(2035, 4, 10, 10),
          servico: 'Tosa',
        );
        final agenda = repo.agendamentos.singleWhere((a) => a.petId == pet.id);
        await expectLater(
          repo.salvarAgendamento(
            petId: pet.id!,
            dataHora: agenda.dataHora,
            servico: 'Banho',
          ),
          throwsA(isA<ApiException>()),
        );
        await expectLater(
          repo.excluirCliente(cliente.id!),
          throwsA(isA<ApiException>()),
        );
        await repo.salvarAgendamento(
          id: agenda.id,
          petId: pet.id!,
          dataHora: DateTime(2035, 4, 10, 11),
          servico: 'Banho e Tosa',
        );
        await repo.salvarClienteComPet(
          clienteId: cliente.id,
          petId: pet.id,
          nomeCliente: 'Tutor Android Editado',
          telefone: '',
          nomePet: 'Pet Editado',
          especie: pet.especie,
          raca: pet.raca,
          porte: pet.porte,
        );
        await tester.pumpAndSettle();
        expect(find.text('Tutor Android Editado'), findsOneWidget);
        await tester.tap(find.byType(NavigationDestination).first);
        await tester.pumpAndSettle();
        expect(
          find.text('Pet Editado (Tutor Android Editado)'),
          findsOneWidget,
        );
        expect(find.text('Banho e Tosa'), findsOneWidget);
        await repo.excluirAgendamento(agenda.id!);
        await repo.excluirCliente(cliente.id!);

        // Fecha e reabre o SQLite de cache, simulando uma nova sessão sem rede.
        final origem = await local.origem();
        await tester.pumpWidget(const SizedBox());
        await repo.fechar();
        final novoLocal = LocalStore(diretorio: pasta.path);
        expect(await novoLocal.origem(), origem);
        offline = AppRepository(
          local: novoLocal,
          api: ApiClient(
            baseUrl: api.baseUrl,
            client: MockClient(
              (_) async => throw http.ClientException('Offline de teste'),
            ),
          ),
        );
        await offline.iniciar();
        expect(offline.offline, isTrue);
        expect(offline.clientes.single.nome, 'Tutor Legado Teste');
        expect(offline.agendamentos.single.petNome, 'Pet Legado');
        await expectLater(
          offline.excluirCliente(offline.clientes.single.id!),
          throwsA(isA<ApiException>()),
        );
        await tester.pumpWidget(BanhoTosaApp(repository: offline));
        await tester.pumpAndSettle(const Duration(seconds: 3));
        expect(find.textContaining('Consulta offline'), findsOneWidget);
        expect(
          tester
              .widget<FloatingActionButton>(
                find.byType(FloatingActionButton).first,
              )
              .onPressed,
          isNull,
        );
        expect((await novoLocal.lerLegado())['agendamentos'], hasLength(1));
        await tester.pumpWidget(const SizedBox());
      } finally {
        await offline?.fechar();
        offline?.dispose();
        await repo.fechar();
        repo.dispose();
        await pasta.delete(recursive: true);
      }
    },
  );
}

Future<void> aguardar(WidgetTester tester, bool Function() terminou) async {
  for (var i = 0; i < 100; i++) {
    await tester.pump(const Duration(milliseconds: 200));
    if (terminou()) return;
  }
  fail('A operação HTTP não concluiu no tempo esperado.');
}
