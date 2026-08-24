# Proposta — Banho & Tosa App

## 1. Nome da aplicação
Banho & Tosa App

## 2. Problema que a aplicação pretende resolver
Petshops de pequeno e médio porte costumam organizar seus agendamentos de banho e tosa de forma manual (papel, planilhas ou WhatsApp), o que gera conflitos de horário, perda de histórico de atendimento dos animais e dificuldade em manter contato com os clientes. O aplicativo centraliza o cadastro de clientes e pets e organiza a agenda diária de forma simples e visual, evitando choques de horário e mantendo um histórico acessível de cada animal atendido.

## 3. Público-alvo
Donos e atendentes de petshops de pequeno e médio porte que realizam serviços de banho e tosa e ainda não utilizam um sistema informatizado de agendamento.

## 4. Objetivo principal
Oferecer uma ferramenta mobile simples para cadastro de clientes/pets e gerenciamento da agenda de banho e tosa, reduzindo conflitos de horário e centralizando o histórico de atendimentos.

## 5. Descrição das principais funcionalidades
- Cadastro de clientes (tutores)
- Cadastro de pets vinculados a cada cliente (nome, espécie, raça, porte, observações)
- Agendamento de serviços de banho e/ou tosa, com data e horário
- Visualização da agenda diária/semanal
- Histórico de atendimentos por pet
- Notificações locais para lembrar de agendamentos próximos (etapa futura)

## 6. Telas previstas
1. **Login/Splash** — tela inicial de abertura do app
2. **Lista de Clientes** — exibe todos os clientes cadastrados, com busca
3. **Cadastro/Edição de Cliente e Pet** — formulário para adicionar ou editar um cliente e seus pets
4. **Agenda** — visão diária/semanal dos agendamentos marcados
5. **Novo Agendamento** — formulário para marcar um novo horário de banho/tosa, vinculando cliente e pet
6. **Detalhes do Pet** — histórico de atendimentos daquele animal específico

## 7. Fluxo básico de navegação
```
Splash
  └── Agenda (tela principal)
        ├── Novo Agendamento
        │      └── (seleciona Cliente/Pet já cadastrado ou cria novo)
        ├── Lista de Clientes
        │      ├── Cadastro/Edição de Cliente e Pet
        │      └── Detalhes do Pet
        └── (toque em um agendamento existente) → Detalhes do Pet
```
A tela **Agenda** funciona como tela central (hub), a partir da qual o usuário acessa o cadastro de clientes/pets ou cria novos agendamentos.

## 8. Tecnologia escolhida para o desenvolvimento mobile
**Flutter** (Dart). Escolhido por permitir uma única base de código para múltiplas plataformas (Android e, futuramente, iOS), possuir hot reload (o que agiliza o ciclo de desenvolvimento incremental exigido pela disciplina), e contar com um ecossistema maduro de pacotes para persistência local, notificações e consumo de APIs.

## 9. Tecnologia escolhida para o backend
Nesta primeira etapa, **não haverá backend próprio**. Os dados serão armazenados localmente no dispositivo (ver item 11). A adoção de um backend (próprio ou serviço externo, como Firebase) será avaliada em etapas futuras, caso o escopo evolua para sincronização entre dispositivos ou múltiplos usuários.

## 10. Necessidade de comunicação com APIs externas
Não há necessidade de comunicação com APIs externas nesta etapa inicial. Essa necessidade poderá surgir futuramente caso sejam adicionadas funcionalidades como notificações push remotas ou sincronização em nuvem.

## 11. Forma prevista de armazenamento de dados
Armazenamento local no dispositivo, utilizando um banco de dados embutido (ex: SQLite, via pacote `sqflite`, ou alternativa equivalente do ecossistema Flutter), garantindo que o app funcione mesmo sem conexão com a internet.

## 12. Repositório Git
Repositório público disponível em: https://github.com/Edsonnetocf/banho-tosa-app

## 13. Estrutura inicial de diretórios do projeto
```
banho-tosa-app/
├── README.md
├── docs/
│   ├── proposta.md
│   ├── arquitetura.md
│   └── evidencias.md
├── src/          (código-fonte do projeto Flutter)
│   ├── lib/
│   ├── android/
│   ├── ios/
│   ├── tests/
│   └── pubspec.yaml
└── tests/        (referenciado em src/tests, conforme estrutura Flutter)
```
