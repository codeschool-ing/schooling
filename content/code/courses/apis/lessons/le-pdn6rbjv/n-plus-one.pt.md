---
title: O problema N+1
version: 1
---

**Um resolver roda uma vez por objeto, então um campo sob uma lista roda uma vez por item, e, se ele
chega ao banco, roda uma consulta por item.** Uma lista de N livros, cada um pedindo seu autor, custa
uma consulta para a lista e mais N para os autores. Esse é o **problema N+1**, e todo servidor
GraphQL escrito do jeito óbvio o tem.

É fácil acreditar que o GraphQL resolveu isso. A página que custou sete requisições ao `rest.py` na
primeira seção é uma requisição só ao `graph.py`, então o problema parece ter sumido. Ele mudou de
lugar. Peça todos os títulos com o nome do autor:

```
ana@api:~/shelf$ curl -s localhost:8000/graphql -H 'Content-Type: application/json' -d '{"query": "{ books { title author { name } } }"}' | jq -c .extensions
{"sqlQueries":7}
```

Sete consultas SQL, e o terminal do servidor mostra quais:

```
  sql: SELECT * FROM books ORDER BY id
  sql: SELECT * FROM authors WHERE id = 1
  sql: SELECT * FROM authors WHERE id = 1
  sql: SELECT * FROM authors WHERE id = 2
  sql: SELECT * FROM authors WHERE id = 2
  sql: SELECT * FROM authors WHERE id = 3
  sql: SELECT * FROM authors WHERE id = 4
127.0.0.1 - - [10/Oct/2026 01:38:14] "POST /graphql HTTP/1.1" 200 -
```

São as sete requisições da página REST, feitas pelo servidor em vez do cliente. Numa máquina só, com
SQLite, isso custa muito pouco. Com um banco do outro lado de uma rede, cada uma dessas consultas é
uma ida e volta própria, e uma lista de cem livros vira cento e uma delas.

## Agrupando

A saída é parar de pedir autores um de cada vez. O resolver de `Book.author` não busca nada; ele
devolve uma promessa do autor 1, ou do autor 2, e segue em frente. Quando todo livro da lista já
pediu, e o servidor não tem mais nada a fazer além de esperar promessas, uma consulta busca todos os
autores pedidos, e cada promessa é cumprida com o resultado. O `Loader` do `graph.py` é isso, em
vinte linhas: `load` junta os ids e `fetch` os pede com `WHERE id IN (…)`. O padrão costuma ser
chamado de **data loader**, por causa do DataLoader, a biblioteca JavaScript que o Facebook publicou
para isso, e a maioria dos servidores GraphQL tem um.

Pare o servidor com `Ctrl+C` e suba-o com o agrupamento ligado:

```sh
python3 graph.py --batch
```

A mesma consulta:

```
ana@api:~/shelf$ curl -s localhost:8000/graphql -H 'Content-Type: application/json' -d '{"query": "{ books { title author { name } } }"}' | jq -c .extensions
{"sqlQueries":2}
```

```
  sql: SELECT * FROM books ORDER BY id
  sql: SELECT * FROM authors WHERE id IN (1, 2, 3, 4)
127.0.0.1 - - [10/Oct/2026 01:38:15] "POST /graphql HTTP/1.1" 200 -
```

Duas consultas em vez de sete, e o autor 1 foi pedido uma vez. O loader não só agrupa, ele lembra:
um id já prometido durante esta requisição não é buscado de novo.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"Duas fileiras de consultas SQL para a consulta books com título e nome do autor. Sem --batch: uma consulta para os livros, depois seis para os autores 1, 1, 2, 2, 3 e 4, sete no total. Com --batch: uma para os livros e uma para os autores WHERE id IN (1, 2, 3, 4), duas no total.\"><text x=\"20\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">sem --batch</text><rect x=\"20\" y=\"44\" width=\"90\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"65.0\" y=\"61.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">books</text><rect x=\"122\" y=\"44\" width=\"74\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"159.0\" y=\"61.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">author 1</text><rect x=\"204\" y=\"44\" width=\"74\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"241.0\" y=\"61.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">author 1</text><rect x=\"286\" y=\"44\" width=\"74\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"323.0\" y=\"61.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">author 2</text><rect x=\"368\" y=\"44\" width=\"74\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"405.0\" y=\"61.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">author 2</text><rect x=\"450\" y=\"44\" width=\"74\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"487.0\" y=\"61.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">author 3</text><rect x=\"532\" y=\"44\" width=\"74\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"569.0\" y=\"61.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">author 4</text><text x=\"640\" y=\"61\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\" font-weight=\"600\">7 consultas</text><text x=\"20\" y=\"112\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">com --batch</text><rect x=\"20\" y=\"126\" width=\"90\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"65.0\" y=\"143.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">books</text><rect x=\"122\" y=\"126\" width=\"238\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"241.0\" y=\"143.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">authors IN (1, 2, 3, 4)</text><text x=\"640\" y=\"143\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">2 consultas</text><text x=\"20\" y=\"186\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1 para a lista, depois 1 por livro: esse é o N+1</text></svg>", "caption": "O SQL por trás de uma consulta por todos os títulos e o nome do autor de cada um, como o graph.py imprimiu. Sem o loader cada livro pede o próprio autor, e os autores 1 e 2 são buscados duas vezes cada; com ele as seis buscas viram uma."}
```

## O que um loader não conserta

Um loader conserta o campo para o qual foi escrito. Desça mais: o autor de cada livro, os livros
desse autor, e os autores deles de novo:

```
ana@api:~/shelf$ curl -s localhost:8000/graphql -H 'Content-Type: application/json' -d '{"query": "{ books { author { books { author { name } } } } }"}' | jq -c .extensions
{"sqlQueries":8}
```

```
  sql: SELECT * FROM books ORDER BY id
  sql: SELECT * FROM authors WHERE id IN (1, 2, 3, 4)
  sql: SELECT * FROM books WHERE author_id = 1 ORDER BY id
  sql: SELECT * FROM books WHERE author_id = 1 ORDER BY id
  sql: SELECT * FROM books WHERE author_id = 2 ORDER BY id
  sql: SELECT * FROM books WHERE author_id = 2 ORDER BY id
  sql: SELECT * FROM books WHERE author_id = 3 ORDER BY id
  sql: SELECT * FROM books WHERE author_id = 4 ORDER BY id
127.0.0.1 - - [10/Oct/2026 01:38:15] "POST /graphql HTTP/1.1" 200 -
```

Os autores vieram numa consulta só, e os dez do último nível não custaram nada, porque todos já
tinham sido prometidos. `Author.books` não tem loader, e voltou a uma consulta por autor: seis, com
os livros dos autores 1 e 2 pedidos duas vezes. Todo campo que chega ao banco de dentro de uma lista
precisa do seu próprio loader, e achar os que faltam é para isso que serve uma contagem como
`sqlQueries`. A mesma consulta sem `--batch` custou 23.

Um loader vive uma requisição, e isso é proposital. Compartilhado entre requisições ele seria um
cache, com todas as perguntas que um cache traz: por quanto tempo um autor continua válido, e se a
resposta de um usuário pode ser mostrada a outro.
