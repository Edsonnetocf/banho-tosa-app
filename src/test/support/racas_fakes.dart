import 'package:petshop_app/data/catalogo_racas.dart';
import 'package:petshop_app/data/racas_cache.dart';

class CacheRacasTeste extends RacasCache {
  CatalogoRacas? dados;
  CacheRacasTeste(this.dados);
  @override
  Future<CatalogoRacas?> ler() async => dados;
  @override
  Future<void> salvar(CatalogoRacas novo) async => dados = novo;
  @override
  Future<void> fechar() async {}
}
