import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:petshop_app/data/api_client.dart';
import 'package:petshop_app/data/app_repository.dart';
import 'package:petshop_app/data/app_scope.dart';
import 'package:petshop_app/data/catalogo_racas.dart';
import 'package:petshop_app/data/fotos_pet_repository.dart';
import 'package:petshop_app/data/racas_repository.dart';
import 'package:petshop_app/screens/agenda_screen.dart';
import 'package:petshop_app/screens/cliente_form_screen.dart';
import 'package:petshop_app/screens/pet_detalhes_screen.dart';
import 'package:petshop_app/widgets/foto_pet.dart';

import 'support/fakes.dart';
import 'support/fotos_fakes.dart';
import 'support/racas_fakes.dart';

class CenarioFotos {
  final local = FotosMemoria();
  final galeria = GaleriaTeste();
  late final AppRepository repo;
  final racas = RacasRepository(
    cache: CacheRacasTeste(
      CatalogoRacas(nomes: ['Poodle'], atualizadoEm: DateTime.now()),
    ),
  );
  bool enviarLocation = true;
  int posts = 0;
  Map<String, dynamic>? enviado;
  final clientes = <Map<String, Object?>>[
    {
      'id': 7,
      'nome': 'Tutor',
      'telefone': '',
      'pets': [
        {
          'id': 11,
          'cliente_id': 7,
          'nome': 'Rex',
          'especie': 'Gato',
          'raca': '',
          'porte': 'Médio',
        },
        {
          'id': 12,
          'cliente_id': 7,
          'nome': 'Luna',
          'especie': 'Gato',
          'raca': '',
          'porte': 'Pequeno',
        },
      ],
    },
  ];

  CenarioFotos() {
    repo = AppRepository(
      local: MemoriaLocal(),
      galeria: galeria,
      fotos: FotosPetRepository(servidor: 'http://teste/api', store: local),
      api: ApiClient(
        baseUrl: 'http://teste/api',
        client: MockClient((r) async {
          if (r.method == 'POST' || r.method == 'PUT') {
            enviado = jsonDecode(r.body) as Map<String, dynamic>;
            final pet = Map<String, Object?>.from(enviado!['pet'] as Map);
            if (r.method == 'POST') {
              posts++;
              clientes.add({
                'id': 51,
                'nome': enviado!['nome'],
                'telefone': '',
                'pets': [
                  {...pet, 'id': 82, 'cliente_id': 51},
                ],
              });
              // Outro cadastro com o mesmo nome: não pode receber a foto.
              clientes.add({
                'id': 99,
                'nome': enviado!['nome'],
                'telefone': '',
                'pets': [
                  {...pet, 'id': 150, 'cliente_id': 99},
                ],
              });
            } else {
              final tutor = clientes.first;
              tutor['nome'] = enviado!['nome'];
              tutor['pets'] = [
                for (final antigo in tutor['pets'] as List)
                  (antigo as Map)['id'] == pet['id']
                      ? {...pet, 'cliente_id': 7}
                      : antigo,
              ];
            }
          }
          return http.Response(
            jsonEncode({
              'clientes': clientes,
              'agendamentos': [
                {
                  'id': 1,
                  'pet_id': 11,
                  'pet_nome': 'Rex',
                  'cliente_nome': 'Tutor',
                  'data_hora': '2030-01-01T10:00:00',
                  'servico': 'Banho',
                },
              ],
            }),
            r.method == 'POST' ? 201 : 200,
            headers: {
              'content-type': 'application/json; charset=utf-8',
              if (r.method == 'POST' && enviarLocation)
                'location': '/api/clientes/51',
            },
          );
        }),
      ),
    );
    local.dados[repo.fotos.servidor] = {11: '/privado/anterior.img'};
  }

  Future<void> iniciar() async {
    await repo.iniciar();
    await repo.fotos.carregar();
  }

