---
title: Um pedido de assinatura, feito e conferido com openssl
version: 1
---

**Para conseguir um certificado você manda à Apple um pedido de assinatura de certificado, e só a
metade pública da sua chave vai nele.** Um CSR guarda a sua chave pública e um nome, assinados com a
sua chave privada para provar que você a tem. A página de ajuda da Apple *Create a certificate signing
request*, lida em 30 de outubro de 2026, faz um com o Keychain Access num Mac: um endereço de e-mail,
um nome comum e "Saved to disk". A mesma página mostra o `openssl genrsa` e o `openssl req` para os
tipos de certificado que exigem uma chave feita na linha de comando. **O `openssl` está em todo
Ubuntu**, então o pedido em si pode ser feito e examinado aqui. Enviá-lo, e o certificado que a Apple
devolveria, não foi executado.

## A chave e o pedido

Crie um diretório para isso e rode:

```
ana@vm:~/signing$ openssl genrsa -out dev.key 2048
ana@vm:~/signing$ openssl req -new -key dev.key -out dev.certSigningRequest -subj "/emailAddress=ana@example.com/CN=Ana Dev Key/C=BR"
ana@vm:~/signing$ openssl req -in dev.certSigningRequest -noout -verify -subject
Certificate request self-signature verify OK
subject=emailAddress = ana@example.com, CN = Ana Dev Key, C = BR
ana@vm:~/signing$ openssl req -in dev.certSigningRequest -noout -text | grep -E "Public-Key|Signature Algorithm" | sort -u
                Public-Key: (2048 bit)
    Signature Algorithm: sha256WithRSAEncryption
ana@vm:~/signing$ ls -l
total 8
-rw-r--r-- 1 ana ana  956 Oct 30 15:59 dev.certSigningRequest
-rw------- 1 ana ana 1704 Oct 30 15:59 dev.key
```

O `genrsa` cria uma chave privada RSA de 2048 bits e não imprime nada. O `req -new` faz o pedido a
partir dela, com os três campos que o Keychain Access pede: um e-mail, um nome comum e um país. Os dois
comandos seguintes leem o pedido de volta. **`self-signature verify OK` é a prova de posse**: o pedido
é assinado com a chave privada cuja metade pública ele carrega, então quem o manda tem essa chave.
Olhe o `ls -l` antes de seguir. O pedido pode ser lido por todos porque é público, e a chave é
`-rw-------`, legível só por você, porque é o único segredo desta aula.

## Uma cadeia, feita para praticar

A autoridade certificadora da Apple não roda aqui, e não deve ser imitada. O que dá para mostrar é o
mecanismo, com uma autoridade certificadora feita para isso e chamada de brinquedo: uma raiz, um
intermediário assinado pela raiz, e o seu pedido assinado pelo intermediário, a forma da figura da
seção 04.

```
ana@vm:~/signing$ openssl req -x509 -newkey rsa:2048 -nodes -keyout root.key -out root.pem -days 3650 -subj "/CN=Toy Root CA" 2>/dev/null
ana@vm:~/signing$ openssl req -newkey rsa:2048 -nodes -keyout inter.key -out inter.csr -subj "/CN=Toy Intermediate CA" 2>/dev/null
ana@vm:~/signing$ printf "basicConstraints=critical,CA:TRUE\n" > ca.ext
ana@vm:~/signing$ openssl x509 -req -in inter.csr -CA root.pem -CAkey root.key -extfile ca.ext -days 1825 -out inter.pem
Certificate request self-signature ok
subject=CN = Toy Intermediate CA
ana@vm:~/signing$ openssl x509 -req -in dev.certSigningRequest -CA inter.pem -CAkey inter.key -days 365 -out dev.pem
Certificate request self-signature ok
subject=emailAddress = ana@example.com, CN = Ana Dev Key, C = BR
ana@vm:~/signing$ openssl x509 -in dev.pem -noout -subject -issuer -enddate
subject=emailAddress = ana@example.com, CN = Ana Dev Key, C = BR
issuer=CN = Toy Intermediate CA
notAfter=Oct 30 18:59:35 2027 GMT
```

O arquivo `ca.ext` marca o intermediário como autoridade certificadora; sem ele, um certificado que
ele assinasse não seria aceito. O assunto do seu certificado é o do seu pedido, o emissor é o
intermediário, e ele vence um ano depois do dia em que foi feito.

## Conferindo, e o intermediário que falta

```
ana@vm:~/signing$ openssl verify -CAfile root.pem -untrusted inter.pem dev.pem
dev.pem: OK
ana@vm:~/signing$ openssl verify -CAfile root.pem dev.pem
emailAddress = ana@example.com, CN = Ana Dev Key, C = BR
error 20 at 0 depth lookup: unable to get local issuer certificate
error dev.pem: verification failed
```

**A primeira conferência passa e a segunda falha, com os mesmos arquivos.** Com a raiz como confiável
e o intermediário como um elo que pode usar, o `openssl` monta a cadeia até a raiz. Com só a raiz, ele
não consegue ir do seu certificado até ela: `unable to get local issuer certificate` é a mensagem de
um intermediário que falta. É o elo do meio esquecido da seção 04, e num Mac ele aparece como um
certificado em que o Xcode não confia até o intermediário WWDR atual ser instalado.

Quando terminar, apague os arquivos de brinquedo. O `dev.key` seria uma chave privada de verdade se
algum dia fosse usado, e nada neste curso o usa de novo.
