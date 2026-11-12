import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:petshop_app/data/api_client.dart';
import 'package:petshop_app/data/app_repository.dart';
import 'package:petshop_app/data/app_scope.dart';
import 'package:petshop_app/data/catalogo_racas.dart';
import 'package:petshop_app/data/racas_repository.dart';
import 'package:petshop_app/models/cliente.dart';
import 'package:petshop_app/models/pet.dart';
import 'package:petshop_app/screens/cliente_form_screen.dart';

import 'support/racas_fakes.dart';
import 'support/fakes.dart';

void main() {
  for (final editar in [false, true]) {
    testWidgets(
      '${editar ? 'edição preserva raça existente' : 'cadastro salva raça selecionada'} no contrato HTTP atual',
      (tester) async {
        final racas = RacasRepository(
          cache: CacheRacasTeste(
            CatalogoRacas(
              nomes: ['Pastor-alemão'],
              atualizadoEm: DateTime.now(),
            ),
          ),
        );
        Map<String, dynamic>? enviado;
        String? metodo;
        final repo = AppRepository(
          local: MemoriaLocal(),
          api: ApiClient(
            client: MockClient((r) async {
              if (r.method == 'GET') {
                return http.Response(
                  jsonEncode({'clientes': [], 'agendamentos': []}),
                  200,
                  headers: {'content-type': 'application/json; charset=utf-8'},
                );
              }
              metodo = r.method;
              enviado = jsonDecode(r.body) as Map<String, dynamic>;
              final pet = Map<String, dynamic>.from(enviado!['pet'] as Map);
              return http.Response(
                jsonEncode({
                  'clientes': [
                    {
                      'id': 1,
                      'nome': enviado!['nome'],
                      'telefone': enviado!['telefone'],
                      'pets': [
                        {...pet, 'id': 2, 'cliente_id': 1},
                      ],
                    },
                  ],
                  'agendamentos': [],
                }),
                200,
                headers: {'content-type': 'application/json; charset=utf-8'},
              );
            }),
          ),
        );
        addTearDown(() async {
          await tester.pumpWidget(const SizedBox());
          await repo.fechar();
          repo.dispose();
          await racas.fechar();
          racas.dispose();
        });
        await repo.iniciar();
        final antigo = Cliente(
          id: 1,
          nome: 'Tutor existente',
          telefone: '',
          pets: [
            Pet(
              id: 2,
              clienteId: 1,
              nome: 'Pet existente',
              especie: 'Cachorro',
              raca: 'Raça informada anteriormente',
              porte: 'Médio',
            ),
          ],
        );
        await tester.pumpWidget(
          AppScope(
            repository: repo,
            child: MaterialApp(
              home: Builder(
                builder: (context) => Scaffold(
                  body: TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => ClienteFormScreen(
                          cliente: editar ? antigo : null,
                          racasRepository: racas,
                        ),
                      ),
                    ),
                    child: const Text('Abrir'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Abrir'));
        await tester.pumpAndSettle();
        final campos = find.byType(TextFormField);
        if (!editar) {
          await tester.enterText(campos.at(0), 'Tutor novo');
          await tester.ensureVisible(campos.at(2));
          await tester.enterText(campos.at(2), 'Rex');
        }
        final campo = find.byKey(const ValueKey('campo_raca'));
        await tester.ensureVisible(campo);
        if (editar) {
          expect(
            tester.widget<TextFormField>(campo).controller!.text,
            antigo.pets.single.raca,
          );
        } else {
          await tester.enterText(campo, 'alemao');
          await tester.pumpAndSettle();
          await tester.tap(find.text('Pastor-alemão'));
          await tester.pumpAndSettle();
        }
        final salvar = find.widgetWithText(
          ElevatedButton,
          editar ? 'Salvar Alterações' : 'Salvar',
        );
        await tester.scrollUntilVisible(
          salvar,
          150,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(salvar);
        await tester.pumpAndSettle();
        expect(metodo, editar ? 'PUT' : 'POST');
        final esperado = editar ? antigo.pets.single.raca : 'Pastor-alemão';
        expect(enviado!['pet']['raca'], esperado);
        expect(repo.clientes.single.pets.single.raca, esperado);
      },
    );
  }
}
