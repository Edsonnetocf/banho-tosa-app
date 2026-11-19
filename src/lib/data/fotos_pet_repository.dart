import 'dart:async';

import 'package:flutter/foundation.dart';

import '../utils/app_log.dart';
import 'fotos_pet_store.dart';

/// Uma instância compartilhada fornece as mesmas fotos para todas as telas.
class FotosPetRepository extends ChangeNotifier {
  final String servidor;
  final FotosPetStore store;
  FotosPetRepository({required String servidor, FotosPetStore? store})
    : servidor = servidor.trim().replaceFirst(RegExp(r'/+$'), ''),
      store = store ?? FotosPetStoreLocal() {
    if (this.servidor.isEmpty) throw ArgumentError('Servidor não informado.');
  }

  final _fotos = <int, String>{};
  bool carregando = false;
  bool ocupado = false;
  bool _carregou = false;
  bool _fechando = false;
  String? erro;
  Future<void>? _leitura;
  Future<void>? _operacao;

  Map<int, String> get fotos => Map.unmodifiable(_fotos);
  String? caminhoPara(int petId) => _fotos[petId];

  Future<void> carregar() {
    _verificarAberto();
    if (_carregou) return Future.value();
    return _leitura ??= _carregar().whenComplete(() => _leitura = null);
  }

  Future<void> _carregar() async {
    carregando = true;
    erro = null;
    notifyListeners();
    try {
      final salvas = await store.carregar(servidor);
      _fotos
        ..clear()
        ..addAll(salvas);
      _carregou = true;
      AppLog.sucesso(
        'FOTOS',
        '${_fotos.length} foto(s) local(is) carregada(s).',
      );
    } catch (_) {
      erro = 'Não foi possível carregar as fotos deste aparelho.';
      AppLog.erro('FOTOS', 'Falha ao carregar o índice local de fotos.');
    } finally {
      carregando = false;
      notifyListeners();
    }
  }

  Future<void> definirFoto(int petId, String origem) => _alterar(
    petId,
    () => store.salvar(servidor, petId, origem),
  );

  Future<void> removerFoto(int petId) => _alterar(petId, () async {
    await store.remover(servidor, petId);
    return null;
  });

  Future<void> _alterar(int petId, Future<String?> Function() alterar) async {
    _verificarAberto();
    if (petId <= 0) {
      throw const FotoPetException('Pet inválido para associar a foto.');
    }
    await carregar();
    _verificarAberto();
    if (!_carregou) throw FotoPetException(erro!);
    if (ocupado) {
      throw const FotoPetException('Aguarde a operação de foto em andamento.');
    }
    ocupado = true;
    erro = null;
    final terminou = Completer<void>();
    _operacao = terminou.future;
    notifyListeners();
    try {
      final caminho = await alterar();
      if (caminho == null) {
        _fotos.remove(petId);
      } else {
        _fotos[petId] = caminho;
      }
      AppLog.sucesso('FOTOS', 'Associação da foto atualizada no aparelho.');
    } catch (falha) {
      erro = falha is FotoPetException
          ? falha.mensagem
          : 'Não foi possível atualizar a foto. Tente novamente.';
      AppLog.erro(
        'FOTOS',
        'Falha ao atualizar a foto; associação anterior preservada.',
      );
      throw FotoPetException(erro!);
    } finally {
      ocupado = false;
      terminou.complete();
      _operacao = null;
      notifyListeners();
    }
  }

  void _verificarAberto() {
    if (_fechando) throw StateError('Repositório de fotos encerrado.');
  }

  Future<void> fechar() async {
    _fechando = true;
    await _leitura;
    await _operacao;
    await store.fechar();
  }
}
