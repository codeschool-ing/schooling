---
title: "Prebuild: pastas nativas geradas a partir de um arquivo"
version: 1
---

**Num projeto Expo, as pastas nativas são saída, não fonte.** Elas são escritas por um comando, `npx
expo prebuild`, a partir do `app.json` e das bibliotecas instaladas, e podem ser apagadas e escritas de
novo a qualquer momento. O Expo chama isso de **Continuous Native Generation**. É a resposta aos três
custos do projeto bare, e o melhor jeito de entendê-la é vê-la acontecer.

## Um projeto sem pastas nativas

Crie um segundo projeto, desta vez a partir do modelo do Expo, e deixe-o instalar:

```
ana@dev:~$ npx create-expo-app@5.0.0 try-expo --template blank-typescript@sdk-58 > /dev/null 2>&1
ana@dev:~$ cd try-expo
ana@dev:~/try-expo$ ls
AGENTS.md
App.tsx
LICENSE
app.json
assets
index.ts
node_modules
package-lock.json
package.json
tsconfig.json
ana@dev:~/try-expo$ tail -3 .gitignore
# generated native folders
/ios
/android
```

Não há `android/` nem `ios/`, e o `.gitignore` do modelo diz o que fazer quando elas aparecerem:
deixá-las fora do git. **O que vai para o commit é a descrição; o que é gerado não vai.**

## Gerando as pastas

O `npx expo prebuild` lê a configuração e escreve os dois projetos. `--no-install` pula o CocoaPods,
que só existe num Mac; as pastas são escritas assim mesmo:

```
ana@dev:~/try-expo$ npx expo prebuild --no-install > /dev/null 2>&1
ana@dev:~/try-expo$ ls android ios
android:
app
build.gradle
gradle
gradle.properties
gradlew
gradlew.bat
settings.gradle

ios:
Podfile
Podfile.properties.json
tryexpo
tryexpo.xcodeproj
ana@dev:~/try-expo$ grep applicationId android/app/build.gradle
        applicationId 'com.anonymous.tryexpo'
```

Elas têm o mesmo formato das do projeto bare, porque o modelo por trás delas é o do próprio React
Native com os acréscimos do Expo. O identificador Android, `com.anonymous.tryexpo`, é um marcador feito
a partir do nome do projeto: ninguém disse ainda como este app se chama numa loja.

## Mudando a descrição, não a saída

**Todo app Android é identificado por um nome de pacote**, escrito como um domínio ao contrário, e as
lojas o usam como a identidade do app para sempre. Num projeto bare você editaria o `build.gradle`.
Aqui você o escreve no `app.json`, dentro do objeto `"android"`, ao lado do que o modelo pôs ali:

```json
"package": "org.example.planner"
```

Depois gere de novo. `--clean` apaga as pastas antes, para que nada escrito da última vez sobreviva:

```
ana@dev:~/try-expo$ grep -n package app.json
21:      "package": "org.example.planner"
ana@dev:~/try-expo$ npx expo prebuild --clean --no-install > /dev/null 2>&1
ana@dev:~/try-expo$ grep applicationId android/app/build.gradle
        applicationId 'org.example.planner'
```

O identificador no arquivo do Gradle agora diz `org.example.planner`, e ninguém editou aquele arquivo.
O mesmo vale para o identificador de bundle do iOS (`"ios": { "bundleIdentifier": … }`), o nome do app,
o ícone, a versão, a orientação, e as permissões da aula 13: **um arquivo, as duas plataformas**.

## O que isso compra, e a regra de que precisa

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"l02-cng\" aria-label=\"Continuous Native Generation. O app.json, as bibliotecas instaladas e os seus config plugins vão para o git. O npx expo prebuild os lê e escreve as pastas android e ios, que o git ignora. Uma edição feita à mão numa pasta gerada se perde no próximo prebuild --clean.\"><defs><marker id=\"l02-cng-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"110\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">vai para o git</text><rect x=\"30\" y=\"36\" width=\"160\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"110.0\" y=\"53.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">app.json</text><rect x=\"30\" y=\"80\" width=\"160\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"110.0\" y=\"95.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">bibliotecas instaladas</text><text x=\"110.0\" y=\"108.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">e os plugins delas</text><rect x=\"30\" y=\"134\" width=\"160\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"110.0\" y=\"151.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">os seus plugins</text><rect x=\"260\" y=\"80\" width=\"180\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"350.0\" y=\"102.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">npx expo prebuild</text><path d=\"M190 53 L260 102\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l02-cng-ah-paper-dim)\"></path><path d=\"M190 102 L260 102\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l02-cng-ah-paper-dim)\"></path><path d=\"M190 151 L260 102\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l02-cng-ah-paper-dim)\"></path><text x=\"600\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper-dim)\">gerado, ignorado pelo git</text><rect x=\"520\" y=\"50\" width=\"160\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"600.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">android/</text><rect x=\"520\" y=\"114\" width=\"160\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"600.0\" y=\"134.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">ios/</text><path d=\"M440 95 L520 70\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l02-cng-ah-paper-dim)\"></path><path d=\"M440 110 L520 134\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l02-cng-ah-paper-dim)\"></path><text x=\"560\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--amber)\">uma edição feita aqui à mão some depois do prebuild --clean</text></svg>", "caption": "A descrição é fonte; os projetos nativos são saída, escritos de novo sempre que a descrição muda."}
```

Os três custos do projeto bare mudam de forma:

- **Uma mudança de configuração é uma edição só**, em JSON, e as duas plataformas a recebem.
- **Uma atualização gera as pastas de novo** a partir do modelo novo, então não há diff para aplicar à
  mão. As suas mudanças moram no `app.json` e em plugins, que sobrevivem à regeneração porque são
  aplicados durante ela.
- **Uma biblioteca com configuração nativa** traz um config plugin que faz essa configuração durante o
  prebuild, então instalá-la e gerar de novo é o trabalho todo.

O preço é uma regra, e ela é rígida: **nunca edite à mão uma pasta gerada.** O próximo `prebuild
--clean` apaga a edição sem dizer nada, e o build seguinte funciona, menos o que quer que a edição
fazia. Quando uma mudança precisa chegar ao projeto nativo, ela é escrita como um config plugin, que é
a próxima seção. Uma equipe que quer editar as pastas nativas diretamente pode parar de gerá-las e
colocá-las no commit; isso é um projeto bare de novo, e um projeto Expo pode virar um a qualquer
momento.
