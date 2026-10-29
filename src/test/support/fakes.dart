import 'package:petshop_app/data/local_store.dart';

class MemoriaLocal implements PersistenciaLocal {
  final caches = <String, Map<String, Object?>>{};
  bool falharAoSalvar = false;
  Map<String, Object?> legado = {
    'clientes': [],
    'pets': [],
    'agendamentos': [],
  };
  @override
  Future<Map<String, Object?>?> lerCache(String servidor) async =>
      caches[servidor];
  @override
  Future<void> salvarCache(String servidor, Map<String, Object?> estado) async {
    if (falharAoSalvar) throw StateError('Disco indisponível');
    caches[servidor] = estado;
  }

  @override
  Future<Map<String, Object?>> lerLegado() async => legado;
  @override
  Future<String> origem() async => 'origem-local-teste-1234';
  @override
  Future<void> fechar() async {}
}
