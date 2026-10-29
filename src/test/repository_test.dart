import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:petshop_app/data/api_client.dart';
import 'package:petshop_app/data/app_repository.dart';

import 'support/fakes.dart';

Map<String, Object?> estado([String nome = 'Tutor']) => {
  'clientes': [
    {
      'id': 1,
      'nome': nome,
      'telefone': '',
      'pets': [
        {
          'id': 2,
          'cliente_id': 1,
          'nome': 'Rex',
          'especie': 'Cachorro',
          'raca': '',
          'porte': 'Médio',
        },
      ],
    },
  ],
  'agendamentos': [],
};
http.Response json(Object dados, [int status = 200]) => http.Response(
  jsonEncode(dados),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

void main() {
  test('API envia JSON UTF-8, método e cabeçalhos corretos', () async {
    final api = ApiClient(
      client: MockClient((r) async {
        expect(r.method, 'POST');
        expect(r.headers['content-type'], contains('application/json'));
        expect(jsonDecode(r.body)['nome'], 'João');
        return json(estado('João'), 201);
      }),
    );
    expect(
      (await api.requisitar('POST', '/clientes', {'nome': 'João'}))['clientes'],
      isNotEmpty,
    );
    api.close();
  });
  test('snapshot da gravação atualiza modelos e cache sem outro GET', () async {
    var chamadas = 0;
    final local = MemoriaLocal();
    final repo = AppRepository(
      local: local,
      api: ApiClient(
        client: MockClient((r) async {
          chamadas++;
          return json(r.method == 'GET' ? estado() : estado('Atualizado'));
        }),
      ),
    );
    await repo.iniciar();
    await repo.salvarClienteComPet(
      clienteId: 1,
      petId: 2,
      nomeCliente: 'Atualizado',
      telefone: '',
      nomePet: 'Rex',
      especie: 'Cachorro',
      raca: '',
      porte: 'Médio',
    );
    expect(chamadas, 2);
    expect(repo.clientes.single.nome, 'Atualizado');
    expect(local.caches[repo.api.baseUrl]!['atualizado_em'], isNotNull);
    await repo.fechar();
    repo.dispose();
  });
  test(
    'cache pode ser reaberto offline, mas nenhuma gravação é enviada',
    () async {
      final local = MemoriaLocal();
      local.caches['http://teste/api'] = estado();
      var chamadas = 0;
      final repo = AppRepository(
        local: local,
        api: ApiClient(
          baseUrl: 'http://teste/api',
          client: MockClient((r) async {
            chamadas++;
            throw http.ClientException('Offline');
          }),
        ),
      );
      await repo.iniciar();
      expect(repo.clientes.single.nome, 'Tutor');
      expect(repo.offline, isTrue);
      expect(repo.podeGravar, isFalse);
      await expectLater(repo.excluirCliente(1), throwsA(isA<ApiException>()));
      expect(chamadas, 1);
      await repo.fechar();
      repo.dispose();
    },
  );
  test('cache de outro servidor não é exibido', () async {
    final local = MemoriaLocal();
    local.caches['http://outro/api'] = estado();
    final repo = AppRepository(
      local: local,
      api: ApiClient(
        baseUrl: 'http://teste/api',
        client: MockClient((_) async => throw http.ClientException('Offline')),
      ),
    );
    await repo.iniciar();
    expect(repo.possuiDados, isFalse);
    expect(repo.clientes, isEmpty);
    await repo.fechar();
    repo.dispose();
  });
  test(
    'conflito mantém dados anteriores e devolve mensagem do servidor',
    () async {
      final repo = AppRepository(
        local: MemoriaLocal(),
        api: ApiClient(
          client: MockClient(
            (r) async => r.method == 'GET'
                ? json(estado())
                : json({'mensagem': 'Horário ocupado.'}, 409),
          ),
        ),
      );
      await repo.iniciar();
      await expectLater(
        repo.salvarAgendamento(
          petId: 2,
          dataHora: DateTime(2030),
          servico: 'Banho',
        ),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'mensagem',
            'Horário ocupado.',
          ),
        ),
      );
      expect(repo.clientes.single.nome, 'Tutor');
      expect(repo.podeGravar, isTrue);
      await repo.fechar();
      repo.dispose();
    },
  );
  test(
    'gravação confirmada não vira falha se o cache não puder ser salvo',
    () async {
      final local = MemoriaLocal()..falharAoSalvar = true;
      final repo = AppRepository(
        local: local,
        api: ApiClient(client: MockClient((_) async => json(estado()))),
      );
      await repo.iniciar();
      await repo.excluirAgendamento(1);
      expect(repo.aviso, contains('cache local'));
      expect(repo.offline, isFalse);
      await repo.fechar();
      repo.dispose();
    },
  );
  test(
    'timeout de gravação não é repetido e exige atualizar conexão',
    () async {
      var chamadas = 0;
      final repo = AppRepository(
        local: MemoriaLocal(),
        api: ApiClient(
          timeout: const Duration(milliseconds: 5),
          client: MockClient((r) async {
            chamadas++;
            if (r.method != 'GET') {
              await Future<void>.delayed(const Duration(milliseconds: 30));
            }
            return json(estado());
          }),
        ),
      );
      await repo.iniciar();
      await expectLater(repo.excluirCliente(1), throwsA(isA<ApiException>()));
      expect(chamadas, 2);
      expect(repo.offline, isTrue);
      await repo.fechar();
      repo.dispose();
    },
  );
  test(
    'importação envia origem persistida e não altera legado local',
    () async {
      final local = MemoriaLocal()
        ..legado = {
          'clientes': [
            {'id': 1, 'nome': 'Antigo'},
          ],
          'pets': [],
          'agendamentos': [],
        };
      final repo = AppRepository(
        local: local,
        api: ApiClient(
          client: MockClient((r) async {
            if (r.method == 'POST') {
              expect(jsonDecode(r.body)['origem'], 'origem-local-teste-1234');
              return json({
                ...estado('Importado'),
                'importacao': {
                  'clientes': 1,
                  'pets': 0,
                  'agendamentos': 0,
                  'repetida': false,
                },
              }, 201);
            }
            return json(estado());
          }),
        ),
      );
      await repo.iniciar();
      await repo.importarLegado();
      expect(repo.clientes.single.nome, 'Importado');
      expect((local.legado['clientes'] as List).single['nome'], 'Antigo');
      await repo.fechar();
      repo.dispose();
    },
  );
}
