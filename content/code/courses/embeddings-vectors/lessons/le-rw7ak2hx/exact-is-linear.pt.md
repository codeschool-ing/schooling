---
title: A busca exata lê tudo
version: 1
---

A aula 11 mediu o tempo da busca exata e viu que ele acompanha a quantidade: dez vezes mais
vetores, cerca de dez vezes mais tempo. É esse o custo que todo índice desta aula existe para
evitar, e antes de medir como eles evitam você precisa de uma coleção grande o bastante para senti-lo
e de um conjunto de consultas cujas respostas verdadeiras você conhece.

## Cem mil vetores, e o que eles são

O atalho óbvio é encher um índice de números aleatórios. **Vetores aleatórios são o teste errado
para um índice aproximado**, porque não têm vizinhanças: em 384 dimensões, pontos uniformemente
aleatórios ficam quase à mesma distância uns dos outros, e um índice que aposta em estrutura não tem
em que apostar. A seção sobre IVF mede o que isso faz. Embeddings de verdade são o oposto; tudo o que
as aulas 3 a 6 fizeram dependia de textos sobre o mesmo assunto caírem perto uns dos outros.

Transformar 100.000 textos reais em vetores exigiria 100.000 textos, e o curso tem 334. Então
`make_set.py` monta o conjunto a partir desses 334:

```schooling-example
{
  "language": "python",
  "file": "make_set.py",
  "parts": [
    {
      "code": "import json\nimport faiss\nimport numpy as np\nfrom minilm import embed\n\nsources = [(\"help\", \"body\"), (\"queries\", \"text\"), (\"tickets\", \"text\"),\n           (\"books\", \"blurb\"), (\"inbox\", \"text\"), (\"week2\", \"text\")]\ntexts = [json.loads(line)[key] for name, key in sources\n         for line in open(f\"data/{name}.jsonl\")]\nreal = embed(texts)",
      "note": "Os textos do próprio curso: os artigos de ajuda, as perguntas, os chamados, as sinopses dos livros e os dois conjuntos de mensagens. Transformados em vetores pelo all-MiniLM-L6-v2, dão 334 vetores reais."
    },
    {
      "code": "rng = np.random.default_rng(15)\n\ndef blends(n):\n    a = real[rng.integers(len(real), size=n)]\n    b = real[rng.integers(len(real), size=n)]\n    w = rng.random((n, 1))\n    v = w * a + (1 - w) * b + rng.normal(scale=0.05, size=(n, 384))\n    return (v / np.linalg.norm(v, axis=1, keepdims=True)).astype(\"float32\")\n\nX, Q = blends(100_000), blends(1_000)",
      "note": "Uma mistura pega dois vetores reais ao acaso, combina os dois numa proporção aleatória, soma ruído de 0,05 por coordenada e divide pelo comprimento. O gerador tem semente fixa, então toda execução faz o mesmo conjunto."
    },
    {
      "code": "exact = faiss.IndexFlatIP(384)\nexact.add(X)\nscores, truth = exact.search(Q, 10)\nnp.save(\"vectors.npy\", X)\nnp.save(\"queries.npy\", Q)\nnp.save(\"truth.npy\", truth)",
      "note": "A busca exata do FAISS encontra os 10 primeiros verdadeiros de cada consulta. Os três arquivos são o que todo programa seguinte carrega."
    },
    {
      "code": "print(f\"{len(real)} real vectors, {len(X):,} blends, {len(Q):,} queries\")\nprint(f\"best score per query, median: {np.median(scores[:, 0]):.3f}\")\nprint(f\"10th score per query, median: {np.median(scores[:, 9]):.3f}\")",
      "note": "Duas medianas: a nota da melhor correspondência de cada consulta e a da décima."
    }
  ],
  "output": "ana@lab:~/emb$ python make_set.py\n334 real vectors, 100,000 blends, 1,000 queries\nbest score per query, median: 0.508\n10th score per query, median: 0.470"
}
```

**Cada um dos 100.000 vetores é uma mistura de dois vetores reais do all-MiniLM-L6-v2**, numa
proporção aleatória, com um pouco de ruído, dividida pelo seu comprimento. As misturas herdam a
forma do espaço real: se aglomeram onde os textos se aglomeram e rareiam onde eles rareiam. As 1.000
consultas são feitas do mesmo jeito e não estão na coleção.

O último passo é aquele de que toda medida abaixo depende. **`IndexFlatIP` é busca exata**, a mesma
multiplicação seguida de ordenação da linha de NumPy da aula 3, e `truth.npy` guarda os 10
primeiros dela para cada consulta. Esse é o gabarito: o que quer que um índice aproximado devolva é
comparado com ele.

Repare nas duas medianas. A melhor correspondência tem nota 0,508 e a décima 0,470, então os dez
vizinhos mais próximos de uma consulta ficam espremidos numa faixa estreita de notas. Guarde isso;
vai decidir vários resultados desta aula.

## O tempo acompanha a quantidade

Todo tempo desta aula foi medido nesta máquina, com outros trabalhos rodando ao lado:

```
ana@lab:~/emb$ nproc; grep -m1 "model name" /proc/cpuinfo
4
model name	: Intel(R) Xeon(R) Processor @ 2.10GHz
```

`bench.py`, que a próxima seção mostra, carrega os três arquivos e mede o tempo de uma busca em um
desses quatro núcleos. `exact.py` roda a busca exata sobre os primeiros 12.500, 25.000, 50.000 e 100.000 vetores:

```schooling-example
{
  "language": "python",
  "file": "exact.py",
  "parts": [
    {
      "code": "import faiss\nfrom bench import X, timed\n\nprint(f\"{'vectors':>9} {'per query':>10} {'per vector':>11}\")\nfor n in (12_500, 25_000, 50_000, 100_000):\n    index = faiss.IndexFlatIP(384)\n    index.add(X[:n])\n    _, ms = timed(lambda Q: index.search(Q, 10)[1])\n    print(f\"{n:>9,} {ms:>7.3f} ms {ms * 1e6 / n:>8.1f} ns\")",
      "note": "Um índice exato sobre os primeiros `n` vetores em quatro tamanhos, medido com `bench.timed`. A última coluna divide o tempo pelo número de vetores."
    }
  ],
  "output": "ana@lab:~/emb$ python exact.py\n  vectors  per query  per vector\n   12,500   0.303 ms     24.2 ns\n   25,000   0.712 ms     28.5 ns\n   50,000   1.033 ms     20.7 ns\n  100,000   2.492 ms     24.9 ns"
}
```

**Oito vezes mais vetores levaram 8,2 vezes mais tempo**, de 0,303 ms para 2,492 ms, e o custo por
vetor fica entre 20,7 e 28,5 ns, que é o ruído de uma máquina dividida com outros trabalhos. Esses
tempos são um lote de 1.000 consultas dividido por 1.000, o que deixa o processador usar cada vetor
que carrega para muitas consultas de uma vez. A aula 11 mediu uma consulta por vez com NumPy, então os
tempos de lá medem outra coisa e não são comparáveis com estes.

O que não muda é a forma. A busca exata sobre 100.000 vetores faz 100.000 comparações por consulta,
cada uma com 384 multiplicações e somas, e nenhuma esperteza na aritmética diminui esse número.
**Para ir mais rápido, uma busca precisa pular vetores.** E para pular um, ela precisa decidir, sem
olhar, que aquele vetor não pode estar entre os mais próximos. Quando essa decisão erra, a busca
perde um vizinho verdadeiro, e é isso que *aproximada* quer dizer.
