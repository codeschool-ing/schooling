---
title: A autoridade do próprio escritório
version: 1
---

A intranet do escritório, `intranet.example.com`, usa um certificado da autoridade certificadora do
próprio escritório, coisa que muitas organizações mantêm para os servidores internos. O laptop não
confia nela:

```
ana@laptop:~$ curl -sS -o /dev/null https://intranet.example.com/
curl: (60) SSL certificate problem: unable to get local issuer certificate
More details here: https://curl.se/docs/sslcerts.html

curl failed to verify the legitimacy of the server and therefore could not
establish a secure connection to it. To learn more about this situation and
how to fix it, please visit the web page mentioned above.
ana@laptop:~$ openssl x509 -in office-ca.crt -noout -subject -issuer -fingerprint -sha256
subject=O = Example Ltd, CN = Example Ltd Office CA
issuer=O = Example Ltd, CN = Example Ltd Office CA
sha256 Fingerprint=2C:36:FD:F3:D1:2C:F5:D9:A0:5E:07:F3:AB:92:82:24:85:50:B5:31:94:D8:2D:D9:CA:F9:42:31:88:EA:07:75
ana@laptop:~$ sudo cp office-ca.crt /usr/local/share/ca-certificates/example-office-ca.crt
ana@laptop:~$ sudo update-ca-certificates
Updating certificates in /etc/ssl/certs...
rehash: warning: skipping ca-certificates.crt,it does not contain exactly one certificate or CRL
1 added, 0 removed; done.
Running hooks in /etc/ca-certificates/update.d...
done.
ana@laptop:~$ curl -sS -o /dev/null -w '%{http_code}\n' https://intranet.example.com/
200
```

O mesmo `unable to get local issuer certificate` do intermediário faltando, por outro motivo: desta vez
nada no repositório do laptop assinou coisa alguma da cadeia. O certificado da CA do escritório chegou
de um colega, e o `openssl` imprimiu a **impressão digital** dele (*fingerprint*), o SHA-256 do
certificado. Antes de confiar numa raiz, é esse o número a comparar com um obtido por outro caminho,
lido por telefone por quem cuida da CA, por exemplo. Depois ele foi para o repositório, o
`update-ca-certificates` informou `1 added`, e a intranet agora responde `200`.

**Essa conferência da impressão digital não é cerimônia.** Um certificado raiz no repositório pode
garantir qualquer nome, `www.example.com` ou o de um banco, e a máquina vai acreditar. Instalar um é dar
a quem tem a chave privada dele o poder de se passar por qualquer site para este computador. Redes de
empresa que inspecionam tráfego HTTPS funcionam exatamente assim: instalam uma raiz própria em cada
laptop, e o proxy delas gera certificados na hora. Instale uma raiz só de uma fonte que você consiga
verificar, e só nas máquinas que precisam dela.
