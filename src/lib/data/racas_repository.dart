import 'package:flutter/foundation.dart';

import '../utils/app_log.dart';
import 'catalogo_racas.dart';
import 'racas_api.dart';
import 'racas_cache.dart';

enum EstadoRacas { inicial, carregando, sucesso, vazio, erro }

class RacasRepository extends ChangeNotifier {
  static final instancia = RacasRepository();
  final RacasApi api;
  final RacasCache cache;
  final DateTime Function() _agora;
  final Duration validade;

  RacasRepository({
    RacasApi? api,
    RacasCache? cache,
    DateTime Function()? agora,
    this.validade = const Duration(days: 7),
  }) : api = api ?? RacasApi(),
       cache = cache ?? RacasCacheSqlite(),
       _agora = agora ?? DateTime.now;

  CatalogoRacas? _catalogo;
  bool _cacheLido = false;
  Future<void>? _consultaEmAndamento;

  EstadoRacas estado = EstadoRacas.inicial;
  String? erroConsulta;
  bool falhaCache = false;

  List<String> get nomes => _catalogo?.nomes ?? const [];
  DateTime? get atualizadoEm => _catalogo?.atualizadoEm;

  // Chamado ao abrir o formulário, nunca a cada alteração do texto.
  Future<void> carregar() => _consultaEmAndamento ??= _carregar().whenComplete(
    () => _consultaEmAndamento = null,
  );

  Future<void> _carregar() async {
    if (_catalogo?.validoEm(_agora(), validade) ?? false) {
      AppLog.info(
        'RACAS',
        'Cache em memória válido | ${nomes.length} nomes | sem nova consulta.',
      );
      return;
    }
    estado = EstadoRacas.carregando;
    erroConsulta = null;
    falhaCache = false;
    notifyListeners();

    if (!_cacheLido) {
      _cacheLido = true;
      try {
        _catalogo = await cache.ler();
        AppLog.info(
          'RACAS',
          _catalogo == null
              ? 'Nenhum catálogo no cache local.'
              : 'Cache local carregado | ${nomes.length} nomes | atualizado em $atualizadoEm.',
        );
      } catch (_) {
        falhaCache = true;
        AppLog.aviso('RACAS', 'Falha ao ler o cache; tentando o Wikidata.');
      }
      // Publica os dados guardados antes de aguardar a rede.
      notifyListeners();
    }

    if (_catalogo?.validoEm(_agora(), validade) ?? false) {
      estado = EstadoRacas.sucesso;
      AppLog.sucesso(
        'RACAS',
        'Cache dentro do prazo | sem consulta ao Wikidata.',
      );
      notifyListeners();
      return;
    }

    try {
      AppLog.info('WIKIDATA', 'Consultando nomes de raças em português.');
      final recebidos = await api.consultar();
      if (recebidos.isEmpty) {
        // Uma resposta vazia não apaga um catálogo válido anterior.
        estado = EstadoRacas.vazio;
        AppLog.aviso(
          'WIKIDATA',
          'Consulta sem nomes | catálogo anterior preservado.',
        );
      } else {
        _catalogo = CatalogoRacas(nomes: recebidos, atualizadoEm: _agora());
        estado = EstadoRacas.sucesso;
        AppLog.sucesso(
          'WIKIDATA',
          '${recebidos.length} nomes em português recebidos.',
        );
        try {
          await cache.salvar(_catalogo!);
          AppLog.sucesso('RACAS', 'Catálogo salvo no cache local.');
        } catch (_) {
          // A consulta continua utilizável em memória se a gravação falhar.
          falhaCache = true;
          AppLog.aviso(
            'RACAS',
            'Falha ao salvar cache; catálogo disponível em memória.',
          );
        }
      }
    } on RacasException catch (erro) {
      erroConsulta = erro.mensagem;
      estado = EstadoRacas.erro;
      AppLog.erro(
        'WIKIDATA',
        '${erro.mensagem} | ${nomes.length} nomes disponíveis no cache.',
      );
    } finally {
      notifyListeners();
    }
  }

  Future<void> fechar() async {
    await _consultaEmAndamento;
    api.fechar();
    await cache.fechar();
  }
}
