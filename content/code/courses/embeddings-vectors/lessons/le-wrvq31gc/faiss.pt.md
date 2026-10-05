---
title: FAISS, um índice e mais nada
version: 1
---

O FAISS aparece na maioria das listas de bancos de vetores, e não é um. **É uma biblioteca que guarda
vetores na memória e acha os mais próximos**, escrita em C++ pelo laboratório de pesquisa da Meta, com
interface para Python; o laboratório do curso fixa o `faiss-cpu` 1.15.1, e existe uma versão para GPU
ao lado dela. Ele não guarda texto, nem metadados, nem os seus ids, não tem servidor nem linguagem de
consulta, e não grava nada em disco a não ser que você peça. O que ele faz, faz rápido e de muitas
formas, e é por isso que bancos de dados são construídos em cima dele.

O menor programa com FAISS põe os 40 vetores da central de ajuda num índice plano e faz a pergunta da
aula 1:

```schooling-example
{
  "language": "python",
  "file": "flat.py",
  "parts": [
    {
      "code": "import json\nimport faiss\nfrom minilm import embed\n\nhelp = [json.loads(line) for line in open(\"data/help.jsonl\")]\nids = [h[\"id\"] for h in help]\nX = embed([h[\"title\"] + \". \" + h[\"body\"] for h in help])",
      "note": "Os 40 artigos, transformados em vetores como em toda aula desde a aula 3. `ids` guarda os ids na mesma ordem das linhas de `X`."
    },
    {
      "code": "index = faiss.IndexFlatIP(384)\nindex.add(X)\nprint(index.ntotal, \"vectors of\", index.d, \"dimensions\")",
      "note": "`IndexFlatIP` compara pelo produto interno, que para vetores unitários é a similaridade cosseno. Ele recebe a dimensão e mais nada."
    },
    {
      "code": "D, I = index.search(embed(\"how do I get my money back\"), 3)\nprint(\"positions:\", I[0], \" scores:\", D[0].round(4))\nprint(\"articles: \", [ids[i] for i in I[0]])",
      "note": "`search` recebe uma matriz de perguntas e devolve duas: as notas e as posições das linhas mais próximas. As posições são convertidas de volta em ids de artigo à mão."
    }
  ],
  "output": "ana@lab:~/emb$ python flat.py\n40 vectors of 384 dimensions\npositions: [17 14 21]  scores: [0.4456 0.4376 0.3994]\narticles:  ['h18', 'h15', 'h22']"
}
```

As notas são os produtos escalares que a aula 1 imprimiu, 0,4456 para o artigo do presente, porque o
`IndexFlatIP` compara pelo produto interno e os vetores têm comprimento 1. Um índice **plano** (*flat*)
é busca exata: ele compara a pergunta com cada vetor guardado, que é o `D @ q` da aula 3 escrito em
C++.

**O que volta são posições.** `[17 14 21]` quer dizer o 18º, o 15º e o 22º vetores adicionados, e só
a lista `ids` que o programa guardou ao lado do índice os transforma em h18, h15 e h22. Apague um
artigo, refaça a lista em outra ordem, e as posições passam a apontar para outros artigos enquanto o
índice responde com a mesma confiança de antes.

## Os seus próprios ids, e um arquivo

`IndexIDMap` embrulha outro índice e guarda um inteiro de 64 bits ao lado de cada vetor, então a
busca devolve os seus números em vez de posições. Só inteiros: h15 tem de virar 15.

```schooling-example
{
  "language": "python",
  "file": "ids.py",
  "parts": [
    {
      "code": "import json\nimport os\nimport faiss\nimport numpy as np\nfrom minilm import embed\n\nhelp = [json.loads(line) for line in open(\"data/help.jsonl\")]\nX = embed([h[\"title\"] + \". \" + h[\"body\"] for h in help])\nq = embed(\"how do I get my money back\")",
      "note": "Os mesmos vetores, e a pergunta transformada em vetor uma vez."
    },
    {
      "code": "index = faiss.IndexIDMap(faiss.IndexFlatIP(384))\nindex.add_with_ids(X, np.array([int(h[\"id\"][1:]) for h in help]))\nprint(\"ids:\", index.search(q, 3)[1][0])",
      "note": "`IndexIDMap` embrulha o índice plano e guarda um inteiro de 64 bits para cada vetor. h15 vira 15, porque o FAISS não aceita strings."
    },
    {
      "code": "index.remove_ids(np.array([18]))\nprint(\"ids:\", index.search(q, 3)[1][0], \"of\", index.ntotal)",
      "note": "Remova o id 18, o artigo do presente, e busque de novo."
    },
    {
      "code": "faiss.write_index(index, \"help.faiss\")\nagain = faiss.read_index(\"help.faiss\")\nprint(again.ntotal, \"vectors read back,\", os.path.getsize(\"help.faiss\"), \"bytes on disk\")",
      "note": "Grave o índice num arquivo e leia num objeto novo, como outro programa faria."
    }
  ],
  "output": "ana@lab:~/emb$ python ids.py\nids: [18 15 22]\nids: [15 22 14] of 39\n39 vectors read back, 60306 bytes on disk"
}
```

Sem h18, a busca desceu uma posição e achou h14. O arquivo tem 60.306 bytes: 39 vetores de 1.536
bytes dão 59.904, os ids somam 39 × 8 = 312, e os 90 bytes que sobram descrevem o índice. **Os
títulos, os corpos e as categorias não estão nele**, e nunca vão estar. Outra coisa precisa guardá-los,
com os mesmos inteiros como chave: um dicionário, um arquivo JSON, uma tabela num banco de dados.
Manter esse depósito e o índice em sincronia a cada mudança é trabalho do seu programa, que é a
coerência que a aula 11 pediu de qualquer armazenamento, sem ninguém para garantir.

## Uma biblioteca confere pouco

Na aula 12, o Chroma recusou um vetor do WordLlama com uma frase que nomeava as duas dimensões. O FAISS também
recusa, e diz isto:

```python
import faiss
import numpy as np

index = faiss.IndexFlatIP(384)
try:
    index.add(np.zeros((1, 256), dtype="float32"))
except Exception as e:
    print(type(e).__name__, repr(str(e)))
```

```
ana@lab:~/emb$ python wrong.py
AssertionError ''
```

Uma asserção com a mensagem vazia. O FAISS pegou o erro, e o programa que o cometeu não fica sabendo
nada sobre ele. É a troca que uma biblioteca faz o tempo todo: ela supõe que quem chama conhece a dimensão,
a métrica e o significado de cada id, e não gasta nada conferindo.
