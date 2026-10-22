# Banho & Tosa App

## Descrição da aplicação

Aplicativo mobile voltado para petshops de pequeno e médio porte, com foco na gestão de agendamentos de banho e tosa e no cadastro de clientes e seus respectivos animais de estimação.

## Problema que a aplicação resolve

Muitos petshops de pequeno porte ainda organizam seus agendamentos manualmente (papel, planilhas ou WhatsApp), o que pode gerar conflitos de horário, perda de informações e dificuldades na organização dos atendimentos.

O Banho & Tosa App centraliza o cadastro de clientes e pets e organiza os agendamentos, permitindo consultar, atualizar e remover informações armazenadas localmente.

## Tecnologias utilizadas

- **Flutter (Dart):** desenvolvimento da aplicação mobile.
- **Material Design 3:** componentes e organização da interface.
- **SQLite:** banco de dados relacional para persistência local.
- **sqflite:** pacote utilizado para acessar o SQLite no Flutter.
- **path:** pacote utilizado para construir o caminho do arquivo do banco de dados.

**Justificativa técnica:** o Flutter foi escolhido por permitir o desenvolvimento de uma interface única para múltiplas plataformas (Android e, futuramente, iOS) a partir de uma única base de código, reduzindo o tempo de desenvolvimento.

Além disso, o framework oferece suporte a Hot Reload, um ecossistema de pacotes e documentação oficial extensa, facilitando o desenvolvimento incremental durante a disciplina.

O SQLite foi escolhido por permitir o armazenamento estruturado de clientes, pets e agendamentos, mantendo os relacionamentos entre esses registros por meio de identificadores e chaves estrangeiras.

## Instruções para execução

1. Certifique-se de ter o Flutter SDK instalado e configurado (`flutter doctor`).
2. Clone este repositório.
3. Navegue até a pasta do código-fonte: `cd src`.
4. Instale as dependências: `flutter pub get`.
5. Inicie um emulador Android ou conecte um dispositivo compatível.
6. Execute o aplicativo: `flutter run`.

Para verificar o código e executar os testes automatizados, utilize os seguintes comandos dentro da pasta `src`:

- `flutter analyze`
- `flutter test`

## Funcionalidades implementadas

- Tela inicial de Splash.
- Tela de Agenda com listagem de agendamentos.
- Cadastro, edição e exclusão de agendamentos.
- Seleção de cliente, pet, serviço, data e horário.
- Verificação de conflitos entre agendamentos no mesmo horário.
- Lista de clientes com busca e layout adaptável (lista/grid).
- Cadastro e edição de clientes e pets.
- Exclusão de clientes sem agendamentos associados.
- Tela de detalhes do pet.
- Persistência local de clientes, pets e agendamentos com SQLite.
- Recuperação dos dados após o encerramento e a reabertura da aplicação.

## Navegação e Acessibilidade (Etapa 3)

- Navegação principal por abas fixas (Agenda e Clientes) utilizando `NavigationBar`.
- Navegação interna por pilha (`Navigator.push/pop`) com botão de voltar automático.
- Uso de `IndexedStack` para preservar o estado das abas.
- Feedback visual de carregamento ao salvar clientes e agendamentos.
- Mensagens de confirmação e erro utilizando `SnackBar`.
- Diálogos de confirmação antes da exclusão de registros.
- Uso de `Semantics`, `MergeSemantics` e `ExcludeSemantics` para acessibilidade.
- Áreas de toque de no mínimo 48dp, seguindo a Lei de Fitts.
- Contraste de texto adequado no tema principal da aplicação.

## Persistência Local (Etapa 4)

A aplicação utiliza um banco de dados SQLite denominado `banho_tosa.db`, armazenado localmente no dispositivo.

O banco possui três tabelas:

- **clientes:** armazena nome e telefone.
- **pets:** armazena as informações dos animais e sua associação com os clientes.
- **agendamentos:** armazena serviço, data, horário e associação com os pets.

As operações de criação, consulta, atualização e exclusão são realizadas por meio da classe `DatabaseHelper`, localizada em `src/lib/data/database_helper.dart`.

Os formulários realizam operações reais de armazenamento, substituindo o salvamento simulado das etapas anteriores.

Os dados permanecem armazenados após o encerramento e a reabertura do aplicativo, enquanto o armazenamento local da aplicação for preservado.

### Teste de persistência

1. Executar o aplicativo no emulador Android.
2. Cadastrar um cliente e seu pet.
3. Criar um agendamento.
4. Encerrar completamente o aplicativo.
5. Reabri-lo sem limpar seus dados.
6. Verificar se os registros continuam disponíveis.
7. Editar ou excluir registros e repetir a verificação.

## Documentação

- [Proposta inicial](docs/proposta.md)
- [Etapa 2: Protótipo de interface](docs/etapa-02.md)
- [Etapa 3: Navegação, UX e acessibilidade](docs/etapa-03.md)
- [Etapa 4: Persistência local de dados](docs/etapa-04.md)

## Limitações conhecidas

- Os dados são armazenados localmente, sem sincronização entre dispositivos.
- Não existe comunicação com backend ou APIs externas.
- O formulário de cadastro trabalha com um pet por vez.
- A tela de detalhes apresenta o primeiro pet associado ao cliente.
- O histórico de atendimentos concluídos ainda não foi implementado.
- A persistência SQLite desta etapa foi preparada para utilização no Android.
- O banco de dados não possui uma camada adicional de criptografia implementada pelo aplicativo.
