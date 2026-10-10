---
title: O que o motor faz com uma palavra
version: 1
---

Alimente o índice com o catálogo. O alimentador cria o índice a partir do `index.json` na primeira vez,
depois manda todo produto numa requisição em lote:

```
ana@vm:~/lab/search$ $R feed.py
created index products
fed 24 products
```

Antes de uma palavra ser guardada, ela passa pelo **analisador** do índice. O endpoint `_analyze` mostra o
que ele faz com um pedaço de texto:

```
ana@vm:~/lab/search$ curl -s 'localhost:9200/products/_analyze?filter_path=tokens.token' -H 'Content-Type: application/json' -d '{"field": "name", "text": "Cafés torrados em grãos"}'; echo
{"tokens":[{"token":"caf"},{"token":"torr"},{"token":"em"},{"token":"gra"}]}
```

`Cafés torrados em grãos` virou quatro termos: `caf`, `torr`, `em`, `gra`. O tokenizador dividiu o texto
em palavras; `lowercase` e `asciifolding` transformaram `Cafés` em `cafes` e `grãos` em `graos`; o
redutor de radicais do português do Brasil cortou cada palavra até um radical, então `cafés`, `café` e
`cafe` viram todos `caf`, e `torrado`, `torrada` e `torrados` viram todos `torr`. O mesmo analisador roda
sobre o que o cliente digita, então `cafe torrado` e `Cafés torrados` são procurados como os mesmos dois
termos.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"Um índice invertido. À esquerda, três produtos: 1 Café torrado em grãos, 2 Café moído tradicional, 22 Farinha de mandioca. No meio, o analisador transforma cada nome em termos: caf, torr, gra, moid, tradicional, farinh, mandioc. À direita, cada termo aponta para os produtos que o contêm: caf para 1 e 2, torr para 1, mandioc para 22.\"><defs><marker id=\"l17-inverted-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"240\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"30\" y=\"40\" width=\"220\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"40\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">1  Café torrado em grãos</text><rect x=\"30\" y=\"100\" width=\"220\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"40\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">2  Café moído tradicional</text><rect x=\"30\" y=\"160\" width=\"220\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"40\" y=\"180\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">22  Farinha de mandioca</text><text x=\"390\" y=\"28\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">analisador</text><path d=\"M252 120 L318 120\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l17-inverted-ah-phosphor)\"></path><rect x=\"320\" y=\"40\" width=\"140\" height=\"160\" rx=\"4\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"390\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">minúsculas</text><text x=\"390\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">tirar acentos</text><text x=\"390\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">radical</text><path d=\"M462 120 L518 120\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l17-inverted-ah-phosphor)\"></path><rect x=\"520\" y=\"40\" width=\"80\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"560\" y=\"53\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">caf</text><text x=\"612\" y=\"53\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">→ 1, 2</text><rect x=\"520\" y=\"74\" width=\"80\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"560\" y=\"87\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">torr</text><text x=\"612\" y=\"87\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">→ 1</text><rect x=\"520\" y=\"108\" width=\"80\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"560\" y=\"121\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">gra</text><text x=\"612\" y=\"121\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">→ 1</text><rect x=\"520\" y=\"142\" width=\"80\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"560\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">moid</text><text x=\"612\" y=\"155\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">→ 2</text><rect x=\"520\" y=\"176\" width=\"80\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"560\" y=\"189\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">mandioc</text><text x=\"612\" y=\"189\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">→ 22</text><text x=\"360\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">busca: analisar a consulta do mesmo jeito, depois procurar os termos</text></svg>", "caption": "Um índice invertido liga cada termo aos documentos que o contêm, como o índice remissivo no fim de um livro liga uma palavra às páginas dela."}
```

Esses termos vão para um **índice invertido**: para cada termo, a lista dos documentos que o contêm, e
onde. Ele é invertido em relação à tabela, que vai de um documento para as palavras dele; o índice vai de
uma palavra para os documentos dela, como o índice remissivo no fim de um livro. Uma busca por dois termos
lê duas listas e as combina, e nunca olha um documento que não contém nenhum dos dois.

O analisador é a decisão que mais importa e a mais difícil de mudar: ele é aplicado quando os documentos
são gravados, então mudá-lo significa **reindexar tudo**. É por isso que o `index.json` é um arquivo
próprio, revisado como código, e que toda instalação séria de busca tem um jeito de construir um índice
novo ao lado do velho e trocar para ele, o que a aula 13 reconheceria como reconstruir um modelo de
leitura.
