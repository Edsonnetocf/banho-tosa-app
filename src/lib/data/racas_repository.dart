import 'package:flutter/foundation.dart';

import 'catalogo_racas.dart';
import 'racas_api.dart';
import 'racas_cache.dart';

enum EstadoRacas { inicial, carregando, sucesso, vazio, erro }

class RacasRepository extends ChangeNotifier {
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
    if (_catalogo?.validoEm(_agora(), validade) ?? false) return;
    estado = EstadoRacas.carregando;
    erroConsulta = null;
    falhaCache = false;
    notifyListeners();

    if (!_cacheLido) {
      _cacheLido = true;
      try {
        _catalogo = await cache.ler();
      } catch (_) {
        falhaCache = true;
      }
      // Publica os dados guardados antes de aguardar a rede.
      notifyListeners();
    }

    if (_catalogo?.validoEm(_agora(), validade) ?? false) {
      estado = EstadoRacas.sucesso;
      notifyListeners();
      return;
    }

    try {
      final recebidos = await api.consultar();
      if (recebidos.isEmpty) {
        // Uma resposta vazia não apaga um catálogo válido anterior.
        estado = EstadoRacas.vazio;
      } else {
        _catalogo = CatalogoRacas(nomes: recebidos, atualizadoEm: _agora());
        estado = EstadoRacas.sucesso;
        try {
          await cache.salvar(_catalogo!);
        } catch (_) {
          // A consulta continua utilizável em memória se a gravação falhar.
          falhaCache = true;
        }
      }
    } on RacasException catch (erro) {
      erroConsulta = erro.mensagem;
      estado = EstadoRacas.erro;
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
