---
title: Um módulo local, criado
version: 1
---

O `create-expo-module` escreve um módulo a partir do modelo do Expo. Com `--local` ele o escreve dentro do
projeto, em `modules/`, e não como um pacote próprio; o autolinking o encontra lá, como encontra uma
biblioteca no `node_modules`. As opções respondem às perguntas que a ferramenta faria:

```
ana@dev:~/planner$ npx create-expo-module@58.0.3 week-start --local --barrel --name WeekStart --package org.example.weekstart --platform apple android web --features Function --description 'The first day of the week' > /dev/null 2>&1
ana@dev:~/planner$ find modules -type f | sort
modules/week-start/CHANGELOG.md
modules/week-start/LICENSE
modules/week-start/android/build.gradle
modules/week-start/android/src/main/AndroidManifest.xml
modules/week-start/android/src/main/java/org/example/weekstart/WeekStartModule.kt
modules/week-start/expo-module.config.json
modules/week-start/index.ts
modules/week-start/ios/WeekStart.podspec
modules/week-start/ios/WeekStartModule.swift
modules/week-start/src/WeekStart.types.ts
modules/week-start/src/WeekStartModule.ts
modules/week-start/src/WeekStartModule.web.ts
```

- **O `expo-module.config.json`** nomeia a classe do módulo em cada plataforma; é o que o autolinking lê.
- **O `android/`** é uma pequena biblioteca Gradle: `build.gradle`, um manifest, e uma classe Kotlin no
  pacote dado em `--package`.
- **O `ios/`** tem a classe Swift e um **podspec**, a descrição de que o CocoaPods precisa para construí-la
  dentro do projeto iOS.
- **O `src/`** é a cara em JavaScript: o tipo do módulo nos celulares, a versão web dele, e um arquivo para
  tipos compartilhados. O `index.ts`, do `--barrel`, reexporta tudo, então o app importa `modules/week-start`.

O `--features Function` pediu um exemplo de uma função síncrona, que é o que este módulo é. O exemplo do
modelo diz olá; a próxima seção o substitui.
