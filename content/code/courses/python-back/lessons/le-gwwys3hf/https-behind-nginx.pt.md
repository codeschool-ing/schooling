---
title: HTTPS, e o que a aplicação acredita
version: 1
---

Um certificado de verdade precisa de um domínio de verdade: o **certbot** pede um ao Let's Encrypt,
prova que o domínio é seu, e o renova, e o curso `servers-cache` faz exatamente isso. O
`agenda.example.org` não é seu nem de ninguém, então esta seção faz um certificado **autoassinado**, em
que nenhum navegador confia e que no mais é o mesmo arquivo no mesmo lugar:

```
ana@vm:~/agenda$ sudo install -d -m 755 /etc/ssl/agenda
ana@vm:~/agenda$ sudo openssl req -x509 -newkey ec -pkeyopt ec_paramgen_curve:prime256v1 -nodes -days 90 -subj "/CN=agenda.example.org" -addext "subjectAltName=DNS:agenda.example.org,DNS:api.agenda.example.org" -keyout /etc/ssl/agenda/agenda.key -out /etc/ssl/agenda/agenda.crt
-----
ana@vm:~/agenda$ openssl x509 -in /etc/ssl/agenda/agenda.crt -noout -subject -ext subjectAltName -enddate
subject=CN = agenda.example.org
X509v3 Subject Alternative Name: 
    DNS:agenda.example.org, DNS:api.agenda.example.org
notAfter=Jan 21 00:55:58 2027 GMT
```

O certificado cobre os dois nomes, por noventa dias. Troque o site por uma versão que redireciona a
porta 80 e serve a 443:

```conf
# /etc/nginx/sites-available/agenda
server {
    listen 80;
    server_name agenda.example.org api.agenda.example.org;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl;
    server_name agenda.example.org;

    ssl_certificate /etc/ssl/agenda/agenda.crt;
    ssl_certificate_key /etc/ssl/agenda/agenda.key;

    location /static/ {
        alias /var/www/agenda/static/;
    }

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}

server {
    listen 443 ssl;
    server_name api.agenda.example.org;

    ssl_certificate /etc/ssl/agenda/agenda.crt;
    ssl_certificate_key /etc/ssl/agenda/agenda.key;

    add_header X-Content-Type-Options nosniff always;
    add_header X-Frame-Options DENY always;
    add_header Referrer-Policy same-origin always;
    add_header Strict-Transport-Security "max-age=3600" always;

    location / {
        proxy_pass http://127.0.0.1:8001;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

```
ana@vm:~/agenda$ sudo nginx -t && sudo systemctl reload nginx
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
ana@vm:~/agenda$ curl -sI http://127.0.0.1/events/ -H "Host: agenda.example.org" | grep -iE "^(HTTP|location)"
HTTP/1.1 301 Moved Permanently
Location: https://agenda.example.org/events/
```

A porta 80 agora só redireciona. Por HTTPS, o curl recusa o certificado até ser mandado confiar nele,
que é o que um navegador faria, e **a resposta certa é confiar nele, nunca desligar a conferência**:

```
ana@vm:~/agenda$ curl -s -o /dev/null -w "%{http_code}\n" --resolve agenda.example.org:443:127.0.0.1 https://agenda.example.org/events/
000
ana@vm:~/agenda$ curl -s -o /dev/null -w "%{http_code}\n" --cacert /etc/ssl/agenda/agenda.crt --resolve agenda.example.org:443:127.0.0.1 https://agenda.example.org/events/
200
ana@vm:~/agenda$ curl -sI --cacert /etc/ssl/agenda/agenda.crt --resolve agenda.example.org:443:127.0.0.1 https://agenda.example.org/admin/login/ | grep -iE "^(HTTP|strict|set-cookie)" | cut -c1-90
HTTP/1.1 200 OK
Strict-Transport-Security: max-age=3600
Set-Cookie: csrftoken=AG0hJHgnhth2uWK7iqNL66uEFnHdBHUg; expires=Fri, 22 Oct 2027 00:55:59 
```

O `000` foi o curl desistindo de um certificado desconhecido. Com `--cacert` a página é um 200, e a de
login traz o cabeçalho HSTS do Django e um cookie marcado `Secure`, os dois vindos das configurações que
esta aula acrescentou. A conferência da aula 15 de novo, agora com o ambiente do próprio serviço, pelo
`systemd-run`:

```
ana@vm:~/agenda$ sudo systemd-run --quiet --wait --pipe --uid=ana -p EnvironmentFile=/etc/agenda/agenda.env -p WorkingDirectory=/home/ana/agenda /home/ana/agenda/.venv/bin/python manage.py check --deploy
System check identified some issues:

WARNINGS:
?: (security.W005) You have not set the SECURE_HSTS_INCLUDE_SUBDOMAINS setting to True. Without this, your site is potentially vulnerable to attack via an insecure connection to a subdomain. Only set this to True if you are certain that all subdomains of your domain should be served exclusively via SSL.
?: (security.W021) You have not set the SECURE_HSTS_PRELOAD setting to True. Without this, your site cannot be submitted to the browser preload list.

