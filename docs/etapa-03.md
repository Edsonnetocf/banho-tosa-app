# Etapa 3: Navegação, UX e Acessibilidade

## Estrutura de navegação implementada
O app usa dois níveis de navegação:
1. Navegação principal por abas fixas (NavigationBar), alternando entre Agenda e Clientes, mantida pelo widget HomeShell.
2. Navegação interna por pilha (Navigator.push/pop) para fluxos secundários: Novo Agendamento, Cadastro de Cliente/Pet e Detalhes do Pet. O botão de voltar é gerado automaticamente pelo AppBar.

## Telas e mecanismos de acesso
- Agenda: aba principal, acessível a qualquer momento pela barra inferior
- Clientes: aba principal, acessível a qualquer momento pela barra inferior
- Novo Agendamento: acessado pelo botão flutuante na Agenda
- Cadastro de Cliente/Pet: acessado pelo botão flutuante em Clientes
- Detalhes do Pet: acessado ao tocar em um cliente na lista

## Menus e mecanismos de navegação utilizados
NavigationBar (Material 3) com dois destinos (Agenda, Clientes), cada um com ícone e rótulo textual visível.

## Feedback visual implementado
- Indicador de carregamento (CircularProgressIndicator) nos botões de salvar, enquanto a ação é processada
- Botões desabilitados durante o carregamento, evitando duplo envio
- SnackBar de confirmação ao concluir uma ação (salvar cliente, salvar agendamento)
- Ícone e rótulo destacados na aba atualmente selecionada

## Principais decisões de UX
- Ações mais frequentes (novo agendamento, novo cliente) ficam em botões flutuantes na parte inferior da tela, dentro da thumb zone, zona de alcance natural do polegar em uso com uma mão
- Uso de IndexedStack para preservar o estado de cada aba ao trocar entre elas, evitando perda de contexto do usuário
- Cada FloatingActionButton recebeu um heroTag único, já que o IndexedStack mantém as duas telas (Agenda e Clientes) montadas simultaneamente na árvore de widgets
- Áreas de toque mantidas em, no mínimo, 48dp, com espaçamento adequado entre elementos vizinhos, seguindo a Lei de Fitts
- Feedback visual imediato ao pressionar botões, evitando a sensação de lentidão e cliques duplicados

## Medidas de acessibilidade implementadas
- Uso de Semantics com label, button e hint em botões que possuem apenas ícone, como adicionar cliente e novo agendamento
- Uso de MergeSemantics para unificar cards com múltiplos textos, como cliente, agendamento e detalhes do pet, em um único bloco de leitura, evitando fragmentação da navegação por leitor de tela
- Uso de ExcludeSemantics em ícones puramente decorativos, como o ícone de pata nos cards de agendamento, reduzindo ruído na árvore de acessibilidade
- Contraste de cor adequado entre texto e fundo, seguindo o mínimo de 4.5:1 recomendado pela WCAG 2.1 nível AA, por exemplo texto branco sobre a cor 0xFF0B6374
- Componentes nativos do Material, como NavigationBar, ListTile e ElevatedButton, já compatíveis nativamente com TalkBack e VoiceOver

## Instruções para execução e teste da navegação
1. cd src
2. flutter pub get
3. flutter run
4. Alterne entre as abas Agenda e Clientes na barra inferior
5. Toque em um cliente para ver seus detalhes, e use o botão de voltar do AppBar para retornar
6. Opcionalmente, ative o TalkBack ou VoiceOver no dispositivo para testar a leitura de tela