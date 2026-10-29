# Arquitetura da aplicação

## Etapa 5

```text
Telas Flutter com Material 3 e Navigator
              |
       AppRepository (estado compartilhado)
         |                 |
   ApiClient HTTP     LocalStore SQLite
         |             cache de consulta
    API Express
         |
 SQLite do servidor
```

A API valida as entradas, preserva os relacionamentos e executa as gravações. Os endpoints de escrita retornam o estado atualizado; as abas Agenda e Clientes observam o mesmo repositório, evitando listas independentes após uma edição.

`src/lib/data/api_client.dart` centraliza HTTP/JSON, limites de espera e erros. `app_repository.dart` coordena estado, rede e cache. `app_scope.dart` disponibiliza o repositório para as telas. `local_store.dart` guarda snapshots por endereço de API em `banho_tosa_api_cache.db`.

O banco `banho_tosa.db` e o código `database_helper.dart` da Etapa 4 foram preservados. As telas atuais gravam exclusivamente pela API. O banco legado é aberto apenas para leitura durante a importação; não existe sincronização bidirecional nem gravação offline.

A importação é uma transação única no servidor: novos IDs são gerados e os relacionamentos são remapeados. O recibo persistente identifica importações repetidas da mesma instalação. Conflitos ou entradas inválidas cancelam todo o lote. A confirmação da API precede a atualização do cache.

Arquivos do servidor:

- `backend/src/server.js`: configuração de host, porta, arquivo SQLite e ciclo de vida.
- `backend/src/database.js`: esquema, consultas e transações.
- `backend/src/app.js`: validação e endpoints de clientes/agendamentos.
- `backend/src/importacao.js`: transferência do banco legado e recibos.

Veja [a Etapa 5](etapa-05.md) para contratos HTTP, limitações, execução e testes. Os documentos das etapas anteriores registram a evolução histórica do projeto.
