# Etapa 5 Primeira versão funcional com backend

## Objetivo e atendimento ao enunciado

Integrar as funcionalidades das etapas anteriores com um backend e executar um fluxo completo de negócio. O escopo foi conferido no arquivo fornecido `ETAPA 05.docx` e nas regras da disciplina; o material de HTTP foi consultado no PDF da Aula 15.

| Requisito | Implementação |
|---|---|
| Frontend mobile integrado a backend | Flutter → HTTP/JSON → Express → SQLite |
| Funcionalidades anteriores integradas | Clientes, pets, agenda, busca, detalhes, edição e exclusão |
| Fluxo completo | Cadastrar cliente/pet → agendar → consultar → editar → excluir agendamento → excluir cliente |
| Interface e navegação | Splash, abas Agenda/Clientes e formulários com Navigator |
| Persistência | SQLite do servidor; cache de leitura no Android |
| Entradas inválidas | Validações no formulário e validações obrigatórias na API |
| Feedback | Carregamento, mensagens, confirmação de exclusão e estado offline |
| Documentação | README, arquitetura e este documento |
| Git | Mesmo repositório; publicação e tag aguardam revisão do responsável |

## Fluxo de negócio

1. Iniciar o backend e abrir o aplicativo Android.
2. Na aba Clientes, tocar no botão de adicionar cliente.
3. Informar o nome do tutor, telefone opcional, nome do pet, espécie, raça opcional e porte.
4. Salvar e conferir o cadastro na lista. A API salva cliente e pet em uma transação.
5. Consultar os detalhes do pet. Quando houver vários pets importados, escolher qual consultar.
6. Na Agenda, tocar em Novo Agendamento e selecionar o pet, serviço, data e horário.
7. Confirmar e conferir o resultado na lista.
8. Editar o cliente e o agendamento pelos menus de opções. As duas abas observam o mesmo estado; alterações de nomes aparecem também na Agenda.
9. Tentar excluir um cliente ainda agendado: a API retorna conflito e preserva os dados.
10. Excluir o agendamento, confirmando o diálogo.
11. Excluir o cliente, confirmando o diálogo. Seus pets são removidos em cascata.
12. Reiniciar a API e o aplicativo para conferir o resultado persistido.

O cadastro de cliente/pet e o agendamento não compõem uma transação única: são operações de negócio distintas. A falha ao agendar não desfaz um cliente já cadastrado.

## Divisão de responsabilidades

O Flutter apresenta os dados, conduz a navegação, valida os formulários e envia requisições assíncronas. O backend valida novamente todas as entradas, aplica as regras de negócio e grava no SQLite.

O servidor é a única fonte de gravações do fluxo atual. As telas não chamam os métodos de escrita do `DatabaseHelper` da Etapa 4. Não existe fallback de gravação no banco antigo quando a rede falha.

A API retorna o estado completo após cada gravação. O `AppRepository` atualiza os modelos compartilhados e tenta persistir o cache. Uma falha no cache depois da confirmação do servidor gera um aviso, sem apresentar uma gravação confirmada como fracassada.

## Persistência e preservação da Etapa 4

Há três arquivos com finalidades distintas:

| Arquivo | Local | Finalidade |
|---|---|---|
| `backend/data/banho_tosa.sqlite` | Servidor | Fonte dos clientes, pets e agendamentos atuais |
| `banho_tosa_api_cache.db` | Android | Último estado confirmado por endereço de API e identidade da instalação |
| `banho_tosa.db` | Android | Banco original da Etapa 4, preservado para importação |

O código `src/lib/data/database_helper.dart` foi mantido. O banco legado é aberto somente para leitura durante a transferência, sem exclusões nem mudança de esquema.

O cache é identificado pela URL da API e inclui a data da última atualização. Ele pode estar desatualizado em relação a outros dispositivos. Sem rede, a interface informa **Consulta offline**, apresenta a última cópia disponível e desabilita criação, edição, exclusão e importação. Sem uma cópia anterior, oferece Tentar novamente.

