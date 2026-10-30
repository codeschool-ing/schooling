---
title: O que a biblioteca declara
version: 1
---

O `expo-notifications` faz notificações locais e push. Instale-o:

```
ana@dev:~/planner$ npx expo install expo-notifications
Unable to fetch compatibility data from React Native Directory. Skipping check.
Dependency validation is unreliable in offline-mode
› Installing 1 SDK 58.0.0 compatible native module using npm
> npm install

added 6 packages, removed 1 package, and audited 1128 packages in 9s

15 vulnerabilities (12 low, 3 high)

To address issues that do not require attention, run:
  npm audit fix

To address all issues (including breaking changes), run:
  npm audit fix --force

Run `npm audit` for details.
```

Desta vez não há frases a escrever: nenhuma das plataformas mostra palavras do app quando pergunta sobre
notificações. O que a biblioteca declara pode ser lido depois de um prebuild:

```
ana@dev:~/planner$ npx expo prebuild --clean --no-install > /dev/null 2>&1
ana@dev:~/planner$ grep uses-permission node_modules/expo-notifications/android/src/main/AndroidManifest.xml
  <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
  <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
ana@dev:~/planner$ grep -A1 aps-environment ios/Studyplanner/Studyplanner.entitlements
    <key>aps-environment</key>
    <string>development</string>
```

- **`POST_NOTIFICATIONS`** é a permissão do Android 13 para mostrar uma notificação qualquer. Antes do
  Android 13 um app as mostrava por padrão; do 13 em diante, a pessoa é perguntada, como para a câmera.
- **`RECEIVE_BOOT_COMPLETED`** deixa a biblioteca ouvir o celular ligar. O Android esquece toda notificação
  agendada quando reinicia, então a biblioteca as agenda de novo no boot.
- **`aps-environment`** nos *entitlements* do iOS é a capacidade de push: uma promessa à Apple de que o app
  vai receber pushes, conferida contra o perfil de assinatura quando o app é construído. `development` é o
  sandbox da Apple, que os development builds usam; um build de loja diz `production`.

As três vêm da biblioteca, pelo manifest e pelo plugin dela; nenhuma está no `app.json`.
