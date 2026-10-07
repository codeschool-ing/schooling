---
title: Pedindo um certificado com o certbot
version: 1
---

O `certbot` é o cliente ACME mantido pela Electronic Frontier Foundation, e o que a maioria dos guias
supõe. Ele busca um certificado de vários jeitos; o usado aqui é o **webroot**: o certbot grava o
token do desafio como um arquivo dentro da raiz do próprio site, e o servidor web que já está rodando
o serve. O Nginx não é mexido e nunca para.

```
ana@web:~$ sudo REQUESTS_CA_BUNDLE=/etc/pebble/api.crt certbot certonly --webroot -w /var/www/ipe -d ipelivros.example -d www.ipelivros.example --server https://localhost:14000/dir --agree-tos -m ana@ipelivros.example --no-eff-email --non-interactive 2>&1
Saving debug log to /var/log/letsencrypt/letsencrypt.log
Account registered.
Requesting a certificate for ipelivros.example and www.ipelivros.example

Successfully received certificate.
Certificate is saved at: /etc/letsencrypt/live/ipelivros.example/fullchain.pem
Key is saved at:         /etc/letsencrypt/live/ipelivros.example/privkey.pem
This certificate expires on 2027-01-05.
These files will be updated when the certificate renews.
Certbot has set up a scheduled task to automatically renew this certificate in the background.

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
If you like Certbot, please consider supporting our work by:
 * Donating to ISRG / Let's Encrypt:   https://letsencrypt.org/donate
 * Donating to EFF:                    https://eff.org/donate-le
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
```

`REQUESTS_CA_BUNDLE` é a única coisa de que este laboratório precisa e um servidor de verdade não: ela
manda o certbot, um programa em Python, confiar no certificado da API do Pebble. `--server` o aponta
para o Pebble em vez da Let's Encrypt. Contra a Let's Encrypt, com um domínio de verdade, o comando é o
mesmo sem esses dois.

## O que a CA fez

Enquanto o certbot esperava, o Pebble conferiu os dois nomes, e o log de acesso do Nginx registrou:

```
ana@web:~$ grep acme-challenge /var/log/nginx/ipelivros.access.log
127.0.0.1 - - [07/Oct/2026:00:39:48 -0300] "GET /.well-known/acme-challenge/HETdSjY3HaNEI5kRnDkQp2JOXgr4vrxIX35BUWQEEXU HTTP/1.1" 200 87 "-" "LetsEncrypt-Pebble-VA (linux; amd64)"
127.0.0.1 - - [07/Oct/2026:00:39:48 -0300] "GET /.well-known/acme-challenge/HETdSjY3HaNEI5kRnDkQp2JOXgr4vrxIX35BUWQEEXU HTTP/1.1" 200 87 "-" "LetsEncrypt-Pebble-VA (linux; amd64)"
127.0.0.1 - - [07/Oct/2026:00:39:48 -0300] "GET /.well-known/acme-challenge/HETdSjY3HaNEI5kRnDkQp2JOXgr4vrxIX35BUWQEEXU HTTP/1.1" 200 87 "-" "LetsEncrypt-Pebble-VA (linux; amd64)"
127.0.0.1 - - [07/Oct/2026:00:39:48 -0300] "GET /.well-known/acme-challenge/q_mhsdMTwCZy3OLUP_CAimDpKVDDGv8_MlYBVJ_N2Yc HTTP/1.1" 200 87 "-" "LetsEncrypt-Pebble-VA (linux; amd64)"
127.0.0.1 - - [07/Oct/2026:00:39:48 -0300] "GET /.well-known/acme-challenge/q_mhsdMTwCZy3OLUP_CAimDpKVDDGv8_MlYBVJ_N2Yc HTTP/1.1" 200 87 "-" "LetsEncrypt-Pebble-VA (linux; amd64)"
127.0.0.1 - - [07/Oct/2026:00:39:48 -0300] "GET /.well-known/acme-challenge/q_mhsdMTwCZy3OLUP_CAimDpKVDDGv8_MlYBVJ_N2Yc HTTP/1.1" 200 87 "-" "LetsEncrypt-Pebble-VA (linux; amd64)"
```

Um token por nome, cada um buscado por HTTP simples na porta 80 por um cliente que se chama
`LetsEncrypt-Pebble-VA`, a *autoridade de validação*. Ela buscou cada token três vezes, imitando o que a
Let's Encrypt faz em produção: confere de vários lugares da internet ao mesmo tempo, para que alguém
capaz de interceptar o tráfego perto de um deles não consiga um certificado para o seu nome. O `200` e
os 87 bytes são o arquivo do token, que o certbot gravou e depois apagou.

## O que o certbot deixou

```
ana@web:~$ sudo ls -l /etc/letsencrypt/live/ipelivros.example/
total 4
-rw-r--r-- 1 root root 692 Oct  7 00:39 README
lrwxrwxrwx 1 root root  41 Oct  7 00:39 cert.pem -> ../../archive/ipelivros.example/cert1.pem
lrwxrwxrwx 1 root root  42 Oct  7 00:39 chain.pem -> ../../archive/ipelivros.example/chain1.pem
lrwxrwxrwx 1 root root  46 Oct  7 00:39 fullchain.pem -> ../../archive/ipelivros.example/fullchain1.pem
lrwxrwxrwx 1 root root  44 Oct  7 00:39 privkey.pem -> ../../archive/ipelivros.example/privkey1.pem
ana@web:~$ sudo openssl x509 -in /etc/letsencrypt/live/ipelivros.example/cert.pem -noout -subject -issuer -dates -ext subjectAltName
subject=CN = ipelivros.example
issuer=CN = Pebble Intermediate CA 6e3a58
notBefore=Oct  7 03:39:49 2026 GMT
notAfter=Jan  5 03:39:48 2027 GMT
X509v3 Subject Alternative Name: 
    DNS:ipelivros.example, DNS:www.ipelivros.example
ana@web:~$ sudo grep -c BEGIN /etc/letsencrypt/live/ipelivros.example/fullchain.pem
2
```

`/etc/letsencrypt/live/<nome>/` guarda **links**, e os arquivos para onde eles apontam são numerados
em `archive/`. Quando o certificado é renovado, o certbot grava `cert2.pem` e move os links, então um
servidor web configurado com os caminhos de `live/` nunca precisa ter a configuração editada de novo.
Os quatro arquivos:

| arquivo | o que é | quem precisa |
|---|---|---|
| `privkey.pem` | a chave privada | o `ssl_certificate_key` do Nginx, e mais ninguém |
| `cert.pem` | só o certificado do site | quase nada |
| `chain.pem` | a intermediária | quase nada sozinho |
| `fullchain.pem` | o certificado do site seguido da intermediária | o `ssl_certificate` do Nginx |

**Aponte o Nginx para o `fullchain.pem`, nunca para o `cert.pem`.** Um servidor que manda só o
próprio certificado funciona num navegador que por acaso tem a intermediária guardada de outro site,
e falha em todo o resto, inclusive no `curl` e em todo celular que não a viu. É o erro de TLS mais
comum que sobrevive aos testes, porque quem testa tem a intermediária guardada.

O certificado em si nomeia os dois hosts no *Subject Alternative Name*, é emitido pela intermediária do
Pebble e vale por noventa dias a partir do minuto em que foi assinado.
