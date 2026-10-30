---
title: "A chave de upload, e a senha que não está em arquivo nenhum"
version: 1
---

**Um app é identificado pelo nome do pacote e pela chave que o assina**, e um celular só instala uma
atualização se ela estiver assinada pela mesma chave da versão já instalada. A aula 1, seção 08,
disse que a chave de debug é a mesma em toda máquina e nunca é aquela com que se publica. Esta seção
cria a chave com que você publicaria, e as próximas explicam por que no Google Play ela é uma chave
de *upload* e não a assinatura final do app.

## Criando a chave

O `keytool`, que vem com o JDK, cria um par de chaves e um certificado autoassinado dentro de um
**keystore**, um arquivo protegido por senha. A senha é o único segredo desta seção, então nunca deve
ser digitada como parte de um comando, onde o histórico do shell a guardaria. Leia-a para uma
variável exportada só para este terminal, que o `read -rs` não mostra na tela:

```sh
read -rs -p 'Upload key password: ' PLANNER_UPLOAD_PASSWORD && export PLANNER_UPLOAD_PASSWORD
```

Depois crie um diretório fora de qualquer projeto, e a chave dentro dele:

```
ana@vm:~/planner$ mkdir -p ~/keys && chmod 700 ~/keys
ana@vm:~/planner$ keytool -genkeypair -keystore ~/keys/planner-upload.jks -alias upload -keyalg RSA -keysize 4096 -validity 9125 -dname 'CN=Ana Example, O=Example, C=BR' -storepass:env PLANNER_UPLOAD_PASSWORD -keypass:env PLANNER_UPLOAD_PASSWORD
Generating 4,096 bit RSA key pair and self-signed certificate (SHA384withRSA) with a validity of 9,125 days
	for: CN=Ana Example, O=Example, C=BR
ana@vm:~/planner$ keytool -list -v -keystore ~/keys/planner-upload.jks -storepass:env PLANNER_UPLOAD_PASSWORD | grep -E 'Alias name|Keystore type|Owner|Valid from|SHA256:|Key Algorithm'
Keystore type: PKCS12
Alias name: upload
Owner: CN=Ana Example, O=Example, C=BR
Valid from: Fri Oct 30 17:41:09 BRT 2026 until: Tue Oct 24 17:41:09 BRT 2051
	 SHA256: 40:8B:D0:9B:F6:37:4A:DC:56:58:1B:D5:3B:9B:A8:B1:55:DA:DA:E1:E4:01:FE:9F:CB:35:2C:D5:20:CF:41:B1
Subject Public Key Algorithm: 4096-bit RSA key
```

`-storepass:env` diz ao `keytool` para ler a senha da variável de ambiente e não da linha de comando.
A chave é RSA, de 4.096 bits, e vale por 9.125 dias, que são 25 anos: **a documentação do Google
sobre assinatura de apps recomenda uma validade de pelo menos 25 anos**, porque um app assinado por
uma chave vencida não pode ser atualizado. A linha `SHA256` é a impressão digital do certificado, a
forma curta da chave que o Google Play e a restrição de uma chave de API pediriam.

**Este arquivo e a senha dele são a identidade do app.** Guarde uma cópia dos dois em algum lugar que
não seja este computador, e nunca faça commit de nenhum deles: o arquivo de build da seção 02 aponta
um caminho dentro da sua pasta pessoal justamente para que o keystore nunca fique dentro do projeto.

## O build lê a senha do ambiente

A configuração de assinatura `upload` da seção 02 lê `PLANNER_UPLOAD_PASSWORD` com
`providers.environmentVariable`. Num terminal onde a variável nunca foi definida, um build de release
para antes de assinar qualquer coisa:

```
ana@vm:~/planner$ ./gradlew --console=plain assemblePlayRelease 2>&1 | grep -E -A2 'What went wrong'
* What went wrong:
Execution failed for task ':app:validateSigningPlayRelease' (registered by plugin 'com.android.internal.application').
> Keystore file not set for signing config upload
```

**A mensagem culpa o arquivo do keystore, e o arquivo está lá**: o que falta é a senha, e a validação
do plugin a relata sob o nome do arquivo. Quando um build de release falha em `validateSigning`,
confira o ambiente primeiro.

No terminal onde o `read` definiu a variável, o release é construído:

```
ana@vm:~/planner$ ./gradlew --console=plain assembleRelease bundlePlayRelease 2>&1 | grep -E '^BUILD|actionable'
BUILD SUCCESSFUL in 1m 16s
110 actionable tasks: 79 executed, 31 up-to-date
ana@vm:~/planner$ find app/build/outputs -name "*release*.apk" -o -name "*.aab" | sort | xargs ls -l
-rw-r--r-- 1 ana ana  757890 Oct 30 17:42 app/build/outputs/apk/direct/release/app-direct-release.apk
-rw-r--r-- 1 ana ana  757882 Oct 30 17:42 app/build/outputs/apk/play/release/app-play-release.apk
-rw-r--r-- 1 ana ana 1775458 Oct 30 17:42 app/build/outputs/bundle/playRelease/app-play-release.aab
```

## Quem assinou o quê

O `apksigner`, das build tools, lê a assinatura de um APK:

```
ana@vm:~/planner$ $ANDROID_HOME/build-tools/36.1.0/apksigner verify --print-certs app/build/outputs/apk/play/release/app-play-release.apk | grep -E 'DN|SHA-256'
Signer #1 certificate DN: CN=Ana Example, O=Example, C=BR
Signer #1 certificate SHA-256 digest: 408bd09bf6374adc56581bd53b9ba8b155dadae1e401fe9fcb352cd520cf41b1
ana@vm:~/planner$ $ANDROID_HOME/build-tools/36.1.0/apksigner verify --print-certs app/build/outputs/apk/play/debug/app-play-debug.apk | grep -E 'DN|SHA-256'
Signer #1 certificate DN: C=US, O=Android, CN=Android Debug
Signer #1 certificate SHA-256 digest: 4ad6a4e45969a0273254430560e6575336e34abc4d8256a826af6301f38c250d
```

O APK de release está assinado pela chave da Ana, com a impressão digital que o `keytool` mostrou. O
APK de debug está assinado por `CN=Android Debug`, a chave de debug da aula 1. **Sem o sufixo da
seção 02, um celular com o build de debug recusaria o build de release como atualização**, porque os
certificados diferem, e o build de debug teria de ser desinstalado antes, levando os dados junto. Com
o sufixo são dois apps com dois nomes de pacote, e a questão nem aparece.
