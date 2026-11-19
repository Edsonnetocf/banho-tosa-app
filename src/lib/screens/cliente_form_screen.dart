import 'package:flutter/material.dart';

import '../data/app_scope.dart';
import '../models/cliente.dart';
import '../models/pet.dart';
import '../data/fotos_pet_store.dart';
import '../widgets/foto_pet.dart';
import '../utils/app_log.dart';
import '../data/racas_repository.dart';
import '../widgets/campo_raca.dart';

class ClienteFormScreen extends StatefulWidget {
  final Cliente? cliente;
  final Pet? pet;
  final RacasRepository? racasRepository;

  const ClienteFormScreen({
    super.key,
    this.cliente,
    this.pet,
    this.racasRepository,
  });

  @override
  State<ClienteFormScreen> createState() => _ClienteFormScreenState();
}

class _ClienteFormScreenState extends State<ClienteFormScreen> {
  bool _salvando = false;
  bool _escolhendoFoto = false;
  bool _fotoAlterada = false;
  String? _fotoRascunho;
  Pet? get _pet => widget.pet ?? widget.cliente?.pets.firstOrNull;

  final _formKey = GlobalKey<FormState>();
  final _nomeClienteController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _nomePetController = TextEditingController();
  final _racaController = TextEditingController();

  String _especie = 'Cachorro';
  String _porte = 'Médio';

  bool get _editando => widget.cliente != null;

  @override
  void initState() {
    super.initState();

    final cliente = widget.cliente;

    if (cliente != null) {
      _nomeClienteController.text = cliente.nome;
      _telefoneController.text = cliente.telefone;

      final pet = _pet;
      if (pet != null) {
        _nomePetController.text = pet.nome;
        _racaController.text = pet.raca;
        _especie = pet.especie;
        _porte = pet.porte;
      }
    }
  }

  @override
  void dispose() {
    _nomeClienteController.dispose();
    _telefoneController.dispose();
    _nomePetController.dispose();
    _racaController.dispose();
    super.dispose();
  }

  Future<void> _escolherFoto() async {
    if (_salvando || _escolhendoFoto) return;
    FocusScope.of(context).unfocus();
    final galeria = AppScope.read(context).galeria;
    setState(() => _escolhendoFoto = true);
    try {
      final caminho = await galeria.escolher();
      if (!mounted || caminho == null) return;
      setState(() {
        _fotoRascunho = caminho;
        _fotoAlterada = true;
      });
    } catch (erro) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            erro is FotoPetException
                ? erro.mensagem
                : 'Não foi possível abrir a galeria. Tente novamente.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _escolhendoFoto = false);
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate() || _salvando || _escolhendoFoto) {
      return;
    }

    setState(() => _salvando = true);

