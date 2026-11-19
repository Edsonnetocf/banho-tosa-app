import 'dart:io';

import 'package:flutter/material.dart';

class FotoPet extends StatelessWidget {
  final String? caminho;
  final double tamanho;
  const FotoPet({super.key, this.caminho, this.tamanho = 48});

  @override
  Widget build(BuildContext context) {
    final fundo = ColoredBox(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Icon(Icons.pets, size: tamanho * 0.5),
    );
    return Semantics(
      label: caminho == null ? 'Pet sem foto' : 'Foto do pet',
      image: true,
      excludeSemantics: true,
      child: ClipOval(
        child: SizedBox.square(
          dimension: tamanho,
          child: caminho == null
              ? fundo
              : Image.file(
                  File(caminho!),
                  key: ValueKey(caminho),
                  fit: BoxFit.cover,
                  cacheWidth: (tamanho * MediaQuery.devicePixelRatioOf(context))
                      .ceil(),
                  errorBuilder: (_, _, _) => fundo,
                ),
        ),
      ),
    );
  }
}
