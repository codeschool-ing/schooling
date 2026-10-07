---
title: Um terceiro que responde por uma chave
version: 1
---

**Um certificado é uma declaração, assinada por alguém em quem você já confia, de que uma chave
pública pertence a um nome.** Essa é a ideia inteira. A infraestrutura de chaves públicas, PKI, é
tudo o que é preciso para tornar essas declarações confiáveis na escala da internet: quem pode
assiná-las, como são conferidas, e o que acontece quando uma se revela falsa.

## O problema que os certificados resolvem

As aulas 2, 3 e 7 pararam todas no mesmo ponto. Uma chave pública não diz de quem é, e a troca de
chaves assinada que derrota um homem no meio só funciona se a Ana souber qual chave pública é mesmo
a do servidor. Ela não pode perguntar ao servidor: um impostor responde "sim, esta é a minha chave"
exatamente como o servidor real responderia. Ela precisa de mais alguém, que não esteja no caminho,
que tenha conferido antes.

No SSH, a aula 6 respondeu isso à mão: um arquivo `allowed_signers`, ou a impressão digital que uma
pessoa compara na primeira conexão. Isso funciona para uma equipe de dez. Não funciona para um
paciente abrindo o portal da Vereda num celular, que nunca ouviu falar de impressão digital e nunca
vai ligar para ninguém para conferir uma.

## O que um certificado amarra

O certificado do portal da Vereda nomeia o titular e a autoridade que o emitiu:

```
ana@lab:~/lab$ openssl x509 -in pki/portal.pem -noout -subject -issuer
subject=C = BR, O = Vereda Fisioterapia, CN = portal.vereda.example
issuer=C = BR, O = Vereda Fisioterapia, CN = Vereda Issuing CA 1
```

E carrega uma chave pública:

```
ana@lab:~/lab$ openssl x509 -in pki/portal.pem -noout -pubkey
-----BEGIN PUBLIC KEY-----
MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEhJUPnGMjGZ+5QuxX+6XKfF1Nrfun
GJflFVDf4FVcfDEtMAY90zJYuJG9Ryt/UVgdqhUMOiN5NyKvI2D3RuAJKQ==
-----END PUBLIC KEY-----
```

Essa chave é a metade pública da chave privada que o servidor do portal guarda, byte a byte:

```
ana@lab:~/lab$ openssl x509 -in pki/portal.pem -noout -pubkey | cmp - <(openssl pkey -in pki/portal.key -pubout) && echo "the certificate carries the public half of portal.key"
the certificate carries the public half of portal.key
```

Então o certificado amarra três coisas: um **nome** (`portal.vereda.example`), uma **chave pública**
e um **emissor** que assinou o par. Um navegador que confia no emissor, e confere a assinatura do
emissor, pode acreditar que essa chave pertence a esse nome. Ele ainda confere mais uma coisa:
durante o handshake, o servidor prova que tem a chave privada correspondente assinando a troca
(aula 7). Um certificado sozinho é público; qualquer um pode copiá-lo. Ter a chave privada é o que o
handshake testa.

## O que a autoridade de fato confere

Uma **autoridade certificadora** (AC) só assina depois de conferir que quem pede controla o nome.
Nos certificados que os navegadores usam, essa verificação costuma ser automática e só sobre o
domínio:

- **validação de domínio (DV)**: quem pede prova que controla o domínio, servindo um arquivo num
  endereço dado ou publicando um registro DNS. O Let's Encrypt automatiza isso com o protocolo ACME,
  e é a maioria dos certificados da web;
- **validação de organização (OV)** e **validação estendida (EV)** acrescentam verificações sobre a
  empresa por trás do domínio. Os navegadores pararam de mostrar o EV de forma diferente por volta de
  2019, porque os usuários não percebiam a diferença.

Um certificado DV diz, portanto, "quem pediu isto controlava `portal.vereda.example` naquele
momento", não "esta é uma clínica confiável". É exatamente o que o navegador precisa saber para
descartar um homem no meio, e nada além disso.
