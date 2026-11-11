import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:petshop_app/data/catalogo_racas.dart';
import 'package:petshop_app/data/racas_api.dart';
import 'package:petshop_app/data/racas_cache.dart';
import 'package:petshop_app/data/racas_repository.dart';

Map<String, Object> nome(String texto, {String idioma = 'pt'}) => {
  'nome': {'type': 'literal', 'xml:lang': idioma, 'value': texto},
};

http.Response resposta(List<Object> nomes) => http.Response(
  jsonEncode({
    'results': {'bindings': nomes},
  }),
  200,
  headers: {'content-type': 'application/sparql-results+json; charset=utf-8'},
);

class CacheMemoria extends RacasCache {
  CatalogoRacas? catalogo;
  bool falharLeitura = false;
  bool falharGravacao = false;
  int gravacoes = 0;

  CacheMemoria([this.catalogo]);

  @override
  Future<CatalogoRacas?> ler() async {
    if (falharLeitura) throw StateError('Falha de leitura');
    return catalogo;
  }

  @override
  Future<void> salvar(CatalogoRacas novo) async {
    if (falharGravacao) throw StateError('Falha de gravação');
    gravacoes++;
    catalogo = novo;
  }

  @override
  Future<void> fechar() async {}
}

void main() {
  test(
    'GET consulta somente pt e preserva nomes UTF-8 sem duplicatas',
    () async {
      final api = RacasApi(
        client: MockClient((r) async {
          expect(r.method, 'GET');
          expect(r.url.scheme, 'https');
          expect(r.url.host, 'query.wikidata.org');
          expect(r.url.queryParameters['format'], 'json');
          expect(
            r.url.queryParameters['query'],
            contains('LANG(?nome) = "pt"'),
          );
          expect(r.headers['accept'], 'application/sparql-results+json');
          expect(r.headers['user-agent'], contains('BanhoTosaApp/'));
          return resposta([
            nome('Pastor-alemão'),
            nome(' Dálmata '),
            nome('Dálmata'),
            nome('German Shepherd', idioma: 'en'),
            nome(''),
            nome('x' * 121),
          ]);
        }),
      );
      addTearDown(api.fechar);
      expect(await api.consultar(), ['Dálmata', 'Pastor-alemão']);
    },
  );

  for (final status in [429, 500]) {
    test(
      'HTTP $status é tratado sem repetir automaticamente a consulta',
      () async {
        var chamadas = 0;
        final api = RacasApi(
          client: MockClient((_) async {
            chamadas++;
            return http.Response('Serviço indisponível', status);
          }),
        );
        addTearDown(api.fechar);
        await expectLater(api.consultar(), throwsA(isA<RacasException>()));
        expect(chamadas, 1);
      },
    );
  }

  for (final corpo in [
    '<html>Erro</html>',
    '{}',
    '{"results":{"bindings":[{"nome":{"value":123}}]}}',
  ]) {
    test(
      'resposta inválida não é aceita como catálogo vazio: $corpo',
      () async {
        final api = RacasApi(
          client: MockClient((_) async => http.Response(corpo, 200)),
        );
        addTearDown(api.fechar);
        await expectLater(api.consultar(), throwsA(isA<RacasException>()));
      },
    );
  }

  test('timeout tem tratamento próprio', () async {
    final api = RacasApi(
      timeout: const Duration(milliseconds: 5),
      client: MockClient((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 30));
        return resposta([]);
      }),
    );
    addTearDown(api.fechar);
    await expectLater(
      api.consultar(),
      throwsA(
        isA<RacasException>().having(
          (e) => e.mensagem,
          'mensagem',
          contains('demorou'),
        ),
      ),
    );
  });

  final agora = DateTime.utc(2026, 11, 11, 12);
  CatalogoRacas catalogo(Duration idade) => CatalogoRacas(
    nomes: ['Dálmata'],
    atualizadoEm: agora.subtract(idade),
  );

  Future<void> fechar(RacasRepository repo) async {
    await repo.fechar();
    repo.dispose();
  }

  test(
    'cache de menos de sete dias dispensa rede, inclusive ao reabrir',
    () async {
      var chamadas = 0;
      final cache = CacheMemoria(catalogo(const Duration(days: 6)));
      for (var i = 0; i < 2; i++) {
        final repo = RacasRepository(
          cache: cache,
          agora: () => agora,
          api: RacasApi(
            client: MockClient((_) async {
              chamadas++;
              return resposta([]);
            }),
          ),
        );
        await repo.carregar();
        expect(repo.nomes, ['Dálmata']);
        expect(repo.estado, EstadoRacas.sucesso);
        await fechar(repo);
      }
      expect(chamadas, 0);
    },
  );

  for (final idade in [const Duration(days: 7), const Duration(days: -1)]) {
    test('cache com idade $idade precisa de atualização', () async {
      var chamadas = 0;
      final cache = CacheMemoria(catalogo(idade));
      final repo = RacasRepository(
        cache: cache,
        agora: () => agora,
        api: RacasApi(
          client: MockClient((_) async {
            chamadas++;
            return resposta([nome('Pastor-alemão')]);
          }),
        ),
      );
      addTearDown(() => fechar(repo));
      await repo.carregar();
      expect(chamadas, 1);
      expect(repo.nomes, ['Pastor-alemão']);
      expect(cache.catalogo!.atualizadoEm, agora);
    });
  }

  test('cache vencido aparece enquanto uma única consulta atualiza em segundo plano', () async {
    final iniciou = Completer<void>();
    final liberar = Completer<http.Response>();
    var chamadas = 0;
    final cache = CacheMemoria(catalogo(const Duration(days: 8)));
    final repo = RacasRepository(
      cache: cache,
      agora: () => agora,
      api: RacasApi(
        client: MockClient((_) {
          chamadas++;
          iniciou.complete();
          return liberar.future;
        }),
      ),
    );
    addTearDown(() => fechar(repo));
    final primeira = repo.carregar();
    final segunda = repo.carregar();
    await iniciou.future;
    expect(repo.estado, EstadoRacas.carregando);
    expect(repo.nomes, ['Dálmata']);
    liberar.complete(resposta([nome('Pastor-alemão')]));
    await Future.wait([primeira, segunda]);
    expect(chamadas, 1);
    expect(repo.estado, EstadoRacas.sucesso);
    expect(cache.catalogo!.nomes, ['Pastor-alemão']);
  });

  for (final comCache in [false, true]) {
    test(
      'falha de rede com cache=$comCache preserva dados e registra erro interno',
      () async {
        final anterior = comCache ? catalogo(const Duration(days: 8)) : null;
        final cache = CacheMemoria(anterior);
        final repo = RacasRepository(
          cache: cache,
          agora: () => agora,
          api: RacasApi(
            client: MockClient(
              (_) async => throw http.ClientException('Offline'),
            ),
          ),
        );
        addTearDown(() => fechar(repo));
        await repo.carregar();
        expect(repo.estado, EstadoRacas.erro);
        expect(repo.erroConsulta, isNotNull);
        expect(repo.nomes, comCache ? ['Dálmata'] : isEmpty);
        expect(cache.catalogo, same(anterior));
        expect(cache.gravacoes, 0);
      },
    );

    test(
      'resposta vazia com cache=$comCache não apaga catálogo anterior',
      () async {
        final anterior = comCache ? catalogo(const Duration(days: 8)) : null;
        final cache = CacheMemoria(anterior);
        final repo = RacasRepository(
          cache: cache,
          agora: () => agora,
          api: RacasApi(client: MockClient((_) async => resposta([]))),
        );
        addTearDown(() => fechar(repo));
        await repo.carregar();
        expect(repo.estado, EstadoRacas.vazio);
        expect(repo.nomes, comCache ? ['Dálmata'] : isEmpty);
        expect(cache.catalogo, same(anterior));
        expect(cache.gravacoes, 0);
      },
    );
  }

  for (final falhaLeitura in [false, true]) {
    test(
      'consulta continua utilizável quando cache falha na ${falhaLeitura ? 'leitura' : 'gravação'}',
      () async {
        final cache = CacheMemoria()
          ..falharLeitura = falhaLeitura
          ..falharGravacao = !falhaLeitura;
        var chamadas = 0;
        final repo = RacasRepository(
          cache: cache,
          agora: () => agora,
          api: RacasApi(
            client: MockClient((_) async {
              chamadas++;
              return resposta([nome('Dálmata')]);
            }),
          ),
        );
        addTearDown(() => fechar(repo));
        await repo.carregar();
        await repo.carregar();
        expect(repo.nomes, ['Dálmata']);
        expect(repo.estado, EstadoRacas.sucesso);
        expect(repo.falhaCache, isTrue);
        expect(chamadas, 1);
      },
    );
  }
}
