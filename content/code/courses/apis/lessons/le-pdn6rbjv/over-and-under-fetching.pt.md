---
title: O problema que o GraphQL resolve
version: 1
---

**Um endpoint REST decide o formato da resposta, e todo cliente recebe esse formato.** Foi isso que
deixou a API da aula 1 fácil de ler, de pôr em cache e de documentar, e tem um preço que cresce com
o número de telas construídas em cima dela. Uma tela precisa de um conjunto específico de campos de
um conjunto específico de recursos, e os endpoints foram recortados pelos recursos, não pelas
telas. Então a tela recebe mais do que precisa de um endpoint, e menos do que precisa de cada um.

Suba o `rest.py` de novo no segundo terminal se ele não estiver rodando, e veja as duas metades.

## Mais do que a tela precisa

Uma lista de títulos precisa de um campo por livro. `/v1/books/2` manda sete, e a coleção manda os
sete de cada livro:

```
ana@api:~/shelf$ curl -s localhost:8000/v1/books/2
{"id": 2, "isbn": "9786500000023", "title": "Memórias Póstumas de Brás Cubas", "author_id": 1, "year": 1881, "price_cents": 4490, "stock": 7}
ana@api:~/shelf$ curl -s localhost:8000/v1/books | wc -c
797
```

Isso é **sobrebusca** (over-fetching): 797 bytes para uma lista em que os títulos são uma fração.
Numa mesa com uma conexão rápida o desperdício é pequeno, e é a metade que as pessoas percebem
primeiro. A outra metade custa mais.

## Menos do que a tela precisa

A página de um livro mostra o livro, o nome do autor e os outros livros do autor. Nenhum endereço
do `rest.py` tem os três, então a página pergunta três vezes:

```
ana@api:~/shelf$ curl -s localhost:8000/v1/books/2 | jq -c '{title, author_id}'
{"title":"Memórias Póstumas de Brás Cubas","author_id":1}
ana@api:~/shelf$ curl -s localhost:8000/v1/authors/1 | jq -c '{name}'
{"name":"Machado de Assis"}
ana@api:~/shelf$ curl -s localhost:8000/v1/authors/1/books | jq -c '[.[].title]'
["Dom Casmurro","Memórias Póstumas de Brás Cubas"]
```

A segunda requisição só pode ser escrita depois que a primeira respondeu, porque o id do autor está
na primeira resposta. Três requisições em sequência custam três idas e voltas, e numa rede de
celular a ida e volta é a parte cara. Isso é **subbusca** (under-fetching): toda resposta é pequena
demais, então o cliente compensa com mais requisições.

Uma lista é pior. Uma página que mostra todos os livros com o nome do autor pede uma vez os livros e
depois uma vez por livro:

```
ana@api:~/shelf$ for a in $(curl -s localhost:8000/v1/books | jq ".[].author_id"); do curl -s localhost:8000/v1/authors/$a | jq -r .name; done
Machado de Assis
Machado de Assis
Clarice Lispector
Clarice Lispector
José Saramago
Chimamanda Ngozi Adichie
```

O servidor viu sete requisições para uma página, e fez a mesma pergunta sobre Machado de Assis duas
vezes:

```
127.0.0.1 - - [10/Oct/2026 01:38:11] "GET /v1/books HTTP/1.1" 200 -
127.0.0.1 - - [10/Oct/2026 01:38:11] "GET /v1/authors/1 HTTP/1.1" 200 -
127.0.0.1 - - [10/Oct/2026 01:38:11] "GET /v1/authors/1 HTTP/1.1" 200 -
127.0.0.1 - - [10/Oct/2026 01:38:11] "GET /v1/authors/2 HTTP/1.1" 200 -
127.0.0.1 - - [10/Oct/2026 01:38:11] "GET /v1/authors/2 HTTP/1.1" 200 -
127.0.0.1 - - [10/Oct/2026 01:38:11] "GET /v1/authors/3 HTTP/1.1" 200 -
127.0.0.1 - - [10/Oct/2026 01:38:11] "GET /v1/authors/4 HTTP/1.1" 200 -
```

## As duas saídas

O REST tem respostas próprias. O servidor pode ganhar um endpoint por tela, um `/v1/book-pages/2`
que devolve exatamente o que a página desenha, ou aceitar parâmetros que cortam e ampliam uma
resposta, como `?fields=title` e `?include=author`. As duas funcionam. As duas significam que a
equipe dona do servidor escreve algo novo para cada tela, e a API vai virando, devagar, uma lista
das páginas de alguém.

