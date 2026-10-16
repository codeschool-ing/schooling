---
title: Filtrar e ordenar
version: 1
---

**Filtros e ordenação vão na query string, todo parâmetro tem nome no contrato, e os campos pelos
quais o cliente pode ordenar vêm de uma lista que o servidor mantém.** Uma coleção sem filtros manda
todas as linhas para todo cliente, que joga a maioria fora; uma com filtros que ninguém escreveu
ganha uma grafia diferente em cada endpoint.

O `catalogue.py` aceita dois filtros e uma ordenação, e eles se combinam. Os livros de Machado de
Assis, do mais novo para o mais antigo; tudo o que está esgotado; e os três mais caros:

```
ana@api:~/shelf$ curl -s 'localhost:8000/v1/books?author_id=1&sort=-year' | jq -c '.items[] | {id, title, year}'
{"id":1,"title":"Dom Casmurro","year":1899}
{"id":7,"title":"Quincas Borba","year":1891}
{"id":2,"title":"Memórias Póstumas de Brás Cubas","year":1881}
ana@api:~/shelf$ curl -s 'localhost:8000/v1/books?in_stock=false' | jq -c '.items[] | {id, title, stock}'
{"id":3,"title":"A Hora da Estrela","stock":0}
{"id":7,"title":"Quincas Borba","stock":0}
ana@api:~/shelf$ curl -s 'localhost:8000/v1/books?sort=-price&limit=3' | jq -c '.items[] | {title, price: .price.amount_cents}'
{"title":"Americanah","price":6490}
{"title":"Ensaio sobre a Cegueira","price":5990}
{"title":"Memórias Póstumas de Brás Cubas","price":4490}
```

Um sinal de menos na frente de um campo ordena em ordem decrescente. Outras APIs escrevem a mesma
coisa como `sort=price&order=desc`; qualquer um funciona se for o único. Atrás de cada ordenação, o
`catalogue.py` acrescenta o id como segunda chave, para que dois livros do mesmo ano sempre voltem na
mesma ordem. O SQL não promete nada sobre a ordem de linhas empatadas, e sem essa segunda chave duas
requisições pela mesma página poderiam discordar.

## Uma lista permitida para ordenar

A implementação tentadora pega o nome do campo da query string e o põe no `ORDER BY`. Ele não pode
ir como parâmetro, porque parâmetros do SQL carregam valores, nunca nomes de coluna, então teria que
ser colado no texto do SQL, e aí o que o cliente digitou vira parte da consulta. O `catalogue.py`
mantém um dicionário, `SORTS`, de cada nome público para uma coluna. Só um nome que está nele é
aceito, e só a coluna para a qual ele aponta chega ao SQL:

```
ana@api:~/shelf$ curl -s 'localhost:8000/v1/books?sort=isbn' | jq -r .detail
sort takes id, title, year, price, with a leading - for descending
```

O dicionário faz um segundo trabalho. O nome público `price` aponta para a coluna `price_cents`,
então o contrato fica livre para dar nomes pensando nos clientes, e não na tabela. E ele é uma lista
do que dá para deixar rápido: todo campo nele é um para o qual o banco deveria ter um índice.

## Um parâmetro desconhecido é um erro

A falha silenciosa aqui é o erro de digitação. Um cliente que pede `?auther_id=1`, ou um filtro que
a API nunca teve, recebe o catálogo inteiro com um 200, e acredita que foi filtrado. O `catalogue.py`
recusa o que não reconhece, e confere os valores do que reconhece:

```
ana@api:~/shelf$ curl -s 'localhost:8000/v1/books?colour=red' | jq -r .detail
/v1/books does not take: colour
ana@api:~/shelf$ curl -s 'localhost:8000/v1/books?in_stock=yes' | jq -r .detail
in_stock is true or false
```

**Um cursor pertence à sua ordenação.** O valor de `after` de uma caminhada ordenada por id não
significa nada numa caminhada ordenada por título, e o cursor leva a ordenação para a qual foi feito,
então uma divergência é recusada em vez de respondida com a página errada:

```
ana@api:~/shelf$ curl -s 'localhost:8000/v1/books?sort=title&after=WyJpZCIsIDIsIDJd' | jq -r .detail
after takes the cursor of a next link, with the same sort
```

Faixas e valores múltiplos também têm convenções, como `year_min=1900` ou `author_id=1,2`. Nenhuma é
padrão; escolha uma, escreva-a, e use-a em todo endpoint.