Ao recuperar a conexão, o usuário toca em Atualizar. Não há sincronização bidirecional nem fila de operações offline.

## Importação dos dados antigos

Com a API acessível, tocar em **Importar dados da Etapa 4**, na barra superior, e confirmar o diálogo.

1. O Android lê clientes, pets e agendamentos do SQLite antigo em uma transação de leitura.
2. A instalação possui um identificador aleatório persistido antes do envio.
3. O lote é enviado por `POST /api/importacoes`.
4. O servidor valida os dados e gera novos IDs, remapeando as associações entre tutor, pet e agendamento.
5. Todos os registros e o recibo são gravados na mesma transação.
6. A API responde com as contagens e o estado atualizado; o aplicativo atualiza a interface e o cache.

Repetir a solicitação da mesma instalação retorna o recibo anterior, sem duplicar registros, inclusive quando uma resposta anterior se perdeu. Registros importados e posteriormente excluídos no servidor não reaparecem ao repetir a importação.

Um conflito de horário ou entrada inválida cancela todo o lote e não registra o recibo. O banco original continua disponível. Não há junção automática por nome/telefone: importar duas instalações diferentes que contenham cópias dos mesmos dados pode gerar cadastros duplicados. O processo foi definido para a transferência inicial do banco da instalação existente.

Não limpe o armazenamento nem desinstale o aplicativo antes da transferência. Esses procedimentos removem os dados locais e a identidade da instalação. Reiniciar o app ou atualizar sua instalação preservando os dados não remove essa identidade. Guarde também uma cópia do arquivo SQLite do servidor; perder o banco do servidor perde seus dados e recibos.

Valores antigos que não atendam às validações atuais impedem a transferência do lote; a API informa o motivo e os registros permanecem no banco original. O ajuste desses dados deve ser feito de maneira controlada, com backup, antes de repetir o processo.

## Contrato HTTP

Todos os caminhos abaixo têm prefixo `/api`. Corpos de escrita usam `Content-Type: application/json`; respostas são JSON. Clientes contêm uma lista `pets`; agendamentos incluem `pet_nome` e `cliente_nome` para exibição.

| Método | Caminho | Resultado |
|---|---|---|
| GET | `/health` | Verifica API e SQLite, 200 |
| GET | `/estado` | Clientes/pets e agendamentos, 200 |
| GET | `/clientes` | Lista de clientes com pets, 200 |
| GET | `/clientes/:id` | Cliente, 200 ou 404 |
| POST | `/clientes` | Cria tutor e pet, 201 com Location |
| PUT | `/clientes/:id` | Atualiza tutor e o pet informado, 200 |
| DELETE | `/clientes/:id` | Exclui tutor sem agendamentos e seus pets, 200 |
| GET | `/agendamentos` | Lista com nomes relacionados, 200 |
| GET | `/agendamentos/:id` | Agendamento, 200 ou 404 |
| POST | `/agendamentos` | Cria agendamento, 201 com Location |
| PUT | `/agendamentos/:id` | Atualiza agendamento, 200 |
| DELETE | `/agendamentos/:id` | Exclui agendamento, 200 |
| POST | `/importacoes` | Importa lote, 201; repetição reconhecida, 200 |

As escritas retornam `{ "clientes": [...], "agendamentos": [...] }`. A importação acrescenta `importacao`, com contagens e `repetida`. DELETE retorna 200 porque há um corpo JSON atualizado.

Exemplo de criação de cliente:

```json
{
  "nome": "Maria",
  "telefone": "(62) 99999-1234",
  "pet": { "nome": "Rex", "especie": "Cachorro", "raca": "", "porte": "Médio" }
}
```

Na edição, enviar todos esses campos e acrescentar o `id` do pet no objeto `pet`. O pet deve pertencer ao cliente da URL. Sem `pet.id`, a API acrescenta um pet ao cliente, permitindo completar um cadastro legado sem pets.

Exemplo de agendamento:

```json
{ "pet_id": 1, "data_hora": "2030-05-20T09:00:00.000", "servico": "Banho" }
```

