---
title: Perguntando se uma cópia ainda serve
version: 1
---

Quando uma cópia fica velha, o cache não precisa jogá-la fora e baixar a resposta inteira de novo. Ele
pode fazer à origem uma pergunta bem menor: **"tenho esta versão; ela mudou?"** Isso é uma
**requisição condicional**, e a resposta "não" é `304 Not Modified`, sem corpo.

A pergunta precisa de um jeito de nomear a versão que o cache tem, e o HTTP tem dois, que já estavam
na folha de estilo na aula 1:

- **`ETag`**, uma etiqueta opaca para este conteúdo exato. O cache a devolve em `If-None-Match`.
- **`Last-Modified`**, uma data. O cache a devolve em `If-Modified-Since`.

```
ana@web:~$ curl -sI https://ipelivros.example/css/site.css | grep -i etag
ETag: "6a96cc50-ed"
ana@web:~$ curl -s -o /dev/null -w '%{http_code} %{size_download} bytes\n' -H 'If-None-Match: "6a96cc50-ed"' https://ipelivros.example/css/site.css
304 0 bytes
ana@web:~$ curl -s -o /dev/null -w '%{http_code} %{size_download} bytes\n' -H 'If-None-Match: "6a96cc50-ee"' https://ipelivros.example/css/site.css
200 237 bytes
ana@web:~$ curl -s -o /dev/null -w '%{http_code} %{size_download} bytes\n' -H 'If-Modified-Since: Tue, 01 Sep 2026 13:00:00 GMT' https://ipelivros.example/css/site.css
304 0 bytes
```

A etiqueta certa recebe `304` e zero bytes de corpo. Uma etiqueta errada por um caractere, que é o
que um cache tem depois de o arquivo mudar, recebe o arquivo inteiro com a etiqueta nova. A data
funciona do mesmo jeito. **Quando as duas são mandadas, vale o `If-None-Match`**, porque uma data tem
resolução de um segundo e um arquivo pode mudar duas vezes num segundo; uma etiqueta não se engana
assim.

## Etiquetas fortes e fracas

```
ana@web:~$ curl -sI -H 'Accept-Encoding: gzip' https://ipelivros.example/js/app.js | grep -iE '^(etag|content-encoding)'
ETag: W/"6a96cc50-1ce"
Content-Encoding: gzip
```

O mesmo script, pedido comprimido, recebe uma etiqueta que começa com `W/`: uma etiqueta **fraca**
(*weak*). O Nginx a marca como fraca porque os bytes comprimidos não são os bytes a partir dos quais a
etiqueta foi calculada; o conteúdo quer dizer a mesma coisa, e os bytes diferem. Uma etiqueta fraca
serve para "mudou?" e não para nada que dependa dos bytes exatos, como retomar um download na metade
de um arquivo.

## A validação poupa banda, não trabalho

A loja calcula um `ETag` para cada livro a partir dos bytes do JSON, e responde ao `If-None-Match` com
um `304`, como uma aplicação deve:

```
ana@web:~$ curl -s -o /dev/null -w '%{http_code} %{size_download} bytes in %{time_total} s\n' https://ipelivros.example/api/books/1
200 124 bytes in 0.154089 s
ana@web:~$ curl -s -o /dev/null -w '%{http_code} %{size_download} bytes in %{time_total} s\n' -H 'If-None-Match: "806121fbab2ee803"' https://ipelivros.example/api/books/1
304 0 bytes in 0.158108 s
ana@web:~$ curl -s localhost:8001/api/stats; curl -s localhost:8002/api/stats
{"server": "shop1", "db_queries": 1}
{"server": "shop2", "db_queries": 1}
```

`304` e nenhum corpo, e **os mesmos 0,15 segundos**, porque a loja rodou a consulta ao banco para
montar a resposta que depois transformou em hash e comparou. Uma consulta para cada requisição, em cada
loja. O `304` poupou os 124 bytes do corpo na rede e não poupou nada do trabalho, e para um catálogo de
doze linhas numa rede local o corpo nunca foi a parte cara.

Essa é a regra geral: **a validação poupa a transferência; só o frescor poupa o trabalho.** Uma
aplicação pode fazer melhor que a loja guardando algo barato de comparar, um número de versão ou uma
coluna `updated_at`, e respondendo o `304` antes de montar a resposta. Mesmo assim ela ainda recebe a
requisição. O jeito de impedir que a requisição chegue à aplicação é uma cópia fresca, guardada na
frente dela, que é a próxima seção.
