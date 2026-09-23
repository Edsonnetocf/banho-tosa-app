import 'package:flutter/material.dart';
import 'agenda_screen.dart';
import 'clientes_screen.dart';

///mantem a barra de abas fixa na parte de baixo e troca o conteudo entre agenda e clientes
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _abaSelecionada = 0;

  //indexedStack mantem o estado de cada aba mesmo trocando entre elas
  final List<Widget> _telas = const [
    AgendaScreen(),
    ClientesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _abaSelecionada,
        children: _telas,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _abaSelecionada,
        onDestinationSelected: (index) {
          setState(() => _abaSelecionada = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today),
            label: 'Agenda',
            tooltip: 'Ver agenda de hoje',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Clientes',
            tooltip: 'Ver lista de clientes',
          ),
        ],
      ),
    );
  }
}