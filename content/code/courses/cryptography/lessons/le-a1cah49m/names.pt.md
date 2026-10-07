---
title: Nomes: quais hosts um certificado cobre
version: 1
---

**Um cliente confere se o nome de host a que se conectou aparece na lista Subject Alternative Name
do certificado, e em nenhum outro lugar.** Um certificado perfeitamente válido para um nome é inútil
para outro, e essa verificação é o que impede que um certificado roubado ou emitido por engano para
`example.org` seja usado para se passar pela Vereda.

## A lista, e a verificação

O certificado do portal lista um nome:

```
ana@lab:~/lab$ openssl x509 -in pki/portal.pem -noout -ext subjectAltName
X509v3 Subject Alternative Name: 
    DNS:portal.vereda.example
```

Pedida para conferir esse nome, a verificação passa:

```
ana@lab:~/lab$ openssl verify -attime 1781535600 -verify_hostname portal.vereda.example -CAfile pki/root.pem -untrusted pki/issuing1.pem pki/portal.pem
pki/portal.pem: OK
```

Perguntada sobre `www.vereda.example`, que o certificado não lista, ela falha, embora a cadeia, as
datas e a assinatura estejam todas certas:

```
ana@lab:~/lab$ openssl verify -attime 1781535600 -verify_hostname www.vereda.example -CAfile pki/root.pem -untrusted pki/issuing1.pem pki/portal.pem
C = BR, O = Vereda Fisioterapia, CN = portal.vereda.example
error 62 at 0 depth lookup: hostname mismatch
error pki/portal.pem: verification failed
```

## O nome comum não é conferido

A linha `Subject` também diz `CN = portal.vereda.example`, e durante anos os clientes compararam o
nome do host com ele. Esse recurso de reserva era uma fonte de ambiguidade, e os navegadores o
abandonaram: o Chrome parou de ler o nome comum em 2017, e as regras do CA/Browser Forum exigem que
todo nome esteja na lista SAN. **Um certificado cujo nome aparece só no CN falha num navegador
moderno.** Isso ainda é um erro comum em certificados feitos à mão para serviços internos, que então
funcionam numa biblioteca antiga e falham em todo o resto.

## Curingas

Uma entrada SAN pode começar com `*.`, que casa com **exatamente um** rótulo naquela posição:

| entrada SAN | casa com | não casa com |
|---|---|---|
| `*.vereda.example` | `portal.vereda.example`, `agenda.vereda.example` | `vereda.example`, `a.b.vereda.example` |
| `vereda.example` | `vereda.example` | `www.vereda.example` |

Um curinga é conveniente e amplia o que uma única chave roubada expõe: todo host sob o domínio a
compartilha. Equipes que usam um o restringem a hosts com o mesmo dono e a mesma segurança, e
preferem um certificado por serviço onde a automação torna isso barato.

## Quem faz a verificação

O `openssl verify` só conferiu o nome porque foi pedido com `-verify_hostname`. Navegadores e a
maioria das bibliotecas HTTP conferem por padrão. O perigo está no código de nível mais baixo: um
socket TLS cru, uma biblioteca antiga ou uma opção de configuração podem conferir a cadeia e pular o
nome. **Um certificado que se encadeia a uma raiz confiável, conferido sem o nome, prova só que
alguém em algum lugar tem um certificado.** No Python, o `ssl.create_default_context()` confere os
dois; um código que monta um `SSLContext` à mão e põe `check_hostname = False` não confere. A aula
10 mostra o mesmo erro de nome do lado do cliente num handshake real.
