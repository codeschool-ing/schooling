---
title: LDAP e LDAPS: o diretório que confere toda senha
version: 1
---

**O LDAP é o protocolo que as aplicações usam para perguntar a um diretório, Active Directory ou
OpenLDAP, se um usuário existe e se a senha dele está certa.** Essa segunda pergunta é um *bind*: a
aplicação manda o nome e a senha do usuário para o diretório. No LDAP simples, a senha atravessa a
rede em texto claro a cada login de cada aplicação que usa o diretório. Poucas coisas numa rede
corporativa valem mais para quem intercepta.

## O diretório da Vereda recusa o jeito simples

O diretório da Vereda escuta nas duas portas e foi configurado com uma linha,
`security simple_bind=128`, para recusar uma senha numa conexão que não esteja cifrada. Um bind
simples:

```
ana@lab:~/lab$ ldapwhoami -x -H ldap://ldap.vereda.example:3389 -D cn=admin,dc=vereda,dc=example -w directory-admin-lab
ldap_bind: Confidentiality required (13)
	additional info: confidentiality required
```

O servidor diz `confidentiality required` e nada é conferido. A senha atravessou a rede mesmo assim
nessa tentativa, porque o cliente a mandou antes de o servidor poder objetar, então a recusa é uma
proteção contra **clientes mal configurados**, que ela faz falhar ruidosamente em vez de funcionar
em silêncio. A regra do lado do cliente, da seção anterior, é o que impede a senha de sair.

## O mesmo bind, cifrado, de dois jeitos

Com o StartTLS tornado obrigatório pelo `-ZZ`, e o cliente avisado para confiar na raiz da Vereda:

```
ana@lab:~/lab$ LDAPTLS_CACERT=pki/root.pem ldapwhoami -x -ZZ -H ldap://ldap.vereda.example:3389 -D cn=admin,dc=vereda,dc=example -w directory-admin-lab
dn:cn=admin,dc=vereda,dc=example
```

E por LDAPS, TLS implícito na porta própria:

```
ana@lab:~/lab$ LDAPTLS_CACERT=pki/root.pem ldapwhoami -x -H ldaps://ldap.vereda.example:6636 -D cn=admin,dc=vereda,dc=example -w directory-admin-lab
dn:cn=admin,dc=vereda,dc=example
```

## E sem confiar na raiz

O mesmo comando LDAPS, sem `LDAPTLS_CACERT`, então o cliente usa o repositório de confiança do
sistema, que não contém a raiz interna da Vereda (aula 8):

```
ana@lab:~/lab$ ldapwhoami -x -H ldaps://ldap.vereda.example:6636 -D cn=admin,dc=vereda,dc=example -w directory-admin-lab
ldap_sasl_bind(SIMPLE): Can't contact LDAP server (-1)
```

O cliente recusou o certificado e desistiu. A mensagem não ajuda, *Can't contact LDAP server*, e
essa é uma armadilha conhecida: é a mesma mensagem de um servidor fora do ar, então as pessoas
diagnosticam a rede quando o problema é confiança. Acrescentar `-d 1` ao comando mostra o erro de
TLS por trás. A correção é instalar a raiz interna no cliente, não pôr `TLS_REQCERT never` no
`ldap.conf`, o que desliga a verificação para toda conexão LDAP da máquina.

## No Active Directory

Os controladores de domínio da Microsoft oferecem LDAP na 389 e LDAPS na 636, como qualquer
diretório, e por muito tempo aceitaram binds simples sem assinatura por padrão. A Microsoft vem
levando-os a **exigir assinatura LDAP e channel binding**, que amarra uma sessão LDAP autenticada ao
seu canal TLS. Numa rede Windows a pergunta da auditoria é a mesma daqui: quais aplicações ainda
fazem bind em texto claro, e quando os controladores de domínio vão poder recusá-las.
