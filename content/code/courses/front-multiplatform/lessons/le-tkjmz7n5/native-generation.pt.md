---
title: Projetos nativos gerados, toda vez
version: 1
---

**Aqui o Expo toma a decisão oposta à do Capacitor.** A aula 3 pôs `android/` e `ios/` no git, porque o
Capacitor os escreve uma vez e depois eles são seus. O Expo chama a abordagem dele de **Continuous Native
Generation**: os projetos nativos são gerados a partir do `app.json` e dos pacotes que você instalou,
sempre que são necessários, e **eles não ficam no git de jeito nenhum**. O `.gitignore` do modelo já diz
isso:

```
ana@dev:~/planner-native$ grep -n -B1 "^/android" .gitignore
40-/ios
41:/android
```

O que substitui editar os arquivos nativos é configuração. **O `app.json` descreve o app**, e cada pacote
que precisa de algo nos projetos nativos traz um **config plugin**, um programinha que faz essa mudança
quando eles são gerados, como o `expo-router` fez na aula 8.

## Quem o app é

O `npx expo prebuild` é o comando que os gera. Rode-o no projeto como está e ele inventa uma identidade,
porque o `app.json` não nomeia nenhuma:

```
ana@dev:~/planner-native$ npx expo prebuild --platform android --no-install
Skipping Android package name reservation validation in offline-mode.
› Android package name: com.anonymous.plannernative
- Creating native directory (./android)
✔ Created native directory
- Updating package.json
✔ Updated package.json
- Running prebuild
» android: userInterfaceStyle: Install expo-system-ui in your project to enable this feature.
- Running prebuild
✔ Finished prebuild
ana@dev:~/planner-native$ grep applicationId android/app/build.gradle
        applicationId 'com.anonymous.plannernative'
```

A primeira linha é a máquina de gravação rodando o Expo offline de novo, o que pulou uma conferência de
que o nome está livre. **`com.anonymous.plannernative`** é um marcador, e é o mesmo tipo de decisão do
`appId` do Capacitor na aula 2: a identidade do app nas duas lojas, escolhida uma vez. Tire o que foi
gerado, e dê ao app a identidade dele no `app.json`, em `android.package` e `ios.bundleIdentifier`, a
mesma do planner da aula 2; o estado no controle de versão volta para onde estava:

```
ana@dev:~/planner-native$ rm -rf android && git checkout app.json package.json
Updated 2 paths from the index
ana@dev:~/planner-native$ grep -E "bundleIdentifier|\"package\"" app.json
      "bundleIdentifier": "com.example.studyplanner"
      "package": "com.example.studyplanner"
```

E gere de novo:

```
ana@dev:~/planner-native$ npx expo prebuild --platform android --no-install
- Creating native directory (./android)
✔ Created native directory
- Updating package.json
✔ Updated package.json
- Running prebuild
» android: userInterfaceStyle: Install expo-system-ui in your project to enable this feature.
- Running prebuild
✔ Finished prebuild
ana@dev:~/planner-native$ ls android
app
build.gradle
gradle
gradle.properties
gradlew
gradlew.bat
settings.gradle
ana@dev:~/planner-native$ grep applicationId android/app/build.gradle
        applicationId 'com.example.studyplanner'
ana@dev:~/planner-native$ git status --short
 M app.json
 M package.json
```

**A `android/` agora é um projeto Android completo**, com a identidade que o `app.json` deu, e a linha do
Expo sobre o `expo-system-ui` é um config plugin avisando que uma configuração do `app.json` precisa de um
pacote para ter efeito. Num Mac, `--platform ios` escreveria a `ios/` do mesmo jeito.

## Gerado, portanto apagado

```
ana@dev:~/planner-native$ rm -rf android
ana@dev:~/planner-native$ git status --short
 M app.json
 M package.json
```

O que o `git status` mostra é tudo o que mudou no repositório: o `app.json`, com a identidade, e o
`package.json`, onde o `prebuild` mudou os scripts `android` e `ios` para construir os projetos gerados
neste computador. A `android/` em si nunca esteve no git. **Apague-a e nada se perde**: o próximo
`prebuild` a escreve de novo, a partir das mesmas entradas. Esse é o ponto todo, e o custo todo. Um
upgrade do Expo é um upgrade do `package.json` e um `prebuild` novo, sem junção nativa, que é onde apps
Capacitor passam os dias de upgrade. Mas uma mudança feita à mão dentro da `android/` dura até a próxima
geração, então **uma mudança nativa tem que ser um config plugin**, escrito em JavaScript, que dá mais
trabalho que editar um arquivo na primeira vez e menos em todas as seguintes.
