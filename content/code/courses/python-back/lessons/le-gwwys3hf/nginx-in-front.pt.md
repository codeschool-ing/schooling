---
title: O nginx na frente das duas aplicações
version: 1
---

A configuração do nginx para um site é um arquivo em `/etc/nginx/sites-available`, habilitado por um
link em `sites-enabled`. Um arquivo guarda os dois nomes do agenda. O `/etc/nginx/sites-available/agenda`:

```conf
# /etc/nginx/sites-available/agenda
server {
    listen 80;
    server_name agenda.example.org;

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
    listen 80;
    server_name api.agenda.example.org;

    add_header X-Content-Type-Options nosniff always;
    add_header X-Frame-Options DENY always;
    add_header Referrer-Policy same-origin always;

    location / {
        proxy_pass http://127.0.0.1:8001;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

| diretiva | faz |
|---|---|
| `server_name` | a que `Host` este bloco responde: o site, ou a API |
| `location /static/` com `alias` | os arquivos que o `collectstatic` juntou, servidos pelo nginx sem chegar ao Django |
| `proxy_pass` | todo o resto, para a aplicação em `127.0.0.1` |
| `proxy_set_header Host $host` | passa o nome que o cliente pediu, que o `ALLOWED_HOSTS` confere |
| `X-Forwarded-For`, `X-Forwarded-Proto` | o endereço do cliente, e se ele usou HTTPS; a próxima seção precisa dos dois |
| `add_header` | cabeçalhos em toda resposta da API; o `always` inclui os erros |

**Os cabeçalhos estão ali porque o FastAPI não os acrescenta**, e o Django sim: o `SecurityMiddleware` e o
`XFrameOptionsMiddleware` dele já mandam `X-Content-Type-Options` e `X-Frame-Options`. Pô-los no nginx
protege o que quer que rode atrás dele.

Habilite o site, desabilite o padrão, e **teste antes de recarregar**, para que um erro nunca chegue ao
servidor que está rodando:

```
ana@vm:~/agenda$ sudo ln -s /etc/nginx/sites-available/agenda /etc/nginx/sites-enabled/agenda
ana@vm:~/agenda$ sudo rm /etc/nginx/sites-enabled/default
ana@vm:~/agenda$ sudo nginx -t
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
ana@vm:~/agenda$ sudo systemctl reload nginx
```

Pelo nginx, pelo nome:

```
ana@vm:~/agenda$ curl -sI -H "Host: agenda.example.org" http://127.0.0.1/static/events/agenda.css | grep -iE "^(HTTP|server|content-type|content-length)"
HTTP/1.1 200 OK
Server: nginx/1.24.0 (Ubuntu)
Content-Type: text/css
Content-Length: 206
ana@vm:~/agenda$ curl -sI -H "Host: agenda.example.org" http://127.0.0.1/events/ | grep -iE "^(HTTP|location)"
HTTP/1.1 301 Moved Permanently
Location: https://agenda.example.org/events/
ana@vm:~/agenda$ curl -s -D - -o /dev/null -H "Host: api.agenda.example.org" http://127.0.0.1/events | grep -iE "^(HTTP|server|x-|referrer)"
HTTP/1.1 200 OK
Server: nginx/1.24.0 (Ubuntu)
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
Referrer-Policy: same-origin
```

A folha de estilos veio do próprio nginx, do disco. A página do site é o 301 do Django para HTTPS,
através do nginx. E a API respondeu com os três cabeçalhos acrescentados.