  Future<void> abrir(
    WidgetTester tester, {
    bool editar = true,
    bool segundoPet = false,
  }) async {
    final cliente = editar ? repo.clientes.first : null;
    await tester.pumpWidget(
      AppScope(
        repository: repo,
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<bool>(
                    builder: (_) => ClienteFormScreen(
                      cliente: cliente,
                      pet: segundoPet ? cliente!.pets.last : null,
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
  }

  Future<void> escolher(WidgetTester tester) async {
    final botao = find.text('Adicionar foto').evaluate().isNotEmpty
        ? find.text('Adicionar foto')
        : find.text('Trocar foto');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.ensureVisible(botao);
    await tester.pumpAndSettle();
    await tester.tap(botao);
    await tester.pumpAndSettle();
  }

  Future<void> salvar(WidgetTester tester, {bool editar = true}) async {
    final botao = find.widgetWithText(
      ElevatedButton,
      editar ? 'Salvar Alterações' : 'Salvar',
    );
    await tester.scrollUntilVisible(
      botao,
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(botao);
    await tester.pumpAndSettle();
  }

  Future<void> preencherNovo(WidgetTester tester) async {
    final campos = find.byType(TextFormField);
    await tester.enterText(campos.at(0), 'Tutor novo');
    await tester.ensureVisible(campos.at(2));
    await tester.enterText(campos.at(2), 'Pet novo');
  }
}

void main() {
  WidgetController.hitTestWarningShouldBeFatal = true;
  late CenarioFotos c;
  setUp(() async {
    c = CenarioFotos();
    await c.iniciar();
  });
  tearDown(() async {
    await c.repo.fechar();
    c.repo.dispose();
    await c.racas.fechar();
    c.racas.dispose();
  });

  testWidgets('cancelar a galeria preserva a foto e não grava cadastro', (
    tester,
  ) async {
    await c.abrir(tester);
    c.galeria.resultados.add(null);
    await c.escolher(tester);
    expect(
      tester.widget<FotoPet>(find.byType(FotoPet)).caminho,
      '/privado/anterior.img',
    );
    expect(c.local.gravacoes, 0);
    expect(c.enviado, isNull);
    expect(find.textContaining('Carregando foto'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'escolher e abandonar formulário não altera a foto compartilhada',
    (tester) async {
      await c.abrir(tester);
      c.galeria.resultados.add('/galeria/nova.png');
      await c.escolher(tester);
      expect(
        tester.widget<FotoPet>(find.byType(FotoPet)).caminho,
        '/galeria/nova.png',
      );
      expect(c.repo.fotos.caminhoPara(11), '/privado/anterior.img');
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(c.local.gravacoes, 0);
      expect(c.enviado, isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('novo cadastro usa Location mesmo com nomes iguais no snapshot', (
    tester,
  ) async {
    await c.abrir(tester, editar: false);
    await c.preencherNovo(tester);
    c.galeria.resultados.add('/galeria/nova.png');
    await c.escolher(tester);
    await c.salvar(tester, editar: false);
    expect(c.posts, 1);
    expect(c.repo.fotos.caminhoPara(82), '/privado/foto-1.img');
    expect(c.repo.fotos.caminhoPara(150), isNull);
    expect(c.enviado, isNot(contains('foto')));
    expect(find.byType(ClienteFormScreen), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('falha da foto após POST avisa sem repetir o cadastro', (
    tester,
  ) async {
    await c.abrir(tester, editar: false);
    await c.preencherNovo(tester);
    c.galeria.resultados.add('/galeria/nova.png');
    await c.escolher(tester);
    c.local.falhaAlteracao = true;
    await c.salvar(tester, editar: false);
    expect(c.posts, 1);
    expect(c.repo.clientes.any((cliente) => cliente.id == 51), isTrue);
    expect(find.textContaining('Cadastro salvo, mas a foto'), findsOneWidget);
    expect(find.byType(ClienteFormScreen), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('sem Location não adivinha pet nem repete POST confirmado', (
    tester,
  ) async {
    c.enviarLocation = false;
    await c.abrir(tester, editar: false);
    await c.preencherNovo(tester);
    c.galeria.resultados.add('/galeria/nova.png');
    await c.escolher(tester);
    await c.salvar(tester, editar: false);
    expect(c.posts, 1);
    expect(c.local.gravacoes, 0);
    expect(find.textContaining('Cadastro salvo, mas a foto'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('edição de outro pet do cliente altera somente sua foto', (
    tester,
  ) async {
    await c.abrir(tester, segundoPet: true);
    c.galeria.resultados.add('/galeria/luna.png');
    await c.escolher(tester);
    await c.salvar(tester);
    expect(c.enviado!['pet']['id'], 12);
    expect(c.repo.fotos.caminhoPara(12), '/privado/foto-1.img');
    expect(c.repo.fotos.caminhoPara(11), '/privado/anterior.img');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('remoção é rascunho até salvar e pode ser cancelada', (
    tester,
  ) async {
    await c.abrir(tester);
    await tester.ensureVisible(find.byTooltip('Remover foto'));
    await tester.tap(find.byTooltip('Remover foto'));
    await tester.pumpAndSettle();
    expect(tester.widget<FotoPet>(find.byType(FotoPet)).caminho, isNull);
    expect(c.repo.fotos.caminhoPara(11), '/privado/anterior.img');
    await c.salvar(tester);
    expect(c.repo.fotos.caminhoPara(11), isNull);
    expect(c.local.dados[c.repo.fotos.servidor]!.containsKey(11), isFalse);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('galeria indisponível informa falha sem alterar foto', (
    tester,
  ) async {
    await c.abrir(tester);
    c.galeria.falhar = true;
    await c.escolher(tester);
    expect(find.text('Galeria indisponível. Tente novamente.'), findsOneWidget);
    expect(c.repo.fotos.caminhoPara(11), '/privado/anterior.img');
    expect(c.enviado, isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('agenda e detalhes observam troca e remoção sem novo GET', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final cliente = c.repo.clientes.first;
    await tester.pumpWidget(
      AppScope(
        repository: c.repo,
        child: MaterialApp(
          home: Row(
            children: [
              const Expanded(child: AgendaScreen()),
              Expanded(
                child: PetDetalhesScreen(
                  cliente: cliente,
                  pet: cliente.pets.first,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await c.repo.fotos.definirFoto(11, '/galeria/nova.png');
    await tester.pumpAndSettle();
    expect(find.byType(FotoPet), findsNWidgets(2));
    for (final widget in tester.widgetList<FotoPet>(find.byType(FotoPet))) {
      expect(widget.caminho, '/privado/foto-1.img');
    }
    await c.repo.fotos.removerFoto(11);
    await tester.pumpAndSettle();
    for (final widget in tester.widgetList<FotoPet>(find.byType(FotoPet))) {
      expect(widget.caminho, isNull);
    }
    await tester.pumpWidget(const SizedBox());
  });
}
