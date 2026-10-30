---
title: Os projetos Android e iOS
version: 1
---

**Cada plataforma é mais um pacote e um comando.** O pacote traz a metade da ponte daquela plataforma,
e o `cap add` escreve um projeto nativo que a usa:

```
ana@dev:~/planner$ npm install -E @capacitor/android@8.5.3 @capacitor/ios@8.5.3

added 2 packages, and audited 120 packages in 676ms

3 moderate severity vulnerabilities

To address all issues (including breaking changes), run:
  npm audit fix --force

Run `npm audit` for details.
ana@dev:~/planner$ npx cap add android
✔ Adding native android project in android in 52.63ms
✔ add in 53.07ms
✔ Copying web assets from dist to android/app/src/main/assets/public in 5.73ms
✔ Creating capacitor.config.json in android/app/src/main/assets in 687.24μs
✔ copy android in 16.35ms
✔ Updating Android plugins in 1.39ms
✔ update android in 17.01ms
✔ Syncing Gradle in 390.32μs
[success] android platform added!
Follow the Developer Workflow guide to get building:
https://capacitorjs.com/docs/basics/workflow
ana@dev:~/planner$ npx cap add ios
✔ Adding native Xcode project in ios in 26.97ms
✔ add in 27.46ms
✔ Copying web assets from dist to ios/App/App/public in 4.46ms
✔ Creating capacitor.config.json in ios/App/App in 493.88μs
✔ copy ios in 14.36ms
✔ Updating iOS plugins in 1.20ms
[info] All Capacitor plugins have a Package.swift file and will be included in Package.swift
[info] Writing Package.swift
✔ update ios in 15.71ms
[success] ios platform added!
Follow the Developer Workflow guide to get building:
https://capacitorjs.com/docs/basics/workflow
```

Cada `cap add` fez os mesmos três passos, e as linhas dizem quais: **escreveu um projeto nativo**,
**copiou a `dist/`** para dentro dele e **atualizou os plugins** que o projeto conhece, nenhum ainda. O
projeto Android usa o Gradle, a ferramenta de build do Android, e por isso "Syncing Gradle" é o último
passo. O iOS lista as dependências nativas em `Package.swift`, para o Swift Package Manager do Xcode.

## O que chegou

```
ana@dev:~/planner$ git status --short
 M package-lock.json
 M package.json
?? android/
?? capacitor.config.ts
?? ios/
ana@dev:~/planner$ ls android ios/App
android:
app
build.gradle
capacitor-cordova-android-plugins
capacitor.settings.gradle
gradle
gradle.properties
gradlew
gradlew.bat
settings.gradle
variables.gradle

ios/App:
App
App.xcodeproj
CapApp-SPM
```

**Duas pastas, `android/` e `ios/`, e as duas agora são suas.** A `android/` é um projeto Gradle que o
Android Studio abre: `app/` é o app em si e os arquivos em volta configuram o build. A `ios/App` guarda
o `App.xcodeproj`, que o Xcode abre, a `App/` com os arquivos Swift do app, e a `CapApp-SPM`, o pacote
Swift que traz o Capacitor. A aula 3 abre as duas e diz quais arquivos você vai editar.

**As duas vão para o git**, o contrário do que se espera de código gerado. O Capacitor as escreve uma
vez e nunca mais. Daqui em diante quem muda é você: um ícone, uma permissão, uma linha de código
nativo. Uma pasta que é regerada é saída de build e pertence ao `.gitignore`; uma pasta que você edita
é código-fonte.

## `cap doctor`

O `npx cap doctor` confere as versões e as ferramentas de cada plataforma, e imprime uma linha por
plataforma. Na máquina Linux onde este curso foi gravado, a linha do iOS é esta:

```
ana@dev:~/planner$ npx cap doctor | grep -E "installed|Xcode"
[error] Xcode is not installed
```

Esse `[error]` é a fronteira que a aula 1 declarou, dita pela própria ferramenta: não há Xcode no
Linux, então o projeto iOS pode ser gerado e editado aqui, e construído só num Mac. A linha do Android
informa sucesso na mesma máquina, o que só quer dizer que o projeto dele está em ordem: ela não confere
se existe um SDK do Android, e a aula 3 encontra o momento em que um é necessário.
