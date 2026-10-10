---
title: Resolvers, e como uma consulta é percorrida
version: 1
---

**O esquema diz o que pode ser pedido; um resolver é a função que produz o valor de um campo.**
Executar uma consulta é percorrê-la da raiz para baixo e, em cada campo, chamar o resolver daquele
campo uma vez para cada objeto a que o campo pertence. O que um resolver devolve vira o objeto em que
os campos abaixo dele são resolvidos.

Uma imagem comum de um servidor GraphQL é a de que ele traduz a consulta inteira em um comando SQL.
Ele não faz nada disso. Cada campo é resolvido por conta própria, e o servidor faz o que os seus
resolvers fizerem. A página de livro da seção sobre o `graph.py` rodou três comandos, um por resolver
que toca o banco, na ordem em que o percurso chegou a eles:

```
  sql: SELECT * FROM books WHERE id = '2'
  sql: SELECT * FROM authors WHERE id = 1
  sql: SELECT * FROM books WHERE author_id = 1 ORDER BY id
127.0.0.1 - - [10/Oct/2026 01:38:12] "POST /graphql HTTP/1.1" 200 -
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 340\" role=\"img\" aria-label=\"Uma árvore de chamadas de resolvers para a consulta book(id: 2) com título, nome do autor e os títulos dos livros do autor. Query.book roda o SQL 1 e devolve o livro 2. O título vem do resolver padrão; Book.author roda o SQL 2 e devolve o autor 1. O nome do autor vem do resolver padrão; Author.books roda o SQL 3 e devolve os livros 1 e 2, cujos títulos vêm do resolver padrão.\"><defs><marker id=\"l03-tree-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"280\" y=\"14\" width=\"160\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"27.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">book(id: 2)</text><text x=\"360.0\" y=\"42.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">Query.book · SQL 1</text><rect x=\"110\" y=\"100\" width=\"130\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"175.0\" y=\"113.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">title</text><text x=\"175.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">padrão</text><rect x=\"400\" y=\"100\" width=\"160\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"480.0\" y=\"113.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">author</text><text x=\"480.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">Book.author · SQL 2</text><rect x=\"250\" y=\"186\" width=\"130\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"315.0\" y=\"199.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">name</text><text x=\"315.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">padrão</text><rect x=\"480\" y=\"186\" width=\"170\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"565.0\" y=\"199.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">books</text><text x=\"565.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">Author.books · SQL 3</text><rect x=\"420\" y=\"272\" width=\"120\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"480.0\" y=\"285.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">title</text><text x=\"480.0\" y=\"300.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">do livro 1</text><rect x=\"580\" y=\"272\" width=\"120\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"640.0\" y=\"285.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">title</text><text x=\"640.0\" y=\"300.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">do livro 2</text><line x1=\"360\" y1=\"54\" x2=\"175\" y2=\"98\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l03-tree-ah)\"></line><line x1=\"360\" y1=\"54\" x2=\"480\" y2=\"98\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l03-tree-ah)\"></line><line x1=\"480\" y1=\"140\" x2=\"315\" y2=\"184\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l03-tree-ah)\"></line><line x1=\"480\" y1=\"140\" x2=\"565\" y2=\"184\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l03-tree-ah)\"></line><line x1=\"565\" y1=\"226\" x2=\"480\" y2=\"270\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l03-tree-ah)\"></line><line x1=\"565\" y1=\"226\" x2=\"640\" y2=\"270\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l03-tree-ah)\"></line><rect x=\"20\" y=\"262\" width=\"22\" height=\"14\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"50\" y=\"269\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">um resolver nosso, que roda SQL</text><rect x=\"20\" y=\"290\" width=\"22\" height=\"14\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"50\" y=\"297\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o resolver padrão: uma chave do dict acima</text><text x=\"175\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">&quot;Memórias Póstumas…&quot;</text></svg>", "caption": "Como o graph.py percorre uma consulta. Cada caixa é uma chamada; as três de borda contínua são funções do graph.py e cada uma roda uma consulta SQL, enquanto as tracejadas leem uma chave do dict que o pai devolveu.", "same": ["Author.books · SQL 3", "Book.author · SQL 2", "Query.book · SQL 1"]}
```

## O que um resolver recebe

Todo resolver recebe as mesmas quatro coisas, embora as bibliotecas as entreguem em ordens
diferentes. A implementação de referência em JavaScript passa `(parent, args, context, info)`; o
graphql-core passa `parent` e `info` e depois os argumentos pelo nome, e é por isso que os resolvers
do `graph.py` têm a cara de `one_book(parent, info, id)`.

| | o que é | no `graph.py` |
|---|---|---|
| `parent` | o valor que o campo de cima devolveu | em `Book.author`, a linha do livro como dict |
| argumentos | os argumentos do campo, já conferidos contra os tipos | `id`, `authorId`, `bookId`, `stock` |
| contexto | um objeto compartilhado por todos os resolvers de uma requisição | a conexão com o banco e o loader |
| `info` | onde o percurso está: o nome do campo, o caminho, o esquema | `info.context` é como o contexto chega |

O contexto é o lugar de tudo o que pertence à requisição e não a um campo: uma conexão, o usuário
que enviou a requisição, um cache que não pode durar mais do que ela. A lição 11 trata de decidir o
que cada usuário pode ver, e num servidor GraphQL o contexto é onde o resolver encontra esse usuário.

## O resolver padrão

O esquema tem quinze campos e o `graph.py` tem sete funções. Os outros oito, `title`, `year`, `name`
e os demais, são respondidos pelo **resolver padrão**, que procura no pai uma chave ou um atributo
com o nome do campo. É por isso que as funções do `graph.py` devolvem dicts simples: um dict feito de
uma linha já contém `title` e `year`, e não é preciso escrever mais nada.

`priceCents` tem função só porque a coluna se chama `price_cents`. Sem ela o resolver padrão não
encontraria nenhuma chave chamada `priceCents` e não devolveria nada, e a requisição falharia, porque
o esquema promete que o campo nunca é nulo. Um resolver é onde os nomes da API se separam dos nomes
do banco.

## O percurso

No `graph.py` o percurso é em profundidade, como o log acima mostra. Quando um campo devolve uma
lista, os campos dele são resolvidos em cada item; quando devolve um objeto, nesse objeto; quando
devolve `null`, nada abaixo dele roda. Então o número de chamadas de resolver não é fixado pela
consulta: a mesma consulta custa mais numa loja com mais livros. É essa a propriedade que a próxima
seção mede, e a que a seção sobre proteger o servidor precisa limitar.
