---
title: Recall, a medida do aproximado
version: 1
---

A aula 3 usou a palavra **recall** para outra coisa, e as duas se confundem com facilidade. Lá ela
dizia se o artigo que o curso julgou certo voltava para a pergunta de uma cliente: uma medida do
modelo e da busca juntos, contra o julgamento de uma pessoa. Aqui ela compara um índice com a busca
exata e nada mais. **Recall@10 é a fração dos 10 primeiros da busca exata que o índice também
devolveu.** Não diz nada sobre se esses dez eram boas respostas. Isso é assunto do modelo, e o
melhor que um índice pode fazer é devolver exatamente o que a busca exata devolveria.

## Medindo

`bench.py` é o pequeno módulo que todo programa desta aula importa:

```schooling-example
{
  "language": "python",
  "file": "bench.py",
  "parts": [
    {
      "code": "import time\nimport faiss\nimport numpy as np\n\nX = np.load(\"vectors.npy\")\nQ = np.load(\"queries.npy\")\ntruth = np.load(\"truth.npy\")",
      "note": "A coleção, as consultas e o gabarito que `make_set.py` salvou."
    },
    {
      "code": "def recall(I):\n    return np.mean([len(set(found) & set(true)) / 10\n                    for found, true in zip(I, truth)])",
      "note": "Recall@10 de um resultado inteiro: para cada consulta, quantos dos dez ids devolvidos estão entre os dez da busca exata, dividido por dez, na média das 1.000 consultas."
    },
    {
      "code": "def timed(search):\n    faiss.omp_set_num_threads(1)\n    start = time.perf_counter()\n    I = search(Q)\n    ms = (time.perf_counter() - start) * 1000 / len(Q)\n    faiss.omp_set_num_threads(4)\n    return I, ms",
      "note": "Mede o tempo de uma busca das 1.000 consultas em um núcleo e devolve os milissegundos por consulta. Depois o FAISS volta a quatro threads, para que construir um índice ainda use a máquina inteira."
    }
  ]
}
```

`recall.py` o usa em duas buscas que pulam vetores. A primeira é ingênua de propósito: escolher um
décimo aleatório da coleção e buscar nele de forma exata. A segunda é `HNSW32`, uma das strings de
fábrica que a aula 13 nomeou, com os padrões do FAISS:

```schooling-example
{
  "language": "python",
  "file": "recall.py",
  "parts": [
    {
      "code": "import faiss\nimport numpy as np\nfrom bench import X, Q, truth, recall\n\nrng = np.random.default_rng(1)\npart = rng.choice(len(X), size=10_000, replace=False)\nsample = faiss.IndexIDMap(faiss.IndexFlatIP(384))\nsample.add_with_ids(X[part], part)\n_, I = sample.search(Q, 10)\nprint(f\"exact search over a random tenth: recall@10 {recall(I):.3f}\")",
      "note": "Um décimo aleatório da coleção, guardado com os ids originais pelo `IndexIDMap` para que o resultado possa ser comparado com o gabarito, e buscado de forma exata."
    },
    {
      "code": "hnsw = faiss.index_factory(384, \"HNSW32\", faiss.METRIC_INNER_PRODUCT)\nhnsw.add(X)\nS, I = hnsw.search(Q, 10)\nper = np.array([len(set(a) & set(b)) / 10 for a, b in zip(I, truth)])\nprint(f\"HNSW32 over everything:          recall@10 {per.mean():.3f}\")\nprint(f\"queries with all 10: {np.sum(per == 1)}, with 5 or fewer: {np.sum(per <= 0.5)}\")",
      "note": "O `HNSW32` da aula 13 sobre os 100.000 vetores, com os padrões do FAISS. `per` guarda o recall de cada consulta para que a dispersão possa ser contada, e não só a média."
    },
    {
      "code": "true_scores = (X[truth] * Q[:, None, :]).sum(axis=2)\nprint(f\"mean score of the 10 returned: exact {true_scores.mean():.4f}, HNSW32 {S.mean():.4f}\")",
      "note": "As notas dos dez vetores que a busca exata devolveu, recalculadas a partir dos vetores, ao lado das notas que o `HNSW32` devolveu."
    }
  ],
  "output": "ana@lab:~/emb$ python recall.py\nexact search over a random tenth: recall@10 0.104\nHNSW32 over everything:          recall@10 0.841\nqueries with all 10: 683, with 5 or fewer: 149\nmean score of the 10 returned: exact 0.4750, HNSW32 0.4593"
}
```

**O décimo aleatório achou 0,104 dos vizinhos verdadeiros**, que é o que ler um décimo aleatório
tem de achar: cada um dos dez está na amostra com chance de um em dez. Essa é a base. Todo índice lê
só uma parte da coleção, e **todo o trabalho dele é superar a fração que lê**, adivinhando qual
parte guarda os vizinhos. O `HNSW32` lê bem menos de um décimo, como as seções sobre HNSW contam, e
achou 0,841.

## Uma média esconde a dispersão

O 0,841 é uma média sobre 1.000 consultas, e as consultas não o dividiram por igual. 683 delas
receberam os dez vizinhos, e 149 receberam cinco ou menos. Uma busca boa na média ainda pode ser ruim
para a cliente cuja pergunta cai numa parte do espaço que o índice atendeu mal, e um teste com
meia dúzia de consultas não vai encontrar essa cliente.

A aula 13 rodou o mesmo `HNSW32` sobre o seu próprio conjunto de cópias com ruído e achou os dez
vizinhos para todas as consultas. **O recall pertence ao índice e aos dados juntos**, e é por isso
que ele tem de ser medido em vetores parecidos com os seus.

## O que uma perda custa

A última linha põe um número no que foram as perdas. Os dez vetores que a busca exata devolveu
tiveram nota média de 0,4750, e os dez que o `HNSW32` devolveu, 0,4593. **Um vizinho perdido é
substituído por outro um pouco mais longe**, e não por um vetor qualquer: a busca achou a vizinhança
certa e perdeu alguns dos seus membros. Quando o melhor e o décimo vizinho da consulta mediana têm
notas 0,508 e 0,470, como a seção anterior mediu, um passo pequeno na nota basta para trocar um pelo
outro.

Se isso importa é uma pergunta sobre a aplicação. Dez trechos entregues a um modelo de linguagem
perdem pouco quando um é trocado por um vizinho quase idêntico. Uma verificação de envios duplicados
que procura a única cópia de um arquivo perde tudo quando essa cópia é a que ficou de fora.

## Aproximado é um botão de ajuste

Todo índice aproximado tem um parâmetro que lê mais da coleção em troca de mais recall, e o resto
desta aula gira esses parâmetros e mede os dois lados. O método não muda: **escolha o recall de que
você precisa e depois ache o parâmetro mais barato que o alcança nos seus dados**, com o gabarito
vindo da busca exata sobre uma amostra das suas próprias consultas. A busca exata sobre 1.000
consultas levou segundos aqui, embora atender toda cliente desse jeito seja justamente o que o
índice existe para evitar.
