---
title: Diversidade
version: 1
---

Uma lista dos cinco livros mais próximos são cinco respostas à mesma pergunta, e livros que ficam
todos perto de um mesmo ponto não podem estar longe uns dos outros. Uma leitora que vê cinco
sugestões quase iguais recebeu, na prática, uma só. O limite por autor da seção anterior é uma regra
para um tipo de repetição. A **Relevância Marginal Máxima** (*Maximal Marginal Relevance*, MMR) é uma
regra geral: escolha os livros um de cada vez, e faça cada escolha nova pagar pelo quanto ela se
parece com as que já foram feitas.

## A regra

A cada passo, cada livro que sobra recebe um valor:

```localised
valor = lambda * semelhança com o leitor - (1 - lambda) * maior semelhança com um livro já escolhido
```

O livro de maior valor é escolhido, e o passo se repete até a lista encher. `lambda`, escrito λ daqui em diante, é um botão
entre 0 e 1. Em 1, o segundo termo some e a MMR é a ordem simples. Conforme ele desce, parecer com o
que já está na lista custa mais, e um livro que traz algo novo pode passar à frente de um que está um
pouco mais perto do leitor.

```schooling-example
{
  "language": "python",
  "file": "mmr.py",
  "parts": [
    {
      "code": "import numpy as np\nfrom books import B, books, readers, row\n\nr = readers[\"r02\"]\nv = B[[row[i] for i in r[\"finished\"]]].mean(axis=0)\nv /= np.linalg.norm(v)\npool = [i for i in range(len(books)) if books[i][\"id\"] not in r[\"finished\"]]",
      "note": "O vetor do Caio e o conjunto de livros que ele não terminou."
    },
    {
      "code": "def mmr(v, pool, k, lam):\n    chosen, pool = [], list(pool)\n    while pool and len(chosen) < k:\n        def value(i):\n            like = max((B[i] @ B[j] for j in chosen), default=0.0)\n            return lam * (B[i] @ v) - (1 - lam) * like\n        best = max(pool, key=value)\n        chosen.append(best)\n        pool.remove(best)\n    return chosen",
      "note": "A cada passo, o valor de cada livro que sobra é a semelhança com o leitor, com peso `lam`, menos a maior semelhança com um livro já escolhido, com peso `1 - lam`. O melhor é escolhido e sai do conjunto."
    },
    {
      "code": "for lam in (1.0, 0.7, 0.6, 0.5):\n    print(f\"lambda {lam}\")\n    for i in mmr(v, pool, 5, lam):\n        print(f\"  {B[i] @ v:.3f}  {books[i]['id']}  {books[i]['genre']:15} {books[i]['title']}  ({books[i]['author']})\")",
      "note": "O mesmo leitor com quatro posições do botão. A nota impressa é a semelhança simples com o Caio, para que as listas possam ser comparadas."
    }
  ]
}
```

```
ana@lab:~/emb$ python mmr.py
lambda 1.0
  0.536  b17  science fiction Journey to the Centre of the Earth  (Jules Verne)
  0.483  b28  adventure       Around the World in Eighty Days  (Jules Verne)
  0.471  b57  science fiction The Island of Doctor Moreau  (H. G. Wells)
  0.401  b31  adventure       Moby-Dick  (Herman Melville)
  0.400  b18  science fiction The Invisible Man  (H. G. Wells)
lambda 0.7
  0.536  b17  science fiction Journey to the Centre of the Earth  (Jules Verne)
  0.483  b28  adventure       Around the World in Eighty Days  (Jules Verne)
  0.471  b57  science fiction The Island of Doctor Moreau  (H. G. Wells)
  0.400  b18  science fiction The Invisible Man  (H. G. Wells)
  0.401  b31  adventure       Moby-Dick  (Herman Melville)
lambda 0.6
  0.536  b17  science fiction Journey to the Centre of the Earth  (Jules Verne)
  0.483  b28  adventure       Around the World in Eighty Days  (Jules Verne)
  0.401  b31  adventure       Moby-Dick  (Herman Melville)
  0.471  b57  science fiction The Island of Doctor Moreau  (H. G. Wells)
  0.303  b51  non-fiction     The Art of War  (Sun Tzu)
lambda 0.5
  0.536  b17  science fiction Journey to the Centre of the Earth  (Jules Verne)
  0.176  b06  romance         Persuasion  (Jane Austen)
  0.303  b51  non-fiction     The Art of War  (Sun Tzu)
  0.483  b28  adventure       Around the World in Eighty Days  (Jules Verne)
  0.401  b31  adventure       Moby-Dick  (Herman Melville)
```

## Lendo as quatro listas

**Com λ = 1,0 a lista é a ordem de `reader.py`**, o que confere que o código está certo. Com 0,7
dois livros trocam de lugar e nada mais muda: os candidatos do Caio já são variados o bastante para
que uma penalidade pequena não ache nada que valha trocar.

Com 0,6 *The Invisible Man* (*O homem invisível*) sai, e **The Art of War** (*A arte da guerra*)
entra com 0,303, um livro sobre estratégia para um leitor de ficção científica. Com 0,5 o segundo
lugar vai para **Persuasion** (*Persuasão*), um romance, com 0,176, o mais distante do Caio de tudo o
que aparece nas quatro listas. É a MMR fazendo o que mandaram: Persuasion não se parece com nada já
escolhido, e nessa posição do botão ser diferente vale tanto quanto ser relevante.

**O botão não tem posição certa, e este catálogo mostra por que ele precisa ser medido.** Entre 0,7
e 0,5 a lista vai de quase igual a absurda em dois passos. Onde fica o meio útil depende do quanto
os candidatos se parecem entre si, o que depende do catálogo e do modelo. Num catálogo com quarenta
edições de um mesmo clássico, a penalidade pesaria com um λ bem mais alto que aqui. O jeito de
escolher é o de sempre: teste algumas posições e meça o que os leitores fazem com as listas.

## O que a MMR não vê

*Around the World in Eighty Days* ficou em todas as listas, ao lado de *Journey to the Centre of the
Earth* (*Viagem ao centro da Terra*), os dois de Verne. A MMR compara os vetores, e os vetores foram
feitos de títulos e sinopses; o nome do autor nunca virou vetor, então para a MMR dois livros do
mesmo autor só se parecem tanto quanto as histórias deles. Repetição que mora nos metadados é pega
por uma regra sobre os metadados, e é por isso que o limite por autor e a MMR são usados juntos, e
não um no lugar do outro.

A MMR também aparece fora das recomendações. Uma busca que devolve cinco trechos do mesmo parágrafo
desperdiça quatro lugares, e a mesma regra pode impedir que os trechos entregues a um modelo de
linguagem, o assunto de `rag`, se repitam.
