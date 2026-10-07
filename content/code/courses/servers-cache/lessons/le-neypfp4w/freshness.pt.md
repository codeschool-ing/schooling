---
title: Fresca, por quanto tempo
version: 1
---

## De onde esta aula parte

O endurecimento da aula 4 pertence a um servidor de verdade, e duas partes dele atrapalham o que esta
aula mede: o limite de taxa recusa a maior parte das requisições de um benchmark, e o `Cache-Control:
no-store` da própria API esconde os cabeçalhos de que esta aula trata. Guarde uma cópia do site da aula
4, tire os acréscimos dela e parta do site como a aula 3 o deixou:

```sh
sudo cp /etc/nginx/sites-available/ipelivros ~/ipelivros.lesson-4
sudo rm /etc/nginx/sites-enabled/catch-all /etc/nginx/conf.d/limits.conf
sudo rm -r /var/www/ipe/.git /etc/systemd/system/shop@.service.d
sudo sed -i 's/server_tokens off;/# server_tokens off;/' /etc/nginx/nginx.conf
sudo systemctl daemon-reload && sudo systemctl restart shop@1 shop@2
```

`/etc/nginx/sites-available/ipelivros`, no lugar do que estiver lá:

```conf
upstream shop {
    zone shop 64k;
    least_conn;
    server 127.0.0.1:8001;
    server 127.0.0.1:8002;
    keepalive 16;
}

server {
    listen 443 ssl;
    include snippets/ipelivros-tls.conf;
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
```

```sh
sudo nginx -t && sudo systemctl reload nginx
```

## Por quanto tempo uma cópia vale

Um cache precisa de uma resposta antes de guardar qualquer coisa: **por quanto tempo esta cópia ainda
serve?** Uma cópia que ainda serve está **fresca** (*fresh*), e o cache a entrega sem perguntar a
ninguém. Quando o tempo dela acaba, ela fica **velha** (*stale*), e o cache precisa conferir com a
origem antes de usá-la de novo, que é a próxima seção.

Agora nem a folha de estilo nem a API dizem nada:

```
ana@web:~$ curl -sI https://ipelivros.example/css/site.css | grep -iE '^(HTTP|cache-control|expires|last-modified|etag)'
HTTP/1.1 200 OK
Last-Modified: Tue, 01 Sep 2026 13:00:00 GMT
ETag: "6a96cc50-ed"
ana@web:~$ curl -sI https://ipelivros.example/api/books/1 | grep -iE '^(HTTP|cache-control|expires|last-modified|etag)'
HTTP/1.1 200 OK
ETag: "806121fbab2ee803"
Last-Modified: Tue, 01 Sep 2026 13:00:00 GMT
```

Nenhum `Cache-Control`, nenhum `Expires`. Um navegador que só tem o `Last-Modified` recorre a uma
**heurística**: a RFC sugere considerar a cópia fresca por um décimo do tempo desde a última mudança do
arquivo. A folha de estilo mudou pela última vez cinco semanas antes desta captura, então um navegador
poderia guardá-la por três dias e meio por esse palpite, sem perguntar, e se ele faz isso fica a
critério dele. **Uma resposta sem tempo de vida explícito é guardada pela regra que o leitor
preferir**, o único resultado que ninguém escolheu.

## Dizendo explicitamente

Para arquivos estáticos, o `expires` do Nginx escreve os dois cabeçalhos. Um location para os arquivos
do próprio site:

```
ana@web:~$ sudo sed -i '0,/    location \/ {/s||    location ~* \\.(css\|js\|svg)$ {\n        expires 1h;\n    }\n\n    location / {|' /etc/nginx/sites-available/ipelivros && grep -n -A2 'location ~' /etc/nginx/sites-available/ipelivros
17:    location ~* \.(css|js|svg)$ {
18-        expires 1h;
19-    }
ana@web:~$ curl -sI https://ipelivros.example/css/site.css | grep -iE '^(date|cache-control|expires|last-modified)'
Date: Wed, 07 Oct 2026 04:00:45 GMT
Last-Modified: Tue, 01 Sep 2026 13:00:00 GMT
Expires: Wed, 07 Oct 2026 05:00:45 GMT
Cache-Control: max-age=3600
```

`Cache-Control: max-age=3600` diz "fresca por 3.600 segundos a partir de quando foi recebida", e é o
cabeçalho que todo cache moderno lê. `Expires` diz o mesmo como uma data, calculada a partir do próprio
cabeçalho `Date` da resposta mais uma hora; é o cabeçalho antigo, mantido para os clientes mais velhos,
e quando os dois estão presentes vale o `max-age`. Tempo relativo é o desenho melhor: não depende de o
relógio da máquina que lê estar certo.

A aplicação decide pelas próprias respostas. A loja lê `SHOP_CACHE_CONTROL` do arquivo de ambiente e
manda o que ele disser:

```
ana@web:~$ echo 'SHOP_CACHE_CONTROL=max-age=60' | sudo tee /etc/shop/shop.env && sudo systemctl restart shop@1 shop@2
SHOP_CACHE_CONTROL=max-age=60
ana@web:~$ curl -sI https://ipelivros.example/api/books/1 | grep -iE '^(cache-control|etag|last-modified)'
ETag: "806121fbab2ee803"
Last-Modified: Tue, 01 Sep 2026 13:00:00 GMT
Cache-Control: max-age=60
```

Um livro agora fica fresco por um minuto depois de qualquer cópia dele ser tirada. O número é uma
decisão do negócio, não dos servidores: um preço desatualizado em um minuto é aceitável numa página de
catálogo e não na página que faz o pagamento. A aula 6 trata do que fazer quando um minuto é demais.
