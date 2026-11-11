import 'dart:io';

import 'package:petshop_app/data/racas_api.dart';

Future<void> main() async {
  final api = RacasApi();
  try {
    final nomes = await api.consultar();
    if (nomes.isEmpty) {
      stderr.writeln('A consulta respondeu sem nomes em português.');
      exitCode = 1;
      return;
    }
    stdout.writeln('${nomes.length} nomes em português recebidos do Wikidata.');
    for (final nome in nomes.where(
      (n) =>
          n.toLowerCase().contains('pastor-alem') ||
          n.toLowerCase().contains('buldogue fran') ||
          n.toLowerCase().contains('dálmata'),
    )) {
      stdout.writeln('- $nome');
    }
    stdout.writeln('Consulta concluída. Nenhum cadastro foi alterado.');
  } on RacasException catch (erro) {
    stderr.writeln(erro);
    exitCode = 1;
  } finally {
    api.fechar();
  }
}
