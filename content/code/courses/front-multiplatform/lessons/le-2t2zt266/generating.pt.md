---
title: Gerando o plugin
version: 1
---

**O gerador do Capacitor escreve um projeto de plugin inteiro**: o lado TypeScript, uma biblioteca
Android, um pacote Swift para iOS, um app de demonstração e os scripts para construí-los. Ele mora ao
lado do planner, numa pasta própria, porque um plugin é um pacote próprio com a sua versão, e o planner
vai instalá-lo como qualquer outro. Toda pergunta que o gerador faria é respondida na linha:

```
ana@dev:~$ npm init @capacitor/plugin@0.22.0 keep-awake -- --name capacitor-keep-awake --package-id com.example.keepawake --class-name KeepAwake --repo https://example.org/keep-awake --author "Ana Lima <ana@example.org>" --license MIT --description "Keep the screen on while a study session runs" --android-lang kotlin > /dev/null
npm warn deprecated inflight@1.0.6: This module is not supported, and leaks memory. Do not use it. Check out lru-cache if you want a good and tested way to coalesce async requests by a key value, which is much more comprehensive and powerful.
npm warn deprecated @humanwhocodes/config-array@0.13.0: Use @eslint/config-array instead
npm warn deprecated rimraf@3.0.2: Rimraf versions prior to v4 are no longer supported
npm warn deprecated @humanwhocodes/object-schema@2.0.3: Use @eslint/object-schema instead
npm warn deprecated glob@7.2.3: Old versions of glob are not supported, and contain widely publicized security vulnerabilities, which have been fixed in the current version. Please update. Support for old versions may be purchased (at exorbitant rates) by contacting i@izs.me
npm warn deprecated eslint@8.57.1: This version is no longer supported. Please see https://eslint.org/version-support for other options.
npm warn deprecated uuid@7.0.3: uuid@10 and below is no longer supported.  For ESM codebases, update to uuid@latest.  For CommonJS codebases, use uuid@11 (but be aware this version will likely be deprecated in 2028).

dist/esm/index.js → dist/plugin.js, dist/plugin.cjs.js...
created dist/plugin.js, dist/plugin.cjs.js in 42ms
Switched to a new branch 'main'
ana@dev:~$ cd keep-awake
ana@dev:~/keep-awake$ git ls-files ':!example-app' ':!*/gradle/wrapper/*' ':!*.gitkeep'
.eslintignore
.gitignore
.prettierignore
CONTRIBUTING.md
CapacitorKeepAwake.podspec
Package.swift
README.md
android/.gitignore
android/build.gradle
android/gradle.properties
android/gradlew
android/gradlew.bat
android/proguard-rules.pro
android/settings.gradle
android/src/androidTest/kotlin/com/getcapacitor/android/ExampleInstrumentedTest.kt
android/src/main/AndroidManifest.xml
android/src/main/kotlin/com/example/keepawake/KeepAwake.kt
android/src/main/kotlin/com/example/keepawake/KeepAwakePlugin.kt
android/src/test/kotlin/com/getcapacitor/ExampleUnitTest.kt
ios/.gitignore
ios/Sources/KeepAwakePlugin/KeepAwake.swift
ios/Sources/KeepAwakePlugin/KeepAwakePlugin.swift
ios/Tests/KeepAwakePluginTests/KeepAwakeTests.swift
package.json
rollup.config.mjs
src/definitions.ts
src/index.ts
src/web.ts
tsconfig.json
```

- **`--name`** é o nome do pacote npm, o que o planner vai importar. `capacitor-` na frente é a
  convenção que torna um plugin fácil de achar.
- **`--package-id`** é o pacote Android e a identidade em domínio invertido do código nativo. Use um
  domínio que você controla, como com o `appId`.
- **`--class-name`** é o nome que os três lados compartilham, e a próxima seção mostra por que isso
  importa.
- **`--android-lang kotlin`**: o gerador escreve Java se ninguém disser o contrário. Kotlin é o que a
  própria documentação do Google e os modelos do Android Studio usam hoje, e o mais curto dos dois para
  ler.

O gerador também fez da pasta um repositório git, com um commit, rodou `npm install` nela e a construiu
uma vez. O relatório dele foi para `/dev/null`, porque termina com emoji que esta página não consegue
desenhar; o que ainda apareceu é o que outros programas escreveram no fluxo de erro, os avisos do npm
sobre pacotes antigos entre as ferramentas do gerador e a linha do Rollup sobre o build. Nenhum deles é
um problema no seu plugin. O que ele fez é a lista de arquivos, e três grupos importam, as três
implementações:

| pasta | o que é |
|---|---|
| `src/` | o TypeScript: a interface, a implementação web e a linha que as liga |
| `android/` | uma biblioteca Android, escrita em Kotlin, construída pelo Gradle dentro do app que a instala |
| `ios/` | um pacote Swift, construído pelo Xcode dentro do app que o instala |

A chave `capacitor` do `package.json` diz ao comando `cap` onde ficam as duas pastas nativas, e o
`Package.swift` e o `.podspec` descrevem o lado iOS ao Swift Package Manager e ao CocoaPods. As faixas de
versão dele, `^8.0.0` e afins, estão certas **para uma biblioteca**: dizem com quais versões do Capacitor
o plugin funciona, e quem fixa é o app que o instala.

## A ligação

O `src/index.ts` é gerado e fica como está:

```
ana@dev:~/keep-awake$ cat src/index.ts
import { registerPlugin } from '@capacitor/core';

import type { KeepAwakePlugin } from './definitions';

const KeepAwake = registerPlugin<KeepAwakePlugin>('KeepAwake', {
  web: () => import('./web').then((m) => new m.KeepAwakeWeb()),
});

export * from './definitions';
export { KeepAwake };
```

**O `registerPlugin` é onde as três implementações se encontram**. Num celular, o Capacitor acha a
classe nativa registrada sob `'KeepAwake'` e manda cada chamada para ela. Num navegador não há nenhuma,
então ele roda a função dada como `web`, que só carrega `src/web.ts` quando ela é necessária pela
primeira vez.

## O que o gerador escreveu e o planner não precisa

O modelo é um método `echo` nos três lados, um app de demonstração em `example-app/`, um teste de
exemplo em cada plataforma e uma classe de implementação separada em cada lado nativo. Este plugin é
pequeno o bastante para manter tudo na própria classe do plugin, então os arquivos extras saem, e sai
também o alvo de teste no `Package.swift` que apontava para o teste iOS apagado:

```
ana@dev:~/keep-awake$ git rm -rq example-app ios/Tests android/src/test android/src/androidTest android/src/main/kotlin/com/example/keepawake/KeepAwake.kt ios/Sources/KeepAwakePlugin/KeepAwake.swift
ana@dev:~/keep-awake$ sed -n '/targets: \[/,$p' Package.swift
            targets: ["KeepAwakePlugin"])
    ],
    dependencies: [
        .package(url: "https://github.com/ionic-team/capacitor-swift-pm.git", from: "8.0.0")
    ],
    targets: [
        .target(
            name: "KeepAwakePlugin",
            dependencies: [
                .product(name: "Capacitor", package: "capacitor-swift-pm"),
                .product(name: "Cordova", package: "capacitor-swift-pm")
            ],
            path: "ios/Sources/KeepAwakePlugin")
    ]
)
```

Um plugin de que outras pessoas dependem merece testes em cada plataforma, e a estrutura do gerador é a
que se deve manter para isso. **Eles precisam de um SDK do Android e do Xcode para rodar**, que a máquina
de gravação deste curso não tinha.
