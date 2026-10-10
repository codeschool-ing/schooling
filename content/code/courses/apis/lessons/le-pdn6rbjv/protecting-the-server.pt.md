---
title: Protegendo o servidor
version: 1
---

**No REST o servidor decide quanto trabalho uma requisição pode causar. No GraphQL quem decide é o
cliente.** Um endpoint do `rest.py` roda as mesmas consultas não importa quem chame. Uma consulta ao
`graph.py` pode pedir uma árvore tão larga e tão funda quanto o esquema permitir, e numa livraria em
que um livro tem autor e um autor tem livros, a árvore não tem fundo.

Então contar requisições, que é como a lição 12 limita um cliente, não mede a carga aqui. Uma
requisição de cinquenta caracteres, os livros, os autores deles, os livros desses autores e os
autores deles de novo:

```
ana@api:~/shelf$ curl -s localhost:8000/graphql -H 'Content-Type: application/json' -d '{"query": "{ books { author { books { author { name } } } } }"}' | jq -c .extensions
{"sqlQueries":23}
```

Vinte e três consultas SQL para uma requisição, numa loja com seis livros. Cada nível multiplica o de
cima, e o agrupamento só divide o total:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"A consulta books, author, books, author, name, nível por nível. O nível 1 devolve 6 livros, o nível 2 seis autores, o nível 3 dez livros, o nível 4 dez autores. SQL sem --batch: 1, 6, 6 e 10, 23 no total. Com --batch: 1, 1, 6 e 0, 8 no total.\"><text x=\"560\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\" font-weight=\"600\">SQL, desligado</text><text x=\"650\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\" font-weight=\"600\">SQL, ligado</text><text x=\"220\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\" font-weight=\"600\">objetos devolvidos</text><text x=\"20\" y=\"55\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">books</text><rect x=\"150\" y=\"45\" width=\"22\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"180\" y=\"45\" width=\"22\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"210\" y=\"45\" width=\"22\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"240\" y=\"45\" width=\"22\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"270\" y=\"45\" width=\"22\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"300\" y=\"45\" width=\"22\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"560\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">1</text><text x=\"650\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">1</text><text x=\"32\" y=\"97\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">author</text><rect x=\"150\" y=\"87\" width=\"22\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"180\" y=\"87\" width=\"22\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"210\" y=\"87\" width=\"22\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"240\" y=\"87\" width=\"22\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"270\" y=\"87\" width=\"22\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"300\" y=\"87\" width=\"22\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"560\" y=\"97\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">6</text><text x=\"650\" y=\"97\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">1</text><text x=\"44\" y=\"139\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">books</text><rect x=\"150\" y=\"129\" width=\"22\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"180\" y=\"129\" width=\"22\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"210\" y=\"129\" width=\"22\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"240\" y=\"129\" width=\"22\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"270\" y=\"129\" width=\"22\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"300\" y=\"129\" width=\"22\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"330\" y=\"129\" width=\"22\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"360\" y=\"129\" width=\"22\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"390\" y=\"129\" width=\"22\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"420\" y=\"129\" width=\"22\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"560\" y=\"139\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">6</text><text x=\"650\" y=\"139\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">6</text><text x=\"56\" y=\"181\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">author</text><rect x=\"150\" y=\"171\" width=\"22\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"180\" y=\"171\" width=\"22\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"210\" y=\"171\" width=\"22\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"240\" y=\"171\" width=\"22\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"270\" y=\"171\" width=\"22\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"300\" y=\"171\" width=\"22\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"330\" y=\"171\" width=\"22\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"360\" y=\"171\" width=\"22\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"390\" y=\"171\" width=\"22\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"420\" y=\"171\" width=\"22\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"560\" y=\"181\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">10</text><text x=\"650\" y=\"181\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">0</text><line x1=\"520\" y1=\"212\" x2=\"690\" y2=\"212\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></line><text x=\"560\" y=\"228\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\" font-weight=\"600\">23</text><text x=\"650\" y=\"228\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\" font-weight=\"600\">8</text><text x=\"20\" y=\"228\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">uma requisição, 50 caracteres de consulta</text></svg>", "caption": "Uma consulta de cinco níveis, books, author, books, author, name, e dentro do limite. Cada nível multiplica o de cima, e a contagem de SQL acompanha; o agrupamento a reduz de 23 para 8, mas não impede a multiplicação."}
```

## Um limite de profundidade

A defesa mais simples recusa uma consulta funda demais, antes de rodar qualquer parte dela. O
`graph.py` conta os campos no caminho mais longo da consulta, seguindo os fragments, e recusa
qualquer coisa além de `MAX_DEPTH`, que é 5. Um nível a mais que a consulta acima:

```
ana@api:~/shelf$ curl -s localhost:8000/graphql -H 'Content-Type: application/json' -d '{"query": "{ books { author { books { author { books { title } } } } } }"}' -w '%{http_code}\n'
{"errors": [{"message": "the query is 6 levels deep and the limit is 5"}]}
400
```

Recusada com 400, sem um único comando SQL. Profundidade é uma medida grosseira, porém. Uma consulta
pode ser rasa e ainda assim larga, pedindo lado a lado todas as listas do esquema, e um argumento de
lista como `books(first: 1000)` deixa um nível tão caro quanto vários.

Ela também pega mais do que você queria. A consulta que as ferramentas enviam para ler um esquema
inteiro, aquela de que dependem os editores e geradores da seção anterior, é mais funda que o
limite:

```
ana@api:~/shelf$ python3 -c 'import graph, graphql; print(graph.deepest(graphql.parse(graphql.get_introspection_query())))'
13
```

Treze níveis, então o `graph.py` do jeito que está recusaria as ferramentas. Servidores com limite de
profundidade isentam os campos de introspecção ou os medem à parte, o que é mais uma linha de código
que ninguém escreve até o editor parar de funcionar.

## Um limite de custo

A medida melhor dá a cada campo um **custo**, multiplica o custo dos campos de uma lista por quantos
itens a lista pode devolver, e recusa a consulta cujo total passa de um orçamento. Isso exige que
toda lista tenha um limite que o servidor conheça, o que é uma boa regra de qualquer jeito: um
argumento como `first` com um máximo, em vez de uma lista que devolve o que a tabela tiver. Vários
servidores e gateways GraphQL trazem análise de custo pronta, e o mesmo número dá um limite de taxa
melhor do que uma contagem de requisições.

## Consultas persistidas

A defesa mais forte tira a linguagem da requisição. Com **consultas persistidas** (persisted
queries), toda consulta que um cliente vai enviar é registrada no servidor quando o cliente é
construído, e o cliente manda só o id ou o hash dela, com as variáveis. O servidor roda as consultas
que conhece e recusa qualquer outro texto. Isso transforma uma linguagem de consulta aberta numa
lista fixa de operações, cada uma medida antes de ir para produção, e serve exatamente para o caso em
que você escreve todos os clientes.

## Por que o cache HTTP fica mais difícil

Para qualquer coisa que só enxerga HTTP, as últimas requisições desta lição se parecem: uma escrita
que falhou pela metade, uma leitura, duas perguntas sobre o esquema e uma consulta recusada, todas
com o mesmo método para o mesmo endereço:

```
127.0.0.1 - - [10/Oct/2026 01:38:15] "POST /graphql HTTP/1.1" 200 -
  sql: SELECT * FROM books WHERE id = '1'
  sql: SELECT * FROM books WHERE id = '2'
