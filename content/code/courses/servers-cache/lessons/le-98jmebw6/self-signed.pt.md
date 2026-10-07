---
title: Um certificado que assina a si mesmo
version: 1
---

## De onde esta aula parte

Esta aula parte do site como a aula 2 o montou, sem os experimentos de `location` das últimas seções
dela. Ponha isto em `/etc/nginx/sites-available/ipelivros`, no lugar do que estiver lá:

```conf
upstream shop {
    zone shop 64k;
    least_conn;
    server 127.0.0.1:8001;
    server 127.0.0.1:8002;
    keepalive 16;
}

server {
    listen 80;
    server_name ipelivros.example www.ipelivros.example;

    root /var/www/ipe;
    index index.html;

    location / {
        try_files $uri $uri/ =404;
    }

    location /api/ {
        proxy_pass http://shop;
        proxy_http_version 1.1;
        proxy_set_header Connection        "";
        proxy_set_header Host              $host;
        proxy_set_header X-Real-IP         $remote_addr;
        proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 10s;
    }

    access_log /var/log/nginx/ipelivros.access.log;
    error_log  /var/log/nginx/ipelivros.error.log;
}
```

```sh
sudo nginx -t && sudo systemctl reload nginx
```

## Um certificado que assina a si mesmo

Qualquer um pode fazer um certificado. O `openssl` faz em um comando, com uma chave P-256, válido por
trinta dias, para os dois nomes da livraria:

```
ana@web:~$ sudo mkdir -p /etc/ssl/ipelivros && cd /etc/ssl/ipelivros && sudo openssl req -x509 -newkey ec -pkeyopt ec_paramgen_curve:P-256 -nodes -days 30 -subj "/CN=ipelivros.example" -addext "subjectAltName=DNS:ipelivros.example,DNS:www.ipelivros.example" -keyout self.key -out self.crt 2>&1; ls -l
-----
total 8
-rw-r--r-- 1 root root 672 Oct  7 00:39 self.crt
-rw------- 1 root root 241 Oct  7 00:39 self.key
ana@web:~$ openssl x509 -in /etc/ssl/ipelivros/self.crt -noout -subject -issuer -dates
subject=CN = ipelivros.example
issuer=CN = ipelivros.example
notBefore=Oct  7 03:39:45 2026 GMT
notAfter=Nov  6 03:39:45 2026 GMT
```

**O sujeito e o emissor são o mesmo nome.** Ninguém garantiu esse certificado além dele mesmo, que é o
que *autoassinado* quer dizer. Duas linhas num snippet dizem ao Nginx onde estão o certificado e a
chave privada, e o bloco server do site ganha um segundo `listen`:

```conf
ssl_certificate     /etc/ssl/ipelivros/self.crt;
ssl_certificate_key /etc/ssl/ipelivros/self.key;
```

Salve essas duas linhas como `/etc/nginx/snippets/ipelivros-self.conf`. O `listen` novo e o
`include` entram abaixo do `listen 80;` no bloco server do site; este `sed` os põe lá, e o teste e o
reload vêm em seguida, como sempre:

```sh
sudo sed -i 's/^    listen 80;/    listen 80;\n    listen 443 ssl;\n    include snippets\/ipelivros-self.conf;/' /etc/nginx/sites-available/ipelivros
sudo nginx -t && sudo systemctl reload nginx
```

```
ana@web:~$ sed -n '/^server {/,/root/p' /etc/nginx/sites-available/ipelivros
server {
    listen 80;
    listen 443 ssl;
    include snippets/ipelivros-self.conf;
    server_name ipelivros.example www.ipelivros.example;

    root /var/www/ipe;
```

O arquivo da chave foi gravado com permissões `-rw-------`, legível só pelo root, e isso está certo:
o mestre do Nginx o lê como root antes de os workers passarem a `www-data`, e **a chave privada é o
único arquivo deste servidor cujo roubo permite a outra pessoa ser você**. Agora peça a página por
HTTPS:

```
ana@web:~$ curl -sS https://ipelivros.example/ -o /dev/null
curl: (60) SSL certificate problem: self-signed certificate
More details here: https://curl.se/docs/sslcerts.html

curl failed to verify the legitimacy of the server and therefore could not
establish a secure connection to it. To learn more about this situation and
how to fix it, please visit the web page mentioned above.
ana@web:~$ curl -sSk https://ipelivros.example/ -o /dev/null -w '%{http_code}\n'
200
ana@web:~$ curl -sS --cacert /etc/ssl/ipelivros/self.crt https://ipelivros.example/ -o /dev/null -w '%{http_code}\n'
200
```

O `curl` recusou, e disse por quê: nada em que ele confia assinou esse certificado. As outras duas
tentativas "funcionam", e vale distingui-las. **`-k` desliga a verificação**: a conexão é
criptografada, com quem quer que tenha respondido, o que não prova nada. `--cacert` manda o `curl`
confiar neste certificado como se fosse uma raiz, o que é honesto para um certificado que você mesmo
fez e copiou para o cliente, e impossível para desconhecidos na internet, que não têm como obter uma
cópia em que possam acreditar.

Um certificado autoassinado é a ferramenta certa exatamente para esse caso: um serviço cujos clientes
você também controla, como duas máquinas suas conversando numa rede privada. Para um site é a
ferramenta errada, porque todo visitante vê um aviso do navegador, e ensinar visitantes a clicar
para passar de avisos é como eles acabam passando pelo aviso que importa. O hábito do `-k` é o mesmo
erro num terminal, e acaba em scripts que depois rodam em produção.
