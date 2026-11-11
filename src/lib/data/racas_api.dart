import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class RacasException implements Exception {
  final String mensagem;
  const RacasException(this.mensagem);

  @override
  String toString() => mensagem;
}

class RacasApi {
  static final endpoint = Uri.https('query.wikidata.org', '/sparql');

  // Somente nomes em português; não há fallback para rótulos em inglês.
  static const consulta = """
PREFIX wd: <http://www.wikidata.org/entity/>
PREFIX wdt: <http://www.wikidata.org/prop/direct/>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
SELECT DISTINCT ?nome WHERE {
  ?raca wdt:P31 wd:Q39367;
        rdfs:label ?nome.
  FILTER(LANG(?nome) = "pt")
}
ORDER BY ?nome
""";

  final http.Client _client;
  final Duration timeout;

  RacasApi({http.Client? client, this.timeout = const Duration(seconds: 15)})
    : _client = client ?? http.Client();

  Future<List<String>> consultar() async {
    try {
      final resposta = await _client
          .get(
            endpoint.replace(
              queryParameters: {'query': consulta, 'format': 'json'},
            ),
            headers: {
              'Accept': 'application/sparql-results+json',
              'User-Agent': 'BanhoTosaApp/1.0 (https://github.com/Edsonnetocf/banho-tosa-app)',
            },
          )
          .timeout(timeout);
      if (resposta.statusCode != 200) {
        throw RacasException('Consulta de raças: HTTP ${resposta.statusCode}.');
      }

      final dados = jsonDecode(utf8.decode(resposta.bodyBytes));
      if (dados is! Map ||
          dados['results'] is! Map ||
          dados['results']['bindings'] is! List) {
        throw const FormatException('Resposta SPARQL inválida.');
      }

      final nomes = <String>{};
      for (final item in dados['results']['bindings'] as List) {
        if (item is! Map || item['nome'] is! Map) {
          throw const FormatException('Nome de raça ausente.');
        }
        final nome = item['nome'] as Map;
        if (nome['type'] != 'literal' ||
            nome['value'] is! String ||
            nome['xml:lang'] is! String) {
          throw const FormatException('Nome de raça inválido.');
        }
        if (nome['xml:lang'] != 'pt') continue;
        final texto = (nome['value'] as String).trim();
        if (texto.isNotEmpty && texto.length <= 120) nomes.add(texto);
      }
      return List.unmodifiable(
        nomes.toList()..sort(
          (a, b) => a.toLowerCase().compareTo(b.toLowerCase()),
        ),
      );
    } on TimeoutException {
      throw const RacasException('O Wikidata demorou para responder.');
    } on http.ClientException {
      throw const RacasException('Não foi possível consultar o Wikidata.');
    } on FormatException {
      throw const RacasException('O Wikidata enviou uma resposta inválida.');
    }
  }

  void fechar() => _client.close();
}
