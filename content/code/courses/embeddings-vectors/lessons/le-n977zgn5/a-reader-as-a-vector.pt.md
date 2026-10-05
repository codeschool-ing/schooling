---
title: Um leitor como vetor
version: 1
---

Uma fileira embaixo de um livro responde *o que se parece com este*. Uma página para uma leitora
conectada precisa responder *do que ela gostaria*, e para isso é preciso um vetor para a leitora. O
mais simples é feito do que ela já terminou: **tire a média dos vetores dos livros dela e normalize
de novo**. As recomendações são os livros não lidos mais próximos dessa média, a mesma busca outra
vez.

```schooling-example
{
  "language": "python",
  "file": "reader.py",
  "parts": [
    {
      "code": "import sys\nimport numpy as np\nfrom books import B, books, readers, row, show\n\nr = readers[sys.argv[1]]\nmine = [row[i] for i in r[\"finished\"]]\nprint(r[\"name\"], \"finished:\", \", \".join(books[i][\"title\"] for i in mine))",
      "note": "Acha o leitor passado na linha de comando e as linhas dos livros que ele terminou."
    },
    {
      "code": "v = B[mine].mean(axis=0)\nprint(f\"length of the average: {np.linalg.norm(v):.3f}\")\nv /= np.linalg.norm(v)",
      "note": "O vetor do leitor é a média dos vetores desses livros. Imprime o comprimento e depois divide por ele."
    },
    {
      "code": "show(B @ v, skip=set(r[\"finished\"]))",
      "note": "As recomendações são os livros mais próximos desse vetor, menos os que já foram terminados."
    }
  ]
}
```

```
ana@lab:~/emb$ python reader.py r02
Caio finished: The Time Machine, The War of the Worlds, Twenty Thousand Leagues Under the Sea
length of the average: 0.669
  0.536  b17  science fiction Journey to the Centre of the Earth  (Jules Verne)
  0.483  b28  adventure       Around the World in Eighty Days  (Jules Verne)
  0.471  b57  science fiction The Island of Doctor Moreau  (H. G. Wells)
  0.401  b31  adventure       Moby-Dick  (Herman Melville)
  0.400  b18  science fiction The Invisible Man  (H. G. Wells)
ana@lab:~/emb$ python reader.py r10
Lia finished: Pride and Prejudice, The Hound of the Baskervilles
length of the average: 0.777
  0.535  b04  romance         Wuthering Heights  (Emily Brontë)
  0.467  b11  mystery         The Mysterious Affair at Styles  (Agatha Christie)
  0.440  b32  literary        Great Expectations  (Charles Dickens)
  0.405  b60  adventure       The Scarlet Pimpernel  (Baroness Orczy)
  0.404  b03  romance         Jane Eyre  (Charlotte Brontë)
```

**Caio** terminou três livros de ficção científica, e a lista dele é o que se esperaria: dois de
Verne, dois de Wells e *Moby-Dick*, ficção científica e aventuras de mar e viagem. A média dele tinha
comprimento 0,669 antes da nova normalização, o que diz, como na aula 4, que os três livros dele
apontam em direções bem diferentes; a média normalizada é a direção que eles têm em comum.

## Uma leitora com dois gostos

**Lia** terminou dois livros: *Pride and Prejudice* (*Orgulho e preconceito*), um romance, e *The
Hound of the Baskervilles*, um mistério. A lista dela é liderada por **Wuthering Heights** com 0,535,
e o motivo aparece quando cada candidato é comparado com os dois livros dela separadamente:

```schooling-example
{
  "language": "python",
  "file": "between.py",
  "parts": [
    {
      "code": "import numpy as np\nfrom books import B, books, readers, row\n\nmine = [row[i] for i in readers[\"r10\"][\"finished\"]]\nv = B[mine].mean(axis=0)\nv /= np.linalg.norm(v)\nprint(\"        lia   \" + \"  \".join(books[i][\"id\"] for i in mine))\nfor i in [i for i in np.argsort(-(B @ v)) if i not in mine][:5]:\n    cols = \"  \".join(f\"{B[i] @ B[j]:.3f}\" for j in mine)\n    print(f\"{books[i]['id']}  {B[i] @ v:.3f}  {cols}  {books[i]['title']}\")",
      "note": "O vetor da Lia, montado como em `reader.py`. Para os cinco primeiros livros não lidos dela, imprime a nota contra o vetor dela e depois contra cada um dos dois livros, uma coluna por livro."
    }
  ]
}
```

