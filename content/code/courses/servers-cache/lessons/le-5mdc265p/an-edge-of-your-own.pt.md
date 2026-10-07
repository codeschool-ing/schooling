---
title: Uma borda sua, com o Varnish
version: 1
---

O **Varnish** é um cache que não faz nada além de cache HTTP, e a CDN Fastly nasceu dele. Ele está no
repositório do Ubuntu e o `lab.sh install` o pôs no seu servidor, parado. Aqui ele faz o papel da borda,
e o Nginx faz o papel da origem.

A origem precisa de mais um bloco server: HTTP simples, num endereço que só a própria máquina alcança,
servindo o mesmo site sem cache próprio, para que a borda seja o único cache desta figura. Ele também
etiqueta cada resposta da API com um cabeçalho `Surrogate-Key`, que a seção sobre limpeza por etiqueta
usa:

```
ana@web:~$ cat /etc/nginx/sites-available/origin
# The origin, as the edge sees it: plain HTTP, on an address only this
# machine can reach. Every response carries the tags the edge purges by.
server {
    listen 127.0.0.1:8080;
    server_name ipelivros.example;

    root /var/www/ipe;

    location / {
        try_files $uri $uri/ =404;
    }

    location = /healthz {
        proxy_pass http://shop;
    }

    location = /api/books {
        proxy_pass http://shop;
        add_header Surrogate-Key "listing";
    }

    location ~ ^/api/books/(\d+)$ {
        proxy_pass http://shop;
        add_header Surrogate-Key "book-$1";
    }
}
ana@web:~$ sudo ln -s ../sites-available/origin /etc/nginx/sites-enabled/origin
ana@web:~$ curl -sI -H 'Host: ipelivros.example' http://127.0.0.1:8080/api/books/2 | grep -iE '^(HTTP|cache-control|surrogate-key|x-served-by)'
HTTP/1.1 200 OK
X-Served-By: shop1
Cache-Control: public, max-age=60
Surrogate-Key: book-2
```

A origem ainda responde com o `Cache-Control: public, max-age=60` da loja, e agora uma etiqueta. O
Varnish é configurado em **VCL**, uma linguagem pequena com uma função por etapa de uma requisição. Este
arquivo nomeia a origem e como conferir a saúde dela, quem pode limpar, e três políticas pequenas, cada
uma explicada na seção que a usa:

```conf
vcl 4.1;

# The origin: Nginx on 127.0.0.1:8080, asked every two seconds whether it is
# well, and treated as sick after two failed answers out of three.
backend origin {
    .host = "127.0.0.1";
    .port = "8080";
    .probe = {
        .url = "/healthz";
        .interval = 2s;
        .timeout = 1s;
        .window = 3;
        .threshold = 2;
    }
}

# Who may purge. On a real edge, the machines that publish content.
acl purgers {
    "127.0.0.1";
}

sub vcl_recv {
    # Tracking parameters change the URL and never the answer.
    set req.url = regsuball(req.url, "(?<=[?&])utm_[a-z]+=[^&]*&?", "");
    set req.url = regsub(req.url, "[?&]$", "");

    if (req.method == "PURGE") {
        if (client.ip !~ purgers) {
            return (synth(403, "Forbidden"));
        }
        return (purge);
    }
    if (req.method == "BAN") {
        if (client.ip !~ purgers) {
            return (synth(403, "Forbidden"));
        }
        ban("obj.http.Surrogate-Key ~ " + req.http.X-Ban-Tags);
        return (synth(200, "Banned"));
    }
}

sub vcl_backend_response {
    # Keep an expired object for an hour, to serve while the origin is
    # fetched again or while it is down.
    set beresp.grace = 1h;
}

sub vcl_deliver {
    if (obj.hits > 0) {
        set resp.http.X-Cache = "HIT";
    } else {
        set resp.http.X-Cache = "MISS";
    }
    # The tags are for the edge, not for the public.
    unset resp.http.Surrogate-Key;
}
```

O que o arquivo não diz importa tanto quanto: todo o resto é a **lógica embutida do Varnish**, que roda
depois de cada uma dessas funções a não ser que a função retorne antes. É o motivo de o arquivo poder
ser tão curto, e a próxima seção trata da coisa mais importante que ela faz.

```
ana@web:~$ sudo varnishd -C -f /etc/varnish/default.vcl > /dev/null 2>&1 && echo "VCL compiles"
VCL compiles
ana@web:~$ sudo systemctl start varnish && systemctl is-active varnish
active
ana@web:~$ sudo ss -ltnp | grep -E ':(6081|6082|8080) ' | awk '{print $4, $6}'
127.0.0.1:8080 users:(("nginx",pid=1370,fd=21),("nginx",pid=1369,fd=21),("nginx",pid=1368,fd=21),("nginx",pid=1367,fd=21),("nginx",pid=177,fd=21))
0.0.0.0:6081 users:(("cache-main",pid=1431,fd=3),("varnishd",pid=1405,fd=3))
127.0.0.1:6082 users:(("varnishd",pid=1405,fd=6))
```

O Varnish escuta na 6081 para os visitantes e na 6082, só no loopback, para os comandos de
administração. Peça um livro três vezes:

```
ana@web:~$ curl -s -o /dev/null -D - -H 'Host: ipelivros.example' http://localhost:6081/api/books/2 | grep -iE '^(age|x-cache|x-varnish|cache-control)'
Cache-Control: public, max-age=60
X-Varnish: 2
Age: 0
X-Cache: MISS
ana@web:~$ curl -s -o /dev/null -D - -H 'Host: ipelivros.example' http://localhost:6081/api/books/2 | grep -iE '^(age|x-cache|x-varnish|cache-control)'
Cache-Control: public, max-age=60
X-Varnish: 32770 3
Age: 0
X-Cache: HIT
ana@web:~$ sleep 3; curl -s -o /dev/null -D - -H 'Host: ipelivros.example' http://localhost:6081/api/books/2 | grep -iE '^(age|x-cache|x-varnish|cache-control)'
Cache-Control: public, max-age=60
X-Varnish: 5 3
Age: 3
X-Cache: HIT
ana@web:~$ curl -sI -H 'Host: ipelivros.example' http://localhost:6081/api/books/2 | grep -iE '^(via|surrogate-key|x-served-by)'
X-Served-By: shop2
Via: 1.1 varnish (Varnish/7.1)
```

Três cabeçalhos contam a história de uma borda, e cada CDN tem a própria grafia deles. **`X-Varnish`**
traz um número de transação num erro e dois num acerto: o desta requisição, e o da que guardou a cópia.
**`Age`** é há quantos segundos a cópia está na borda, 3 depois do `sleep 3`; o navegador do visitante o
subtrai do `max-age`, então uma cópia que passou 50 dos seus 60 segundos na borda fica fresca no
navegador por só mais 10. E **`Via`** diz que havia um proxy no caminho. A etiqueta sumiu, removida no
`vcl_deliver`, como deve, já que ela descreve o funcionamento interno do site.
