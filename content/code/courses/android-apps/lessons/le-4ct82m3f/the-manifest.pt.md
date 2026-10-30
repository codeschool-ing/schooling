---
title: A permissão, e o HTTP sem criptografia que o Android recusa
version: 1
---

**Todo teste desta aula rodou na JVM, onde nada pergunta se o app pode usar a rede. Um celular
pergunta.** Um app Android só pode abrir um socket se o manifesto dele declarar a permissão
`INTERNET`. O manifesto do próprio planner nunca a declarou, e mesmo assim o manifesto combinado da
seção 07 da aula 1 a tem. O relatório da combinação diz de onde ela veio:

```
ana@vm:~/planner$ grep -A2 '^uses-permission#android.permission.INTERNET' app/build/outputs/logs/manifest-merger-debug-report.txt
uses-permission#android.permission.INTERNET
ADDED from [com.squareup.okhttp3:okhttp-android:5.5.1] /home/ana/.gradle/caches/9.8.2/transforms/58ebe4428bd93930cdb1773341c39660/transformed/okhttp/AndroidManifest.xml:8:5-67
	android:name
```

**Quem a trouxe foi o OkHttp.** O OkHttp 5 é publicado para Android como uma biblioteca com
manifesto próprio, `okhttp-android`, e esse manifesto pede `INTERNET` em nome do app. É exatamente o
caso de que a seção 07 da aula 1 avisou, uma dependência pedindo uma permissão, e desta vez é a que o
app precisa. Declare-a você mesmo assim: o manifesto do app deve dizer o que o app usa, e no dia em
que uma biblioteca deixar de pedir, um app que contava com ela falha na primeira requisição com uma
`SecurityException`. **Não executado**: essa falha precisa de um aparelho. Uma permissão declarada
duas vezes é combinada numa só, e o relatório passa a listar as duas origens. A linha vai no alto do
manifesto:

```xml
<!-- app/src/main/AndroidManifest.xml -->
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <uses-permission android:name="android.permission.INTERNET" />

    <application
        android:label="@string/app_name"
        android:theme="@android:style/Theme.Material.Light.NoActionBar">
        <activity
            android:name=".MainActivity"
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>

</manifest>
```

`INTERNET` é uma permissão **normal**: o sistema a concede na instalação e nunca mostra uma caixa de
diálogo ao estudante. A aula 20 é sobre o outro tipo, as que o estudante é perguntado.

## HTTP sem criptografia é recusado por padrão

A partir do `targetSdk` 28, o Android recusa tráfego **em texto claro**, `http://` em vez de
`https://`, a menos que o app diga o contrário. O planner mira o 36 e o servidor dele é `https://`,
então não há nada a dizer. O caso em que há é o desenvolvimento: um servidor rodando no seu próprio
computador, alcançado a partir do emulador em `10.0.2.2`, em geral fala HTTP simples. O jeito estreito
de permitir isso é uma **configuração de segurança de rede** que nomeia esse único endereço, no source
set `debug`, para que não possa chegar a um build de release:

```xml
<!-- app/src/debug/res/xml/network_security_config.xml -->
<network-security-config>
    <domain-config cleartextTrafficPermitted="true">
        <domain includeSubdomains="false">10.0.2.2</domain>
    </domain-config>
</network-security-config>
```

```xml
<!-- app/src/debug/AndroidManifest.xml -->
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application android:networkSecurityConfig="@xml/network_security_config" />
</manifest>
```

Um arquivo em `src/debug/` só participa do build de debug, e o segundo manifesto é combinado por cima
do principal, acrescentando um atributo. A aula 22 fala mais de source sets. As duas mudanças, no
manifesto combinado de debug:

```
ana@vm:~/planner$ ./gradlew --console=plain assembleDebug 2>&1 | grep -E "^BUILD"
BUILD SUCCESSFUL in 9s
ana@vm:~/planner$ grep -E 'android.permission.INTERNET|networkSecurityConfig' app/build/intermediates/merged_manifest/debug/processDebugMainManifest/AndroidManifest.xml
    <uses-permission android:name="android.permission.INTERNET" />
        android:networkSecurityConfig="@xml/network_security_config"
```

A alternativa bruta, `android:usesCleartextTraffic="true"` na aplicação, permite HTTP simples para
todo endereço em todo build, release incluído. É o que a maioria das respostas na web sugere, porque
funciona na hora, e é a configuração que deixa o Wi-Fi de um café ler o que o app envia.

**Não executado**: alcançar `10.0.2.2` a partir de um emulador precisa do emulador e de um servidor no
computador; a documentação do Google sobre a configuração de segurança de rede é a fonte dos dois
arquivos.
