---
title: O preço que não mudou
version: 1
---

## De onde esta aula parte

A aula 5 deixou um formato de log, um `expires` para os arquivos estáticos e um segundo log de acesso
no site. Esta aula parte sem eles, do site com o cache ligado:

```sh
sudo rm /etc/nginx/conf.d/cache-log.conf
```

`/etc/nginx/sites-available/ipelivros`:

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
        proxy_cache api_cache;
        proxy_cache_bypass $http_authorization;
        proxy_no_cache     $http_authorization;
        add_header X-Cache-Status $upstream_cache_status always;
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

## O preço que não mudou

A aula 5 terminou com um cache que responde dezessete vezes mais rápido que a aplicação atrás dele.
Esta aula começa pelo que isso custa. A dona da loja baixa o preço de um livro:

```
ana@web:~$ curl -s -D /tmp/h https://ipelivros.example/api/books/2 | jq -c '{title, price_cents}'; grep -i x-cache-status /tmp/h
{"title":"Grande Sertão: Veredas","price_cents":8990}
X-Cache-Status: MISS
ana@web:~$ curl -s -X PUT -d '{"price_cents": 7990}' https://ipelivros.example/api/books/2 | jq -c '{title, price_cents}'
{"title":"Grande Sertão: Veredas","price_cents":7990}
ana@web:~$ curl -s -D /tmp/h https://ipelivros.example/api/books/2 | jq -c '{title, price_cents}'; grep -i x-cache-status /tmp/h
{"title":"Grande Sertão: Veredas","price_cents":8990}
X-Cache-Status: HIT
ana@web:~$ curl -s localhost:8001/api/books/2 | jq -c '{title, price_cents}'
{"title":"Grande Sertão: Veredas","price_cents":7990}
```

**O banco diz 7.990 centavos e todo visitante ouve 8.990.** Nada falhou. O cache fez exatamente o que
mandaram: a loja disse que a resposta valia por sessenta segundos, o Nginx a guardou por sessenta
segundos, e o `PUT` que mudou o preço foi direto à loja sem o cache nem ficar sabendo. Consultada
diretamente, sem passar pelo cache, a loja dá o preço novo.

Esse é o problema inteiro desta aula, e o motivo da velha piada de que só há duas coisas difíceis na
computação: invalidação de cache e dar nome às coisas. **Um cache é uma cópia, e uma cópia não sabe
quando o original muda.** Algo precisa avisá-la, ou ela precisa parar de acreditar em si mesma depois de
um tempo, e toda técnica desta aula é uma dessas duas.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 190\" role=\"img\" aria-label=\"Uma linha do tempo de sessenta segundos. No segundo 0 o cache guarda o preço 8.990. No segundo 20 o banco muda para 7.990. Do segundo 20 ao 60 o cache continua respondendo 8.990: quarenta segundos de resposta errada. No segundo 60 a cópia vence e a próxima requisição busca 7.990.\"><defs><marker id=\"fsw-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><line x1=\"60\" y1=\"120\" x2=\"640\" y2=\"120\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#fsw-ah)\"></line><line x1=\"60.0\" y1=\"114\" x2=\"60.0\" y2=\"126\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></line><text x=\"60.0\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0 s</text><line x1=\"225.71428571428572\" y1=\"114\" x2=\"225.71428571428572\" y2=\"126\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></line><text x=\"225.71428571428572\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">20 s</text><line x1=\"557.1428571428571\" y1=\"114\" x2=\"557.1428571428571\" y2=\"126\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></line><text x=\"557.1428571428571\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">60 s</text><rect x=\"60.0\" y=\"70\" width=\"165.71428571428572\" height=\"30\" fill=\"var(--phosphor-dim)\" stroke=\"none\" fill-opacity=\"0.5\"></rect><rect x=\"225.71428571428572\" y=\"70\" width=\"331.4285714285714\" height=\"30\" fill=\"var(--amber)\" stroke=\"none\" fill-opacity=\"0.35\"></rect><text x=\"142.85714285714286\" y=\"85\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">cache: 8.990, certo</text><text x=\"391.42857142857144\" y=\"85\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">cache: 8.990 enquanto o banco diz 7.990</text><text x=\"225.71428571428572\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">o preço muda</text><line x1=\"225.71428571428572\" y1=\"56\" x2=\"225.71428571428572\" y2=\"68\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#fsw-ah)\"></line><text x=\"557.1428571428571\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">a cópia vence</text><line x1=\"557.1428571428571\" y1=\"56\" x2=\"557.1428571428571\" y2=\"68\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#fsw-ah)\"></line><text x=\"391.42857142857144\" y=\"165\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">a janela de dado velho: no máximo um tempo de vida</text></svg>", "caption": "Uma cópia com tempo de vida de sessenta segundos, e uma mudança no segundo 20. Sem invalidação, a resposta errada vive até a cópia vencer."}
```

Dois números descrevem o risco. **Por quanto tempo uma cópia pode estar errada**, que é no máximo o tempo
de vida dela: sessenta segundos aqui. E **quão errada ela pode estar**: um preço desatualizado em um
minuto numa página de catálogo é um incômodo; o mesmo preço na página que faz o pagamento é uma
reclamação, e na página que confirma um pedido é um problema jurídico. A próxima seção transforma isso
numa decisão.