System check identified 2 issues (0 silenced).
```

Os quatro avisos de HTTPS sumiram. Os dois que sobram são deliberados: **include subdomains** e
**preload** estendem o HSTS a todo nome abaixo do domínio e às listas embutidas dos navegadores, e os
dois são difíceis de desfazer, então um site os liga depois que o HSTS rodou sem problemas por um tempo,
que é o que o `max-age` curto de uma hora permite.

## O que a aplicação acredita

Atrás de um proxy, toda requisição chega à aplicação vinda de `127.0.0.1`, por HTTP simples. Dois
cabeçalhos dizem o contrário, e **só porque se confia no nginx para escrevê-los**.

O `X-Forwarded-Proto` é o que o `SECURE_PROXY_SSL_HEADER` lê: o Django trata uma requisição como HTTPS
quando esse cabeçalho diz `https`, que é o motivo de o cookie seguro ter sido definido. Sem ele, o
`SECURE_SSL_REDIRECT` mandaria toda requisição de volta para HTTPS, para sempre; a próxima seção mostra
esse laço.

O `X-Forwarded-For` é o endereço do cliente. Pergunte à API de outro endereço local, `127.0.0.2`, uma vez
normalmente e uma vez com um cabeçalho forjado:

```
ana@vm:~/agenda$ curl -s -o /dev/null --interface 127.0.0.2 --cacert /etc/ssl/agenda/agenda.crt --resolve api.agenda.example.org:443:127.0.0.1 https://api.agenda.example.org/events/django-night
ana@vm:~/agenda$ curl -s -o /dev/null --interface 127.0.0.2 -H "X-Forwarded-For: 203.0.113.9" --cacert /etc/ssl/agenda/agenda.crt --resolve api.agenda.example.org:443:127.0.0.1 https://api.agenda.example.org/events/django-night
ana@vm:~/agenda$ journalctl -u agenda-api -n 2 --no-pager -o cat
INFO:     127.0.0.2:0 - "GET /events/django-night HTTP/1.0" 200 OK
INFO:     127.0.0.2:0 - "GET /events/django-night HTTP/1.0" 200 OK
ana@vm:~/agenda$ sudo tail -2 /var/log/nginx/access.log | cut -c1-110
127.0.0.2 - - [23/Oct/2026:00:56:00 +0000] "GET /events/django-night HTTP/1.1" 200 162 "-" "curl/8.5.0"
127.0.0.2 - - [23/Oct/2026:00:56:00 +0000] "GET /events/django-night HTTP/1.1" 200 162 "-" "curl/8.5.0"
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 194\" role=\"img\" aria-label=\"O curl, conectando de 127.0.0.2, manda um X-Forwarded-For forjado de 203.0.113.9. O nginx acrescenta o endereço que viu, dando 203.0.113.9, 127.0.0.2. O Uvicorn, que só confia em 127.0.0.1, de onde o nginx se conecta, toma a última entrada não confiável, 127.0.0.2, como o cliente.\"> <defs><marker id=\"fw-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs> <rect x=\"10\" y=\"60\" width=\"190\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"105\" y=\"84\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">curl, de 127.0.0.2</text> <text x=\"105\" y=\"102\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">X-Forwarded-For: 203.0.113.9</text> <path d=\"M200 90 L226 90\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#fw-a)\"></path> <rect x=\"230\" y=\"60\" width=\"200\" height=\"60\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.15\" stroke=\"var(--phosphor)\"></rect> <text x=\"330\" y=\"84\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o nginx acrescenta quem viu</text> <text x=\"330\" y=\"102\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">203.0.113.9, 127.0.0.2</text> <path d=\"M430 90 L486 90\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#fw-a)\"></path> <rect x=\"490\" y=\"60\" width=\"210\" height=\"60\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"595\" y=\"84\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o uvicorn só confia em 127.0.0.1</text> <text x=\"595\" y=\"102\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">client = 127.0.0.2</text> <text x=\"360\" y=\"160\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">Leia da direita, e pare no primeiro endereço em que você não confia:</text> <text x=\"360\" y=\"178\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">tudo à esquerda dele é o que o cliente escolheu escrever.</text> </svg>", "caption": "Por que o endereço forjado não chegou ao log da API: o cabeçalho é uma lista, e só a ponta direita dela é escrita por algo confiável."}
```

**As duas requisições estão no log como 127.0.0.2**, no log do nginx e no do Uvicorn. O
`--proxy-headers` faz o Uvicorn ler o cabeçalho; o `--forwarded-allow-ips 127.0.0.1` diz que só as
entradas do nginx são acreditadas, então o `203.0.113.9` forjado à esquerda delas é ignorado. O Django
não tem configuração equivalente: o `REMOTE_ADDR` é sempre o endereço do proxy, e uma view que precise
do endereço do cliente tem de ler o cabeçalho do mesmo jeito cuidadoso, pela direita.
