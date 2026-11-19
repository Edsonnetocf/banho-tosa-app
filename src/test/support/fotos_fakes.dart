import 'dart:async';
import 'dart:collection';

import 'package:petshop_app/data/fotos_pet_repository.dart';
import 'package:petshop_app/data/fotos_pet_store.dart';
import 'package:petshop_app/data/galeria_pet.dart';

class FotosMemoria extends FotosPetStore {
  final dados = <String, Map<int, String>>{};
  bool falhaLeitura = false;
  bool falhaAlteracao = false;
  int leituras = 0;
  int gravacoes = 0;
  bool fechado = false;
  Completer<void>? inicio;
  Completer<void>? liberar;
  @override
  Future<Map<int, String>> carregar(String servidor) async {
    leituras++;
    if (falhaLeitura) throw StateError('Falha simulada');
    return Map.from(dados[servidor] ?? {});
  }

  @override
  Future<String> salvar(String servidor, int petId, String origem) async {
    gravacoes++;
    inicio?.complete();
    if (liberar != null) await liberar!.future;
    if (falhaAlteracao) throw StateError('Falha simulada');
    final caminho = '/privado/foto-$gravacoes.img';
    (dados[servidor] ??= {})[petId] = caminho;
    return caminho;
  }

  @override
  Future<void> remover(String servidor, int petId) async {
    if (falhaAlteracao) throw StateError('Falha simulada');
    dados[servidor]?.remove(petId);
  }

  @override
  Future<void> fechar() async => fechado = true;
}

FotosPetRepository fotosTeste() => FotosPetRepository(
  servidor: 'http://10.0.2.2:3000/api',
  store: FotosMemoria(),
);

class GaleriaTeste implements GaleriaPet {
  final resultados = Queue<String?>();
  bool falhar = false;
  int aberturas = 0;
  @override
  Future<String?> escolher() async {
    aberturas++;
    if (falhar) {
      throw const FotoPetException('Galeria indisponível. Tente novamente.');
    }
    return resultados.isEmpty ? null : resultados.removeFirst();
  }

  @override
  Future<bool> descartarSelecaoInterrompida() async => false;
}
