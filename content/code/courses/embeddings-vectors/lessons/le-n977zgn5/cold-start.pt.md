---
title: Partida a frio
version: 1
---

Um recomendador é fácil de julgar com leitores de histórico longo. Os casos difíceis ficam nas
pontas: um livro que ninguém leu ainda, e um leitor que não leu nada. Os dois se chamam **partida a
frio** (*cold start*), e o método desta aula lida bem com um deles e com o outro de jeito
nenhum.

```schooling-example
{
  "language": "python",
  "file": "coldstart.py",
  "parts": [
    {
      "code": "from collections import Counter\nimport numpy as np\nfrom minilm import embed\nfrom books import B, books, readers, row, show",
      "note": "Os mesmos auxiliares, e `Counter` para a lista de populares."
    },
    {
      "code": "new = embed(\"The Lost World. A professor leads an expedition to a remote plateau \"\n            \"in South America where dinosaurs still roam.\")[0]\nprint(\"The Lost World, nearest in the catalogue:\")\nshow(B @ new)",
      "note": "Um livro que não está no catálogo: transforma título e sinopse em vetor e mostra os livros mais próximos."
    },
    {
      "code": "print(\"readers who would see it in their top 5:\")\nfor r in readers.values():\n    if not r[\"finished\"]:\n        continue\n    v = B[[row[i] for i in r[\"finished\"]]].mean(axis=0)\n    v /= np.linalg.norm(v)\n    unread = [B[i] @ v for i in range(len(books)) if books[i][\"id\"] not in r[\"finished\"]]\n    rank = 1 + sum(s > new @ v for s in unread)\n    if rank <= 5:\n        print(f\"  {r['name']:6} rank {rank}  ({new @ v:.3f})\")",
      "note": "Para cada leitor que terminou alguma coisa, conta quantos dos livros não lidos dele têm nota maior que o novo. Imprime os leitores para quem ele entraria entre os cinco primeiros."
    },
    {
      "code": "print(\"Marcos has finished:\", readers[\"r11\"][\"finished\"])\ncounts = Counter(i for r in readers.values() for i in r[\"finished\"])\nfor book_id, n in counts.most_common(3):\n    print(f\"  {n} readers  {books[row[book_id]]['title']}\")",
      "note": "O Marcos não terminou nada. Conta quantos leitores terminaram cada livro e mostra os três mais terminados."
    },
    {
      "code": "q = embed(\"ghost stories and haunted houses\")[0]\nprint(\"Marcos asked for ghost stories:\")\nshow(B @ q, n=3)",
      "note": "Ou pergunta a ele, e transforma a resposta em vetor como se fosse um livro."
    }
  ]
}
```

```
ana@lab:~/emb$ python coldstart.py
The Lost World, nearest in the catalogue:
  0.643  b17  science fiction Journey to the Centre of the Earth  (Jules Verne)
  0.467  b57  science fiction The Island of Doctor Moreau  (H. G. Wells)
  0.439  b15  science fiction Frankenstein  (Mary Shelley)
  0.397  b16  science fiction Twenty Thousand Leagues Under the Sea  (Jules Verne)
  0.392  b47  non-fiction     Walden  (Henry David Thoreau)
readers who would see it in their top 5:
  Caio   rank 1  (0.540)
  Íris   rank 3  (0.374)
Marcos has finished: []
  3 readers  The Hound of the Baskervilles
  2 readers  Pride and Prejudice
  2 readers  Dracula
Marcos asked for ghost stories:
  0.572  b21  horror          The Turn of the Screw  (Henry James)
  0.470  b38  literary        Bleak House  (Charles Dickens)
  0.392  b07  mystery         The Hound of the Baskervilles  (Arthur Conan Doyle)
```

## Um livro novo tem vetor na hora

*The Lost World* (*O mundo perdido*) não está no catálogo. A sinopse dele, escrita no programa, vira
vetor do mesmo jeito que as outras sessenta, e o livro está pronto para ser recomendado antes de
vender um exemplar. O vizinho mais próximo é *Journey to the Centre of the Earth*, com 0,643, outro
professor numa expedição a um mundo pré-histórico perdido. A segunda metade do programa pergunta ao
vetor de cada leitor em que posição o livro novo ficaria entre os que ele ainda não leu. **O Caio o
veria em primeiro.**