O horário representa o horário civil do petshop, sem fuso e com precisão de minuto. Formatos equivalentes de minuto são normalizados antes da comparação. A aplicação não calcula duração dos serviços nem permite atendimentos simultâneos. Datas passadas não são bloqueadas nesta etapa, preservando o comportamento anterior.

## Validações e respostas de erro

- Nomes obrigatórios, sem espaços isolados e com limite de 120 caracteres.
- Raça opcional com limite de 120 caracteres.
- Telefone opcional, até 25 caracteres; preenchido, admite formatação e exige 10 ou 11 dígitos.
- Espécies: Cachorro, Gato e Outro. Portes: Pequeno, Médio e Grande.
- Serviços: Banho, Tosa e Banho e Tosa.
- IDs positivos e inteiros seguros; recursos referenciados precisam existir.
- Datas reais de 2020 a 2100, sem segundos diferentes de zero ou indicação de fuso.
- Conflito de horário impedido na criação e na edição, desconsiderando o próprio registro.
- Exclusão de cliente com agendamentos bloqueada.
- Importações com IDs repetidos ou referências quebradas rejeitadas.

| Status | Situação |
|---|---|
| 400 | Entrada inválida ou JSON malformado |
| 404 | Registro ou endpoint não encontrado |
| 409 | Horário ocupado ou cliente com agendamento |
| 413 | Corpo maior que 2 MB |
| 415 | Content-Type incompatível |
| 500 | Falha interna, sem detalhes do banco na resposta |

A API usa parâmetros SQL para os valores. O cliente trata erro de rede, limite de espera de dez segundos, resposta inválida e mensagens de erro do servidor. Uma escrita com resposta perdida pode ter sido concluída: ela não é repetida automaticamente e a mensagem orienta atualizar a lista antes de tentar novamente.

## Feedback e navegação

- Splash seguida das abas Agenda e Clientes.
- Estado das abas preservado pelo IndexedStack.
- Indicador de progresso durante atualização, importação e salvamento.
- Botões desabilitados durante operações e no modo offline.
- Mensagens de sucesso e de erro por SnackBar.
- Diálogos antes da importação e das exclusões.
- Barra com conexão, última atualização e botão Atualizar.
- Botões com tooltips, campos rotulados e manutenção dos componentes de acessibilidade existentes.

## Como executar e testar

O [README](../README.md) contém os comandos completos de instalação e execução, sempre distinguindo as pastas `backend` e `src`.

No PowerShell, dentro de `backend`:

```powershell
npm.cmd ci
npm.cmd test
npm.cmd start
```

Em outro terminal, dentro de `src`:

```powershell
flutter pub get
flutter analyze
flutter test
flutter run -d emulator-5554
```

Ajustar o ID conforme `flutter devices`. No emulador, o padrão é `http://10.0.2.2:3000/api`. Para outros ambientes, usar `--dart-define=API_BASE_URL=...` e configurar `HOST`/`PORT` no backend. `DB_PATH` permite escolher um arquivo SQLite diferente. HTTP local está habilitado apenas no manifest Android de debug.

### Teste de integração Android

O teste cria dados e exige um backend vazio e exclusivo. Não usar o banco de desenvolvimento. Ele utiliza um diretório SQLite temporário no Android, preservando o banco real da instalação.

Em um terminal, dentro de `backend`:

```powershell
$env:PORT='3100'
$env:DB_PATH=Join-Path $env:TEMP ('banho-tosa-integracao-' + [guid]::NewGuid().ToString('N') + '.sqlite')
npm.cmd start
```

Em outro terminal, dentro de `src`, com o emulador iniciado:

```powershell
flutter test integration_test/fluxo_backend_test.dart -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:3100/api
```

Cada repetição deve começar com outro banco vazio no backend. Pare a API com Ctrl+C e execute novamente o bloco com `NewGuid`. Ao encerrar os testes, feche esse terminal para remover suas variáveis de ambiente da sessão.

