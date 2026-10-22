# Etapa 4: Persistência Local de Dados

## Objetivo

Implementar o armazenamento local dos dados do Banho & Tosa App, permitindo cadastrar, consultar, atualizar e remover clientes, pets e agendamentos, mantendo os registros disponíveis após o encerramento da aplicação.

## Mecanismo de persistência utilizado

Foi utilizado o SQLite, por meio do pacote `sqflite` do Flutter, com auxílio do pacote `path` para definir o caminho do banco de dados.

O banco é armazenado localmente no dispositivo, no arquivo `banho_tosa.db`, sem necessidade de backend ou conexão com a internet.

## Justificativa da escolha

O SQLite foi escolhido por ser um banco de dados relacional, adequado para armazenar informações estruturadas e relacionadas.

No aplicativo, um cliente pode possuir pets, e cada pet pode possuir agendamentos. O SQLite permite manter esses relacionamentos utilizando chaves estrangeiras.

A escolha também está alinhada à proposta inicial do projeto, que previa armazenamento local com SQLite.

## Estrutura dos dados armazenados

O banco possui três tabelas:

**clientes**

- `id`: identificador único.
- `nome`: nome do cliente.
- `telefone`: telefone do cliente.

**pets**

- `id`: identificador único.
- `cliente_id`: referência ao cliente responsável.
- `nome`: nome do pet.
- `especie`: espécie do animal.
- `raca`: raça do animal.
- `porte`: porte do animal.

**agendamentos**

- `id`: identificador único.
- `pet_id`: referência ao pet.
- `data_hora`: data e horário do agendamento.
- `servico`: serviço solicitado.

Os relacionamentos são definidos por chaves estrangeiras. A data e o horário possuem uma restrição de unicidade, evitando dois agendamentos no mesmo instante.

## Operações de persistência implementadas

**Criação e armazenamento:** os formulários permitem cadastrar clientes, pets e agendamentos, armazenando os registros no SQLite.

**Recuperação:** as telas de Clientes e Agenda consultam os dados armazenados ao serem carregadas.

**Atualização:** os registros existentes podem ser editados pelos formulários, utilizando seus identificadores.

**Remoção:** clientes e agendamentos podem ser excluídos após confirmação. A exclusão de um cliente com agendamentos associados é impedida para preservar a integridade dos dados.

As operações estão centralizadas no arquivo `src/lib/data/database_helper.dart`.

## Telas que utilizam os dados persistidos

- **Clientes:** exibe e permite pesquisar clientes armazenados.
- **Cadastro de Cliente e Pet:** realiza o cadastro e a edição.
- **Detalhes do Pet:** apresenta informações do pet recuperadas do banco.
- **Agenda:** exibe, edita e permite excluir agendamentos armazenados.
- **Novo Agendamento:** permite criar ou atualizar agendamentos vinculados aos pets cadastrados.

## Instruções de execução e teste

Para executar o aplicativo, entre na pasta `src` e utilize os comandos:

```bash
flutter pub get
flutter run
```

Para verificar o código e executar os testes automatizados:

```bash
flutter analyze
flutter test
```

Os testes de persistência devem ser realizados no emulador Android, verificando as operações de cadastro, consulta, edição e exclusão.

## Procedimento para verificar a persistência

1. Executar o aplicativo no emulador Android.
2. Cadastrar um cliente e seu pet.
3. Verificar se o cadastro aparece na lista de Clientes.
4. Criar um agendamento para o pet cadastrado.
5. Verificar se o agendamento aparece na Agenda.
6. Encerrar completamente o aplicativo, utilizando a opção de forçar parada do Android.
7. Reabrir o aplicativo sem limpar seus dados.
8. Verificar se o cliente, o pet e o agendamento continuam disponíveis.
9. Editar as informações e repetir o encerramento e a reabertura.
10. Excluir um agendamento e confirmar que ele não reaparece após reiniciar.

O Hot Reload não deve ser utilizado como única comprovação da persistência.

## Decisões técnicas

- Utilização de SQLite para persistência relacional.
- Centralização das operações em `database_helper.dart`.
- Uso de identificadores e chaves estrangeiras para relacionar os registros.
- Uso de transação para salvar cliente e pet em conjunto.
- Tratamento de erros e mensagens de feedback nas operações.
- Preservação da navegação e dos componentes das etapas anteriores.

## Limitações conhecidas

- O armazenamento é local, sem sincronização entre dispositivos.
- Não existe backend ou integração com APIs externas.
- O formulário de cliente trabalha com um pet por vez.
- A tela de detalhes apresenta o primeiro pet do cliente.
- O histórico de atendimentos concluídos ainda não foi implementado.
- A persistência foi desenvolvida e destinada aos testes no Android.

## Bibliotecas e ferramentas utilizadas

- **Flutter e Dart:** desenvolvimento da aplicação.
- **sqflite:** integração com SQLite.
- **path:** construção do caminho do banco de dados.
- **ChatGPT:** apoio na implementação e documentação, com revisão e testes pelo desenvolvedor.

## Repositório

https://github.com/Edsonnetocf/banho-tosa-app

Tag prevista para a entrega: `etapa-04`.