```
ana@lab:~/emb$ python between.py
        lia   b01  b07
b04  0.535  0.388  0.444  Wuthering Heights
b11  0.467  0.328  0.397  The Mysterious Affair at Styles
b32  0.440  0.424  0.260  Great Expectations
b60  0.405  0.285  0.344  The Scarlet Pimpernel
b03  0.404  0.265  0.363  Jane Eyre
```

**Wuthering Heights tem 0,388 contra um dos livros dela e 0,444 contra o outro.** Ele fica
razoavelmente perto dos dois, e é isso que o põe em primeiro. *The Adventures of Sherlock Holmes*
está quase tão perto do Hound, 0,411, e só a 0,200 de *Pride and Prejudice*, então nem entra na
lista. A nota contra a média normalizada é a soma das notas contra cada livro, dividida por uma
constante, o comprimento da soma. Um livro razoavelmente perto dos dois vence um livro colado em
um deles e longe do outro.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 470\" role=\"img\" aria-label=\"Um gráfico de dispersão dos 58 livros que a Lia não leu. O eixo horizontal é a semelhança de cada livro com Pride and Prejudice, o vertical a semelhança com The Hound of the Baskervilles. Os cinco livros recomendados pela média dos dois dela, marcados como círculos vazados, ficam mais para cima e para a direita ao longo de uma diagonal: Wuthering Heights, The Mysterious Affair at Styles, Great Expectations, The Scarlet Pimpernel e Jane Eyre. Sense and Sensibility, perto só de Pride and Prejudice, e The Adventures of Sherlock Holmes, perto só do Hound, ficam abaixo da diagonal tracejada em que está a quinta recomendação.\"><path d=\"M80 390 L80 50\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M80 390 L680 390\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"80\" y=\"404\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.0</text><text x=\"72\" y=\"390\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.0</text><path d=\"M200 390 L200 50\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M80 322 L680 322\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"200\" y=\"404\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.1</text><text x=\"72\" y=\"322\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.1</text><path d=\"M320 390 L320 50\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M80 254 L680 254\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"320\" y=\"404\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.2</text><text x=\"72\" y=\"254\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.2</text><path d=\"M440 390 L440 50\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M80 186 L680 186\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"440\" y=\"404\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.3</text><text x=\"72\" y=\"186\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.3</text><path d=\"M560 390 L560 50\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M80 118 L680 118\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"560\" y=\"404\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.4</text><text x=\"72\" y=\"118\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.4</text><path d=\"M680 390 L680 50\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M80 50 L680 50\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"680\" y=\"404\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.5</text><text x=\"72\" y=\"50\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.5</text><path d=\"M80 390 L680 390\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M80 390 L80 50\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M233.6 50 L680 303\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\"></path><circle cx=\"526.4\" cy=\"239\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"398\" cy=\"143.2\" r=\"6\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"2.2\"></circle><text x=\"390\" y=\"157.2\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Jane Eyre</text><circle cx=\"545.6\" cy=\"88.1\" r=\"6\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"2.2\"></circle><text x=\"535.6\" y=\"88.1\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Wuthering Heights</text><circle cx=\"387.2\" cy=\"321.3\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"478.4\" cy=\"332.2\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"304.4\" cy=\"147.9\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"309.2\" cy=\"211.8\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"374\" cy=\"212.5\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"473.6\" cy=\"120\" r=\"6\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"2.2\"></circle><text x=\"483.6\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">The Mysterious Affair at Styles</text><circle cx=\"359.6\" cy=\"184.6\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"260\" cy=\"230.2\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"242\" cy=\"310.4\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"314\" cy=\"205.7\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"185.6\" cy=\"308.4\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"282.8\" cy=\"246.5\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"237.2\" cy=\"229.5\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"269.6\" cy=\"137.7\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"394.4\" cy=\"192.1\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"300.8\" cy=\"183.3\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"257.6\" cy=\"269.6\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"340.4\" cy=\"213.9\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"338\" cy=\"176.5\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"330.8\" cy=\"207.8\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"309.2\" cy=\"202.3\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"275.6\" cy=\"222.7\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"270.8\" cy=\"281.9\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"250.4\" cy=\"210.5\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"155.6\" cy=\"129.6\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"306.8\" cy=\"231.6\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"588.8\" cy=\"213.2\" r=\"6\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"2.2\"></circle><text x=\"598.8\" y=\"213.2\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Great Expectations</text><circle cx=\"497.6\" cy=\"222\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"478.4\" cy=\"330.2\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"490.4\" cy=\"202.3\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"424.4\" cy=\"193.5\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"358.4\" cy=\"221.4\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"306.8\" cy=\"150.6\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"334.4\" cy=\"239\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"345.2\" cy=\"296.2\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"407.6\" cy=\"245.8\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"455.6\" cy=\"253.3\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"358.4\" cy=\"216.6\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"340.4\" cy=\"186\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"428\" cy=\"189.4\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"478.4\" cy=\"189.4\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"413.6\" cy=\"257.4\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"168.8\" cy=\"261.5\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"520.4\" cy=\"238.4\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"519.2\" cy=\"349.9\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"333.2\" cy=\"313.2\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"262.4\" cy=\"325.4\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"354.8\" cy=\"136.4\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"480.8\" cy=\"280.5\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"320\" cy=\"110.5\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><text x=\"310\" y=\"110.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">The Adventures of Sherlock Holmes</text><circle cx=\"278\" cy=\"224.8\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"360.8\" cy=\"134.3\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"258.8\" cy=\"179.9\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"580.4\" cy=\"264.2\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><text x=\"570.4\" y=\"264.2\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Sense and Sensibility</text><circle cx=\"422\" cy=\"156.1\" r=\"6\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"2.2\"></circle><text x=\"432\" y=\"156.1\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">The Scarlet Pimpernel</text><text x=\"380\" y=\"424\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">semelhança com Pride and Prejudice</text><text x=\"80\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">semelhança com The Hound of the Baskervilles</text><circle cx=\"96\" cy=\"452\" r=\"6\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"2.2\"></circle><text x=\"110\" y=\"452\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">recomendados pela média</text><circle cx=\"310\" cy=\"452\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><text x=\"322\" y=\"452\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">outros livros não lidos</text><path d=\"M500 452 L528 452\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"536\" y=\"452\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">a diagonal da quinta</text></svg>", "caption": "Cada livro que a Lia não leu, posicionado pela semelhança com cada um dos dois dela. Ordenar pela média é ordenar pela distância ao longo da diagonal: os cinco recomendados são os que ficam mais para cima e para a direita, e um livro perto de só um dos dela fica aquém da linha tracejada.", "same": ["Great Expectations", "Jane Eyre", "Sense and Sensibility", "The Adventures of Sherlock Holmes", "The Mysterious Affair at Styles", "The Scarlet Pimpernel", "Wuthering Heights"]}
```

A figura põe cada livro que a Lia não leu na posição dada pela semelhança com cada um dos dois
dela. A ordem da média corre na diagonal: o lugar de um livro depende do quanto ele fica para cima e
para a direita, e os cinco recomendados são os que vão mais longe nessa diagonal. Um livro no canto
de cima à esquerda ou de baixo à direita, muito perto de um dos livros dela e longe do outro, perde
para o meio.

**Às vezes o meio é o que a leitora quer**, um romance gótico para quem leu um romance e um
mistério gótico. Às vezes é um livro que não serve a nenhum dos dois humores dela. A média não sabe
dizer qual dos casos é, porque jogou fora o fato de que eram dois livros. Um sistema que queira
manter os dois gostos os mantém separados: um vetor por grupo do que a leitora terminou, cada um
buscado sozinho, e os resultados juntados. Isso é mais maquinário, e com dois livros terminados não
há grupo para achar; a média é onde todo recomendador começa.

## Tudo o que ela leu conta igual

A média trata um livro que a Lia terminou semana passada e um que terminou há três anos como iguais,
e um livro que ela adorou como um que ela largou na última página. Sistemas reais dão pesos à média:
livros recentes pesam mais, livros avaliados pesam pela nota, livros devolvidos pesam contra. Cada
peso é um palpite sobre o que a leitora quis dizer, e o jeito de escolher entre palpites é o mesmo
que a aula 4 usou para classificadores: guarde uma parte do histórico de cada leitora e confira se
as recomendações teriam encontrado essa parte.
