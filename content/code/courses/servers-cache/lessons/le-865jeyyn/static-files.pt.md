---
title: Servindo arquivos estáticos bem
version: 1
---

Tudo sob `/var/www/ipe` é servido pelo Nginx sem a aplicação nem ficar sabendo, e isso é quase tudo
o que uma página web pede: a folha de estilo, o script, as imagens. Três configurações decidem quão
bem isso é feito.

## Compressão

O `nginx.conf` do Ubuntu liga a compressão com `gzip on`, e deixa a parte útil comentada:

```
ana@web:~$ grep -n gzip /etc/nginx/nginx.conf
46:	gzip on;
48:	# gzip_vary on;
49:	# gzip_proxied any;
50:	# gzip_comp_level 6;
51:	# gzip_buffers 16 8k;
52:	# gzip_http_version 1.1;
53:	# gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;
```

Sem `gzip_types`, o Nginx comprime `text/html` e nada mais. A folha de estilo, o script e o JSON da
API saem como estão, mesmo para um cliente que pediu gzip:

```
ana@web:~$ curl -s -o /dev/null -w '%{size_download} bytes\n' -H 'Accept-Encoding: gzip' http://ipelivros.example/api/books
723 bytes
ana@web:~$ curl -sI -H 'Accept-Encoding: gzip' http://ipelivros.example/js/app.js | grep -iE 'content-(type|encoding|length)'
Content-Type: application/javascript
Content-Length: 462
```

Um arquivo em `conf.d` é incluído dentro de `http { }`, então três linhas ali valem para todo site:

```
ana@web:~$ cat /etc/nginx/conf.d/gzip.conf
gzip_types text/css application/javascript application/json image/svg+xml;
gzip_min_length 256;
gzip_vary on;
ana@web:~$ curl -sI -H 'Accept-Encoding: gzip' http://ipelivros.example/js/app.js | grep -iE 'content-(type|encoding|length)|vary'
Content-Type: application/javascript
Vary: Accept-Encoding
Content-Encoding: gzip
ana@web:~$ curl -s -o /dev/null -w '%{size_download} bytes\n' -H 'Accept-Encoding: gzip' http://ipelivros.example/api/books
303 bytes
ana@web:~$ curl -s -o /dev/null -w '%{size_download} bytes\n' http://ipelivros.example/api/books
723 bytes
```

O catálogo foi de 723 bytes para 303 para um cliente que aceita gzip, e ficou em 723 para um que não
aceita. **O `gzip_types` lista o que comprimir, e a lista é sobre o que se comprime**: texto, JSON,
JavaScript e SVG encolhem para um terço ou menos; JPEG, PNG, WebP e vídeo já vêm comprimidos e só
gastam CPU na tentativa. `gzip_min_length 256` pula respostas tão pequenas que o cabeçalho do gzip
pesa mais que a economia. E `gzip_vary on` acrescenta `Vary: Accept-Encoding`, que avisa a qualquer
cache entre aqui e o navegador que a cópia comprimida e a não comprimida são respostas diferentes. A
aula 5 mostra o que dá errado sem isso.

O Nginx comprime a cada requisição, o que é barato neste tamanho. Para arquivos grandes que nunca
mudam, `gzip_static on` manda um `.gz` escrito de antemão ao lado do arquivo, comprimido uma vez no
nível mais alto em vez de a cada requisição.

## `sendfile` e o kernel

`sendfile on`, que já está no `nginx.conf` do Ubuntu, deixa o kernel copiar um arquivo direto do
cache de páginas para o socket, sem os bytes passarem pela memória do Nginx. É por isso que um
servidor web corre mais que um programa que lê um arquivo e o escreve de volta. Ele não combina com
gzip: uma resposta comprimida precisa passar pelo Nginx para ser comprimida.

## Recusando o que é grande demais

Um servidor web lê o corpo da requisição antes de a aplicação vê-lo, então é o lugar para recusar um
que seja absurdo. O limite padrão é um megabyte:

```
ana@web:~$ head -c 2000000 /dev/zero | curl -s -o /dev/null -w '%{http_code}\n' -X PUT --data-binary @- http://ipelivros.example/api/books/1
413
ana@web:~$ tail -n 1 /var/log/nginx/ipelivros.error.log
2026/10/07 00:26:35 [error] 1433#1433: *325 client intended to send too large body: 2000000 bytes, client: 127.0.0.1, server: ipelivros.example, request: "PUT /api/books/1 HTTP/1.1", host: "ipelivros.example"
```

O `413` é respondido a partir do `Content-Length` que o cliente anunciou, antes de dois megabytes serem
lidos. `client_max_body_size` o aumenta por site ou por location, e um formulário de upload é o único
lugar onde deve: `client_max_body_size 20m;` dentro de `location /upload/` e em nenhum outro.
