---
title: Relevância, erros de digitação e facetas
version: 1
---

Busque café torrado, do jeito que um cliente digitaria:

```
ana@vm:~/lab/search$ $R search.py café torrado
5 matches
  11.10  Café torrado em grãos
   5.67  Café descafeinado
   4.83  Café moído tradicional
   4.83  Café em cápsulas
   1.60  Farinha de mandioca
categories: café (4), mercearia (1)
```

Cinco produtos, em ordem, cada um com uma **pontuação**, e uma contagem por categoria ao lado. A
pontuação é o **BM25**, a função de ordenação que todo motor desta aula usa por padrão. Três coisas a
aumentam: o termo aparece no campo (mais vezes conta, com retornos decrescentes), o termo é **raro** naquele campo
no catálogo (entre os nomes, `torr` está em um e `caf` em quatro, então `torr` vale mais), e o campo é
**curto** (uma combinação num nome de cinco palavras diz mais que uma numa descrição longa). O `name^3` no
`search.py` acrescenta uma quarta: uma combinação no nome conta três vezes mais que uma na descrição. É
por isso que `Café torrado em grãos` vem primeiro, com as duas palavras no nome, os outros cafés vêm atrás
por `café`, e `Farinha de mandioca` vem por último, achada só pelo `torrada` da descrição.

O banco, perguntado do jeito óbvio, se sai pior com as mesmas palavras:

```
ana@vm:~/lab/search$ docker compose exec -T db psql -U postgres -c "SELECT name FROM products WHERE name ILIKE '%cafe torrado%'" -c "SELECT name FROM products WHERE name ILIKE '%café torrado%'"
 name 
------
(0 rows)

         name          
-----------------------
 Café torrado em grãos
(1 row)
```

Sem o acento, nada; com ele, uma linha, porque só um nome tem as duas palavras lado a lado.

Agora um cliente com pressa digita `cafe torado`. O acento não importa mais, mas `torado` não é uma
palavra do índice:

```
ana@vm:~/lab/search$ $R search.py cafe torado
4 matches
   5.67  Café descafeinado
   4.83  Café moído tradicional
   4.83  Café em cápsulas
   4.20  Café torrado em grãos
categories: café (4)
```

Os cafés ainda são achados, por `cafe`, mas o que o cliente queria caiu para quarto, porque nada combinou
com `torado`. O `--fuzzy` deixa cada termo estar até duas edições longe de um termo do índice, a
distância de Levenshtein, ajustada ao tamanho da palavra:

```
ana@vm:~/lab/search$ $R search.py cafe torado --fuzzy
5 matches
   8.80  Café torrado em grãos
   5.67  Café descafeinado
   4.83  Café moído tradicional
   4.83  Café em cápsulas
   1.07  Farinha de mandioca
categories: café (4), mercearia (1)
```

`torado` alcançou `torr` de novo, e o café torrado voltou para o topo. A tolerância tem um preço de
costume, mais resultados um pouco errados, que o BM25 mantém abaixo dos certos. A linha `categories` é a
faceta: contagens que a loja mostra ao lado dos resultados como filtros, calculadas na mesma requisição.
