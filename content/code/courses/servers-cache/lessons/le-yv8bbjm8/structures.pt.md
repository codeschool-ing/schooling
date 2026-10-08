---
title: Hashes, listas, conjuntos e conjuntos ordenados
version: 1
---

Os outros quatro tipos são o que torna o Redis mais que um cache de strings: cada um responde no
servidor a uma pergunta que, de outro jeito, exigiria ler um valor inteiro para a aplicação, mudá-lo e
gravá-lo de volta.

**Um hash** é um registro pequeno: campos com nome dentro de uma chave.

```
ana@web:~$ redis-cli HSET book:2 title "Grande Sertão: Veredas" price_cents 8990 stock 4
3
ana@web:~$ redis-cli HGET book:2 price_cents; redis-cli HINCRBY book:2 stock -1; redis-cli HGETALL book:2
8990
3
title
Grande Sertão: Veredas
price_cents
8990
stock
3
```

Um campo pode ser lido ou mudado sem mexer nos outros, e o `HINCRBY` tira uma unidade do estoque de forma
atômica, como o `INCR` numa string. Um livro inteiro guardado como JSON numa string exigiria uma
leitura, uma mudança na aplicação e uma gravação, com uma corrida no meio.

**Uma lista** guarda ordem, e com o `LTRIM` guarda um número fixo dos itens mais recentes:

```
ana@web:~$ for b in 3 7 2 9 3; do redis-cli LPUSH recent:ana book:$b > /dev/null; done; redis-cli LTRIM recent:ana 0 2; redis-cli LRANGE recent:ana 0 -1
OK
book:3
book:9
book:2
```

Cinco visualizações empurradas pela esquerda, `book:3` duas vezes; cortada em três, a lista são os três
últimos em ordem de recência. "Vistos recentemente" na página de uma loja é isso, um `LPUSH` e um `LTRIM`
por visualização.

**Um conjunto** guarda membros sem ordem nem repetição, e conjuntos podem ser intersectados no servidor:

```
ana@web:~$ redis-cli SADD tag:classic book:4 book:11 book:2; redis-cli SADD tag:sertao book:2 book:12 book:1; redis-cli SINTER tag:classic tag:sertao
3
3
book:2
```

**Um conjunto ordenado** dá uma nota a cada membro e os mantém ordenados por ela:

```
ana@web:~$ redis-cli ZINCRBY bestsellers 5 book:9; redis-cli ZINCRBY bestsellers 3 book:2; redis-cli ZINCRBY bestsellers 4 book:4; redis-cli ZINCRBY bestsellers 2 book:2
5
3
4
5
ana@web:~$ redis-cli ZREVRANGE bestsellers 0 2 WITHSCORES
book:9
5
book:2
5
book:4
4
```

O `ZINCRBY` somou ao `book:2` duas vezes, 3 e depois 2, e o ranking é calculado pelo Redis, não pela
aplicação. Um empate em 5 é desfeito pelo nome, em ordem inversa, e por isso o `book:9` veio primeiro.
Mais vendidos, placares e "mais vistos nesta hora" são todos um conjunto ordenado.

```
ana@web:~$ redis-cli --scan --pattern "book:*"; redis-cli DBSIZE
book:2
8
```

O `--scan` percorre as chaves em lotes pequenos sem travar o servidor, o substituto seguro do `KEYS *`
de que a primeira seção avisou, e o `DBSIZE` conta todas.

| tipo | guarda | um uso típico |
|---|---|---|
| string | bytes, ou um inteiro | um documento JSON em cache, um contador, um lock |
| hash | campos com nome | um registro cujos campos mudam separados |
| lista | uma sequência ordenada | itens recentes, uma fila simples |
| conjunto | membros únicos | etiquetas, quem está online |
| conjunto ordenado | membros com notas | rankings, coisas ordenadas por tempo |
