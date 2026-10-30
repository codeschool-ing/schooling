---
title: Uma chave de upload para o Android
version: 1
---

**Uma chave Android mora num keystore, um arquivo protegido por senha, e o `keytool` cria um.** O `keytool` vem
com o Java, que a aula 3 instalou para as ferramentas do Android, então ele já está no seu computador. Guarde o
keystore **fora de todo projeto**, numa pasta que só você abre, para nenhum `git add .` alcançá-lo.

A senha também não deve parar no histórico do seu shell. Digite-a uma vez numa variável com o `read`, que não
mostra nada enquanto você digita, e passe ao `keytool` o nome da variável:

```sh
read -rs KEY_PASS && export KEY_PASS
```

Depois a chave: RSA, 4096 bits, válida por 10.000 dias, uns 27 anos; a documentação do Android pede pelo menos
25, para a chave durar mais que o app:

```
ana@dev:~$ mkdir -p ~/keys && chmod 700 ~/keys
ana@dev:~$ keytool -genkeypair -keystore ~/keys/planner-upload.jks -alias upload -keyalg RSA -keysize 4096 -validity 10000 -dname "CN=Ana, O=Study planner, C=BR" -storepass:env KEY_PASS
Generating 4,096 bit RSA key pair and self-signed certificate (SHA384withRSA) with a validity of 10,000 days
	for: CN=Ana, O=Study planner, C=BR
```

**`-alias upload`** dá nome à chave dentro do keystore, e `-dname` é o nome escrito no certificado dela: uma
pessoa ou uma organização, e um país. Ninguém confere isso num cadastro; é o que o certificado diz sobre você.
Listado, o keystore mostra a única coisa que vão pedir para você copiar no console do Google Play, a impressão
digital do certificado:

```
ana@dev:~$ keytool -list -keystore ~/keys/planner-upload.jks -storepass:env KEY_PASS
Keystore type: PKCS12
Keystore provider: SUN

Your keystore contains 1 entry

upload, Oct 23, 2026, PrivateKeyEntry, 
Certificate fingerprint (SHA-256): EE:C1:FE:3C:9F:7E:6F:69:82:F6:38:D4:04:BF:F8:8C:42:C1:79:FB:2E:DF:80:BF:FD:E4:B1:7F:4D:69:D7:64
ana@dev:~$ ls -l ~/keys
total 8
-rw-r--r-- 1 ana ana 4296 Oct 23 22:47 planner-upload.jks
```

**A impressão digital identifica a chave sem revelá-la**, então pode ir num pedido de suporte, numa tela de
configuração ou num documento. O arquivo do keystore e a senha dele são as duas coisas que não podem ir a lugar
nenhum. O arquivo só é legível por você porque a pasta é `700`; num computador compartilhado, faça também
`chmod 600` no arquivo.

## Guarde, duas vezes

**Faça backup do keystore em dois lugares, e da senha junto**, num gerenciador de senhas, por exemplo, e não no
mesmo lugar do arquivo. Com o Play App Signing, uma chave de upload perdida pode ser substituída; um APK que você
mesmo distribui não tem esse resgate, e a chave é a identidade do app enquanto ele existir.

O repositório do planner também se recusa a levar uma por acidente. Estas três linhas no `.gitignore` cobrem um
keystore copiado para dentro do projeto e o arquivo de propriedades que projetos Android costumam usar para
guardar o caminho e a senha dele, e o `git check-ignore` prova que linha pega cada nome:

```
ana@dev:~/planner$ printf "*.jks\n*.keystore\nkeystore.properties\n" >> .gitignore
ana@dev:~/planner$ git check-ignore -v android/app/planner-upload.jks android/keystore.properties
.gitignore:26:*.jks	android/app/planner-upload.jks
.gitignore:28:keystore.properties	android/keystore.properties
```

*O passo que usa a chave, assinar um release, não foi executado: ele precisa do SDK do Android e do Gradle, que a
máquina de gravação não conseguiu instalar.* A aula 13 o mostrou: `npx cap build android` com `--keystorepath` e
`--keystorealias`, que pede as senhas, ou as lê de `--keystorepass` e `--keystorealiaspass`, flags que um job de
CI preenche com os seus secrets.
