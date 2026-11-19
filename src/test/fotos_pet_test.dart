import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:petshop_app/data/fotos_pet_repository.dart';
import 'package:petshop_app/data/fotos_pet_store.dart';

import 'support/fotos_fakes.dart';

void main() {
  late FotosMemoria local;
  late FotosPetRepository repo;
  setUp(() {
    local = FotosMemoria()
      ..dados['http://teste/api'] = {7: '/privado/anterior.img'};
    repo = FotosPetRepository(servidor: 'http://teste/api/', store: local);
  });
  tearDown(() async {
    await repo.fechar();
    repo.dispose();
  });

  test(
    'carrega o índice uma vez e impede alteração externa do estado',
    () async {
      await Future.wait([repo.carregar(), repo.carregar()]);
      await repo.carregar();
      expect(local.leituras, 1);
      expect(repo.caminhoPara(7), '/privado/anterior.img');
      expect(() => repo.fotos[7] = 'alterado', throwsUnsupportedError);
    },
  );

  test('observadores só recebem a foto nova após sua persistência', () async {
    await repo.carregar();
    final primeiraTela = <String?>[];
    final segundaTela = <String?>[];
    repo.addListener(() => primeiraTela.add(repo.caminhoPara(7)));
    repo.addListener(() => segundaTela.add(repo.caminhoPara(7)));
    local.inicio = Completer<void>();
    local.liberar = Completer<void>();
    final salvar = repo.definirFoto(7, 'foto-escolhida');
    await local.inicio!.future;
    expect(repo.ocupado, isTrue);
    expect(repo.caminhoPara(7), '/privado/anterior.img');
    local.liberar!.complete();
    await salvar;
    expect(primeiraTela.last, '/privado/foto-1.img');
    expect(segundaTela.last, primeiraTela.last);
    expect(local.dados[repo.servidor]![7], primeiraTela.last);
  });

  test(
    'falha ao trocar mantém foto anterior e libera nova tentativa',
    () async {
      local.falhaAlteracao = true;
      await expectLater(
        repo.definirFoto(7, 'nova'),
        throwsA(isA<FotoPetException>()),
      );
      expect(repo.caminhoPara(7), '/privado/anterior.img');
      expect(repo.erro, isNotNull);
      expect(repo.ocupado, isFalse);
      local.falhaAlteracao = false;
      await repo.definirFoto(7, 'nova');
      expect(repo.caminhoPara(7), '/privado/foto-2.img');
      expect(repo.erro, isNull);
    },
  );

  test(
    'remoção falha preserva foto; remoção confirmada limpa o estado',
    () async {
      local.falhaAlteracao = true;
      await expectLater(repo.removerFoto(7), throwsA(isA<FotoPetException>()));
      expect(repo.caminhoPara(7), '/privado/anterior.img');
      local.falhaAlteracao = false;
      await repo.removerFoto(7);
      expect(repo.caminhoPara(7), isNull);
      expect(local.dados[repo.servidor]!.containsKey(7), isFalse);
    },
  );

  test(
    'falha de leitura permite tentar novamente sem perder o índice',
    () async {
      local.falhaLeitura = true;
      await repo.carregar();
      expect(repo.erro, isNotNull);
      await expectLater(
        repo.definirFoto(7, 'nova'),
        throwsA(isA<FotoPetException>()),
      );
      expect(local.gravacoes, 0);
      local.falhaLeitura = false;
      await repo.carregar();
      expect(repo.caminhoPara(7), '/privado/anterior.img');
      expect(repo.erro, isNull);
    },
  );

  test('mesmo ID em servidores diferentes não mistura fotos', () async {
    local.dados['http://outro/api'] = {7: '/privado/outro.img'};
    final outro = FotosPetRepository(
      servidor: 'http://outro/api',
      store: local,
    );
    try {
      await repo.carregar();
      await outro.carregar();
      expect(repo.caminhoPara(7), '/privado/anterior.img');
      expect(outro.caminhoPara(7), '/privado/outro.img');
    } finally {
      await outro.fechar();
      outro.dispose();
    }
  });

  test(
    'bloqueia alteração concorrente e aguarda operação antes de fechar',
    () async {
      await repo.carregar();
      local.inicio = Completer<void>();
      local.liberar = Completer<void>();
      final salvar = repo.definirFoto(7, 'nova');
      await local.inicio!.future;
      await expectLater(repo.removerFoto(7), throwsA(isA<FotoPetException>()));
      final fechar = repo.fechar();
      expect(local.fechado, isFalse);
      local.liberar!.complete();
      await salvar;
      await fechar;
      expect(local.fechado, isTrue);
      expect(() => repo.carregar(), throwsStateError);
    },
  );

  test('ID inválido é rejeitado antes de carregar ou gravar', () async {
    await expectLater(
      repo.definirFoto(0, 'foto'),
      throwsA(isA<FotoPetException>()),
    );
    expect(local.leituras, 0);
    expect(local.gravacoes, 0);
  });
}
