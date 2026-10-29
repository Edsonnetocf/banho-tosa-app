import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiException extends StateError {
  final bool indisponivel;
  ApiException(super.message, {this.indisponivel = false});
  @override
  String toString() => message.toString();
}

class ApiClient {
  final http.Client _client;
  final String baseUrl;
  final Duration timeout;

  ApiClient({
    http.Client? client,
    String? baseUrl,
    this.timeout = const Duration(seconds: 10),
  }) : _client = client ?? http.Client(),
       baseUrl =
           (baseUrl ??
                   const String.fromEnvironment(
                     'API_BASE_URL',
                     defaultValue: 'http://10.0.2.2:3000/api',
                   ))
               .replaceFirst(RegExp(r'/+$'), '');

  Future<Map<String, Object?>> requisitar(
    String metodo,
    String caminho, [
    Map<String, Object?>? corpo,
  ]) async {
    try {
      final request = http.Request(metodo, Uri.parse('$baseUrl$caminho'));
      request.headers['Accept'] = 'application/json';
      if (corpo != null) {
        request.headers['Content-Type'] = 'application/json; charset=utf-8';
        request.body = jsonEncode(corpo);
      }
      final resposta = await _client
          .send(request)
          .then(http.Response.fromStream)
          .timeout(timeout);
      final dados = jsonDecode(utf8.decode(resposta.bodyBytes));
      if (resposta.statusCode < 200 || resposta.statusCode >= 300) {
        throw ApiException(
          dados is Map && dados['mensagem'] is String
              ? dados['mensagem'] as String
              : 'O servidor não concluiu a operação.',
          indisponivel: resposta.statusCode >= 500,
        );
      }
      if (dados is! Map<String, dynamic>) {
        throw const FormatException('Objeto JSON esperado');
      }
      return Map<String, Object?>.from(dados);
    } on TimeoutException {
      throw ApiException(
        'O servidor demorou para responder. Atualize a lista '
        'para conferir o resultado antes de repetir uma gravação.',
        indisponivel: true,
      );
    } on http.ClientException {
      throw ApiException(
        'Sem conexão com o servidor. Confira a API e tente atualizar.',
        indisponivel: true,
      );
    } on FormatException {
      throw ApiException(
        'O servidor enviou uma resposta inválida.',
        indisponivel: true,
      );
    }
  }

  void close() => _client.close();
}
