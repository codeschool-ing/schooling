---
title: O que há dentro de um APK
version: 1
---

**Um APK é um arquivo zip**, e vale abrir um antes de confiar em qualquer número sobre ele. O build
de debug da seção 06 tem 12 MB para uma frase numa tela, e esse tamanho tem um motivo que dá para
ver:

```
ana@vm:~/planner/app/build/outputs/apk/debug$ unzip -l app-debug.apk | tail -1
 29821170                     120 files
ana@vm:~/planner/app/build/outputs/apk/debug$ unzip -l app-debug.apk | grep -E "classes[0-9]*\.dex|AndroidManifest|resources.arsc"
 18634372  1981-01-01 01:01   classes.dex
    41316  1981-01-01 01:01   classes2.dex
     7348  1981-01-01 01:01   classes3.dex
   119604  1981-01-01 01:01   classes4.dex
 10370792  1981-01-01 01:01   classes5.dex
     5772  1981-01-01 01:01   AndroidManifest.xml
   474184  1981-01-01 01:01   resources.arsc
```

Cinco arquivos chamados `classes*.dex` guardam o código, quase nada dele seu. **Dex** é o bytecode do
Android. O build compila Kotlin para classes da JVM como qualquer build Kotlin, e depois uma
ferramenta chamada **D8** as converte em dex, que é o que o runtime do Android executa. Um arquivo
dex guarda no máximo 65.536 referências a métodos, então um build com mais do que isso as espalha
por vários; é por isso que são cinco. `resources.arsc` é a tabela compilada dos recursos da seção
07, e `AndroidManifest.xml` é o manifesto combinado, em forma binária.

O `aapt2`, das build tools, lê o que o celular leria primeiro:

```
ana@vm:~/planner/app/build/outputs/apk/debug$ $ANDROID_HOME/build-tools/36.1.0/aapt2 dump badging app-debug.apk | head -5
package: name='com.example.planner' versionCode='1' versionName='0.1.0' platformBuildVersionName='17' platformBuildVersionCode='37' compileSdkVersion='37' compileSdkVersionCodename='17'
minSdkVersion:'26'
targetSdkVersion:'36'
uses-permission: name='com.example.planner.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION'
application-label:'Planner'
```

O nome do pacote, as duas versões do `defaultConfig`, os números do SDK e o rótulo. Toda loja e todo
instalador começam por aqui.

A Android CLI lê tudo e diz o que acha:

```
ana@vm:~/planner/app/build/outputs/apk/debug$ android analyze app-debug.apk 2>&1 | sed -e "s/.*\r//" | grep -v "^Downloading"
Basic info:
 - Package Name: com.example.planner
 - Version Name: 0.1.0
 - Version Code: 1

Optimization info:
 Warnings:
    * This app has an extremely low rate of dex optimization, with at least one key optimization type enabled on less than 25% of its dex code.

 - AGP Version: 9.5.0
 - Uncompressed Dex Size: 29173432 bytes (27.82 MB)
 - Dex Marker Metadata: R8 Enabled=false, D8 Enabled=true, Full Mode=false
 - Dex Heuristic Obfuscation: 0.80%
```

**"An extremely low rate of dex optimization"** está correto e era esperado. `R8 Enabled=false` diz
por quê: um build de debug pula o otimizador para compilar depressa e para um depurador ver cada
linha. Os 27,82 MB de dex descompactado são o total de cada biblioteca da qual o app depende, usada
ou não. A aula 22 liga o R8 no build de release e mede o mesmo arquivo de novo.

## A assinatura de debug

Um celular só instala um APK assinado, e este está assinado embora você nunca tenha criado uma
chave. O primeiro build de debug cria `~/.android/debug.keystore`, uma chave com uma senha conhecida
por todos, e assina todo build de debug com ela. **Uma chave de debug é a mesma em toda máquina que
compila com ela, de propósito, e nunca é a que você usa para publicar.** A aula 22 cria a de
verdade, e explica por que perdê-la significa nunca mais atualizar o seu app.

## Instalando

**Não executado.** Com um celular ligado pelo USB e as opções de desenvolvedor ativadas, ou com um
emulador aberto, a documentação do Google instala o build de debug com `./gradlew installDebug`, ou
com `adb install app/build/outputs/apk/debug/app-debug.apk`, e o ícone chamado Planner aparece junto
dos outros. O `android run` da Android CLI compila, instala e abre o app num passo só. Nenhum dos
três pôde rodar na máquina de gravação, que não tinha aparelho; a seção 02 diz por quê.
