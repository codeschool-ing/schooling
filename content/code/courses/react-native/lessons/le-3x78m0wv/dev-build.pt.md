---
title: Um development build para Android, no seu computador
version: 1
---

**Um development build é o seu app compilado com o próprio código nativo**, mais o `expo-dev-client`
para que ele carregue JavaScript do servidor de desenvolvimento do jeito que o Expo Go faz. A aula 2
disse por que você acaba precisando de um. Esta seção o constrói para Android no computador, o que
pede mais duas ferramentas e nenhuma conta em lugar nenhum.

## Duas ferramentas: um JDK e o Android SDK

**O Gradle precisa de Java, e o plugin Gradle do React Native 0.88 pede o Java 17.** No Ubuntu, e no WSL:

```sh
sudo apt install openjdk-17-jdk-headless
```

**O Android SDK** são os compiladores, as bibliotecas da plataforma e as ferramentas de empacotamento. O
Android Studio o instala, com o emulador, e no macOS e no Windows esse é o caminho mais simples; a
página *Set up your environment* do React Native passa por ele em cada sistema. No Linux ele também pode
ser instalado sem o Android Studio: baixe o *Command line tools only* para Linux na página de download do
Android Studio, `commandlinetools-linux-16111833_latest.zip` no dia em que isto foi gravado, e
descompacte-o onde o Android Studio teria posto o SDK:

```sh
mkdir -p ~/Android/Sdk/cmdline-tools
unzip commandlinetools-linux-16111833_latest.zip -d ~/Android/Sdk/cmdline-tools
mv ~/Android/Sdk/cmdline-tools/cmdline-tools ~/Android/Sdk/cmdline-tools/latest
```

Depois diga ao shell onde fica cada coisa. Acrescente estas três linhas ao fim do `~/.bashrc`, e abra um
terminal novo:

```sh
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
export ANDROID_HOME=$HOME/Android/Sdk
export PATH=$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:$PATH
```

E peça ao `sdkmanager` as peças com que o React Native 0.88 compila. Ele mostra antes as licenças do
Google, e nada se instala até você aceitá-las:

```sh
sdkmanager --licenses
sdkmanager "platform-tools" "platforms;android-37.0" "build-tools;37.0.0" "ndk;27.1.12297006" "cmake;3.22.1"
```

**São 2,5 GB**, a maior parte do NDK, que compila a metade em C++ do React Native. As ferramentas de linha
de comando recentes imprimem um aviso de que o `sdkmanager` está dando lugar a um novo comando `android`;
na versão que este curso usou, o `sdkmanager` ainda instala tudo.

## Identificando o app

Antes do primeiro build nativo, dê ao app o nome e a identidade em cada loja, no `app.json`, como fez a
aula 2: troque `"name"` por `"Study planner"`, e acrescente `"package": "org.example.planner"` dentro de
`"android"` e `"bundleIdentifier": "org.example.planner"` dentro de `"ios"`. Depois gere o projeto
Android:

```
ana@dev:~/planner$ grep -nE "\"(name|package|bundleIdentifier)\"" app.json
3:    "name": "Study planner",
11:      "bundleIdentifier": "org.example.planner"
21:      "package": "org.example.planner"
ana@dev:~/planner$ npx expo prebuild --platform android --no-install > /dev/null 2>&1
ana@dev:~/planner$ grep applicationId android/app/build.gradle
        applicationId 'org.example.planner'
```

## Compilando

O projeto Android é um projeto Gradle, e o Gradle vem com ele como um script de embrulho, o `./gradlew`,
que baixa a versão certa do Gradle na primeira vez. O `assembleDebug` constrói um APK de debug, um pacote
instalável assinado com uma chave que serve só para desenvolvimento:

```
ana@dev:~/planner$ cd android
ana@dev:~/planner/android$ ./gradlew assembleDebug -PreactNativeArchitectures=arm64-v8a 2>&1 | tail -3

BUILD SUCCESSFUL in 2m 19s
446 actionable tasks: 446 executed
```

**O primeiro build é lento**, porque o Gradle baixa a própria distribuição e cada biblioteca, e o NDK
compila o C++ do React Native. Os builds seguintes reaproveitam quase tudo: o tempo acima foi medido
num computador cujos caches do Gradle um build anterior já tinha enchido, e o primeiríssimo build no seu
vai demorar mais. O `-PreactNativeArchitectures` limita o C++ a uma família de processador:
`arm64-v8a` é quase todo celular vendido nos últimos anos, e `x86_64` é um emulador num computador Intel
ou AMD. Deixá-lo de fora compila as quatro famílias, que é o que um release precisa e leva várias vezes
mais tempo.

## O que saiu

```
ana@dev:~/planner/android$ ls -lh app/build/outputs/apk/debug/
total 64M
-rw-r--r-- 1 ana ana 64M Oct 30 15:28 app-debug.apk
-rw-r--r-- 1 ana ana 403 Oct 30 15:28 output-metadata.json
ana@dev:~/planner/android$ ~/Android/Sdk/build-tools/37.0.0/aapt2 dump badging app/build/outputs/apk/debug/app-debug.apk | grep -E "^(package|minSdkVersion|targetSdkVersion|application-label:|native-code)"
package: name='org.example.planner' versionCode='1' versionName='1.0.0' platformBuildVersionName='17' platformBuildVersionCode='37' compileSdkVersion='37' compileSdkVersionCodename='17'
minSdkVersion:'24'
targetSdkVersion:'36'
application-label:'Study planner'
native-code: 'arm64-v8a'
ana@dev:~/planner/android$ unzip -l app/build/outputs/apk/debug/app-debug.apk | grep -cE "index.android.bundle"
0
ana@dev:~/planner/android$ unzip -l app/build/outputs/apk/debug/app-debug.apk | grep -E "libhermes|libreactnative"
   568952  1981-01-01 01:01   lib/arm64-v8a/libhermestooling.so
  4021008  1981-01-01 01:01   lib/arm64-v8a/libhermesvm.so
 24062944  1981-01-01 01:01   lib/arm64-v8a/libreactnative.so
```

O `aapt2`, das build tools, lê o pacote sem instalá-lo. O nome do pacote e o rótulo são os que o
`app.json` definiu. O app foi compilado contra o Android 17 (API 37), roda no Android 7.0 (API 24) em
diante, e tem como alvo o Android 16 (API 36), que é o nível pelo qual a loja o julga. O código nativo é
só para `arm64-v8a`, como pedido. **64 MB é o que pesa um build de debug**, e a aula 20 põe o build de
release ao lado dele.

As duas últimas linhas dizem algo sobre o que é um build de *desenvolvimento*. **Não há bundle
JavaScript dentro dele**: o `index.android.bundle` não aparece em lugar nenhum, porque um build de debug
busca o JavaScript no servidor de desenvolvimento toda vez que começa, exatamente como o `curl` da seção
do Metro fez. O Hermes e o C++ do React Native estão dentro, como bibliotecas `.so`. A aula 20 constrói a
variante de release, que traz o bundle em bytecode e roda sem servidor nenhum.

## Instalando

*Instalar este APK num emulador ou num celular não foi feito para este curso: o computador em que ele foi
gravado não tinha nenhum dos dois.* Com um celular Android ligado por USB, com as opções de
desenvolvedor e a depuração USB ativadas, ou com um emulador rodando, o `npx expo run:android` compila,
instala e abre o app num comando só, e o `adb install app/build/outputs/apk/debug/app-debug.apk` instala
um build que você já tem. O app abre numa tela que lista os servidores de desenvolvimento que ele
alcança; com o `npx expo start` rodando na mesma rede, escolha-o, e o planner carrega.