A Íris o veria em terceiro, com 0,374, e ela terminou *Walden*, *Meditations* (*Meditações*) e *On
the Origin of Species* (*A origem das espécies*). Um professor que encontra dinossauros ainda vivos
provavelmente fica perto, aos olhos do modelo, de um livro sobre espécies que mudam ao longo das
gerações. Se uma leitora de filosofia quer uma aventura, só ela pode dizer. É um palpite
razoável, feito no primeiro dia, só com texto.

Essa é a força da recomendação **baseada em conteúdo**, que é tudo o que esta aula construiu: a
recomendação vem do que o livro é, então não precisa de nada dos outros leitores.

## Um leitor novo não tem vetor nenhum

O Marcos tem conta e não terminou nada. A média de nenhum vetor não é um vetor, e nenhuma busca por
semelhança resolve isso. Duas saídas são comuns, e o programa mostra as duas.

**Mostrar o que é popular.** Os livros terminados por mais leitores: *The Hound of the
Baskervilles*, terminado por 3, depois *Pride and Prejudice* e *Dracula* com 2 cada. É uma lista
certa para o cliente médio e para ninguém em particular, e com doze leitores ela se apoia em umas
poucas contagens. Numa loja de verdade as contagens vêm de milhares de leitores e a lista é um
padrão sensato.

**Perguntar.** Uma pergunta no cadastro, *o que você gosta de ler?*, dá uma frase, e uma frase pode
virar vetor como qualquer outra coisa. *Ghost stories and haunted houses* ("histórias de fantasmas e
casas mal-assombradas") encontra **The Turn of the Screw** (*A volta do parafuso*) com 0,572, uma
história de fantasmas numa casa de campo isolada, que é exatamente o certo. Encontra também **Bleak
House** com 0,470, que é sobre um processo judicial, porque o título tem a palavra
*house*. O modelo compara tudo o que recebe, as palavras do título também, e uma consulta curta põe
muito peso em cada palavra.

## Uma leitora com um livro

A Nina terminou um livro, *Around the World in Eighty Days*. O vetor dela é o vetor desse livro, e as
recomendações dela são a fileira embaixo desse livro:

```
ana@lab:~/emb$ python reader.py r12
Nina finished: Around the World in Eighty Days
length of the average: 1.000
  0.395  b13  science fiction The Time Machine  (H. G. Wells)
  0.376  b16  science fiction Twenty Thousand Leagues Under the Sea  (Jules Verne)
  0.369  b56  mystery         The Thirty-Nine Steps  (John Buchan)
  0.344  b17  science fiction Journey to the Centre of the Earth  (Jules Verne)
  0.312  b25  adventure       Treasure Island  (Robert Louis Stevenson)
ana@lab:~/emb$ python like.py b28
b28 Around the World in Eighty Days - adventure
  0.395  b13  science fiction The Time Machine  (H. G. Wells)
  0.376  b16  science fiction Twenty Thousand Leagues Under the Sea  (Jules Verne)
  0.369  b56  mystery         The Thirty-Nine Steps  (John Buchan)
  0.344  b17  science fiction Journey to the Centre of the Earth  (Jules Verne)
  0.312  b25  adventure       Treasure Island  (Robert Louis Stevenson)
```

As duas listas são idênticas, e o comprimento da média, 1,000, diz por quê: a média de um vetor de
comprimento 1 é o próprio vetor. Com um livro ainda não há gosto para tirar média, só um exemplo, e a
lista vai mudar muito com o segundo e o terceiro.

## O outro jeito de montar um leitor

Tudo aqui é baseado em conteúdo. A outra família de recomendadores, a **filtragem colaborativa**
(*collaborative filtering*), nunca lê uma sinopse. Ela aprende um vetor para cada leitor e cada livro
só a partir de quem terminou o quê, de modo que livros terminados pelas mesmas pessoas acabam
próximos; *quem leu este também leu* é a marca dela. Ela acha ligações que nenhuma sinopse contém, e
falha exatamente onde esta aula acerta: um livro novo que ninguém leu não tem vetor nenhum nela.

Com doze leitores ela não teria com o que aprender, e por isso esta aula não a constrói. Aprender
esses vetores é fatoração de matrizes, que o curso `machine-learning` ensina. Lojas de verdade
costumam combinar as duas: o conteúdo para posicionar um livro novo no primeiro dia, e o registro de
quem leu o quê quando ele existir.
