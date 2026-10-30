---
title: Um build de release, e de quem é a chave que ele leva
version: 1
---

A aula 3 construiu um APK de debug. Um build de release é o mesmo comando com `Release` nele, e difere no que
a aula 18 descreveu: bytecode do Hermes dentro, nada de Metro, nenhuma conferência de desenvolvimento. Gere o
projeto nativo e construa um, sem dizer mais nada:

```
ana@dev:~/planner$ npx expo prebuild --platform android --clean --no-install > /dev/null 2>&1
ana@dev:~/planner/android$ ./gradlew :app:assembleRelease -PreactNativeArchitectures=arm64-v8a -q > /dev/null 2>&1
ana@dev:~/planner/android$ $ANDROID_HOME/build-tools/37.0.0/apksigner verify --print-certs app/build/outputs/apk/release/app-release.apk | head -2
V2 Signer: certificate DN: CN=Android Debug, OU=Android, O=Unknown, L=Unknown, ST=Unknown, C=US
V2 Signer: certificate SHA-256 digest: fac61745dc0903786fb9ede62a962b399f7348f0bb6f899b8332667591033b9c
```

**`CN=Android Debug`: o release está assinado com a chave de debug.** O modelo do Expo faz isso de
propósito, para um release construir em qualquer máquina sem keystore; tudo bem para experimentar um release
no seu próprio celular, e o Google Play o recusa. A chave de debug de cada desenvolvedor é diferente e gerada
na máquina dele, então um app assinado com uma também nunca poderia ser atualizado por outra pessoa.

## A sua chave, sem editar um arquivo gerado

As instruções de costume mandam editar o `android/app/build.gradle` e acrescentar uma `signingConfig`. Aqui
esse arquivo é gerado, e a regra da aula 2 vale: o próximo `prebuild --clean` apagaria a edição. O plugin
Android do Gradle aceita os dados da assinatura como propriedades na linha de comando, as mesmas que o
Android Studio passa quando constrói um app assinado, então nada gerado precisa mudar:

```
ana@dev:~/planner/android$ ./gradlew :app:assembleRelease :app:bundleRelease -PreactNativeArchitectures=arm64-v8a -Pandroid.injected.signing.store.file=$HOME/planner-upload.p12 -Pandroid.injected.signing.store.password="$PLANNER_KEY_PASSWORD" -Pandroid.injected.signing.key.alias=upload -Pandroid.injected.signing.key.password="$PLANNER_KEY_PASSWORD" -q > /dev/null 2>&1
ana@dev:~/planner/android$ $ANDROID_HOME/build-tools/37.0.0/apksigner verify --print-certs app/build/outputs/apk/release/app-release.apk | head -2
V2 Signer: certificate DN: CN=Ana, O=Study planner, C=BR
V2 Signer: certificate SHA-256 digest: fed628dbaf749965c2d49a53619fe9bd9e460fe49bf6bf61e9a2a13d654f641f
ana@dev:~/planner/android$ keytool -printcert -jarfile app/build/outputs/bundle/release/app-release.aab | grep -E "Owner|SHA256:"
Owner: CN=Ana, O=Study planner, C=BR
	 SHA256: FE:D6:28:DB:AF:74:99:65:C2:D4:9A:53:61:9F:E9:BD:9E:46:0F:E4:9B:F6:BF:61:E9:A2:A1:3D:65:4F:64:1F
ana@dev:~/planner/android$ du -h app/build/outputs/apk/release/app-release.apk app/build/outputs/bundle/release/app-release.aab
33M	app/build/outputs/apk/release/app-release.apk
25M	app/build/outputs/bundle/release/app-release.aab
ana@dev:~/planner/android$ unzip -p app/build/outputs/apk/release/app-release.apk assets/index.android.bundle | head -c 64 | file -
/dev/stdin: Hermes JavaScript bytecode, version 99
```

- **Os dois artefatos levam a chave de upload**: o APK, que o `apksigner` confere, e o **AAB**, o *Android
  App Bundle*, que o `keytool` lê. As impressões digitais são as que a keystore listou.
- **O AAB é o que o Google Play aceita.** Ele tem todas as arquiteturas e todas as densidades de tela, e o
  Play monta a partir dele o APK de que cada celular precisa. O APK é para instalar direto, no seu celular ou
  no de quem testa.
- **O JavaScript lá dentro é bytecode do Hermes**, o `assets/index.android.bundle`, compilado na hora do
  build.
- **33 megabytes, contra os 91 do build de debug** da aula 17: nenhum suporte a depuração, e bibliotecas
  nativas sem o que um depurador precisaria.

O `$PLANNER_KEY_PASSWORD` fica entre aspas duplas para o shell o expandir; a senha nunca aparece no comando.
Num servidor de build, as mesmas variáveis vêm dos segredos do servidor.
