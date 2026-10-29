import 'package:flutter/material.dart';

import '../data/app_scope.dart';
import 'agenda_screen.dart';
import 'clientes_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _aba = 0;
  bool _importando = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) AppScope.read(context).iniciar();
    });
  }

  Future<void> _importar() async {
    final repo = AppScope.read(context);
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Importar dados da Etapa 4'),
        content: const Text(
          'Enviar os clientes, pets e agendamentos antigos deste dispositivo para o servidor? '
          'O banco original será preservado. Repetir a importação nesta instalação não duplica os registros.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialog, true),
            child: const Text('Importar'),
          ),
        ],
      ),
    );
    if (confirmou != true || !mounted) return;
    setState(() => _importando = true);
    try {
      final resultado = await repo.importarLegado();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            resultado['repetida'] == true
                ? 'Esta instalação já foi importada. Dados atualizados.'
                : 'Importação concluída: ${resultado['clientes']} cliente(s), ${resultado['pets']} pet(s) e '
                      '${resultado['agendamentos']} agendamento(s).',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _importando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = AppScope.of(context);
    final data = repo.atualizadoEm?.toLocal();
    final hora = data == null
        ? ''
        : ' • ${data.day}/${data.month} '
              '${data.hour.toString().padLeft(2, '0')}:${data.minute.toString().padLeft(2, '0')}';
    return Material(
      child: SafeArea(
        child: Column(
          children: [
            Material(
              color: repo.offline
                  ? Theme.of(context).colorScheme.errorContainer
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        repo.offline
                            ? 'Consulta offline$hora'
                            : repo.possuiDados
                            ? 'Servidor conectado$hora'
                            : 'Conectando ao servidor',
                      ),
                    ),
                    IconButton(
                      tooltip: 'Atualizar dados',
                      onPressed: repo.ocupado || _importando
                          ? null
                          : repo.atualizar,
                      icon: const Icon(Icons.refresh),
                    ),
                    IconButton(
                      tooltip: 'Importar dados da Etapa 4',
                      onPressed: repo.podeGravar && !_importando
                          ? _importar
                          : null,
                      icon: const Icon(Icons.file_download_outlined),
                    ),
                  ],
                ),
              ),
            ),
            if (repo.ocupado || _importando) const LinearProgressIndicator(),
            if (repo.erro != null || repo.aviso != null)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  repo.offline && repo.possuiDados
                      ? '${repo.erro ?? ''} Apenas consulta; gravações indisponíveis.'
                      : repo.erro ?? repo.aviso!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            Expanded(
              child: repo.possuiDados
                  ? IndexedStack(
                      index: _aba,
                      children: [
                        HeroMode(
                          enabled: _aba == 0,
                          child: const AgendaScreen(),
                        ),
                        HeroMode(
                          enabled: _aba == 1,
                          child: const ClientesScreen(),
                        ),
                      ],
                    )
                  : Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            repo.ocupado
                                ? 'Carregando dados…'
                                : 'Não há dados do servidor disponíveis.',
                          ),
                          if (!repo.ocupado)
                            TextButton(
                              onPressed: repo.atualizar,
                              child: const Text('Tentar novamente'),
                            ),
                        ],
                      ),
                    ),
            ),
            NavigationBar(
              selectedIndex: _aba,
              onDestinationSelected: (i) => setState(() => _aba = i),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.calendar_today_outlined),
                  label: 'Agenda',
                ),
                NavigationDestination(
                  icon: Icon(Icons.people_outline),
                  label: 'Clientes',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