A integração exercita a importação pela interface, o formulário de cliente, HTTP real para o CRUD e os conflitos, atualização dos nomes nas abas, reabertura do cache SQLite e consulta offline com rede simulada indisponível. A verificação de fechar/forçar parada do processo completo deve ser repetida no roteiro manual abaixo.

### Roteiro manual complementar

1. Usar os passos do fluxo de negócio deste documento.
2. Conferir mensagens e navegação em tela pequena, incluindo o teclado aberto.
3. Cancelar uma exclusão e conferir que o registro permanece.
4. Criar registros e forçar a parada do app pelo Android, sem limpar dados.
5. Reabrir e conferir os registros. Repetir com o backend parado, usando o cache.
6. Reiniciar o backend e atualizar o aplicativo.
7. Quando houver banco real da Etapa 4, importar, conferir os relacionamentos e repetir a importação para confirmar ausência de duplicações.

## Decisões, ferramentas e limites

O backend utiliza Express e SQLite nativo do Node para aproveitar o ambiente disponível e evitar uma biblioteca SQLite com compilação adicional. As transações preservam cliente/pet e o lote de importação; chaves estrangeiras e unicidade complementam as validações.

O cache separado conserva a Etapa 4 sem criar duas bases independentes graváveis. Não foram adicionados autenticação, publicação em nuvem, histórico de conclusão de atendimentos ou infraestrutura de sincronização offline. O alvo de execução é Android em ambiente de desenvolvimento.

O formulário trabalha com o primeiro pet do cliente. Outros pets já importados são mantidos e podem ser selecionados para agendamentos e detalhes.

Ferramentas: Flutter/Dart, Material 3, http, sqflite, path, Node.js, Express, node:sqlite, node:test, flutter_test e integration_test. Codex/ChatGPT foi utilizado no apoio à implementação, revisão, testes e documentação. A revisão e o domínio do código pelo aluno continuam necessários para a apresentação.

## Entrega

Repositório: https://github.com/Edsonnetocf/banho-tosa-app

A tag prevista é `etapa-05`. Não foi criada nem publicada automaticamente. A entrega no GitHub depende da revisão e autorização do responsável, preservando as tags das etapas anteriores.

## Resultados de validação em 29 de outubro de 2026

- Backend: 16 testes aprovados, nenhum reprovado; HTTP real com SQLite em memória e teste de reabertura de arquivo temporário.
- Flutter: 10 testes unitários/de interface aprovados, nenhum reprovado.
- Análise estática: `flutter analyze` sem problemas.
- Android Pixel 8: um teste de integração aprovado com API exclusiva na porta 3100 e bancos temporários, incluindo formulário, transferência dos dados antigos, CRUD, conflitos e cache offline.
- O banco de uso real do servidor e o SQLite legado real do dispositivo não foram usados como fixtures de teste.

O roteiro manual complementar continua disponível para a revisão do responsável antes da publicação.

## Arquivos desta implementação

Backend:

- `backend/package.json`
- `backend/src/app.js`
- `backend/src/database.js`
- `backend/src/server.js`
- `backend/src/importacao.js`
- `backend/test/api.test.js`

Flutter:

- `src/pubspec.yaml` e `src/pubspec.lock`
- `src/android/app/src/main/AndroidManifest.xml`
- `src/android/app/src/debug/AndroidManifest.xml`
- `src/lib/main.dart`
- `src/lib/data/api_client.dart`
- `src/lib/data/app_repository.dart`
- `src/lib/data/app_scope.dart`
- `src/lib/data/local_store.dart`
- `src/lib/screens/home_shell.dart`
- `src/lib/screens/clientes_screen.dart`
- `src/lib/screens/agenda_screen.dart`
- `src/lib/screens/cliente_form_screen.dart`
- `src/lib/screens/novo_agendamento_screen.dart`
- `src/test/widget_test.dart`
- `src/test/repository_test.dart`
- `src/test/support/fakes.dart`
- `src/integration_test/fluxo_backend_test.dart`

Documentação:

- `README.md`
- `docs/arquitetura.md`
- `docs/etapa-05.md`
