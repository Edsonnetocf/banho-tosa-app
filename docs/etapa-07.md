# Etapa 7 — Estado compartilhado e galeria

A etapa adiciona uma foto opcional por pet, escolhida na galeria do aparelho. O objetivo é identificar visualmente o animal no cadastro, nos detalhes e na Agenda, usando as telas existentes.

## Estado compartilhado

`FotosPetRepository` usa `ChangeNotifier` e mantém o mapa de IDs de pets para caminhos das cópias locais. Existe uma instância por `AppRepository`; suas notificações são repassadas ao `AppScope`, o `InheritedNotifier` já utilizado no projeto. Formulário, detalhes e Agenda acessam essa mesma instância, sem buscar novamente os dados da API para atualizar a imagem.

São compartilhadas as fotos persistidas e as condições de leitura, operação e erro. A seleção ainda não salva pertence ao estado local do formulário: cancelar não altera outras telas. Esse mecanismo reaproveita a arquitetura existente e evita duplicar o estado em cada tela.

## Recurso nativo e permissões

O plugin oficial [`image_picker`](https://pub.dev/packages/image_picker) abre o seletor de imagens do sistema com `ImageSource.gallery`. O usuário escolhe uma imagem já existente. Esta versão não abre a câmera e não cria uma tela própria para escolher imagens.

No Android, a seleção é mediada pelo sistema e não foi adicionada permissão ampla de armazenamento ou de câmera. No iOS, `Info.plist` contém a justificativa `NSPhotoLibraryUsageDescription`; a seleção usa `requestFullMetadata: false`. A execução nativa foi validada no Android; iOS requer validação em ambiente Apple.

## Fluxo e persistência

A foto aparece como prévia no formulário e só é aplicada depois que a API confirma o cadastro. Para novos cadastros, o cabeçalho HTTP `Location` identifica o cliente criado; o pet é obtido desse cliente no estado retornado. Não se usa nome, ordem da lista ou maior ID para adivinhar a associação.

O seletor solicita imagens de até 1600 × 1600 pixels e qualidade 85. O app verifica a decodificação e aceita arquivos de até 10 MB. `FotosPetStoreLocal` copia a imagem para a pasta privada obtida por `path_provider` e registra a associação em SQLite, separada pela URL do servidor e pelo ID do pet.

A troca só remove a cópia anterior depois que a nova associação foi persistida. A remoção nunca apaga o original da galeria. Excluir um cliente pela API tenta limpar as cópias de seus pets após a confirmação do servidor. As fotos são locais: não há upload, sincronização ou restauração dessas imagens pelo backend.

## Falhas e interface

A tela exibe apenas a prévia, o botão de adicionar/trocar e a opção de remover quando existe uma foto. Os eventos técnicos aparecem nos logs com a categoria `FOTOS`.

- Cancelar a galeria mantém a seleção anterior. Abandonar o formulário mantém a foto persistida.
- Falha de acesso, imagem inválida ou arquivo grande gera um aviso temporário, sem alterar a foto anterior.
- Falha local após a API salvar o cadastro informa que somente a foto precisa ser tentada novamente pela edição. O POST não é repetido.
- Arquivo local ausente ou ilegível é substituído visualmente pelo ícone de pet.
- Se o Android encerrar o processo durante a escolha, `retrieveLostData()` verifica a seleção interrompida na inicialização. Como o formulário e seu destino não foram restaurados, a imagem não é associada automaticamente; um aviso pede nova escolha no cadastro.

## Executar e verificar

Mantenha a API em execução no terminal de `backend` com `npm.cmd start`. Em outro terminal, dentro de `src`, execute:

```powershell
$env:FLUTTER_WINDOWS='false'
flutter pub get
flutter run -d emulator-5554
```

Ajuste o identificador conforme `flutter devices`. Depois de adicionar o plugin, encerre e execute o app novamente; hot reload não instala código nativo. O emulador precisa ter alguma imagem na galeria: arraste um JPG/PNG para sua janela e procure-o no seletor, inclusive em **Procurar** ou **Downloads**, conforme a versão do Android.

Faça esta verificação manual antes do commit:

1. Cadastre um cliente e pet com foto. Confira a imagem nos detalhes e em um agendamento desse pet.
2. Edite a foto e salve. Volte aos detalhes e à Agenda: ambas devem mostrar a nova imagem.
3. Reabra o app e confira a persistência da foto.
4. Escolha outra imagem e volte sem salvar. Confira que a foto anterior continua aplicada.
5. Abra a galeria e cancele. A prévia deve permanecer como estava.
6. Remova a foto e salve. Os detalhes e a Agenda devem voltar ao ícone de pet; o original deve continuar na galeria.
7. Cadastre outro pet sem foto e confirme que o recurso é opcional.
8. Com dados já carregados, desligue a API e atualize os dados. As fotos continuam disponíveis para consulta junto ao cache; os cadastros continuam exigindo o backend.

## Testes automatizados

Na pasta `src`, a análise e a suíte padrão verificam os estados, o contrato HTTP e os fluxos do formulário:

```powershell
flutter analyze
flutter test
```

Os testes de armazenamento Android usam arquivos e banco temporários:

```powershell
flutter test integration_test/fotos_pet_store_test.dart -d emulator-5554
```

Há também um teste opcional do seletor real, para um **emulador de testes com imagens disponíveis**. Ele usa cadastros simulados e armazenamento temporário. Durante a execução, cancele a primeira abertura da galeria e selecione uma imagem na segunda:

```powershell
flutter test integration_test/galeria_pet_test.dart -d emulator-5554 --dart-define=TESTE_GALERIA_INTERATIVA=true
```