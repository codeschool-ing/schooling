---
title: Deixando coisas de fora
version: 1
---

Os livros mais próximos ainda não são uma lista que alguém deva ver. Três tipos de livro têm de
sair, e nenhum deles é decidido por semelhança: o que a leitora já leu, o que lota a lista com um
autor só, e o que a loja não pode ou não quer vender. O jeito errado de aplicar essas regras é pegar
os cinco primeiros e depois tirar os que quebram uma regra: para o Caio, logo abaixo, isso deixaria
uma lista de um.

## O que a leitora já tem

Os livros que uma leitora terminou são os mais próximos de todos do vetor dela, porque é deles que o
vetor foi feito. `reader.py` já os pulava, e o programa abaixo mostra onde eles teriam caído. É a
regra mais básica de um recomendador e a mais fácil de perder, por exemplo quando a lista fica em
cache e a leitora termina um livro depois de o cache ser montado.

## Um autor tomando conta

A lista do Caio na seção anterior tinha dois livros de Verne e dois de Wells: quatro de cinco lugares
com dois autores. Cada um era uma boa escolha sozinho. Juntos, fazem uma fileira que parece um erro.
Um limite de um livro por autor resolve, e também qualquer regra do mesmo formato: um por série, um
por gênero, no máximo dois da mesma década.

## As regras da própria loja

Alguns livros não podem ser oferecidos hoje: sem estoque, sem licença no país do leitor, retirados
de venda. Alguns não devem ser oferecidos a esse leitor: um título adulto na conta de uma criança.
**Essas regras vêm de dados que um vetor não guarda**, e são conferidas contra esses dados, fora
do embedding.

`filters.py` aplica as três ao Caio. A lista de sem estoque é um único livro escrito no programa, no
lugar do que uma loja de verdade leria do depósito:

```schooling-example
{
  "language": "python",
  "file": "filters.py",
  "parts": [
    {
      "code": "import numpy as np\nfrom books import B, books, readers, row\n\nr = readers[\"r02\"]\nv = B[[row[i] for i in r[\"finished\"]]].mean(axis=0)\nv /= np.linalg.norm(v)\nscores = B @ v",
      "note": "O vetor do Caio e a nota de cada livro contra ele."
    },
    {
      "code": "out_of_stock = {\"b28\"}\nfinished = set(r[\"finished\"])\nauthors = set()",
      "note": "Os dados das três regras: uma lista de estoque, os livros que ele terminou e os autores já na lista, vazia no começo."
    },
    {
      "code": "picked, looked = [], 0\nfor i in np.argsort(-scores):\n    b = books[i]\n    looked += 1\n    if b[\"id\"] in finished:\n        print(f\"  skip {b['id']}  finished       {b['title']}\")\n    elif b[\"id\"] in out_of_stock:\n        print(f\"  skip {b['id']}  out of stock   {b['title']}\")\n    elif b[\"author\"] in authors:\n        print(f\"  skip {b['id']}  same author    {b['title']}  ({b['author']})\")\n    else:\n        authors.add(b[\"author\"])\n        picked.append(i)\n        if len(picked) == 5:\n            break",
      "note": "Desce pela ordem a partir do topo. Um livro que quebra uma regra é pulado, com o motivo impresso; um que passa é escolhido e o autor anotado. Para em cinco."
    },
    {
      "code": "print(f\"looked at {looked} of {len(books)} to find 5\")\nfor i in picked:\n    print(f\"  {scores[i]:.3f}  {books[i]['id']}  {books[i]['genre']:15} {books[i]['title']}  ({books[i]['author']})\")",
      "note": "Até onde a descida foi, e o que ela escolheu."
    }
  ]
}
```

```
ana@lab:~/emb$ python filters.py
  skip b13  finished       The Time Machine
  skip b14  finished       The War of the Worlds
  skip b16  finished       Twenty Thousand Leagues Under the Sea
  skip b28  out of stock   Around the World in Eighty Days
  skip b18  same author    The Invisible Man  (H. G. Wells)
looked at 10 of 60 to find 5
  0.536  b17  science fiction Journey to the Centre of the Earth  (Jules Verne)
  0.471  b57  science fiction The Island of Doctor Moreau  (H. G. Wells)
  0.401  b31  adventure       Moby-Dick  (Herman Melville)
  0.359  b15  science fiction Frankenstein  (Mary Shelley)
  0.357  b25  adventure       Treasure Island  (Robert Louis Stevenson)
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 740 170\" role=\"img\" aria-label=\"Uma sequência de cinco caixas para a lista do Caio. Os 60 livros do catálogo são ordenados pela semelhança com a média dele. Descendo a ordem, um livro é pulado se ele já o terminou, se está sem estoque ou se o autor já está na lista. A descida parou depois de 10 livros, com cinco escolhidos.\"><defs><marker id=\"funpt-ah0\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"10\" y=\"40\" width=\"128\" height=\"60\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"74\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">60 livros, ordenados</text><text x=\"74\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">pela semelhança com o Caio</text><path d=\"M138 70 L157 70\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#funpt-ah0)\"></path><rect x=\"159\" y=\"40\" width=\"128\" height=\"60\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"223\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">já terminou?</text><path d=\"M223 100 L223 128\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#funpt-ah0)\"></path><text x=\"223\" y=\"142\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">pula</text><path d=\"M287 70 L306 70\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#funpt-ah0)\"></path><rect x=\"308\" y=\"40\" width=\"128\" height=\"60\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"372\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">sem estoque?</text><path d=\"M372 100 L372 128\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#funpt-ah0)\"></path><text x=\"372\" y=\"142\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">pula</text><path d=\"M436 70 L455 70\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#funpt-ah0)\"></path><rect x=\"457\" y=\"40\" width=\"128\" height=\"60\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"521\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">autor já na lista?</text><path d=\"M521 100 L521 128\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#funpt-ah0)\"></path><text x=\"521\" y=\"142\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">pula</text><path d=\"M585 70 L604 70\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#funpt-ah0)\"></path><rect x=\"606\" y=\"40\" width=\"128\" height=\"60\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"670\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">5 escolhidos</text><text x=\"670\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">depois de olhar 10</text></svg>", "caption": "Filtrar é descer pela ordem, e não cortá-la em cinco. Cada regra tira livros do topo, então a lista precisa olhar mais para baixo para preencher os cinco lugares."}
```

**Ele olhou 10 dos 60 livros para preencher cinco lugares**, e as linhas `skip` dizem por que cada um
dos outros cinco saiu. Os três livros que o Caio terminou ficaram no topo da própria lista dele,
*Around the World in Eighty Days* estava sem estoque e *The Invisible Man* era um segundo Wells. No
lugar deles vieram *Frankenstein*, com 0,359, e *Treasure Island* (*A ilha do tesouro*), com 0,357,
mais abaixo na ordem e ainda ficção científica e aventura.

## Filtre enquanto desce, não depois de cortar

**O laço desce pela ordem inteira e para quando tem cinco**; ele nunca corta a ordem antes. Com 60 livros
isso não custa nada, já que todo livro já tem nota. Com um milhão de livros e um índice que devolve
só os 50 mais próximos, faz diferença: se as regras tiram 46 desses 50, o leitor recebe quatro
recomendações, e pedir mais ao índice é a única saída. A aula 17 encontra exatamente esse problema em
bancos de vetores, onde um filtro aplicado depois da busca devolve menos resultados que os pedidos, e
mostra os caminhos para contorná-lo.
