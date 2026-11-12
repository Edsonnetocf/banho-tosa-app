String normalizarRaca(String texto) {
  const acentos = 'áàâãäéèêëíìîïóòôõöúùûüç';
  const simples = 'aaaaaeeeeiiiiooooouuuuc';
  var resultado = texto.toLowerCase();
  for (var i = 0; i < acentos.length; i++) {
    resultado = resultado.replaceAll(acentos[i], simples[i]);
  }
  return resultado
      .replaceAll(RegExp(r'[\u0300-\u036f]'), '')
      .replaceAll(RegExp(r'[-\u2010-\u2015\s]+'), ' ')
      .trim();
}

List<String> buscarRacas(Iterable<String> nomes, String texto) {
  final busca = normalizarRaca(texto);
  if (busca.length < 2) return const [];
  final encontrados = <String, String>{};
  for (final nome in nomes) {
    final normalizado = normalizarRaca(nome);
    if (normalizado.contains(busca)) {
      encontrados.putIfAbsent(normalizado, () => nome);
    }
  }
  final chaves = encontrados.keys.toList()
    ..sort((a, b) {
      final aComeca = a.startsWith(busca);
      final bComeca = b.startsWith(busca);
      if (aComeca != bComeca) return aComeca ? -1 : 1;
      return a.compareTo(b);
    });
  return chaves.map((chave) => encontrados[chave]!).toList();
}
