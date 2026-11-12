# Etapa 6 — Integração com serviço externo

Utilização do **Wikidata Query Service** para sugerir raças de cachorro em português no próprio campo **Raça**. A integração usa HTTP, autocomplete e cache local, mantendo o preenchimento livre.

## Serviço e configuração

A operação externa é uma consulta de dados com o pacote `http`, já utilizado pelo projeto. Não exige cadastro, token ou chave.

| Item | Valor |
|---|---|
| Base URL | `https://query.wikidata.org` |
| Endpoint e método | `GET /sparql` |
| Parâmetros da URL | `query`: consulta SPARQL fixa; `format`: `json` |
| Cabeçalhos | `Accept: application/sparql-results+json` e `User-Agent: BanhoTosaApp/1.0 (https://github.com/Edsonnetocf/banho-tosa-app)` |
| Corpo da requisição | Ausente |
| Tempo limite | 15 segundos |

A configuração está em [racas_api.dart](../src/lib/data/racas_api.dart). O serviço é independente de `API_BASE_URL`, que configura apenas o backend do petshop. Referências oficiais: [consultas HTTP/JSON](https://www.wikidata.org/wiki/Wikidata:SPARQL_query_service#Interfacing) e [acesso aos dados, disponíveis sob CC0](https://www.wikidata.org/wiki/Wikidata:Data_access).

## Requisição e resposta

O aplicativo envia a consulta abaixo no parâmetro `query`, codificado na URL por `Uri.replace(queryParameters: ...)`, junto de `format=json`. O texto digitado e os dados de clientes/pets não são enviados ao Wikidata.

```sparql
PREFIX wd: <http://www.wikidata.org/entity/>
PREFIX wdt: <http://www.wikidata.org/prop/direct/>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
SELECT DISTINCT ?nome WHERE {
  ?raca wdt:P31 wd:Q39367;
        rdfs:label ?nome.
  FILTER(LANG(?nome) = "pt")
}
ORDER BY ?nome
```

A consulta seleciona nomes de entidades classificadas como raça de cachorro (`Q39367`), com idioma `pt`. A resposta é um objeto JSON; exemplo reduzido:

```json
{
  "head": { "vars": ["nome"] },
  "results": {
    "bindings": [
      { "nome": {
        "type": "literal",
        "xml:lang": "pt",
        "value": "Pastor-alemão"
      } }
    ]
  }
}
```

O cliente lê `results.bindings[].nome.value`, valida a estrutura e o idioma, decodifica UTF-8, remove duplicatas e espaços nas extremidades, descarta nomes vazios ou maiores que 120 caracteres e ordena a lista. Quantidade e nomes podem mudar conforme a base.

## Fluxo de comunicação e cache

O [RacasRepository](../src/lib/data/racas_repository.dart) coordena a consulta e o armazenamento; a digitação apenas filtra os dados no aparelho.

1. Ao abrir o campo para um cachorro, reutilizar o catálogo em memória ou ler o SQLite.
2. Se o cache tiver menos de sete dias, usar os nomes sem consultar a rede.
3. Sem cache válido, fazer o GET ao Wikidata. Um catálogo vencido continua disponível durante a tentativa de atualização.
4. Se a consulta retornar nomes válidos, atualizar memória e cache. Erro ou resposta vazia preservam o catálogo anterior.
5. Ao selecionar uma sugestão, preencher o campo. Ao salvar, enviar o texto em `pet.raca` no `POST /api/clientes` ou `PUT /api/clientes/:id` existente.

O arquivo `banho_tosa_racas_cache.db` contém a tabela `catalogo`, com `id=1`, `nomes` em JSON e `atualizado_em` em ISO 8601 UTC. Ele é separado dos bancos do backend, do cache de clientes e do banco legado. Não há migração do esquema de clientes/pets.

Falha ao ler o cache permite tentar a rede; falha ao gravá-lo mantém os nomes em memória, sem garantir sua persistência. Consultas simultâneas compartilham a requisição em andamento. Não há requisição por letra digitada nem repetição automática após erro.

## Interface e tratamento dos estados

O [campo de autocomplete](../src/lib/widgets/campo_raca.dart) mantém a tela limpa. Os estados técnicos aparecem nos logs de desenvolvimento, sem faixas, ícones ou mensagens automáticas junto ao campo.

- Sugerir a partir de duas letras, ignorando acentos, maiúsculas e hífens: `alemao` encontra `Pastor-alemão`, entre outras correspondências.
- Mostrar aproximadamente cinco itens com rolagem, conforme o espaço da tela e do teclado. Tocar numa sugestão preenche o campo; tocar fora fecha a lista sem apagar o texto.
- Permitir texto livre, raça vazia e “Sem raça definida”. Para Gato e Outro, o preenchimento é manual.
- Preservar a raça ao trocar a espécie ou editar um cadastro. Respostas atrasadas não sobrescrevem o texto atual.

| Estado/situação | Tratamento e evidência |
|---|---|
| Carregamento | Operação assíncrona, campo editável e cache disponível; log `INFO` em `WIKIDATA` |
| Sucesso | Nomes disponíveis e tentativa de salvar o cache; log `OK` e sugestões ao digitar |
| Resposta sem dados | Manter catálogo anterior ou campo manual; log `AVISO` |
| Falha HTTP, rede, timeout ou JSON inválido | Preservar cache e preenchimento livre; log `ERRO` |
| Falha no cache | Continuar com rede ou memória, conforme a operação; log `AVISO` |
| Nenhuma correspondência na busca local | Fechar a lista e manter o texto, sem nova requisição |

Uma falha no Wikidata não altera a conexão com o backend. Salvar cadastros continua exigindo o servidor do petshop. Logs usam `debugPrint` com `kDebugMode`, horário, nível e categoria, sem registrar dados pessoais ou o texto buscado. Para acompanhar o app aberto:

```powershell
flutter logs -d emulator-5554 | Select-String -SimpleMatch '[BanhoTosa]'
```

Outras opções estão em [depuração](depuracao.md). Atualizar dados e importar registros antigos continuam no menu **⋮** da Agenda e de Clientes.

## Executar

São necessários Node.js 24.14 ou superior, Flutter compatível com Dart 3.13.1 ou superior e um emulador/aparelho Android. Uma consulta nova ao Wikidata exige internet, sem configuração de credenciais.

Em um terminal, a partir da raiz do repositório:

```powershell
Set-Location backend
npm.cmd ci
npm.cmd start
```

Em outro terminal, também a partir da raiz:

```powershell
Set-Location src
flutter pub get
flutter run -d emulator-5554
```

Manter o backend aberto. Sua saúde pode ser conferida em `http://127.0.0.1:3000/api/health`. Ajustar o dispositivo conforme `flutter devices`. O emulador usa `http://10.0.2.2:3000/api`; outro endereço pode ser informado com `--dart-define=API_BASE_URL=...`. A configuração para celular físico está no [README](../README.md#aparelho-físico).

## Testar e demonstrar

Conferir primeiro a consulta isolada e os testes abaixo; depois seguir o roteiro manual. Os testes simulados cobrem carregamento, sucesso, erro, ausência de dados e respostas atrasadas sem depender da disponibilidade do Wikidata.

Dentro de `src`:

```powershell
dart run tool/verificar_wikidata.dart
flutter analyze
flutter test
```

O primeiro comando faz uma consulta real e mostra exemplos em português, sem exigir backend/emulador ou alterar cadastros. Dentro de `backend`, executar `npm.cmd test` para conferir a API.

Para validar o autocomplete com Wikidata real, cache reaberto após falha de rede e captura de tela, usar um emulador de testes e executar em `src`:

```powershell
flutter drive --driver=test_driver/autocomplete_driver.dart --target=integration_test/autocomplete_racas_test.dart -d emulator-5554
```

Esse cenário usa backend simulado e banco temporário; depende de internet e pode falhar se o Wikidata não responder. A captura fica em `src/build/integration_screenshots/autocomplete-racas.png`. Depois, executar `flutter run -d emulator-5554` para voltar ao app normal. O teste de persistência isolado está em `src/integration_test/cache_racas_test.dart`; o fluxo completo de clientes/agendamentos exige a [API com banco exclusivo descrita na Etapa 5](etapa-05.md#teste-de-integração-android).

Roteiro para apresentação:

1. Abrir **Clientes → Novo cliente**. No campo Raça, digitar `p` e depois `pastor`: conferir sugestões e rolagem com o teclado aberto.
2. Buscar `alemao`, rolar até `Pastor-alemão` e selecionar. Tocar fora, editar livremente e salvar com os demais dados válidos.
3. Reabrir a edição e conferir a raça salva. Reabrir o formulário/app sem limpar dados e observar o uso do cache nos logs.
4. Trocar para Gato/Outro e conferir que o texto é mantido e o campo fica manual. Conferir também um cadastro com raça fora do catálogo.

Resultados já verificados: **41 testes Flutter e 16 testes da API aprovados**, análise sem apontamentos, compilação Android e cenários Android de persistência, autocomplete com serviço real e fluxo completo aprovados. A consulta observada retornou 468 nomes distintos; esse número não é um requisito fixo.

## Limites

O catálogo é colaborativo e pode conter raças raras, históricas e variações de grafia, sem garantia de padronização brasileira. Nomes próprios podem conservar sua forma estrangeira. As sugestões atendem cachorros; outras espécies permanecem manuais. O alvo validado é Android, e o serviço público pode apresentar lentidão ou indisponibilidade.


