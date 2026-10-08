---
title: Qual location responde
version: 1
---

Um site de verdade tem mais de dois tipos de caminho, e o Nginx precisa escolher um `location` para
cada requisição. As regras de escolha são curtas e não são as que a maioria das pessoas imagina. Para
vê-las funcionando, cada `location` desta versão do site acrescenta um cabeçalho com o próprio nome:

```conf
    location / {
        try_files $uri $uri/ =404;
        add_header X-Location "prefix /";
    }

    location /api/ {
        proxy_pass http://shop;
        # ...the proxy settings of the previous sections...
        add_header X-Location "prefix /api/";
    }

    location = /healthz {
        proxy_pass http://shop;
        add_header X-Location "exact /healthz";
    }

    location ~* \.(css|js|svg)$ {
        add_header X-Location "regex static";
    }

    location /covers/ {
        alias /var/www/ipe/img/;
        add_header X-Location "prefix /covers/";
    }
```

Oito caminhos, e qual `location` respondeu a cada um:

```
ana@web:~$ for p in / /index.html /healthz /api/books/2 /css/site.css /covers/logo.svg /api/app.js /nope; do printf '%-18s ' $p; curl -s -o /dev/null -D - http://ipelivros.example$p | grep -iE '^(HTTP|X-Location)' | tr -d '\r' | tr '\n' ' '; echo; done
/                  HTTP/1.1 200 OK X-Location: prefix / 
/index.html        HTTP/1.1 200 OK X-Location: prefix / 
/healthz           HTTP/1.1 200 OK X-Location: exact /healthz 
/api/books/2       HTTP/1.1 200 OK X-Location: prefix /api/ 
/css/site.css      HTTP/1.1 200 OK X-Location: regex static 
/covers/logo.svg   HTTP/1.1 404 Not Found 
/api/app.js        HTTP/1.1 404 Not Found 
/nope              HTTP/1.1 404 Not Found 
```

Os cinco primeiros são o que qualquer um esperaria. `/healthz` bateu com o location **exato**,
escrito com `=`, que ganha de todos. `/api/books/2` bateu com o prefixo mais longo. `/css/site.css`
bateu com a expressão regular, `~*` querendo dizer sem diferenciar maiúsculas.

Os dois seguintes são a lição. **`/covers/logo.svg` devia ter sido servido por `/covers/`, e não
foi.** A ordem do Nginx é:

1. um casamento exato com `=` ganha na hora;
2. senão, o **prefixo mais longo** que casa é achado e guardado;
3. se esse prefixo está marcado com `^~`, ele ganha, e nenhuma expressão regular é tentada;
4. senão, as expressões regulares são tentadas **na ordem em que aparecem no arquivo**, e a primeira
   que casa ganha;
5. só se nenhuma casar é que o prefixo guardado responde.

Então `/covers/logo.svg` teve `/covers/` como prefixo mais longo, e depois a regex de estáticos, que
também casa com qualquer coisa terminada em `.svg`, ficou com ele. Esse location não tem `alias`, então
o Nginx procurou `/var/www/ipe/covers/logo.svg`, que não existe. O mesmo aconteceu com `/api/app.js`:
uma requisição destinada à aplicação acabou numa busca de arquivo. Um `404` não traz `X-Location`,
porque o `add_header` só acrescenta em respostas de sucesso, a não ser que seja escrito com `always`.

**O `^~` é a correção: ele diz "se este prefixo é o mais longo, pare de procurar".**

```
ana@web:~$ sudo sed -i 's|    location /covers/ {|    location ^~ /covers/ {|' /etc/nginx/sites-available/ipelivros && grep -n 'covers' /etc/nginx/sites-available/ipelivros
40:    location ^~ /covers/ {
42:        add_header X-Location "prefix /covers/";
ana@web:~$ curl -s -o /dev/null -D - http://ipelivros.example/covers/logo.svg | grep -iE '^(HTTP|X-Location)'
HTTP/1.1 200 OK
X-Location: prefix /covers/
```

## `root`, `alias` e `try_files`

`root` **acrescenta** o caminho inteiro da requisição a um diretório. `alias` **troca** a parte que
casou com o location. Com `location /covers/` e `alias /var/www/ipe/img/`, `/covers/logo.svg` vira
`/var/www/ipe/img/logo.svg`; com `root /var/www/ipe/img/` teria virado
`/var/www/ipe/img/covers/logo.svg`. Mantenha a barra final no location e no alias, ou os dois se
juntam num caminho que não existe.

`try_files $uri $uri/ =404` confere cada candidato na ordem e serve o primeiro que existe, e o último
é o que acontece caso contrário. Uma aplicação de página única usa a mesma linha com `/index.html` no
fim em vez de `=404`, então todo caminho desconhecido carrega a aplicação, que desenha a própria
página. A vitrine da livraria é HTML simples, então um caminho desconhecido é um `404` honesto.
