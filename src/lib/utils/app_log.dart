import 'package:flutter/foundation.dart';

/// Diagnóstico local, somente em desenvolvimento. Não registrar cadastros,
/// corpos HTTP, credenciais ou outros dados pessoais.
abstract final class AppLog {
  static void info(String origem, String mensagem) =>
      _escrever('INFO', origem, mensagem);
  static void sucesso(String origem, String mensagem) =>
      _escrever('OK', origem, mensagem);
  static void aviso(String origem, String mensagem) =>
      _escrever('AVISO', origem, mensagem);
  static void erro(String origem, String mensagem) =>
      _escrever('ERRO', origem, mensagem);

  static void _escrever(String nivel, String origem, String mensagem) {
    if (!kDebugMode) return;
    final hora = DateTime.now().toIso8601String().substring(11, 23);
    debugPrint('[BanhoTosa] [$hora] [$nivel] [$origem] $mensagem');
  }
}
