# Banho & Tosa App

Aplicativo da disciplina Tecnologia de Construção de Software II (CMP2305), desenvolvido com Flutter e Dart para organizar clientes, pets e agendamentos de um petshop. A aplicação reduz a organização manual dos atendimentos e impede reservas no mesmo horário.

## Tecnologias e arquitetura

- Flutter, Dart e Material 3: interface, navegação e validação dos formulários.
- Pacote `http`: comunicação assíncrona HTTP/JSON.
- Node.js e Express: API e regras de negócio.
- SQLite nativo do Node (`node:sqlite`): dados persistentes do servidor.
- SQLite com `sqflite`: cache de consulta no Android e preservação dos dados da Etapa 4.

O servidor é a fonte dos dados graváveis. O aplicativo recebe um estado completo de clientes, pets e agendamentos, atualiza as duas abas e guarda uma cópia local. Sem conexão, essa cópia permite somente consulta. Não existe fila de gravações offline.

O banco antigo `banho_tosa.db` permanece preservado. A importação para o servidor é iniciada pelo usuário e ocorre em uma transação, com remapeamento de IDs e controle de repetição. Veja [a documentação da Etapa 5](docs/etapa-05.md).

## Estrutura

```text
backend/           API Express e testes Node
src/               Projeto Flutter
src/test/          Testes unitários e de interface
src/integration_test/  Teste integrado Android
docs/             Documentação das etapas
```

## Pré-requisitos

- Node.js 24.14 ou superior, com npm.
- Flutter compatível com Dart 3.13.1 ou superior.
- Android SDK e emulador Android, ou aparelho Android conectado.
- Ambiente validado durante o desenvolvimento: Windows, Node 24.14.0, Flutter 3.47.7 e Dart 3.13.5.

Execute `flutter doctor` para conferir o ambiente. O aviso `ExperimentalWarning` de SQLite no Node 24.14, isoladamente, não impede a execução.

## Executar o backend

No PowerShell, entre na pasta `backend` do repositório. No ambiente original:

```powershell
Set-Location -LiteralPath 'C:\Users\edson\OneDrive\Documentos\DEV\Liguagens_testes\flutter-projects\petshop_app\backend'
npm.cmd ci
npm.cmd start
```

Em outra máquina, ajuste o caminho para a sua cópia do repositório. `npm.cmd start` deve ser executado dentro de `backend`, onde está o `package.json`.

Abra `http://127.0.0.1:3000/api/health`. A resposta deve conter `"status":"ok"`. O banco é criado em `backend/data/banho_tosa.sqlite`; reiniciar a API não apaga seus registros. Preserve esse arquivo para preservar os dados do servidor.

Deixe esse terminal aberto. Para encerrar o servidor, use Ctrl+C. Para reiniciar automaticamente ao editar o backend, use `npm.cmd run dev`.

## Executar o aplicativo Android

Em um segundo terminal, entre em `src`:

```powershell
Set-Location -LiteralPath 'C:\Users\edson\OneDrive\Documentos\DEV\Liguagens_testes\flutter-projects\petshop_app\src'
flutter pub get
flutter devices
flutter run -d emulator-5554
```

Substitua `emulator-5554` pelo identificador apresentado em `flutter devices`, se necessário. Inicie o emulador no Android Studio antes de executar o aplicativo.

No emulador Android padrão, o aplicativo utiliza `http://10.0.2.2:3000/api`, que aponta para a API executada no computador.

O endereço pode ser configurado sem editar o código:

```powershell
flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:3000/api
```

### Aparelho físico

Conecte computador e celular à mesma rede. No terminal do backend, antes de iniciar:

```powershell
$env:HOST='0.0.0.0'
npm.cmd start
```

No terminal de `src`, use o IP local do computador, por exemplo:

```powershell
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:3000/api
```

Troque o IP pelo endereço real do computador e selecione o dispositivo indicado pelo Flutter. Se a conexão for bloqueada, confira as regras do Firewall do Windows para a rede privada. O HTTP sem criptografia está habilitado somente no build de desenvolvimento Android; uma versão de produção precisa de backend HTTPS.

## Fluxo para revisar a aplicação

1. Inicie a API e o aplicativo.
2. Na aba Clientes, cadastre um tutor e seu pet. O telefone é opcional; quando informado, deve ter DDD e 10 ou 11 dígitos.
3. Confira o cadastro e os detalhes do pet.
4. Na Agenda, crie um agendamento para esse pet.
5. Tente reservar o mesmo horário: a API deve rejeitar a operação.
6. Edite o cliente e o agendamento. Confira os nomes atualizados nas duas abas.
7. Tente excluir o cliente com agendamento: a API deve bloquear a exclusão.
8. Exclua o agendamento e depois o cliente, confirmando os diálogos.
9. Reinicie a API e o app para conferir a persistência das alterações.
10. Com registros já carregados, pare a API e toque em Atualizar. O app deve identificar o modo offline e permitir apenas consulta.
11. Reinicie a API e toque em Atualizar para voltar a gravar.

Para importar registros antigos, use o botão **Importar dados da Etapa 4** na barra superior. Consulte as condições e os limites na documentação da etapa.

## Testes

Dentro de `backend`:

```powershell
npm.cmd test
```

Dentro de `src`:

```powershell
flutter analyze
flutter test
```

O teste de integração Android deve usar uma API com banco exclusivo e vazio, conforme [o procedimento documentado](docs/etapa-05.md#teste-de-integração-android). Ele não deve ser apontado para um servidor com dados de uso real.

## Funcionalidades

- Splash, navegação por abas e formulários por pilha.
- Busca de clientes e lista/grid adaptável.
- Cadastro e edição de cliente e pet em uma transação.
- Consulta dos detalhes dos pets.
- CRUD de agendamentos, validações e prevenção de conflito de horário.
- Exclusão de clientes sem agendamentos, com remoção dos pets em cascata.
- Feedback de carregamento, sucesso, erro e confirmação de exclusão.
- Cache SQLite para consulta offline, com indicação da última atualização.
- Importação segura do SQLite da Etapa 4 para o backend.

## Limitações conhecidas

- O alvo validado é Android. Não foi adicionada persistência específica para Web, Windows ou iOS.
- As gravações exigem conexão com a API. O cache pode estar desatualizado e é separado por endereço do backend.
- Sem autenticação e sem separação por usuário; a API é uma primeira versão acadêmica para ambiente de desenvolvimento.
- O formulário edita um pet por vez e utiliza o primeiro pet do cadastro. Pets adicionais importados são preservados e podem ser escolhidos na Agenda e na consulta de detalhes.
- Um horário representa um único atendimento, sem cálculo de duração ou capacidade por funcionário.
- Histórico de atendimentos concluídos ainda não implementado.
- Desinstalar o app ou limpar seu armazenamento remove o cache e a identidade de importação. Não repita a importação após esse procedimento sem verificar os dados no servidor.
- O arquivo SQLite não possui criptografia adicional implementada pela aplicação.

## Documentação e repositório

- [Proposta](docs/proposta.md)
- [Arquitetura](docs/arquitetura.md)
- [Etapa 2](docs/etapa-02.md)
- [Etapa 3](docs/etapa-03.md)
- [Etapa 4](docs/etapa-04.md)
- [Etapa 5](docs/etapa-05.md)

Repositório: https://github.com/Edsonnetocf/banho-tosa-app

A publicação e a criação da tag `etapa-05` dependem da revisão e confirmação do responsável pelo projeto.
