---
title: Emitindo um certificado para um serviço interno
version: 1
---

A aplicação em `app` vai ganhar um certificado próprio, para o nome interno `app.corp.example.com`,
para que a aula 20 possa cifrar a conexão do proxy até ela. A emissão tem duas metades, e a chave
nunca troca de mãos.

**O servidor gera sua chave e um pedido.** Um pedido de assinatura de certificado (*certificate
signing request*, CSR) contém a chave pública e o nome, e é assinado com a chave privada para provar
que quem pede a possui:

```
root@admin:~# cd ca; openssl req -newkey ec -pkeyopt ec_paramgen_curve:P-256 -nodes -subj "/CN=app.corp.example.com" -keyout app.key -out app.csr 2>/dev/null; openssl req -in app.csr -noout -subject -verify
Certificate request self-signature verify OK
subject=CN = app.corp.example.com
```

`self-signature verify OK`: quem fez este pedido tem a chave privada que corresponde à chave pública
dentro dele. Numa instalação real isso roda em `app`, e só o CSR viaja até a CA.

**A CA decide o que assinar.** Ela não copia o que quer que o pedido solicite; aplica o seu próprio
perfil. As extensões deste certificado, escritas antes da assinatura:

```
root@admin:~# cd ca; cat app.ext
[server]
basicConstraints = critical,CA:FALSE
keyUsage = critical,digitalSignature
extendedKeyUsage = serverAuth
authorityKeyIdentifier = keyid
subjectAltName = DNS:app.corp.example.com
```

Um certificado de servidor, não de CA, utilizável para assinaturas na autenticação de servidor TLS,
para um nome só. A CA assina com essas extensões e datas fixas, três meses a partir de hoje:

```
root@admin:~# cd ca; openssl ca -batch -config ca.cnf -cert issuing.crt -keyfile issuing.key -extfile app.ext -extensions server -startdate 20260928000000Z -enddate 20261228000000Z -in app.csr -out app.crt -notext 2>&1 | grep -E "Signature ok|Data Base"
Signature ok
root@admin:~# cd ca; openssl x509 -in app.crt -noout -serial -subject -issuer -dates -ext subjectAltName
serial=1003
subject=CN = app.corp.example.com
issuer=O = Example Corp, CN = Example Corp Issuing CA
notBefore=Sep 28 00:00:00 2026 GMT
notAfter=Dec 28 00:00:00 2026 GMT
X509v3 Subject Alternative Name: 
    DNS:app.corp.example.com
```

Número de série `1003`, o próximo na sequência da CA. **A CA mantém um registro de tudo o que já
emitiu**, uma linha por certificado:

```
root@admin:~# cd ca; tail -2 index.txt
V	261130000000Z		1002	unknown	/CN=www.example.com
V	261228000000Z		1003	unknown	/CN=app.corp.example.com
```

`V` de válido, a data de expiração, o número de série e o sujeito. É esse registro que torna possível
a próxima seção: uma CA só consegue revogar o que sabe que emitiu.

## Verificando quem pede

Assinar é mecânico; **decidir se deve assinar é todo o valor da CA**. Uma CA pública verifica o
controle sobre o nome, normalmente pedindo que o solicitante publique um valor aleatório no DNS ou no
servidor web, e emite automaticamente pelo protocolo ACME quando a verificação passa. Uma CA interna
responde ao processo da própria empresa: um chamado, um responsável pelo serviço, um nome dentro do
domínio da empresa. Qualquer que seja a verificação, ela fica escrita, porque uma CA que assina tudo o
que recebe entregou a sua assinatura.
