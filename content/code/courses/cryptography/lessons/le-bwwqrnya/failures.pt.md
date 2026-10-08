---
title: Cinco jeitos de o handshake falhar, e o que cada um significa
version: 1
---

**Um erro de certificado é o cliente se recusando a conversar com um servidor que ele não consegue
identificar, e cada um deles tem uma causa específica que pode ser achada e corrigida no
servidor.** A seção 02 subiu quatro servidores, e três deles têm um problema diferente cada. O `s_client` com
`-verify_return_error` se comporta como um navegador: ele interrompe o handshake quando uma
verificação falha. Só as linhas de veredito aparecem aqui.

## Um que funciona, para comparar

```
ana@lab:~/lab$ echo | openssl s_client -CAfile pki/root.pem -attime 1781535600 -verify_return_error -connect 127.0.0.1:8443 -servername portal.vereda.example -verify_hostname portal.vereda.example 2>&1 | grep -E '^Verif'
Verification: OK
Verified peername: portal.vereda.example
Verify return code: 0 (ok)
```

## As quatro falhas

O servidor na 8444 tem o certificado certo, mas o manda **sem** a AC emissora:

```
ana@lab:~/lab$ echo | openssl s_client -CAfile pki/root.pem -attime 1781535600 -verify_return_error -connect 127.0.0.1:8444 -servername portal.vereda.example -verify_hostname portal.vereda.example 2>&1 | grep -E '^Verif'
Verification error: unable to get local issuer certificate
Verify return code: 20 (unable to get local issuer certificate)
```

O servidor na 8445 manda o certificado da agenda, que **expirou** em 10 de abril:

```
ana@lab:~/lab$ echo | openssl s_client -CAfile pki/root.pem -attime 1781535600 -verify_return_error -connect 127.0.0.1:8445 -servername agenda.vereda.example -verify_hostname agenda.vereda.example 2>&1 | grep -E '^Verif'
Verification error: certificate has expired
Verify return code: 10 (certificate has expired)
```

O servidor do portal de novo, mas o cliente pediu `www.vereda.example`, um **nome** que o
certificado não traz:

```
ana@lab:~/lab$ echo | openssl s_client -CAfile pki/root.pem -attime 1781535600 -verify_return_error -connect 127.0.0.1:8443 -servername portal.vereda.example -verify_hostname www.vereda.example 2>&1 | grep -E '^Verif'
Verification error: hostname mismatch
Verify return code: 62 (hostname mismatch)
```

O servidor da intranet usa um certificado **autoassinado** que nenhum repositório de confiança tem:

```
ana@lab:~/lab$ echo | openssl s_client -CAfile pki/root.pem -attime 1781535600 -verify_return_error -connect 127.0.0.1:8446 -servername intranet.vereda.example -verify_hostname intranet.vereda.example 2>&1 | grep -E '^Verif'
Verification error: self-signed certificate
Verify return code: 18 (self-signed certificate)
```

## O que o servidor vê

O cliente não falha em silêncio. Ele manda um **alerta** TLS com o motivo e fecha a conexão. O fim do
trace do caso expirado:

```
ana@lab:~/lab$ echo | openssl s_client -CAfile pki/root.pem -attime 1781535600 -verify_return_error -connect 127.0.0.1:8445 -servername agenda.vereda.example -trace 2>&1 | vcrypt tls-flow | tail -6
    certificate: Vereda Issuing CA 1
client -> server  Alert: fatal, certificate expired
client: verify error:num=10:certificate has expired
result: Verification error: certificate has expired
result: New, TLSv1.3, Cipher is TLS_AES_256_GCM_SHA384
result: Verify return code: 10 (certificate has expired)
```

O servidor nunca chega ao CertificateVerify nem ao Finished: o cliente parou assim que a mensagem
Certificate falhou na verificação. Os logs de um servidor mostram esses alertas como handshakes que
falharam, e um pico de alertas `certificate expired` numa segunda de manhã é o monitoramento que a
seção 03 da aula 9 deveria ter oferecido.

## Lendo um erro, e corrigindo

| o que o cliente diz | causa | a correção, no servidor |
|---|---|---|
| `unable to get local issuer certificate` | intermediário não mandado, ou raiz em que este cliente não confia | servir a cadeia completa; para uma AC interna, instalar a raiz nos clientes |
| `certificate has expired` | passou do `Not After`, ou o relógio do cliente está errado | renovar, e automatizar a renovação; conferir o relógio do cliente |
| `hostname mismatch` | o nome não está no SAN | emitir um certificado que cubra esse nome, ou usar o nome que ele cobre |
| `self-signed certificate` | ninguém responde pela chave | usar um certificado de uma AC em que os clientes confiam |
| `certificate revoked` | o emissor o retirou | chave nova, certificado novo |

Nenhuma dessas linhas diz "desligue a verificação". Cada falha é o cliente fazendo exatamente o que
este curso argumentou que ele precisa fazer. Um cliente que aceitasse qualquer uma delas aceitaria o
mesmo de um impostor, porque para o cliente o certificado de um impostor tem exatamente a cara de um
servidor com um desses problemas.
