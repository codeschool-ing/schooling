---
title: Mutations, e erros que chegam com um 200
version: 1
---

**Uma mutation é um campo da raiz `Mutation`, e se escreve como uma consulta com a palavra
`mutation` na frente.** Ela recebe argumentos, muda algo e devolve um objeto cujos campos o cliente
seleciona como sempre, então o cliente lê o estado novo na mesma requisição. Há uma regra diferente
da consulta: a especificação exige que os campos de topo de uma mutation rodem **um depois do outro,
na ordem em que foram escritos**, para que uma requisição que escreve duas vezes saiba qual escrita
aconteceu primeiro.

A requisição abaixo ajusta dois estoques de uma vez: o do livro 1 para 10, que está certo, e o do
livro 2 para -1, que o `CHECK (stock >= 0)` do banco recusa. O `-i` mostra a linha de status:

```
ana@api:~/shelf$ curl -si localhost:8000/graphql -H 'Content-Type: application/json' -d '{"query": "mutation { a: setStock(bookId: 1, stock: 10) { title stock } b: setStock(bookId: 2, stock: -1) { title stock } }"}'
HTTP/1.1 200 OK
Server: BaseHTTP/0.6 Python/3.12.3
Date: Sat, 10 Oct 2026 04:38:15 GMT
Content-Type: application/json
Content-Length: 239

{"data": {"a": {"title": "Dom Casmurro", "stock": 10}, "b": null}, "errors": [{"message": "stock -1 refused: CHECK constraint failed: stock >= 0", "locations": [{"line": 1, "column": 62}], "path": ["b"]}], "extensions": {"sqlQueries": 3}}
```

## Dados parciais, e onde está o erro

**A resposta é 200 OK, com `data` e `errors` juntos.** `a` deu certo e traz o estoque novo. `b` é
`null`, e o erro ao lado nomeia o campo com `path`, `["b"]`, e o lugar na consulta com `locations`.
É um sucesso parcial, e o banco concorda:

```
ana@api:~/shelf$ curl -s localhost:8000/graphql -H 'Content-Type: application/json' -d '{"query": "{ a: book(id: 1) { stock } b: book(id: 2) { stock } }"}' | jq -c .data
{"a":{"stock":10},"b":{"stock":7}}
```

O livro 1 agora tem 10 e o livro 2 continua com 7. Cada campo fez seu commit sozinho; nada fez das
duas escritas uma transação, e nada no GraphQL faz. Um cliente que precisa de tudo ou nada pede uma
mutation só que faça tudo, desenhada assim no esquema.

O `null` parou em `b` porque `setStock` devolve `Book`, que pode ser nulo. Se o esquema dissesse
`Book!`, o servidor não poderia pôr `null` ali sem quebrar a própria promessa, então o `null` subiria
até o campo mais próximo que aceita um: aqui, o `data` inteiro, e a resposta traria o erro e nenhum
dado. É o outro lado do conselho da seção sobre o esquema: um campo não nulo que falha derruba o pai
junto.

## O que um 200 quer dizer agora

No `rest.py` o código de status levava o resultado, e a aula 1 defendeu que o cliente decide com
base nele. No GraphQL **um 200 só diz que a consulta rodou.** O terminal do servidor mostra o mesmo
que um sistema de monitoramento veria, três comandos e um sucesso comum:

```
  sql: UPDATE books SET stock = 10 WHERE id = '1'
  sql: SELECT * FROM books WHERE id = '1'
  sql: UPDATE books SET stock = -1 WHERE id = '2'
127.0.0.1 - - [10/Oct/2026 01:38:15] "POST /graphql HTTP/1.1" 200 -
```

Duas consequências, uma de cada lado.

- O monitoramento que conta respostas 5xx e 4xx não vê nada de errado nesta requisição, nem em cem
  iguais a ela. Um servidor GraphQL precisa contar ele mesmo os erros dos corpos, por campo, e mandar
  esse número para onde os alarmes moram.
- O cliente precisa ler `errors` em toda resposta. Um wrapper que só lança exceção quando o status não
  é 2xx vai entregar à tela um `null` sem explicação.

O `graph.py` responde 400 em um caso: quando nada rodou, porque a consulta não passou na análise,
falhou na validação ou era funda demais. Aí o cliente precisa mudar a requisição, que é o que um 4xx
quer dizer. Os servidores divergem nisso, e alguns respondem 200 mesmo assim; depois que a execução
começou, 200 é o que você vai ver quase em todo lugar.

Alguns esquemas vão um passo além e põem a falha esperada dentro dos dados: `setStock` devolveria um
objeto com o livro ou com um campo `problem` que o cliente tem de olhar. O erro passa a ter tipo,
fica documentado no esquema e não tem como passar despercebido, e o `errors` fica para as falhas que
ninguém previu.
