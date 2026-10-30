---
title: Uma identidade antes de qualquer build
version: 1
---

O primeiro build para antes de compilar qualquer coisa:

```
ana@dev:~/planner$ npx tauri build
        Info Looking up installed tauri packages to check mismatched versions...
You must change the bundle identifier in `tauri.conf.json identifier`. The default value `com.tauri.dev` is not allowed as it must be unique across applications.
       Error You must change the bundle identifier in `tauri.conf.json identifier`. The default value `com.tauri.dev` is not allowed as it must be unique across applications.
ana@dev:~/planner$ sed -i 's/"com.tauri.dev"/"com.example.studyplanner"/' src-tauri/tauri.conf.json
ana@dev:~/planner$ grep -E "productName|identifier|frontendDist|title" src-tauri/tauri.conf.json
  "productName": "planner",
  "identifier": "com.example.studyplanner",
    "frontendDist": "../dist",
        "title": "Study planner",
```

**O Tauri recusa o próprio marcador.** `com.tauri.dev` é o identificador que o modelo escreve, e como o
`appId` do Capacitor na aula 2 e o `package` do Expo na aula 9, um identificador é a identidade do app: no
macOS ele nomeia o bundle, no Windows o instalador, e em todo sistema ele nomeia a pasta onde o app guarda
os dados. Dar a ele o identificador do próprio planner, `com.example.studyplanner`, o mesmo do app de
celular, é um `sed` na configuração, e as outras configurações são o que o `tauri init` recebeu.

`productName` é `planner`, que nomeia os pacotes que a aula 13 gera; o título da janela é `Study planner`.
