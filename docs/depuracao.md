# Logs de desenvolvimento

Logging é o registro de eventos para acompanhar o aplicativo. O projeto usa o `debugPrint` nativo do Flutter, protegido por `kDebugMode`: estes logs são emitidos somente em builds de desenvolvimento. Não é necessário instalar uma biblioteca adicional.

## Terminal

Mantenha o backend em execução em seu próprio terminal. Em um segundo terminal:

```powershell
Set-Location -LiteralPath 'C:\Users\edson\OneDrive\Documentos\DEV\Liguagens_testes\flutter-projects\petshop_app\src'
flutter run -d emulator-5554
```

O terminal do Flutter mostra os logs do aplicativo; o terminal do Node mostra os eventos do backend. Se o aplicativo de desenvolvimento já estiver aberto no emulador, também é possível acompanhar suas mensagens com `flutter logs -d emulator-5554`.

Para ver apenas os registros do projeto e ocultar mensagens internas do Android, use em outro terminal:

```powershell
flutter logs -d emulator-5554 | Select-String -SimpleMatch '[BanhoTosa]'
```

Exemplo ilustrativo (as quantidades dependem dos dados reais):

```text
[BanhoTosa] [23:08:15.103] [INFO] [API] Atualizando clientes e agendamentos.
[BanhoTosa] [23:08:15.180] [OK] [CACHE] Cópia dos dados do servidor atualizada no aparelho.
[BanhoTosa] [23:08:15.181] [OK] [API] Servidor conectado | clientes=2 | agendamentos=1.
[BanhoTosa] [23:10:01.300] [INFO] [WIKIDATA] Consultando nomes de raças em português.
[BanhoTosa] [23:10:02.400] [OK] [WIKIDATA] 468 nomes em português recebidos.
```

Níveis:

- `INFO`: operação iniciada ou origem dos dados usados.
- `OK`: operação concluída.
- `AVISO`: situação recuperável, catálogo vazio ou cache que não pôde ser lido/salvo.
- `ERRO`: consulta ou comunicação que falhou. A linha indica se há dados locais disponíveis.

Categorias: `API`, `CACHE`, `RACAS`, `WIKIDATA` e `IMPORTACAO`. Busque por `[BanhoTosa]` para localizar apenas os registros do projeto.

## VS Code e DevTools

Ao executar o projeto Flutter pelo depurador do VS Code (F5, com as extensões Dart/Flutter e o projeto `src` aberto), acompanhe o painel **Console de Depuração / Debug Console**.

O Flutter DevTools também possui a aba **Logging**, que permite inspecionar os eventos e as mensagens do console. Veja a [documentação oficial da aba Logging](https://docs.flutter.dev/tools/devtools/logging).

## Interface e privacidade

- O status técnico da conexão e o horário da última atualização ficam nos logs, sem faixa permanente na interface.
- Atualizar e importar dados continuam acessíveis em **⋮ → Atualizar dados / Importar dados antigos**, tanto na Agenda quanto em Clientes.
- Quando não há nenhum dado disponível, a aplicação mantém a opção **Tentar novamente**.
- As validações dos formulários e o retorno de ações explícitas, como salvar ou excluir, continuam na interface.
- Sem servidor, os dados do cache continuam disponíveis somente para consulta; os logs não alteram essa regra.
- Os registros incluem contagens e estados, sem nomes, telefones, corpos HTTP, credenciais ou a consulta digitada pelo usuário.
- O projeto não salva estes logs em arquivo nem os envia a um serviço externo. Os logs da aplicação adicionados aqui ficam desativados em builds de produção.
- Ao abrir o cadastro de um cachorro, o catálogo de raças é carregado ou reutilizado. Os estados da consulta aparecem nos logs; digitar no campo apenas filtra os dados locais. O campo não exibe mensagens, ícones de status ou indicadores de carregamento. A consulta isolada continua disponível com `dart run tool/verificar_wikidata.dart`.