**O GraphQL passa a decisão para o cliente.** Há um endereço só, e a requisição leva uma consulta
que nomeia cada campo de que a tela precisa, em quantos recursos ela tocar. O Facebook o criou em
2012 para seu aplicativo de celular, que tinha exatamente esse problema em redes lentas, e o
publicou em 2015.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Dois diagramas de sequência lado a lado. À esquerda, um cliente pergunta ao rest.py três vezes seguidas: GET /v1/books/2 devolve author_id 1, depois GET /v1/authors/1 devolve o nome, depois GET /v1/authors/1/books devolve dois títulos. À direita, o cliente envia um único POST /graphql e recebe o livro, o autor e os livros numa resposta só, enquanto o graph.py roda 3 consultas SQL por dentro.\"><defs><marker id=\"l03-rt-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"180\" y=\"16\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">REST: cada requisição espera a anterior</text><text x=\"560\" y=\"16\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">GraphQL: uma requisição só</text><rect x=\"15\" y=\"32\" width=\"90\" height=\"28\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"60.0\" y=\"46.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">cliente</text><line x1=\"60\" y1=\"60\" x2=\"60\" y2=\"290\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></line><rect x=\"255\" y=\"32\" width=\"90\" height=\"28\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"300.0\" y=\"46.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">rest.py</text><line x1=\"300\" y1=\"60\" x2=\"300\" y2=\"290\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></line><rect x=\"395\" y=\"32\" width=\"90\" height=\"28\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"440.0\" y=\"46.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">cliente</text><line x1=\"440\" y1=\"60\" x2=\"440\" y2=\"290\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></line><rect x=\"615\" y=\"32\" width=\"90\" height=\"28\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"660.0\" y=\"46.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">graph.py</text><line x1=\"660\" y1=\"60\" x2=\"660\" y2=\"290\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></line><line x1=\"370\" y1=\"30\" x2=\"370\" y2=\"292\" stroke=\"var(--scan)\" stroke-width=\"1\"></line><line x1=\"62\" y1=\"90\" x2=\"297\" y2=\"90\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l03-rt-ah)\"></line><text x=\"179.5\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">GET /v1/books/2</text><line x1=\"298\" y1=\"120\" x2=\"63\" y2=\"120\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l03-rt-ah)\"></line><text x=\"180.5\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">&quot;author_id&quot;: 1</text><line x1=\"62\" y1=\"160\" x2=\"297\" y2=\"160\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l03-rt-ah)\"></line><text x=\"179.5\" y=\"152.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">GET /v1/authors/1</text><line x1=\"298\" y1=\"190\" x2=\"63\" y2=\"190\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l03-rt-ah)\"></line><text x=\"180.5\" y=\"182.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">&quot;name&quot;</text><line x1=\"62\" y1=\"230\" x2=\"297\" y2=\"230\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l03-rt-ah)\"></line><text x=\"179.5\" y=\"222.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">GET /v1/authors/1/books</text><line x1=\"298\" y1=\"260\" x2=\"63\" y2=\"260\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l03-rt-ah)\"></line><text x=\"180.5\" y=\"252.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">dois títulos</text><line x1=\"442\" y1=\"90\" x2=\"657\" y2=\"90\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l03-rt-ah)\"></line><text x=\"549.5\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">POST /graphql</text><line x1=\"658\" y1=\"120\" x2=\"443\" y2=\"120\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l03-rt-ah)\"></line><text x=\"550.5\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">livro, autor e livros</text><text x=\"660\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">3 consultas SQL,</text><text x=\"660\" y=\"163\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">dentro do servidor</text><text x=\"550\" y=\"230\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a consulta nomeia cada campo</text><text x=\"550\" y=\"245\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">que a página usa, e nada mais</text></svg>", "caption": "A mesma página de livro nos dois servidores. O rest.py precisa de três idas e voltas, e a segunda só começa depois que a primeira disse qual autor pedir; o graph.py precisa de uma, e faz as três buscas ele mesmo."}
```

O trabalho não sumiu. O `graph.py` ainda busca o livro, o autor e os livros, três consultas SQL; ele
as faz dentro do servidor, ao lado do banco, em vez de atravessar a rede. Onde esse trabalho pode se
multiplicar é o assunto da seção sobre o problema N+1.
