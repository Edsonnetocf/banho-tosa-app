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
        title: const Text('Importar dados antigos'),
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

  Widget _menuDados() {
    final repo = AppScope.of(context);
    return PopupMenuButton<String>(
      tooltip: 'Mais opções',
      onSelected: (acao) async {
        if (acao == 'atualizar') {
          await repo.atualizar();
        } else if (acao == 'importar') {
          await _importar();
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'atualizar',
          enabled: !repo.ocupado && !_importando,
          child: const Text('Atualizar dados'),
        ),
        PopupMenuItem(
          value: 'importar',
          enabled: repo.podeGravar && !_importando,
          child: const Text('Importar dados antigos'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = AppScope.of(context);
    return Material(
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: repo.possuiDados
                  ? IndexedStack(
                      index: _aba,
                      children: [
                        HeroMode(
                          enabled: _aba == 0,
                          child: AgendaScreen(acoes: [_menuDados()]),
                        ),
                        HeroMode(
                          enabled: _aba == 1,
                          child: ClientesScreen(acoes: [_menuDados()]),
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
