import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:integration_test/integration_test.dart';
import 'package:petshop_app/data/api_client.dart';
import 'package:petshop_app/data/app_repository.dart';
import 'package:petshop_app/data/app_scope.dart';
import 'package:petshop_app/data/fotos_pet_repository.dart';
import 'package:petshop_app/data/fotos_pet_store.dart';
import 'package:petshop_app/data/galeria_pet.dart';
import 'package:petshop_app/screens/cliente_form_screen.dart';
import 'package:petshop_app/screens/pet_detalhes_screen.dart';
import 'package:petshop_app/widgets/foto_pet.dart';

import '../test/support/fakes.dart';

class GaleriaRegistrada extends GaleriaPet {
  final nativa = GaleriaPetNativa();
  String? origem;
  bool selecionando = false;
  @override
  Future<String?> escolher() async {
    selecionando = true;
    try {
      return origem = await nativa.escolher();
    } finally {
      selecionando = false;
    }
  }

  @override
  Future<bool> descartarSelecaoInterrompida() =>
      nativa.descartarSelecaoInterrompida();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  // O seletor pertence ao Android: o usuário escolhe/cancela nele.
  // Habilitar explicitamente evita que uma suíte automática aguarde interação.
  const interativo = bool.fromEnvironment('TESTE_GALERIA_INTERATIVA');
  testWidgets(
    'Android: galeria, cancelamento, salvar e remover foto',
    (tester) async {
      final pasta = await Directory.systemTemp.createTemp('galeria-pet-teste-');
      final galeria = GaleriaRegistrada();
      final fotos = FotosPetRepository(
        servidor: 'http://teste/api',
        store: FotosPetStoreLocal(diretorio: pasta.path),
      );
      final snapshot = {
        'clientes': [
          {
            'id': 1,
            'nome': 'Tutor de teste',
            'telefone': '',
            'pets': [
              {
                'id': 7,
                'cliente_id': 1,
                'nome': 'Pet de teste',
                'especie': 'Gato',
                'raca': '',
                'porte': 'Médio',
              },
            ],
          },
        ],
        'agendamentos': [],
      };
      final repo = AppRepository(
        fotos: fotos,
        galeria: galeria,
        local: MemoriaLocal(),
        api: ApiClient(
          baseUrl: 'http://teste/api',
          client: MockClient(
            (_) async => http.Response(
              jsonEncode(snapshot),
              200,
              headers: {'content-type': 'application/json; charset=utf-8'},
            ),
          ),
        ),
      );
      try {
        await repo.iniciar();
        await fotos.carregar();
        expect(await galeria.descartarSelecaoInterrompida(), isFalse);
        final cliente = repo.clientes.single;
        await tester.pumpWidget(
          AppScope(
            repository: repo,
            child: MaterialApp(
              home: PetDetalhesScreen(
                cliente: cliente,
                pet: cliente.pets.single,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Editar pet'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Adicionar foto'));
        await tester.pumpAndSettle();
        debugPrint(
          'GALERIA_TESTE_CANCELAR: feche a galeria sem escolher foto.',
        );
        await tester.tap(find.text('Adicionar foto'));
        await tester.pumpAndSettle();
        await tester.runAsync(() async {
          final limite = DateTime.now().add(const Duration(minutes: 2));
          while (galeria.selecionando && DateTime.now().isBefore(limite)) {
            await Future<void>.delayed(const Duration(milliseconds: 200));
          }
        });
        await tester.pumpAndSettle();
        expect(fotos.caminhoPara(7), isNull);
        expect(find.text('Adicionar foto'), findsOneWidget);
        debugPrint('GALERIA_TESTE_ESCOLHER: selecione uma imagem na galeria.');
        await tester.tap(find.text('Adicionar foto'));
        await tester.pumpAndSettle();
        final limite = DateTime.now().add(const Duration(minutes: 2));
        await tester.runAsync(() async {
          while (galeria.origem == null && DateTime.now().isBefore(limite)) {
            await Future<void>.delayed(const Duration(milliseconds: 300));
            await tester.pump();
          }
        });
        await tester.pumpAndSettle();
        expect(galeria.origem, isNotNull);
        expect(fotos.caminhoPara(7), isNull); // Ainda é rascunho.
        final salvar = find.widgetWithText(ElevatedButton, 'Salvar Alterações');
        await tester.scrollUntilVisible(
          salvar,
          180,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(salvar);
        await tester.pumpAndSettle();
        expect(find.byType(ClienteFormScreen), findsNothing);
        final copia = fotos.caminhoPara(7)!;
        expect(await File(copia).exists(), isTrue);
        expect(copia, isNot(galeria.origem));
        expect(tester.widget<FotoPet>(find.byType(FotoPet)).caminho, copia);
        await tester.tap(find.byTooltip('Editar pet'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byTooltip('Remover foto'));
        await tester.tap(find.byTooltip('Remover foto'));
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          salvar,
          180,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(salvar);
        await tester.pumpAndSettle();
        expect(fotos.caminhoPara(7), isNull);
        expect(await File(copia).exists(), isFalse);
        expect(await File(galeria.origem!).exists(), isTrue);
        expect(tester.widget<FotoPet>(find.byType(FotoPet)).caminho, isNull);
      } finally {
        await tester.pumpWidget(const SizedBox());
        await repo.fechar();
        repo.dispose();
        await pasta.delete(recursive: true);
      }
    },
    skip: !interativo,
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
