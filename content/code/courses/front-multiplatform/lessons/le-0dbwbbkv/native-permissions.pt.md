---
title: O lado nativo de cada permissão
version: 1
---

**Toda permissão que a web pediu nesta aula tem que ser declarada também nos projetos nativos**, ou o
celular a recusa, ou no iOS fecha o app. Alguns plugins declaram as próprias. O Gradle junta o manifesto
Android de um plugin ao do app quando constrói, então uma permissão que o manifesto de um plugin traz
não exige nada de você:

```
ana@dev:~/planner$ grep -c uses-permission node_modules/@capacitor/*/android/src/main/AndroidManifest.xml
node_modules/@capacitor/camera/android/src/main/AndroidManifest.xml:0
node_modules/@capacitor/filesystem/android/src/main/AndroidManifest.xml:0
node_modules/@capacitor/geolocation/android/src/main/AndroidManifest.xml:0
node_modules/@capacitor/local-notifications/android/src/main/AndroidManifest.xml:4
node_modules/@capacitor/preferences/android/src/main/AndroidManifest.xml:0
```

**Só o `local-notifications` declara as próprias**, porque não funciona sem elas. O de geolocalização
não declara, e a documentação dele diz quais linhas acrescentar, porque só você sabe se o app precisa
de uma posição precisa ou de uma aproximada. Para o planner são as duas linhas de localização,
acrescentadas a `android/app/src/main/AndroidManifest.xml` embaixo da de `INTERNET`.

**O iOS não declara nada em nome de um plugin.** Toda pergunta que um app faz precisa de uma chave no
`Info.plist` com a frase que o diálogo mostra, e os revisores da Apple leem essas frases: uma vaga é
motivo comum de recusa, e uma frase dizendo o que a pessoa ganha é a que se deve escrever. Para o
planner, a câmera, a fototeca e a localização durante o uso, acrescentadas embaixo do `<dict>` em
`ios/App/App/Info.plist`. Os dois arquivos depois das edições:

```
ana@dev:~/planner$ grep -n uses-permission android/app/src/main/AndroidManifest.xml
40:    <uses-permission android:name="android.permission.INTERNET" />
41:    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
42:    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
ana@dev:~/planner$ grep -A1 UsageDescription ios/App/App/Info.plist
	<key>NSCameraUsageDescription</key>
	<string>To take a photo of your notes for a session.</string>
	<key>NSPhotoLibraryUsageDescription</key>
	<string>To attach a photo of your notes from your library.</string>
	<key>NSPhotoLibraryAddUsageDescription</key>
	<string>To save a photo of your notes to your library.</string>
	<key>NSLocationWhenInUseUsageDescription</key>
	<string>To show where you are studying, only when you ask.</string>
```

Notificações locais não precisam de chave no iOS: a pergunta é feita pelo sistema com o texto dele.
Depois construa, sincronize e faça o commit da aula inteira:

```
ana@dev:~/planner$ npm run build > /dev/null && npx cap sync > /dev/null
ana@dev:~/planner$ git add .
ana@dev:~/planner$ git commit -q -m "Keep the plan, export it, remind, locate and photograph"
ana@dev:~/planner$ git log --oneline -1
3d224de Keep the plan, export it, remind, locate and photograph
```

| plugin | Android, no `AndroidManifest.xml` | iOS, no `Info.plist` |
|---|---|---|
| Preferences | nada | nada |
| Filesystem, na `Data` | nada | nada |
| Local notifications | trazido pelo plugin | nada; o sistema pergunta |
| Geolocation | `ACCESS_COARSE_LOCATION`, `ACCESS_FINE_LOCATION` | `NSLocationWhenInUseUsageDescription` |
| Camera | nada para uma foto; linhas de armazenamento para a galeria em Android antigo | `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`, `NSPhotoLibraryAddUsageDescription` |

*Nada disto pôde ser testado num celular para este curso; a aula 3 diz por quê. As linhas são as que a
documentação de cada plugin, no `README.md` dele dentro da `node_modules`, dá para a versão 8.*
