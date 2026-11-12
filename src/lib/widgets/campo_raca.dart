import 'dart:async';

import 'package:flutter/material.dart';

import '../data/racas_repository.dart';
import '../utils/app_log.dart';
import '../utils/busca_racas.dart';

class CampoRaca extends StatefulWidget {
  final TextEditingController controller;
  final RacasRepository repository;
  final bool sugerir;

  const CampoRaca({
    super.key,
    required this.controller,
    required this.repository,
    required this.sugerir,
  });

  @override
  State<CampoRaca> createState() => _CampoRacaState();
}

class _CampoRacaState extends State<CampoRaca> {
  final _focus = FocusNode();
  final _dadosDisponiveis = Completer<void>();
  bool _iniciou = false;

  @override
  void initState() {
    super.initState();
    widget.repository.addListener(_catalogoMudou);
    if (widget.sugerir) _iniciar();
  }

  @override
  void didUpdateWidget(CampoRaca oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.sugerir && !oldWidget.sugerir) _iniciar();
  }

  void _catalogoMudou() {
    final repo = widget.repository;
    if (repo.nomes.isNotEmpty ||
        repo.estado == EstadoRacas.sucesso ||
        repo.estado == EstadoRacas.vazio ||
        repo.estado == EstadoRacas.erro) {
      _liberarEspera();
    }
  }

  void _liberarEspera() {
    if (!_dadosDisponiveis.isCompleted) _dadosDisponiveis.complete();
  }

  void _iniciar() {
    if (_iniciou) return;
    _iniciou = true;
    unawaited(_carregar());
  }

  Future<void> _carregar() async {
    try {
      await widget.repository.carregar();
    } catch (_) {
      // A sugestão é opcional e nunca impede o preenchimento do formulário.
      AppLog.erro(
        'RACAS',
        'Falha ao preparar sugestões; preenchimento manual disponível.',
      );
    } finally {
      _liberarEspera();
    }
  }

  Future<Iterable<String>> _opcoes(TextEditingValue valor) async {
    if (!widget.sugerir || normalizarRaca(valor.text).length < 2) {
      return const [];
    }
    if (widget.repository.nomes.isEmpty) await _dadosDisponiveis.future;
    if (!mounted || !widget.sugerir) return const [];
    // O RawAutocomplete descarta respostas de consultas de texto ultrapassadas.
    return buscarRacas(widget.repository.nomes, valor.text);
  }

  Widget _campo(
    TextEditingController controller,
    FocusNode focus, [
    VoidCallback? enviar,
  ]) => TextFormField(
    key: const ValueKey('campo_raca'),
    controller: controller,
    focusNode: focus,
    maxLength: 120,
    scrollPadding: const EdgeInsets.only(top: 24, bottom: 280),
    decoration: const InputDecoration(
      labelText: 'Raça',
      border: OutlineInputBorder(),
    ),
    onTapOutside: (_) => focus.unfocus(),
    onFieldSubmitted: (_) => enviar?.call(),
  );

  @override
  Widget build(BuildContext context) {
    if (!widget.sugerir) return _campo(widget.controller, _focus);
    return RawAutocomplete<String>(
      textEditingController: widget.controller,
      focusNode: _focus,
      optionsBuilder: _opcoes,
      fieldViewBuilder: (_, controller, focus, enviar) =>
          _campo(controller, focus, enviar),
      optionsViewBuilder: (context, selecionar, opcoes) {
        final nomes = opcoes.toList();
        final destacado = AutocompleteHighlightedOption.of(context);
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            key: const ValueKey('sugestoes_raca'),
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            clipBehavior: Clip.antiAlias,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: nomes.length,
                itemBuilder: (_, i) => ListTile(
                  minTileHeight: 48,
                  title: Text(nomes[i]),
                  tileColor: i == destacado
                      ? Theme.of(context).colorScheme.surfaceContainerHighest
                      : null,
                  onTap: () => selecionar(nomes[i]),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    widget.repository.removeListener(_catalogoMudou);
    _liberarEspera();
    _focus.dispose();
    super.dispose();
  }
}
