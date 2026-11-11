import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:integration_test/integration_test.dart';
import 'package:petshop_app/data/racas_api.dart';
import 'package:petshop_app/data/racas_cache.dart';
import 'package:petshop_app/data/racas_repository.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('catálogo persiste no SQLite e reabre sem rede após sete dias', (
    _,
  ) async {
    // Diretório temporário próprio: não acessa os cadastros do aplicativo.
    final diretorio = await Directory.systemTemp.createTemp(
      'cache_racas_teste_',
    );
    final agora = DateTime.utc(2026, 11, 11);
    var chamadas = 0;
    final primeira = RacasRepository(
      agora: () => agora,
      cache: RacasCacheSqlite(diretorio: diretorio.path),
      api: RacasApi(
        client: MockClient((_) async {
          chamadas++;
          return http.Response(
            jsonEncode({
              'results': {
                'bindings': [
                  {
                    'nome': {
                      'type': 'literal',
                      'xml:lang': 'pt',
                      'value': 'Pastor-alemão',
                    },
                  },
                ],
              },
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      ),
    );
    try {
      await primeira.carregar();
      expect(primeira.estado, EstadoRacas.sucesso);
      expect(primeira.falhaCache, isFalse);
    } finally {
      await primeira.fechar();
      primeira.dispose();
    }

    final reaberta = RacasRepository(
      agora: () => agora.add(const Duration(days: 8)),
      cache: RacasCacheSqlite(diretorio: diretorio.path),
      api: RacasApi(
        client: MockClient((_) async {
          chamadas++;
          throw http.ClientException('Sem rede');
        }),
      ),
    );
    try {
      await reaberta.carregar();
      expect(reaberta.estado, EstadoRacas.erro);
      expect(reaberta.nomes, ['Pastor-alemão']);
      expect(reaberta.atualizadoEm, agora);
      expect(chamadas, 2);
    } finally {
      await reaberta.fechar();
      reaberta.dispose();
      await diretorio.delete(recursive: true);
    }
  });
}