    try {
      final cliente = widget.cliente;

      final repo = AppScope.read(context);
      final petIdSalvo = await repo.salvarClienteComPet(
        clienteId: cliente?.id,
        petId: _pet?.id,
        nomeCliente: _nomeClienteController.text.trim(),
        telefone: _telefoneController.text.trim(),
        nomePet: _nomePetController.text.trim(),
        especie: _especie,
        raca: _racaController.text.trim(),
        porte: _porte,
      );

      String? avisoFoto;
      if (_fotoAlterada) {
        try {
          if (petIdSalvo == null) {
            throw const FotoPetException('Identificador do pet não recebido.');
          }
          if (_fotoRascunho == null) {
            await repo.fotos.removerFoto(petIdSalvo);
          } else {
            await repo.fotos.definirFoto(petIdSalvo, _fotoRascunho!);
          }
        } catch (_) {
          // O cadastro já foi salvo. Nunca oferece reenviar o POST por falha local.
          AppLog.aviso(
            'FOTOS',
            'Cadastro salvo; foto local não atualizada. Repetir somente a foto pela edição.',
          );
          avisoFoto =
              'Cadastro salvo, mas a foto não pôde ser atualizada. '
              'Abra a edição do pet para tentar novamente.';
        }
      }
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            avisoFoto ??
                (_editando
                    ? 'Cadastro atualizado com sucesso!'
                    : 'Cliente e pet cadastrados com sucesso!'),
          ),
        ),
      );

      Navigator.pop(context, true);
    } catch (erro) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível salvar o cadastro: $erro')),
      );
    } finally {
      if (mounted) {
        setState(() => _salvando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = AppScope.of(context);
    final caminhoFoto = _fotoAlterada
        ? _fotoRascunho
        : repo.fotos.caminhoPara(_pet?.id ?? -1);
    return PopScope(
      canPop: !_salvando && !_escolhendoFoto,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _editando ? 'Editar Cliente e Pet' : 'Novo Cliente e Pet',
          ),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Dados do Cliente',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nomeClienteController,
                maxLength: 120,
                decoration: const InputDecoration(
                  labelText: 'Nome do cliente',
                  border: OutlineInputBorder(),
                ),
                validator: (valor) {
                  if (valor == null || valor.trim().isEmpty) {
                    return 'Informe o nome do cliente';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _telefoneController,
                maxLength: 25,
                validator: (valor) {
                  final telefone = valor?.trim() ?? '';
                  if (telefone.isEmpty) return null;
                  if (!RegExp(r'^[\d\s()+-]+$').hasMatch(telefone) ||
                      !RegExp(r'^\d{10,11}$')
                          .hasMatch(telefone.replaceAll(RegExp(r'\D'), ''))) {
                    return 'Informe DDD e número com 10 ou 11 dígitos';
                  }
                  return null;
                },
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Telefone',
                  border: OutlineInputBorder(),
                ),
              ),
              const Divider(height: 32),
              const Text(
                'Dados do Pet',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  FotoPet(caminho: caminhoFoto, tamanho: 80),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextButton.icon(
                      onPressed: _salvando || _escolhendoFoto
                          ? null
                          : _escolherFoto,
                      icon: const Icon(Icons.photo_library_outlined),
                      label: Text(
                        caminhoFoto == null ? 'Adicionar foto' : 'Trocar foto',
                      ),
                    ),
                  ),
                  if (caminhoFoto != null)
                    IconButton(
                      tooltip: 'Remover foto',
                      onPressed: _salvando || _escolhendoFoto
                          ? null
                          : () {
                              setState(() {
                                _fotoRascunho = null;
                                _fotoAlterada = true;
                              });
                            },
                      icon: const Icon(Icons.close),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nomePetController,
                maxLength: 120,
                decoration: const InputDecoration(
                  labelText: 'Nome do pet',
                  border: OutlineInputBorder(),
                ),
                validator: (valor) {
                  if (valor == null || valor.trim().isEmpty) {
                    return 'Informe o nome do pet';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _especie,
                decoration: const InputDecoration(
                  labelText: 'Espécie',
                  border: OutlineInputBorder(),
                ),
                items: ['Cachorro', 'Gato', 'Outro']
                    .map(
                      (especie) => DropdownMenuItem(
                        value: especie,
                        child: Text(especie),
                      ),
                    )
                    .toList(),
                onChanged: (valor) {
                  if (valor != null) {
                    setState(() => _especie = valor);
                  }
                },
              ),
              const SizedBox(height: 12),
              CampoRaca(
                controller: _racaController,
                repository: widget.racasRepository ?? RacasRepository.instancia,
                sugerir: _especie == 'Cachorro',
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _porte,
                decoration: const InputDecoration(
                  labelText: 'Porte',
                  border: OutlineInputBorder(),
                ),
                items: ['Pequeno', 'Médio', 'Grande']
                    .map(
                      (porte) =>
                          DropdownMenuItem(value: porte, child: Text(porte)),
                    )
                    .toList(),
                onChanged: (valor) {
                  if (valor != null) {
                    setState(() => _porte = valor);
                  }
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: const Color(0xFF0B6374),
                ),
                onPressed: _salvando || _escolhendoFoto || !repo.podeGravar
                    ? null
                    : _salvar,
                child: _salvando
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _editando ? 'Salvar Alterações' : 'Salvar',
                        style: const TextStyle(color: Colors.white),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
