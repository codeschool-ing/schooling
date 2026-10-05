---
title: Mais como este
version: 1
---

Embaixo de cada livro no site da Marginalia há espaço para uma fileira chamada *mais como este*. A
imagem comum do que a preenche é um modelo esperto treinado com milhões de compradores. A versão mais
simples não precisa de nada disso: é a busca da aula 3 com um livro no lugar da pergunta.
Transforme cada livro em vetor uma vez, e os livros mais próximos do que está na página são a
fileira.

Isso se chama recomendação **item a item**, ou **baseada em conteúdo**: ela usa o que os livros são,
e não quem os comprou. Os sessenta livros de `data/books.jsonl` têm cada um título, autor, gênero e
uma sinopse curta, e um módulo pequeno os transforma em vetores uma vez para todos os programas
desta aula:

```schooling-example
{
  "language": "python",
  "file": "books.py",
  "parts": [
    {
      "code": "import json\nimport os\nimport numpy as np\nfrom minilm import embed",
      "note": "`embed` roda o all-MiniLM-L6-v2, como em todas as aulas até aqui."
    },
    {
      "code": "books = [json.loads(line) for line in open(\"data/books.jsonl\")]\nreaders = {r[\"reader\"]: r for r in map(json.loads, open(\"data/readers.jsonl\"))}\nrow = {b[\"id\"]: i for i, b in enumerate(books)}",
      "note": "Lê os sessenta livros e os doze leitores. `row` liga o id de um livro à sua posição, que é também a sua linha na matriz de vetores."
    },
    {
      "code": "if not os.path.exists(\"books.npy\"):\n    np.save(\"books.npy\", embed([b[\"title\"] + \". \" + b[\"blurb\"] for b in books]))\nB = np.load(\"books.npy\")",
      "note": "Transforma cada livro em vetor a partir do título e da sinopse, uma vez só; as execuções seguintes carregam `books.npy` em vez de rodar o modelo."
    },
    {
      "code": "def show(scores, skip=(), n=5):\n    for i in np.argsort(-scores):\n        b = books[i]\n        if b[\"id\"] in skip:\n            continue\n        print(f\"  {scores[i]:.3f}  {b['id']}  {b['genre']:15} {b['title']}  ({b['author']})\")\n        n -= 1\n        if n == 0:\n            break",
      "note": "`show` imprime os `n` livros de nota mais alta, pulando os ids que estiverem em `skip`. Todo programa da aula imprime as listas por meio dela."
    }
  ]
}
```

## A fileira embaixo de um livro

```python
import sys
from books import B, books, row, show

b = books[row[sys.argv[1]]]
print(b["id"], b["title"], "-", b["genre"])
show(B @ B[row[b["id"]]], skip={b["id"]})
```

```
ana@lab:~/emb$ python like.py b07
b07 The Hound of the Baskervilles - mystery
  0.444  b04  romance         Wuthering Heights  (Emily Brontë)
  0.411  b55  mystery         The Adventures of Sherlock Holmes  (Arthur Conan Doyle)
  0.397  b11  mystery         The Mysterious Affair at Styles  (Agatha Christie)
  0.383  b30  adventure       The Call of the Wild  (Jack London)
  0.376  b57  science fiction The Island of Doctor Moreau  (H. G. Wells)
ana@lab:~/emb$ python like.py b13
b13 The Time Machine - science fiction
  0.395  b28  adventure       Around the World in Eighty Days  (Jules Verne)
  0.348  b17  science fiction Journey to the Centre of the Earth  (Jules Verne)
  0.346  b18  science fiction The Invisible Man  (H. G. Wells)
  0.328  b15  science fiction Frankenstein  (Mary Shelley)
  0.308  b57  science fiction The Island of Doctor Moreau  (H. G. Wells)
```

Leia a primeira lista antes de confiar nela. Embaixo de **The Hound of the Baskervilles** (*O cão dos
Baskerville*), uma história de detetive, o livro mais próximo é **Wuthering Heights** (*O morro dos
ventos uivantes*), um romance, com 0,444, à frente das histórias de Sherlock Holmes, com 0,411. As
duas sinopses mostram por quê:

