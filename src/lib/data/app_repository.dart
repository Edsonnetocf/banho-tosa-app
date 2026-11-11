import 'package:flutter/foundation.dart';

import '../utils/app_log.dart';
import '../models/cliente.dart';
import '../models/pet.dart';
import '../models/agendamento.dart';
import 'api_client.dart';
import 'local_store.dart';

class AppRepository extends ChangeNotifier {
  static final instancia = AppRepository();
  final ApiClient api;
  final PersistenciaLocal local;
  AppRepository({ApiClient? api, PersistenciaLocal? local})
    : api = api ?? ApiClient(),
      local = local ?? LocalStore();

  List<Cliente> clientes = const [];
  List<Agendamento> agendamentos = const [];
  bool possuiDados = false;
  bool ocupado = false;
  bool offline = false;
  String? erro;
  String? aviso;
  DateTime? atualizadoEm;
  Future<void>? _inicializacao;

  bool get podeGravar => possuiDados && !offline && !ocupado;
  Future<void> iniciar() => _inicializacao ??= atualizar();

  void _aplicar(Map<String, Object?> estado) {
    final novosClientes = (estado['clientes'] as List).map((item) {
      final c = Map<String, Object?>.from(item as Map);
      final pets = (c['pets'] as List)
          .map((p) => Pet.fromMap(Map<String, Object?>.from(p as Map)))
          .toList();
      return Cliente.fromMap(c, pets: pets);
    }).toList();
    final novosAgendamentos = (estado['agendamentos'] as List)
        .map((a) => Agendamento.fromMap(Map<String, Object?>.from(a as Map)))
        .toList();
    clientes = List.unmodifiable(novosClientes);
    agendamentos = List.unmodifiable(novosAgendamentos);
    atualizadoEm = DateTime.tryParse(estado['atualizado_em'] as String? ?? '');
    possuiDados = true;
  }

  Future<void> _guardar(Map<String, Object?> estado) async {
    final snapshot = {
      ...estado,
      'atualizado_em': DateTime.now().toIso8601String(),
    };
    _aplicar(snapshot);
    try {
      await local.salvarCache(api.baseUrl, snapshot);
      AppLog.sucesso(
        'CACHE',
        'Cópia dos dados do servidor atualizada no aparelho.',
      );
    } catch (_) {
      aviso = 'Dados confirmados pelo servidor, mas o cache local não pôde ser atualizado.';
      AppLog.aviso(
        'CACHE',
        'Falha ao guardar a cópia local; dados do servidor mantidos em memória.',
      );
    }
  }

  Future<void> atualizar() async {
    if (ocupado) return;
    AppLog.info('API', 'Atualizando clientes e agendamentos.');
    ocupado = true;
    erro = null;
    aviso = null;
    notifyListeners();
    try {
      if (!possuiDados) {
        try {
          final cache = await local.lerCache(api.baseUrl);
          if (cache != null) {
            _aplicar(cache);
            offline = true;
            AppLog.info(
              'CACHE',
              'Cópia local carregada | última atualização: $atualizadoEm.',
            );
          }
        } catch (_) {
          aviso = 'Não foi possível ler o cache local.';
          AppLog.aviso(
            'CACHE',
            'Falha ao ler a cópia local; tentando o servidor.',
          );
        }
      }
      await _guardar(await api.requisitar('GET', '/estado'));
      offline = false;
      AppLog.sucesso(
        'API',
        'Servidor conectado | clientes=${clientes.length} | agendamentos=${agendamentos.length}.',
      );
    } catch (e) {
      offline = true;
      erro = e is StateError
          ? e.message.toString()
          : 'Não foi possível carregar os dados.';
      AppLog.erro(
        'API',
        possuiDados
            ? 'Atualização falhou | usando cópia local somente para consulta.'
            : 'Atualização falhou | nenhum dado disponível para consulta.',
      );
    } finally {
      ocupado = false;
      notifyListeners();
    }
  }

  Future<Map<String, Object?>> _gravar(
    String metodo,
    String caminho, [
    Map<String, Object?>? corpo,
  ]) async {
    if (!podeGravar) {
      AppLog.aviso(
        'API',
        '$metodo $caminho não enviado: gravação indisponível.',
      );
      throw ApiException('Atualize a conexão com o servidor antes de gravar.');
    }
    ocupado = true;
    erro = null;
    aviso = null;
    AppLog.info('API', '$metodo $caminho | enviando operação.');
    notifyListeners();
    try {
      final estado = await api.requisitar(metodo, caminho, corpo);
      await _guardar(estado);
      AppLog.sucesso(
        'API',
        '$metodo $caminho | operação confirmada pelo servidor.',
      );
      return estado;
    } on ApiException catch (e) {
      if (e.indisponivel) {
        AppLog.erro(
          'API',
          '$metodo $caminho | falha de comunicação com o servidor.',
        );
      } else {
        AppLog.aviso(
          'API',
          '$metodo $caminho | operação recusada pelo servidor.',
        );
      }
      if (e.indisponivel) {
        offline = true;
        erro = e.message.toString();
      }
      rethrow;
    } finally {
      ocupado = false;
      notifyListeners();
    }
  }

  Future<void> salvarClienteComPet({
    int? clienteId,
    int? petId,
    required String nomeCliente,
    required String telefone,
    required String nomePet,
    required String especie,
    required String raca,
    required String porte,
  }) async {
    await _gravar(
      clienteId == null ? 'POST' : 'PUT',
      clienteId == null ? '/clientes' : '/clientes/$clienteId',
      {
        'nome': nomeCliente,
        'telefone': telefone,
        'pet': {
          'id': ?petId,
          'nome': nomePet,
          'especie': especie,
          'raca': raca,
          'porte': porte,
        },
      },
    );
  }

  Future<void> excluirCliente(int id) async {
    await _gravar('DELETE', '/clientes/$id');
  }

  Future<void> excluirAgendamento(int id) async {
    await _gravar('DELETE', '/agendamentos/$id');
  }

  Future<void> salvarAgendamento({
    int? id,
    required int petId,
    required DateTime dataHora,
    required String servico,
  }) async {
    final minuto = DateTime(
      dataHora.year,
      dataHora.month,
      dataHora.day,
      dataHora.hour,
      dataHora.minute,
    );
    await _gravar(
      id == null ? 'POST' : 'PUT',
      id == null ? '/agendamentos' : '/agendamentos/$id',
      {
        'pet_id': petId,
        'data_hora': minuto.toIso8601String(),
        'servico': servico,
      },
    );
  }

  Future<Map<String, Object?>> importarLegado() async {
    AppLog.info('IMPORTACAO', 'Iniciando importação dos dados antigos.');
    final dados = await local.lerLegado();
    if ((dados['clientes'] as List).isEmpty) {
      AppLog.aviso(
        'IMPORTACAO',
        'Nenhum cadastro antigo disponível neste aparelho.',
      );
      throw ApiException('Não há cadastros da Etapa 4 neste dispositivo.');
    }
    final origem = await local.origem();
    final resposta = await _gravar('POST', '/importacoes', {
      ...dados,
      'origem': origem,
    });
    final resultado = Map<String, Object?>.from(resposta['importacao'] as Map);
    AppLog.sucesso(
      'IMPORTACAO',
      'Concluída | clientes=${resultado['clientes']} | pets=${resultado['pets']} | agendamentos=${resultado['agendamentos']} | repetida=${resultado['repetida'] == true}.',
    );
    return resultado;
  }

  Future<void> fechar() async {
    api.close();
    await local.fechar();
  }
}
