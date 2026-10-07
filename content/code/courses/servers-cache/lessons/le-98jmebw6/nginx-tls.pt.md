---
title: O Nginx com um certificado confiável
version: 1
---

O snippet troca os arquivos autoassinados pelos do certbot, e ganha três linhas:

```
ana@web:~$ cat /etc/nginx/snippets/ipelivros-tls.conf
ssl_certificate     /etc/letsencrypt/live/ipelivros.example/fullchain.pem;
ssl_certificate_key /etc/letsencrypt/live/ipelivros.example/privkey.pem;
ssl_protocols       TLSv1.2 TLSv1.3;
ssl_session_cache   shared:TLS:10m;
ssl_session_timeout 1d;
```

`ssl_protocols TLSv1.2 TLSv1.3` descarta as versões anteriores à 1.2, que todo navegador atual parou
de usar e toda auditoria aponta. O cache de sessão deixa um cliente que volta retomar a sessão TLS
anterior em vez de refazer o handshake inteiro, por um dia; `shared` quer dizer que todos os workers
usam o mesmo cache, pelo mesmo motivo de o upstream precisar de `zone` na aula 2.

Esta máquina ainda não confia na raiz do Pebble. Copiá-la para `/usr/local/share/ca-certificates` na
seção anterior foi metade do trabalho, e `update-ca-certificates` é a outra metade: acrescenta o
arquivo à lista que todo programa da máquina lê.

```
ana@web:~$ sudo update-ca-certificates 2>&1
Updating certificates in /etc/ssl/certs...
rehash: warning: skipping ca-certificates.crt,it does not contain exactly one certificate or CRL
1 added, 0 removed; done.
Running hooks in /etc/ca-certificates/update.d...
done.
ana@web:~$ curl -sS https://ipelivros.example/api/books/3 -o /dev/null -w '%{http_code} %{ssl_verify_result}\n'
200 0
```

`200`, e `ssl_verify_result` `0`, que quer dizer que a cadeia foi conferida e aceita, **sem `-k` e sem
`--cacert`**. É o estado em que um certificado da Let's Encrypt fica desde o primeiro segundo, porque a
raiz dela já está nessa lista.

## Olhando o handshake

O `curl -v` descreve a conexão que fez:

```
ana@web:~$ curl -sv https://ipelivros.example/ -o /dev/null 2>&1 | grep -E '^\*  ?(SSL connection|Server certificate|subject|issuer|expire|subjectAltName|SSL certificate verify)'
* SSL connection using TLSv1.3 / TLS_AES_256_GCM_SHA384 / X25519 / id-ecPublicKey
* Server certificate:
*  subject: CN=ipelivros.example
*  expire date: Jan  5 03:39:48 2027 GMT
*  subjectAltName: host "ipelivros.example" matched cert's "ipelivros.example"
*  issuer: CN=Pebble Intermediate CA 6e3a58
*  SSL certificate verify ok.
```

TLS 1.3, uma cifra AES-256-GCM, uma troca de chaves X25519, e o certificado conferido. O `openssl
s_client` mostra a cadeia que o servidor mandou de fato, que é a verificação que pega o erro do
`cert.pem` da seção anterior:

```
ana@web:~$ echo | openssl s_client -connect ipelivros.example:443 -servername ipelivros.example 2>/dev/null | grep -E "^ ?[0-9] s:|^   i:|Verify return|Protocol|Cipher is"
 0 s:CN = ipelivros.example
   i:CN = Pebble Intermediate CA 6e3a58
 1 s:CN = Pebble Intermediate CA 6e3a58
   i:CN = Pebble Root CA 435937
New, TLSv1.3, Cipher is TLS_AES_256_GCM_SHA384
Verify return code: 0 (ok)
```

Foram mandados dois certificados: o `0` é o site, emitido pela intermediária, e o `1` é a
intermediária, emitida pela raiz. A própria raiz não foi mandada, e não precisava.

**E um protocolo velho é recusado.** O cliente do próprio OpenSSL nem oferece mais TLS 1.1 por padrão;
mandado oferecer, com o nível de segurança baixado, recebe uma resposta do Nginx:

```
ana@web:~$ echo | openssl s_client -connect ipelivros.example:443 -servername ipelivros.example -tls1_1 -cipher 'DEFAULT@SECLEVEL=0' 2>&1 | grep -E 'alert|Protocol  *:'
405799AE627F0000:error:0A00042E:SSL routines:ssl3_read_bytes:tlsv1 alert protocol version:../ssl/record/rec_layer_s3.c:1590:SSL alert number 70
    Protocol  : TLSv1.1
```

`protocol version` é o servidor dizendo que não fala o que foi oferecido. É a linha que um scanner de
conformidade procura.

## Mandando HTTP para HTTPS

A porta 80 agora tem uma tarefa: mandar todo cliente voltar por HTTPS. O bloco server do site escuta
só na 443, e um segundo bloco pequeno fica com a porta 80:

```
ana@web:~$ cat /etc/nginx/sites-available/ipelivros.redirect
server {
    listen 80;
    server_name ipelivros.example www.ipelivros.example;

    location /.well-known/acme-challenge/ {
        root /var/www/ipe;
    }

    location / {
        return 301 https://$host$request_uri;
    }
}
ana@web:~$ grep -nE 'server \{|listen|include snippets' /etc/nginx/sites-available/ipelivros
9:server {
10:    listen 443 ssl;
11:    include snippets/ipelivros-tls.conf;
35:server {
36:    listen 80;
```

```
ana@web:~$ curl -sI http://ipelivros.example/css/site.css?v=1 | grep -E "HTTP|Location"
HTTP/1.1 301 Moved Permanently
Location: https://ipelivros.example/css/site.css?v=1
ana@web:~$ curl -s -o /dev/null -w '%{http_code}\n' http://ipelivros.example/.well-known/acme-challenge/nothing
404
```

`301` com `Location: https://...` mantém o caminho e a query, então um favorito para qualquer página
continua funcionando. **O location do `acme-challenge` é a única exceção, e importa**: a próxima
renovação confere o desafio por HTTP simples na porta 80, e um redirecionamento que o engolisse faria a
renovação falhar daqui a noventa dias, num dia em que ninguém está olhando. Um `404` para um token
que não existe é a resposta certa, e mostra que o location é alcançado em vez de redirecionado.