127.0.0.1 - - [10/Oct/2026 01:38:15] "POST /graphql HTTP/1.1" 200 -
127.0.0.1 - - [10/Oct/2026 01:38:16] "POST /graphql HTTP/1.1" 200 -
127.0.0.1 - - [10/Oct/2026 01:38:16] "POST /graphql HTTP/1.1" 200 -
127.0.0.1 - - [10/Oct/2026 01:38:16] "POST /graphql HTTP/1.1" 400 -
```

Um cache HTTP, no navegador ou na frente de um servidor, guarda respostas pelo método e pelo
endereço, e na prática não guarda um `POST` de jeito nenhum. Com um endereço e um método para tudo, a
linha da requisição não diz nada sobre o que foi pedido. O GraphQL sobre HTTP permite mandar uma
leitura como `GET`, com a consulta no endereço; o `graph.py` recusa isso:

```
ana@api:~/shelf$ curl -si 'localhost:8000/graphql?query=%7Bbooks%7Btitle%7D%7D'
HTTP/1.1 405 Method Not Allowed
Server: BaseHTTP/0.6 Python/3.12.3
Date: Sat, 10 Oct 2026 04:38:16 GMT
Content-Type: application/json
Content-Length: 66
Allow: POST

{"errors": [{"message": "send the query with POST to /graphql"}]}
```

Um servidor que aceita `GET` recupera endereços que podem ir para cache, mas uma consulta inteira em
cada endereço é longa e instável. As consultas persistidas resolvem isso também: o endereço leva um id
curto e as variáveis, o mesmo para todo cliente que pede a mesma coisa. Os clientes GraphQL também
mantêm um cache próprio, guardando cada objeto pelo tipo e pelo `id`, o que é mais um motivo para
todo tipo objeto do esquema ter um.
