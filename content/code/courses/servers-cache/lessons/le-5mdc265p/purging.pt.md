---
title: Limpando uma URL, e limpando por etiqueta
version: 1
---

A aula 6 trocava uma cópia de cada vez, por URL. Uma borda também faz isso, e faz algo que o Nginx não
faz: remove **toda cópia que traz uma etiqueta**, seja qual for a URL.

## Uma URL

`PURGE` não é um método HTTP definido por nenhum padrão; é uma convenção que o Varnish, o Squid e as APIs
de muitas CDNs compartilham. O `vcl_recv` acima o aceita só de `purgers`:

```
ana@web:~$ curl -s -o /dev/null -D - -H 'Host: ipelivros.example' http://localhost:6081/api/books/5 | grep -iE '^(age|x-cache|x-varnish|cache-control)'
Cache-Control: public, max-age=60
X-Varnish: 18
Age: 0
X-Cache: MISS
ana@web:~$ curl -s -o /dev/null -w '%{http_code}\n' -X PURGE -H 'Host: ipelivros.example' http://localhost:6081/api/books/5
200
ana@web:~$ curl -s -o /dev/null -D - -H 'Host: ipelivros.example' http://localhost:6081/api/books/5 | grep -iE '^(age|x-cache|x-varnish|cache-control)'
Cache-Control: public, max-age=60
X-Varnish: 21
Age: 0
X-Cache: MISS
```

Uma cópia, um `PURGE` respondido com `200`, e a requisição seguinte errou e a buscou de novo. Um `PURGE`
de um endereço fora da lista recebe `403`, e essa lista é a diferença entre um recurso de limpeza e um
jeito de qualquer um esvaziar o cache.

## Por etiqueta

O preço do livro 2 aparece na página dele e na listagem. Limpar por URL precisa das duas URLs, e quem
muda o preço precisa saber toda página que o mostra. **As etiquetas invertem isso: cada resposta diz o
que contém, e uma limpeza nomeia a coisa que mudou.** A origem etiqueta a página do livro como `book-2` e
a listagem como `listing`, o tratamento de `BAN` transforma um cabeçalho num **ban**, uma regra contra a
qual todo objeto guardado é conferido, e uma mudança de preço vira uma requisição:

```
ana@web:~$ for p in /api/books /api/books/2 /api/books/6; do printf '%-14s ' $p; curl -s -o /dev/null -D - -H 'Host: ipelivros.example' http://localhost:6081$p | grep -i x-cache; done
/api/books     X-Cache: HIT
/api/books/2   X-Cache: HIT
/api/books/6   X-Cache: HIT
ana@web:~$ curl -s -X PUT -d '{"price_cents": 7490}' -H 'Host: ipelivros.example' http://localhost:6081/api/books/2 | jq -c '{title, price_cents}'
{"title":"Grande Sertão: Veredas","price_cents":7490}
ana@web:~$ curl -s -o /dev/null -w '%{http_code}\n' -X BAN -H 'X-Ban-Tags: \b(book-2|listing)\b' -H 'Host: ipelivros.example' http://localhost:6081/
200
ana@web:~$ for p in /api/books /api/books/2 /api/books/6; do printf '%-14s ' $p; curl -s -o /dev/null -D - -H 'Host: ipelivros.example' http://localhost:6081$p | grep -i x-cache; done
/api/books     X-Cache: MISS
/api/books/2   X-Cache: MISS
/api/books/6   X-Cache: HIT
```

```
ana@web:~$ curl -s -H 'Host: ipelivros.example' http://localhost:6081/api/books/2 | jq -c '{title, price_cents}'
{"title":"Grande Sertão: Veredas","price_cents":7490}
ana@web:~$ sudo varnishadm ban.list
Present bans:
1791346659.490675     3 -  obj.http.Surrogate-Key ~ \b(book-2|listing)\b
1791346651.698669     3 C  
```

A listagem e o livro 2 erraram, o livro 6 não foi tocado, e o preço novo apareceu na primeira
requisição. `ban.list` mostra a regra, mantida até todo objeto mais velho que ela ser conferido; o
Varnish testa os objetos com preguiça, quando são pedidos, e uma thread em segundo plano limpa o resto.

A etiqueta no cabeçalho é uma expressão regular, e `\b` marca uma fronteira de palavra, para `book-2` não
casar também com `book-21`. CDNs comerciais oferecem o mesmo com outros nomes: as **surrogate keys** da
Fastly (o nome de cabeçalho usado aqui), as **cache tags** da Cloudflare, as **cache tags** da Akamai. A
ideia é sempre a desta seção: a origem diz o que há numa resposta, e a invalidação nomeia o que mudou.
