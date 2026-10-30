---
title: Uma chave de upload
version: 1
---

O `keytool` vem com o JDK que a aula 3 instalou. Um comando cria uma keystore com uma chave dentro:

```
ana@dev:~$ keytool -genkeypair -storetype PKCS12 -keystore planner-upload.p12 -alias upload -keyalg RSA -keysize 2048 -validity 10000 -storepass:env PLANNER_KEY_PASSWORD -dname "CN=Ana, O=Study planner, C=BR"
Generating 2,048 bit RSA key pair and self-signed certificate (SHA384withRSA) with a validity of 10,000 days
	for: CN=Ana, O=Study planner, C=BR
ana@dev:~$ keytool -list -v -keystore planner-upload.p12 -storepass:env PLANNER_KEY_PASSWORD | grep -E "Alias|Owner|Valid|SHA256:"
Alias name: upload
Owner: CN=Ana, O=Study planner, C=BR
Valid from: Fri Oct 30 19:34:31 BRT 2026 until: Tue Mar 17 19:34:31 BRT 2054
	 SHA256: FE:D6:28:DB:AF:74:99:65:C2:D4:9A:53:61:9F:E9:BD:9E:46:0F:E4:9B:F6:BF:61:E9:A2:A1:3D:65:4F:64:1F
ana@dev:~/planner$ grep -n "p12\|jks" .gitignore
15:*.jks
17:*.p12
```

- **O `-storetype PKCS12`** é o formato padrão; o Android também lê o `JKS`, mais antigo. Uma store PKCS12
  tem uma senha só, para a store e para a chave.
- **O `-alias upload`** dá nome à chave dentro da store; o build vai pedi-la por esse nome.
- **O `-validity 10000`** é em dias, cerca de 27 anos. O Google Play exige uma chave válida até depois de
  2033, e uma chave não pode ser estendida depois.
- **O `-dname`** é o que o certificado diz sobre o dono. Ninguém confere; ele está lá para quem lê.
- **O `-storepass:env PLANNER_KEY_PASSWORD`** lê a senha de uma variável de ambiente em vez da linha de
  comando, onde ela iria parar no histórico do shell e na lista de processos rodando. Defina a variável a
  partir do seu gerenciador de senhas antes de rodar estes comandos, por exemplo com
  `read -s PLANNER_KEY_PASSWORD && export PLANNER_KEY_PASSWORD`, que a lê sem mostrá-la.

**A impressão digital SHA-256 é o nome da chave.** O Google Play e todo serviço que precisa reconhecer o seu
app, um login do Google, uma chave de mapas restrita ao seu app, pedem por ela.

**A keystore é um segredo, e insubstituível sem ajuda.** O modelo do Expo já deixa `*.p12` e `*.jks` fora do
git, como o último comando mostra. Ela pertence a um gerenciador de senhas ou a um backup criptografado, com
a senha, e ao repositório de ninguém. Esta foi criada na pasta pessoal, fora do projeto, pelo mesmo motivo.
