---
title: O manifesto, e recursos entre os quais o celular escolhe
version: 1
---

**O manifesto é o que o celular lê antes de rodar uma linha do seu código.** Ele diz como o app se
chama, qual activity abre quando alguém toca no ícone, quais permissões ele quer e quais versões do
Android ele aceita. O celular, a Play Store e toda ferramenta que inspeciona um app o leem, e nenhum
deles lê o seu Kotlin.

## O manifesto que você escreveu, e o que é entregue

O arquivo da seção 05 tem um `<application>` com uma `<activity>`. Dois atributos sustentam tudo:

- `android:exported="true"` diz que outro app pode iniciar esta activity. O launcher é outro app,
  então a activity que o ícone abre precisa ser exportada; todas as outras deveriam dizer `false`.
  Desde o Android 12 o atributo é obrigatório em qualquer activity com um `<intent-filter>`, e o
  build recusa um manifesto sem ele.
- O `<intent-filter>` com `MAIN` e `LAUNCHER` é o que põe um ícone na tela inicial. Um app pode ter
  várias activities; só as que têm esse filtro ganham ícone.

**O que é entregue não é o arquivo que você escreveu.** Toda biblioteca pode trazer um manifesto
próprio, e o build junta todos com o seu. O resultado está no diretório de build:

```
ana@vm:~/planner$ sed -n 1,20p app/build/intermediates/merged_manifest/debug/processDebugMainManifest/AndroidManifest.xml
<?xml version="1.0" encoding="utf-8"?>
<!-- app/src/main/AndroidManifest.xml -->
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.example.planner"
    android:versionCode="1"
    android:versionName="0.1.0" >

    <uses-sdk
        android:minSdkVersion="26"
        android:targetSdkVersion="36" />

    <permission
        android:name="com.example.planner.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION"
        android:protectionLevel="signature" />

    <uses-permission android:name="com.example.planner.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION" />

    <application
        android:appComponentFactory="androidx.core.app.CoreComponentFactory"
        android:debuggable="true"
```

Chegaram três coisas que você não escreveu. `<uses-sdk>` traz `minSdk` e `targetSdk` do arquivo de
build, que é onde eles ficam hoje. `package` é o `namespace`. E uma permissão com o nome do seu
próprio app, `DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`, veio de `androidx.core`, que a usa para
manter privados os seus broadcast receivers. **Leia o manifesto combinado sempre que acrescentar uma
biblioteca**: é ali que uma dependência pede uma permissão que você nunca quis pedir.

## Recursos, e a classe `R`

Textos, cores, imagens e dimensões moram em `res/`, fora do código, para que o celular possa escolher
entre versões deles. `values/strings.xml` guarda as strings no idioma padrão. Acrescente uma pasta
com um **qualificador** no nome, e os mesmos nomes ganham outros valores nas condições que o
qualificador indica:

```xml
<!-- app/src/main/res/values-pt/strings.xml -->
<resources>
    <string name="welcome">Nenhum curso ainda. Adicione o primeiro.</string>
</resources>
```

`values-pt` é escolhida num celular cujo idioma é o português. `app_name` não está nela, então um
celular em português cai no padrão, `Planner`, uma string de cada vez. O build compila as duas para
dentro do app, e o celular escolhe na hora de rodar:

```
ana@vm:~/planner$ ./gradlew --console=plain assembleDebug 2>&1 | grep -E "^BUILD"
BUILD SUCCESSFUL in 2s
ana@vm:~/planner$ $ANDROID_HOME/build-tools/36.1.0/aapt2 dump resources app/build/outputs/apk/debug/app-debug.apk | grep -A2 "string/welcome"
    resource 0x7f080063 string/welcome
      () "No courses yet. Add the first one."
      (pt) "Nenhum curso ainda. Adicione o primeiro."
ana@vm:~/planner$ grep -E "string (app_name|welcome)" app/build/intermediates/runtime_symbol_list/debug/processDebugResources/R.txt
int string app_name 0x7f080003
int string welcome 0x7f080063
```

`aapt2 dump resources` mostra o recurso único com os dois valores e a configuração de cada um: `()`
é o padrão e `(pt)` é o português. O número `0x7f...` é o **id** do recurso, e o build escreve uma
constante por recurso numa classe gerada, `R`. É isso que `R.string.welcome` em `MainActivity.kt`
nomeia: um inteiro, resolvido para uma string no celular.

**O mesmo mecanismo escolhe por muito mais do que o idioma.** `values-night` guarda cores para o modo
escuro (aula 7), `drawable-xxhdpi` guarda imagens para telas densas, e `values-sw600dp` guarda
dimensões para telas com pelo menos 600 dp de largura, que é um tablet. O celular confere a própria
configuração contra cada pasta e fica com a correspondência mais específica.

**Uma string no código é uma string que ninguém consegue traduzir.** `Text("No courses yet")` compila
e funciona, e fica em inglês em todo celular. Daqui em diante este curso escreve os textos do planner
no `strings.xml`.
