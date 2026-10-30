---
title: Onde vai cada tipo de arquivo, e o que o backup leva
version: 1
---

**A pergunta que decide o lugar de um arquivo não é "qual o tamanho dele", e sim "se este arquivo
sumisse esta noite, o app conseguiria fazê-lo de novo?"** Se sim, é um cache, e o sistema fica à
vontade para apagá-lo. Se não, são dados do usuário, e vão para onde o sistema não vai apagá-los nem
esquecer de copiá-los no backup. Todo o resto desta etapa é essa pergunta feita às pastas que cada
plataforma oferece.

## As pastas, pelo nome

| | Android | iOS |
|---|---|---|
| os dados do próprio app, mantidos e com backup | `filesDir`, a pasta de bancos de dados, as shared preferences | `Library/Application Support` |
| documentos que o usuário fez e pode ver | armazenamento compartilhado, pelos seletores do sistema | `Documents`, que o backup leva |
| mantido, mas sem backup | `noBackupFilesDir` | um arquivo em Application Support marcado com `isExcludedFromBackup` |
| um cache que o sistema pode apagar | `cacheDir` | `Library/Caches` |
| espaço de rascunho por um instante | `cacheDir` também | `tmp` |

As linhas vêm dos guias do Android sobre armazenamento específico do app e sobre o Auto Backup, e do
guia de sistema de arquivos da Apple e do artigo dela sobre otimizar os dados de um app para o
backup do iCloud, todos lidos em 30 de outubro de 2026. Os trechos abaixo pegam as duas pastas mais
usadas em cada plataforma, adaptados das mesmas páginas e da documentação do `expo-file-system`;
**não foram compilados nem executados para este curso**:

```kotlin
val plan = File(context.filesDir, "plan.json")      // kept, backed up
val week = File(context.cacheDir, "week.json")      // may be deleted when space is low
```

```swift
let plan = URL.applicationSupportDirectory.appending(path: "plan.json") // kept, backed up
let week = URL.cachesDirectory.appending(path: "week.json")             // may be purged
```

```tsx
import { File, Paths } from "expo-file-system";

const plan = new File(Paths.document, "plan.json"); // kept, backed up
const week = new File(Paths.cache, "week.json");    // may be deleted by the system
```

## O que o backup leva, e quando

**No Android, o Auto Backup copia os dados de um app para o Google Drive do usuário** para todo app
que mira o Android 6 ou posterior, a menos que o app o desligue. Por padrão ele leva as shared
preferences, os arquivos em `filesDir` e os bancos de dados; ele sempre deixa de fora o `cacheDir` e
o `noBackupFilesDir`. O limite é de **25 MB por app**, e um app acima disso simplesmente não tem
backup. O backup roda quando se passaram pelo menos 24 horas desde o último, e o aparelho está
ocioso e no Wi-Fi, o que a documentação diz que, na prática, acontece mais ou menos toda noite.

**No iOS, o backup do iCloud leva o contêiner do app, menos as pastas que o sistema pode esvaziar**:
`Library/Caches` e `tmp` ficam de fora por padrão. O artigo da Apple pede também a disciplina
contrária, porque um backup que carrega megabytes de miniaturas que o app conseguiria refazer fica
mais lento para o usuário e gasta o espaço dele no iCloud à toa.

**O backup também é o caminho por onde os dados voltam**, e isso tem uma consequência que as pessoas
descobrem do jeito difícil. Um arquivo que identifica *este* celular não pertence ao próximo. O guia
do Auto Backup do Android dá o exemplo: o Firebase Cloud Messaging cria um novo token de registro em
cada aparelho novo, o token a que as mensagens push da aula 17 são endereçadas, e se o antigo for
restaurado o app pode se comportar de forma inesperada. Esse tipo de arquivo pertence à linha
"mantido, mas sem backup".

## Os arquivos do planner, no lugar

| arquivo | o app conseguiria fazê-lo de novo? | onde |
|---|---|---|
| `planner.db`, os cursos e as sessões | não: a aluna os digitou | a pasta de dados do app, com backup |
| `prefs.json`, a aba e o tema | não, mas perdê-lo custa um toque | preferências, com backup |
| `week.json`, a cópia da resposta do servidor | sim: perguntar ao servidor | o cache |
| o token de login | sim, entrando de novo, e ele não pode viajar | o Keychain ou o Keystore |

**A linha do cache é a que a aula 14 deixou em aberto.** O `screen.ts` dela guardava a semana do
servidor num arquivo ao lado do programa. Num celular essa cópia vai para o cache: perdê-la custa uma
requisição, e a tela já sabe o que dizer quando não há cópia nenhuma. O curso `mobile-offline` dá à
sandbox inteira a sua aula 1, e ao cache, com o quanto ele pode crescer, a sua aula 17.
