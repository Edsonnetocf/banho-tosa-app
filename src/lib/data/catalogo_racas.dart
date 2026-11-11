class CatalogoRacas {
  final List<String> nomes;
  final DateTime atualizadoEm;

  CatalogoRacas({required Iterable<String> nomes, required this.atualizadoEm})
    : nomes = List.unmodifiable(nomes);

  bool validoEm(DateTime agora, Duration validade) {
    final idade = agora.difference(atualizadoEm);
    return nomes.isNotEmpty && !idade.isNegative && idade < validade;
  }
}
