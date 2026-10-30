---
title: Por dentro do projeto Android
version: 1
---

**Um app Android é descrito por um arquivo, o `AndroidManifest.xml`, e construído pelo Gradle a partir
dos arquivos em volta dele.** O projeto do Capacitor é pequeno o bastante para ler inteiro, e lê-lo
uma vez diz onde vai cada mudança futura: uma permissão na aula 4, um ícone na aula 13, uma versão na
aula 15. Primeiro o manifesto:

```
ana@dev:~/planner$ cat android/app/src/main/AndroidManifest.xml
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <application
        android:allowBackup="true"
        android:icon="@mipmap/ic_launcher"
        android:label="@string/app_name"
        android:roundIcon="@mipmap/ic_launcher_round"
        android:supportsRtl="true"
        android:theme="@style/AppTheme">

        <activity
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|locale|smallestScreenSize|screenLayout|uiMode|navigation|density"
            android:name=".MainActivity"
            android:label="@string/title_activity_main"
            android:theme="@style/AppTheme.NoActionBarLaunch"
            android:launchMode="singleTask"
            android:exported="true">

            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>

        </activity>

        <provider
            android:name="androidx.core.content.FileProvider"
            android:authorities="${applicationId}.fileprovider"
            android:exported="false"
            android:grantUriPermissions="true">
            <meta-data
                android:name="android.support.FILE_PROVIDER_PATHS"
                android:resource="@xml/file_paths"></meta-data>
        </provider>
    </application>

    <!-- Permissions -->

    <uses-permission android:name="android.permission.INTERNET" />
</manifest>
```

- **`<application>`** é o app: o ícone, o nome (`@string/app_name`, uma referência a um texto
  definido em outro arquivo) e o tema.
- **`<activity>`** é uma tela. Este app tem uma, a `MainActivity`, e o `intent-filter` com `MAIN` e
  `LAUNCHER` é o que a põe na tela inicial. `exported="true"` deixa o lançador, que é outro app,
  iniciá-la.
- **`<provider>`** deixa o app compartilhar um arquivo com outro app sem entregar o próprio
  armazenamento; o plugin de câmera da aula 4 o usa.
- **`<uses-permission>`** lista o que o app pode fazer. O Capacitor pede uma, `INTERNET`, de que até
  um app que só carrega os próprios arquivos precisa, porque a WebView é um cliente de rede. Cada
  plugin que vai além acrescenta uma linha aqui, e a aula 4 as acrescenta.

A única tela é uma linha de Java:

```
ana@dev:~/planner$ cat android/app/src/main/java/com/example/studyplanner/MainActivity.java
package com.example.studyplanner;

import com.getcapacitor.BridgeActivity;

public class MainActivity extends BridgeActivity {}
ana@dev:~/planner$ grep -E "applicationId|versionCode|versionName" android/app/build.gradle
        applicationId "com.example.studyplanner"
        versionCode 1
        versionName "1.0"
ana@dev:~/planner$ head -n 5 android/variables.gradle
ext {
    minSdkVersion = 24
    compileSdkVersion = 36
    targetSdkVersion = 36
    androidxActivityVersion = '1.11.0'
```

**A `BridgeActivity` é do Capacitor.** Ela abre a WebView, carrega os seus arquivos e inicia a ponte,
então a activity do próprio app não tem nada a acrescentar. A aula 5 é a primeira vez que algo entra
entre essas chaves. As outras linhas são a identidade e a versão do app: `applicationId` é o `appId`
da aula 2, e `versionCode` e `versionName` são o assunto da aula 15. O `variables.gradle` guarda as
versões do Android para as quais o app é construído: **`minSdkVersion = 24`** é o Android mais antigo
em que ele se instala, o Android 7.0, e `compileSdkVersion` e `targetSdkVersion` são o mais novo contra
o qual ele é construído e testado. O Google Play sobe o seu mínimo de `targetSdkVersion` todo ano, então
um app que não é reconstruído com um Capacitor mais novo acaba sem conseguir publicar uma atualização.
