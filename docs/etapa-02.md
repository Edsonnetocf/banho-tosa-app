# Etapa 2 — Implementação do Protótipo de Interface

## Telas implementadas
1. Splash Screen: tela inicial de abertura
2. Agenda: lista os agendamentos do dia (tela hub)
3. Clientes: lista de clientes com busca e layout adaptável
4. Cadastro de Cliente/Pet: formulário de entrada de dados
5. Novo Agendamento: formulário para marcar horário
6. Detalhes do Pet: informações e histórico do animal

## Principais componentes utilizados
- Scaffold, AppBar, ListView/ListView.builder, GridView.builder
- Card, ListTile, Container, Row, Column, Expanded
- TextField, TextFormField, DropdownButtonFormField, showTimePicker
- ElevatedButton, FloatingActionButton, IconButton

## Componentes reutilizáveis
- `ClienteCard` (usado na lista de clientes)
- `AgendamentoTile` (usado na lista de agendamentos)

## Elementos de entrada de dados
- Campo de busca de clientes
- Formulário de cadastro de cliente/pet (nome, telefone, espécie, raça, porte)
- Formulário de novo agendamento (cliente, serviço, horário)

## Estratégia de adaptação de layout
Uso de `LayoutBuilder` na tela de Clientes: em telas largas (> 600px, ex. tablets)
os cards são exibidos em grade (GridView); em telas estreitas (celulares),
em lista vertical (ListView). Também é usado `Expanded`/`SizedBox` para evitar
overflow em diferentes tamanhos de tela.

## Instruções para execução
1. `cd src`
2. `flutter pub get`
3. `flutter run`

## Principais decisões de interface
- Dados fictícios (mock) usados no lugar de persistência real, conforme permitido pelo enunciado da etapa.
- Tela de Agenda escolhida como "hub" central, mantendo a decisão de navegação definida na Etapa 1.
- Uso de Material 3 (`useMaterial3: true`) para componentes visuais modernos e consistentes.