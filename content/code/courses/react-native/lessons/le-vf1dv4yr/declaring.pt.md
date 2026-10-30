---
title: Declarando o que o app pode pedir
version: 1
---

**A declaração é configuração nativa, então num projeto Expo ela vem de um config plugin.** O planner vai
usar o `expo-image-picker` para escolher e tirar fotos, e o `expo-file-system` para guardá-las. Instale os
dois nas versões que o SDK 58 espera:

```
ana@dev:~/planner$ npx expo install expo-image-picker expo-file-system
Unable to fetch compatibility data from React Native Directory. Skipping check.
Dependency validation is unreliable in offline-mode
› Installing 2 SDK 58.0.0 compatible native modules using npm
> npm install

added 3 packages, removed 1 package, and audited 1114 packages in 9s

15 vulnerabilities (12 low, 3 high)

To address issues that do not require attention, run:
  npm audit fix

To address all issues (including breaking changes), run:
  npm audit fix --force

Run `npm audit` for details.
```

O `expo-image-picker` traz um plugin, e as opções dele são a declaração. Acrescente-o à lista `"plugins"`
do `app.json`, dentro de `"expo"`, como a aula 2 fez com o plugin do início da semana:

```json
"plugins": [
  [
    "expo-image-picker",
    {
      "cameraPermission": "The planner uses the camera to photograph your notes for a course.",
      "photosPermission": false,
      "microphonePermission": false
    }
  ]
]
```

**O `cameraPermission` é a frase que o iOS mostra no diálogo**, então ela diz para que serve a câmera, em
termos do que a pessoa ganha. *"This app needs camera access"* é a frase que a revisão da Apple devolve. As
duas opções `false` tiram o que o planner nunca usa: ele não lê a galeria, já que o seletor do sistema não
precisa de permissão, e não grava vídeo, então não precisa de microfone.

Gere os projetos nativos e leia o que o plugin escreveu:

```
ana@dev:~/planner$ grep -A9 "\"plugins\"" app.json
    "plugins": [
      [
        "expo-image-picker",
        {
          "cameraPermission": "The planner uses the camera to photograph your notes for a course.",
          "photosPermission": false,
          "microphonePermission": false
        }
      ]
    ]
ana@dev:~/planner$ npx expo prebuild --clean --no-install > /dev/null 2>&1
ana@dev:~/planner$ grep uses-permission android/app/src/main/AndroidManifest.xml
  <uses-permission android:name="android.permission.INTERNET"/>
  <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" android:maxSdkVersion="32" tools:replace="android:maxSdkVersion"/>
  <uses-permission android:name="android.permission.RECORD_AUDIO" tools:node="remove"/>
  <uses-permission android:name="android.permission.SYSTEM_ALERT_WINDOW"/>
  <uses-permission android:name="android.permission.VIBRATE"/>
  <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" android:maxSdkVersion="32" tools:replace="android:maxSdkVersion"/>
ana@dev:~/planner$ grep -A1 UsageDescription ios/Studyplanner/Info.plist
    <key>NSCameraUsageDescription</key>
    <string>The planner uses the camera to photograph your notes for a course.</string>
    <key>NSLocalNetworkUsageDescription</key>
    <string>Expo Dev Launcher uses the local network to discover and connect to development servers running on your computer.</string>
```

No Android, **o `CAMERA` não está na lista**, embora o planner vá pedi-lo. O que o plugin escreveu foi o
`RECORD_AUDIO` com `tools:node="remove"`: uma instrução ao build do Android para apagar aquela permissão
mesmo que uma biblioteca a peça, que é o que o `false` queria dizer. `INTERNET`, `SYSTEM_ALERT_WINDOW` e
`VIBRATE` vêm do modelo do Expo, e as duas permissões de armazenamento terminam em `maxSdkVersion="32"`,
o Android 12.

No iOS, o `NSCameraUsageDescription` traz a frase, palavra por palavra, e não há chave nenhuma da galeria.
O `NSLocalNetworkUsageDescription` é do development build, que procura o Metro na rede local.

## O manifest que o celular recebe

O arquivo do Android é o manifest do próprio app, e não é o que vai no app. **Toda biblioteca Android traz
um manifest próprio, e o Gradle junta todos num só** enquanto constrói. O Gradle consegue rodar só essa
etapa, que leva uns dois minutos da primeira vez. O arquivo juntado é longo, então o segundo comando junta
as linhas dele e guarda só o nome de cada `<uses-permission>`:

```
ana@dev:~/planner/android$ ./gradlew :app:processDebugMainManifest -q > /dev/null 2>&1
ana@dev:~/planner/android$ tr '\n' ' ' < app/build/intermediates/merged_manifest/debug/processDebugMainManifest/AndroidManifest.xml | grep -o '<uses-permission *android:name="[^"]*"' | cut -d'"' -f2 | sort
android.permission.ACCESS_LOCAL_NETWORK
android.permission.ACCESS_NETWORK_STATE
android.permission.ACCESS_WIFI_STATE
android.permission.CAMERA
android.permission.CHANGE_WIFI_MULTICAST_STATE
android.permission.INTERNET
android.permission.READ_EXTERNAL_STORAGE
android.permission.SYSTEM_ALERT_WINDOW
android.permission.VIBRATE
android.permission.WRITE_EXTERNAL_STORAGE
org.example.planner.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION
```

**Lá está o `CAMERA`, vindo do manifest do próprio `expo-image-picker`**, que também declara as duas
permissões antigas de armazenamento, para ninguém ter de lembrar delas. `ACCESS_NETWORK_STATE` e
`ACCESS_WIFI_STATE` são do NetInfo, da aula 10, que lê a conexão. `ACCESS_LOCAL_NETWORK` e
`CHANGE_WIFI_MULTICAST_STATE` vêm de manifests só de debug, o do React Native e o do development build,
que procuram o Metro na rede local. O `RECORD_AUDIO` não aparece em lugar nenhum: é a remoção do plugin
funcionando. A última linha não é do Android, e sim do próprio app, com o nome do pacote, que uma
biblioteca declara para proteger um broadcast receiver.

**Esta é a lista do build de debug.** As entradas só de desenvolvimento vêm de manifests que o Gradle
junta num build de debug e não num de release; *a aula 20 constrói um release, e este curso não comparou
as duas listas*. O que uma loja mostra em *este app pode* é a lista juntada do build de release, então é
essa a lista a ler antes de publicar, nunca a da pasta gerada.

**As pastas são geradas, então nada disso é editado à mão**: o próximo `prebuild --clean` desfaria a
edição, como a aula 2 mostrou. Uma permissão é acrescentada ou removida no `app.json`, pelas opções de um
plugin.