```
ana@lab:~/emb$ grep -E "\"(b04|b07)\"" data/books.jsonl
{"id": "b04", "title": "Wuthering Heights", "author": "Emily Brontë", "year": 1847, "genre": "romance", "blurb": "A foundling and the daughter of the house share a wild love on the moors that turns to revenge across two generations."}
{"id": "b07", "title": "The Hound of the Baskervilles", "author": "Arthur Conan Doyle", "year": 1902, "genre": "mystery", "blurb": "A detective investigates a legendary demon dog said to haunt a family on the lonely Devon moors."}
```

As duas se passam nas charnecas (*moors*) e as duas giram em torno de uma família. O modelo comparou
o que as sinopses descrevem e achou as duas próximas; ele não sabe nada de prateleiras.

A segunda lista parece melhor: quatro dos cinco livros embaixo de **The Time Machine** (*A máquina
do tempo*) são ficção científica. O primeiro não é. **Around the World in Eighty Days** (*A volta ao
mundo em oitenta dias*) é aventura, e lidera com 0,395, provavelmente porque as duas sinopses
acompanham um inglês vitoriano numa viagem extraordinária. O modelo não diz por quê, e um palpite
desses é tudo o que quem lê as notas consegue dar.

**Nenhuma das listas está errada do jeito que uma busca erra.** Um cliente que gostou do Hound pela
atmosfera pode muito bem gostar de Wuthering Heights. Mas é uma ideia de *parecido* diferente da de
um livreiro, e você escolhe entre elas principalmente pelo que transforma em vetor.

## O que você transforma em vetor decide o que *parecido* quer dizer

Um jeito de ver no que o modelo está se apoiando é contar com que frequência os cinco vizinhos mais
próximos de um livro têm o mesmo gênero dele, no catálogo inteiro:

```schooling-example
{
  "language": "python",
  "file": "genres.py",
  "parts": [
    {
      "code": "import numpy as np\nfrom minilm import embed\nfrom books import B, books\n\ngenre = np.array([b[\"genre\"] for b in books])",
      "note": "O gênero de cada livro, como um array na mesma ordem dos vetores."
    },
    {
      "code": "def agreement(V):\n    S = V @ V.T\n    np.fill_diagonal(S, -np.inf)\n    top = np.argsort(-S, axis=1)[:, :5]\n    return int((genre[top] == genre[:, None]).sum())",
      "note": "Para cada livro, os cinco outros livros mais próximos; a diagonal vira menos infinito para que um livro nunca seja vizinho de si mesmo. Conta quantos dos 300 têm o mesmo gênero do livro."
    },
    {
      "code": "same = [(genre == g).sum() - 1 for g in genre]\nchance = sum(5 * s / (len(books) - 1) for s in same)\nprint(f\"chance:              {chance:.1f} of 300\")\nprint(f\"title. blurb:        {agreement(B)} of 300\")",
      "note": "O que o acaso daria: para cada livro, cinco escolhas entre os outros 59, dos quais `same` têm o mesmo gênero."
    },
    {
      "code": "G = embed([b[\"genre\"] + \". \" + b[\"title\"] + \". \" + b[\"blurb\"] for b in books])\nprint(f\"genre. title. blurb: {agreement(G)} of 300\")",
      "note": "A mesma contagem para vetores do gênero, título e sinopse juntos."
    }
  ]
}
```

```
ana@lab:~/emb$ python genres.py
chance:              34.2 of 300
title. blurb:        94 of 300
genre. title. blurb: 235 of 300
```

Sessenta livros com cinco vizinhos cada dão 300 vizinhos. Se os vizinhos fossem sorteados, cerca de
34,2 deles teriam o gênero do livro, a linha `chance`. Título e sinopse dão **94 de 300**: bem acima
do acaso, e ainda menos de um terço. As sinopses descrevem enredos, e enredos atravessam gêneros.

Pôr o gênero no texto, como primeiras palavras, sobe a contagem para **235**. Isso não é o modelo
melhorando. É você dizendo a ele com o que se importar, e a escolha tem um custo. Um gênero escrito
em todo vetor puxa cada livro para a sua prateleira e o afasta do tipo de semelhança
mistério-nas-charnecas, que alguns leitores querem.

Então o texto que entra no embedding é uma decisão de projeto, como as colunas de uma tabela. Título
e sinopse fazem uma fileira que recomenda pela história; o gênero na frente faz uma fileira que
recomenda pela prateleira. Uma loja pode manter as duas e mostrar as duas fileiras, já que um vetor
para sessenta livros não custa nada.

Esta aula fica com título e sinopse, porque as surpresas são o assunto dela. Todo número daqui em
diante vem desses vetores.
