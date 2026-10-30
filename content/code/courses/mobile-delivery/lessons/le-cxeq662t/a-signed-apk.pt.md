---
title: Uma chave, e um pacote assinado com ela
version: 1
---

**Um APK assinado leva quatro passos, e o Android Studio esconde todos atrás de um item de menu.**
Fazê-los à mão uma vez é o que torna legível a configuração do Gradle do seu app de verdade: você
cria uma chave, gera um pacote, alinha, assina, e depois pergunta a uma segunda ferramenta se a
assinatura se sustenta. Trabalhe numa pasta própria, `~/signing`, longe do código do planner.

## A chave

A chave mora num **keystore**, um arquivo protegido por senha que pode guardar várias chaves, cada
uma sob um nome chamado **alias**. O `keytool` vem com o JDK. Não digite a senha no comando, onde o
histórico do shell a guarda; leia-a para uma variável, e o keytool e o apksigner sabem buscá-la
ali:

```sh
read -rs UPLOAD_PASS && export UPLOAD_PASS
```

Digite a senha e tecle Enter; nada aparece na tela. Depois crie a chave: RSA com 4096 bits e
**10.000 dias de validade**, um pouco mais de 27 anos. O certificado tem de durar mais do que o
app. A documentação do Google recomenda 25 anos ou mais, e o Google Play recusa uma chave cuja
validade termina antes de 22 de outubro de 2033. O `-dname` é o nome gravado no certificado;
ninguém o confere, e ele só serve para uma pessoa ler:

```
ana@dev:~/signing$ keytool -genkeypair -keystore upload.jks -storetype PKCS12 -alias upload -keyalg RSA -keysize 4096 -validity 10000 -dname "CN=Ana Souza, O=Study Planner, C=BR" -storepass:env UPLOAD_PASS
Generating 4,096 bit RSA key pair and self-signed certificate (SHA384withRSA) with a validity of 10,000 days
	for: CN=Ana Souza, O=Study Planner, C=BR
ana@dev:~/signing$ keytool -list -keystore upload.jks -storepass:env UPLOAD_PASS
Keystore type: PKCS12
Keystore provider: SUN

Your keystore contains 1 entry

upload, Oct 30, 2026, PrivateKeyEntry, 
Certificate fingerprint (SHA-256): 65:88:A1:69:B6:81:48:9F:04:E1:90:EA:72:3E:9B:77:82:4A:06:B4:92:68:17:B8:F1:FD:24:65:AA:2F:47:95
```

As datas do certificado vieram do relógio do computador que o criou, então o seu vai mostrar o dia
em que você o rodou.

## O pacote

Um app de verdade é gerado pelo Gradle. Para ver a assinatura sozinha, o pacote aqui é o menor que
o Android aceita: um manifesto e mais nada. O `android:hasCode="false"` avisa o sistema de que não
há código compilado para procurar. O nome do pacote é a identidade do app na loja e nunca pode
mudar depois de publicado. Salve isto como `AndroidManifest.xml`:

```xml
<!-- AndroidManifest.xml -->
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.example.planner"
    android:versionCode="1"
    android:versionName="1.0.0">
  <application android:label="Study Planner" android:hasCode="false" />
</manifest>
```

O `aapt2 link` compila o manifesto contra o `android.jar` da plataforma num APK. **O `zipalign` vem
antes da assinatura**, porque a assinatura cobre os bytes do arquivo e movê-los depois a quebraria.
Então o `apksigner sign` assina, e o tamanho do resultado mostra que a assinatura entrou:

```
ana@dev:~/signing$ aapt2 link -o planner-unsigned.apk --manifest AndroidManifest.xml -I $ANDROID_HOME/platforms/android-36/android.jar --min-sdk-version 24 --target-sdk-version 36
ana@dev:~/signing$ zipalign -p -f 4 planner-unsigned.apk planner-aligned.apk
ana@dev:~/signing$ apksigner sign --ks upload.jks --ks-key-alias upload --ks-pass env:UPLOAD_PASS --out planner.apk planner-aligned.apk
ana@dev:~/signing$ ls -l *.apk
-rw-r--r-- 1 ana ana   763 Oct 30 14:46 planner-aligned.apk
-rw-r--r-- 1 ana ana   763 Oct 30 14:46 planner-unsigned.apk
-rw-r--r-- 1 ana ana 12630 Oct 30 14:46 planner.apk
```

## Perguntando se ela se sustenta

O `apksigner verify` é o que uma instalação faz, na sua mesa. Ele nomeia cada **esquema de
assinatura** que conferiu. O esquema v1 é a assinatura JAR antiga, mantida para Androids anteriores
ao 7.0; o v2 e o v3 assinam o arquivo inteiro, e o v3 acrescenta o registro que permite trocar a
chave. O SDK mínimo do pacote é 24, que é o Android 7.0, então o apksigner pulou o v1:

```
ana@dev:~/signing$ apksigner verify --verbose --print-certs planner.apk
Verifies
Verified using v1 scheme (JAR signing): false
Verified using v2 scheme (APK Signature Scheme v2): true
Verified using v3 scheme (APK Signature Scheme v3): true
Verified using v3.1 scheme (APK Signature Scheme v3.1): false
Verified using v4 scheme (APK Signature Scheme v4): false
Verified for SourceStamp: false
Number of signers: 1
Signer #1 certificate DN: CN=Ana Souza, O=Study Planner, C=BR
Signer #1 certificate SHA-256 digest: 6588a169b681489f04e190ea723e9b77824a06b4926817b8f1fd2465aa2f4795
Signer #1 certificate SHA-1 digest: deec87bdddfa2baab2750129c3caf4b34c4e2c93
Signer #1 certificate MD5 digest: fd96abbb27fe11fa950843bc5d1272b3
Signer #1 key algorithm: RSA
Signer #1 key size (bits): 4096
Signer #1 public key SHA-256 digest: 2e415dea2c4a838e70da6c5561946ce8126dba93ce6a0938cdb7e5f209c7025e
Signer #1 public key SHA-1 digest: 60f03bf87a3d9f21c6ef41ac32f0a84992852bd0
Signer #1 public key MD5 digest: f378440bd8429c794699d9dc6c05955c
```

**Anote o digest SHA-256 do certificado.** É a impressão digital que todo serviço do Google pede
quando precisa saber que um app é seu: Firebase, Maps, login com Google. O seu digest é diferente
do de cima, porque a sua chave é.

A mesma pergunta feita ao pacote antes da assinatura recebe uma recusa, que é o que um celular diz
a um app sem assinatura. Sem bloco v2 ou v3 no arquivo, o apksigner volta a procurar a assinatura
v1 antiga, e informa o primeiro arquivo dela que está faltando:

```
ana@dev:~/signing$ apksigner verify planner-aligned.apk
DOES NOT VERIFY
ERROR: Missing META-INF/MANIFEST.MF
```
