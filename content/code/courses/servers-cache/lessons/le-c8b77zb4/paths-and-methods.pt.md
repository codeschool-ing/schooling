---
title: Arquivos que não deviam estar ali, e métodos que ninguém usa
version: 1
---

Uma raiz web acumula coisas que ninguém pretendia publicar: o backup de um editor, um `.env` com uma
senha dentro, um diretório `.git` inteiro copiado junto num deploy. Dê um `.git` a esta, como um deploy descuidado daria, com um arquivo dentro que diz de onde vem o
código:

```sh
sudo mkdir -p /var/www/ipe/.git && printf "[core]\n\trepositoryformatversion = 0\n[remote \"origin\"]\n\turl = git@git.example:ipe/site.git\n" | sudo tee /var/www/ipe/.git/config >/dev/null
```

O Nginx serve o que estiver numa raiz web:

```
ana@web:~$ ls -A /var/www/ipe
.git
css
img
index.html
js
ana@web:~$ curl -s -o /dev/null -w '%{http_code}\n' https://ipelivros.example/.git/config
200
```

`200`. Um diretório `.git` é o histórico completo do site, todo arquivo já commitado e toda senha já
commitada por engano, e há scanners que só procuram `/.git/config` em todo endereço que encontram. **A
correção de verdade é um deploy que nunca o copie**; o trabalho do servidor é tornar o erro inofensivo
quando ele acontece mesmo assim. Um location recusa todo caminho com um componente que começa com
ponto, exceto o único diretório de que o ACME precisa:

```
ana@web:~$ sudo sed -i '0,/    location \/ {/s||    location ~ /\\.(?!well-known/) {\n        return 404;\n    }\n\n    location / {|' /etc/nginx/sites-available/ipelivros && grep -n -A2 'location ~' /etc/nginx/sites-available/ipelivros
18:    location ~ /\.(?!well-known/) {
19-        return 404;
20-    }
ana@web:~$ curl -s -o /dev/null -w '%{http_code}\n' https://ipelivros.example/.git/config
404
ana@web:~$ curl -s -o /dev/null -w '%{http_code}\n' http://ipelivros.example/.well-known/acme-challenge/test
404
```

Ele devolve `404` em vez de `403`, então a resposta para um arquivo oculto que existe é a mesma de um
que não existe, e uma varredura não aprende nada. O caminho do desafio continua chegando ao próprio
location.

## Métodos

A API entende `GET` e `PUT`. Todo o resto chega à aplicação mesmo assim, e se é recusado ou não
depende de quão cuidadosa foi a escrita da aplicação:

```
ana@web:~$ for m in GET PUT DELETE TRACE; do printf '%-6s ' $m; curl -s -o /dev/null -w '%{http_code}\n' -X $m -d '{"price_cents": 4990}' https://ipelivros.example/api/books/1; done
GET    200
PUT    200
DELETE 405
TRACE  405
```

O `DELETE` recebeu `405` da loja, que por acaso responde a ele corretamente. O `TRACE` recebeu `405`
do Nginx, que nunca o repassa. **O `limit_except` deixa o Nginx recusar todo outro método antes de a
aplicação vê-lo**, então um endpoint que ninguém testou com `DELETE` não é o único lugar onde um
`DELETE` faz alguma coisa:

```
ana@web:~$ sudo sed -i 's|        proxy_pass http://shop;|        limit_except GET HEAD PUT { deny all; }\n        proxy_pass http://shop;|' /etc/nginx/sites-available/ipelivros
ana@web:~$ for m in GET PUT DELETE TRACE; do printf '%-6s ' $m; curl -s -o /dev/null -w '%{http_code}\n' -X $m -d '{"price_cents": 4990}' https://ipelivros.example/api/books/1; done
GET    200
PUT    200
DELETE 403
TRACE  405
```

O `DELETE` agora recebe `403` do próprio Nginx. O `GET` traz o `HEAD` junto automaticamente, por isso
o `HEAD` aparece na lista só para facilitar a leitura.
