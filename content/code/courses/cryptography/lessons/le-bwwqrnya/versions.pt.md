---
title: TLS 1.2, versões mais antigas, e o que um servidor deve aceitar
version: 1
---

**O TLS 1.3 (2018) e o TLS 1.2 (2008) são as únicas versões que um servidor deve aceitar hoje; SSL
2.0, SSL 3.0, TLS 1.0 e TLS 1.1 são proibidos pelos próprios órgãos que os padronizaram.** A maior
parte do que uma configuração TLS decide é quais das muitas opções do TLS 1.2 manter, porque o TLS
1.3 removeu quase todas as perigosas.

## O mesmo servidor, por TLS 1.2

O servidor do portal no laboratório aceita as duas versões. Forçado ao TLS 1.2, o cliente vê uma
conversa mais longa:

```
ana@lab:~/lab$ echo | openssl s_client -CAfile pki/root.pem -attime 1781535600 -verify_return_error -connect 127.0.0.1:8443 -servername portal.vereda.example -tls1_2 -trace 2>&1 | vcrypt tls-flow
client -> server  ClientHello
    offers 28 cipher suites
    server_name: portal.vereda.example
server -> client  ServerHello
    chosen cipher suite: TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384
server -> client  Certificate
    certificate: portal.vereda.example
    certificate: Vereda Issuing CA 1
server -> client  ServerKeyExchange
server -> client  ServerHelloDone
client -> server  ClientKeyExchange
client -> server  ChangeCipherSpec
client -> server  Finished
server -> client  NewSessionTicket
server -> client  ChangeCipherSpec
server -> client  Finished
client -> server  Alert: warning, close notify
result: New, TLSv1.2, Cipher is ECDHE-ECDSA-AES256-GCM-SHA384
result: Verify return code: 0 (ok)
```

As diferenças em relação ao handshake TLS 1.3 da seção 02:

- **duas idas e voltas.** A troca de chaves acontece no `ServerKeyExchange` e no `ClientKeyExchange`,
  depois dos hellos, porque um cliente TLS 1.2 não manda um key share na primeira mensagem;
- **o certificado viaja em texto claro**, antes de existir qualquer chave, então um observador
  descobre qual certificado o servidor apresentou;
- a suíte de cifras nomeia **tudo**: `TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384` é uma troca efêmera
  em curva elíptica (`ECDHE`), um certificado ECDSA, AES-256-GCM e SHA-384. Aqui a escolha foi boa,
  porque a configuração deste servidor e este cliente preferem as opções fortes.

## O que é recusado, e por quem

O cliente só oferece TLS 1.1 se mandarem, e este OpenSSL recusa até isso:

```
ana@lab:~/lab$ echo | openssl s_client -CAfile pki/root.pem -attime 1781535600 -verify_return_error -connect 127.0.0.1:8443 -servername portal.vereda.example -tls1_1 2>&1 | grep -o 'no protocols available\|alert protocol version\|unsupported protocol' | head -1
no protocols available
```

O nível de segurança padrão do OpenSSL 3 não fala TLS 1.0 nem 1.1. A RFC 8996 descontinuou os dois
em 2021, e os navegadores os removeram em 2020. Um servidor que ainda os aceita é um achado em
qualquer auditoria, sejam quais forem seus clientes.

Um cliente TLS 1.2 que insiste em `AES256-GCM-SHA384`, uma suíte de **transporte de chave RSA** sem
sigilo futuro (aula 7), também não chega a lugar nenhum:

```
ana@lab:~/lab$ echo | openssl s_client -CAfile pki/root.pem -attime 1781535600 -verify_return_error -connect 127.0.0.1:8443 -servername portal.vereda.example -tls1_2 -cipher AES256-GCM-SHA384 2>&1 | grep -o 'handshake failure\|no shared cipher\|no ciphers available' | head -1
handshake failure
```

O certificado do portal tem uma chave ECDSA, que não pode ser usada para cifrar uma chave para
transporte, então não há suíte que os dois lados consigam usar. Num servidor com certificado RSA,
recusar essas suítes é uma decisão de configuração, e a certa.

## Uma configuração para mirar

A base segura e amplamente compatível é a que a Mozilla publica como configuração *intermediate*:

- versões: só **TLS 1.3 e TLS 1.2**;
- suítes TLS 1.2: só troca de chaves **ECDHE** (ou DHE) com uma cifra **AEAD**, AES-GCM ou
  ChaCha20-Poly1305. Sem transporte de chave RSA, sem CBC, sem RC4, sem 3DES;
- certificados: P-256 ou RSA-2048 para cima, com a cadeia completa servida.

Ferramentas que testam um servidor contra uma base assim, de fora, incluem o `testssl.sh`, o Qualys
SSL Labs e o `nmap --script ssl-enum-ciphers`. O laboratório não as roda, porque elas se conectam a
endereços reais; contra um servidor pelo qual você responde, elas transformam esta seção num
relatório.
