import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../utils/app_log.dart';
import 'fotos_pet_store.dart';

abstract class GaleriaPet {
  Future<String?> escolher();
  Future<bool> descartarSelecaoInterrompida();
}

class GaleriaPetNativa implements GaleriaPet {
  final ImagePicker _picker;
  GaleriaPetNativa({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  @override
  Future<String?> escolher() async {
    AppLog.info('FOTOS', 'Abrindo o seletor de imagens do aparelho.');
    try {
      final imagem = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
        requestFullMetadata: false,
      );
      if (imagem == null) {
        AppLog.info('FOTOS', 'Seleção cancelada; foto anterior preservada.');
        return null;
      }
      final arquivo = File(imagem.path);
      final tamanho = await arquivo.length();
      if (tamanho == 0 || tamanho > 10 * 1024 * 1024) {
        throw const FotoPetException('Escolha uma foto de até 10 MB.');
      }
      // Confere o formato sem decodificar a imagem inteira na memória.
      final codec = await ui.instantiateImageCodec(
        await arquivo.readAsBytes(),
        targetWidth: 1,
      );
      try {
        final frame = await codec.getNextFrame();
        frame.image.dispose();
      } finally {
        codec.dispose();
      }
      AppLog.sucesso(
        'FOTOS',
        'Imagem selecionada; aguardando salvar o cadastro.',
      );
      return imagem.path;
    } on FotoPetException {
      rethrow;
    } on PlatformException catch (erro) {
      AppLog.erro(
        'FOTOS',
        'O seletor de imagens falhou | código=${erro.code}.',
      );
      throw FotoPetException(
        erro.code == 'photo_access_denied'
            ? 'Permita o acesso às fotos nas configurações do aparelho.'
            : 'Não foi possível abrir a galeria. Tente novamente.',
      );
    } catch (_) {
      AppLog.erro('FOTOS', 'Não foi possível ler a imagem selecionada.');
      throw const FotoPetException(
        'Não foi possível ler esta foto. Escolha outra.',
      );
    }
  }

  @override
  Future<bool> descartarSelecaoInterrompida() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return false;
    try {
      final resposta = await _picker.retrieveLostData();
      if (resposta.isEmpty) return false;
      // O formulário não sobrevive à morte do processo. Nunca adivinha o pet.
      AppLog.aviso(
        'FOTOS',
        'Seleção interrompida pelo sistema; escolha novamente no formulário.',
      );
      return true;
    } catch (_) {
      AppLog.aviso(
        'FOTOS',
        'Falha ao conferir seleção interrompida da galeria.',
      );
      return false;
    }
  }
}
