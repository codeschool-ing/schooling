---
title: Reranqueamento
version: 1
---

A escolha até aqui pareceu um botão só: um k pequeno é preciso e perde coisas, um k grande as
encontra e repassa ruído. O **reranqueamento** (reranking) separa isso em duas etapas. Uma primeira
passada rápida busca um número generoso de candidatos, digamos 20, e um avaliador mais lento e
melhor reordena só esses e fica com os melhores, digamos 5. A primeira etapa é ajustada para recall,
a segunda para precisão, e o avaliador lento só vê 20 documentos, seja qual for o tamanho da coleção.

## A segunda etapa costuma ser um cross-encoder

Tudo neste curso até aqui é um **bi-encoder**: a pergunta e o documento viram vetores separadamente
e são comparados depois, o que permite transformar os documentos em vetores uma vez e guardá-los. Um
**cross-encoder** lê a pergunta e um documento juntos, como uma entrada só, por um transformer, e
devolve uma única nota de relevância. Ver os dois ao mesmo tempo permite notar coisas que um produto
escalar não nota, como uma negação que inverte o que o documento diz sobre a pergunta. O preço é que
nada pode ser calculado antes: cada candidato custa uma execução do modelo para cada pergunta, e por
isso ele é usado em 20 candidatos e não numa coleção inteira.

No sentence-transformers fica assim. Isto **não foi executado** aqui: o modelo é baixado de
huggingface.co, que estava fora de alcance do laboratório, e a biblioteca precisa do PyTorch, cujo
índice também estava fora de alcance.

```python
from sentence_transformers import CrossEncoder

reranker = CrossEncoder("cross-encoder/ms-marco-MiniLM-L-6-v2")
scores = reranker.predict([(question, text) for text in candidates])
```

Existem reranqueadores hospedados com o mesmo formato: uma pergunta e uma lista de textos entram, e
sai uma nota por texto. O provedor substituto do laboratório não tem endpoint de reranqueamento,
então nenhum foi chamado aqui também.

## O mesmo padrão, medido

Dá para ver o padrão funcionar sem um cross-encoder, e as duas etapas do experimento abaixo rodaram
nesta máquina. No primeiro, a passada rápida compara **um bit por coordenada** em vez
de 384 floats; no segundo, a passada rápida é o WordLlama e o avaliador melhor são os dois modelos
juntos.

```schooling-example
{
  "language": "python",
  "file": "rerank.py",
  "parts": [
    {
      "code": "import json\nimport numpy as np\nfrom minilm import embed\nfrom wordllama import WordLlama\n\nhelp = [json.loads(line) for line in open(\"data/help.jsonl\")]\nids = [h[\"id\"] for h in help]\ntexts = [h[\"title\"] + \". \" + h[\"body\"] for h in help]\nqueries = [json.loads(line) for line in open(\"data/queries.jsonl\")]\nqtexts = [q[\"text\"] for q in queries]\n\ndef found(ranked, k):\n    return sum(any(ids[j] in q[\"relevant\"] for j in r[:k])\n               for r, q in zip(ranked, queries))"
    },
    {
      "code": "D, Q = embed(texts), embed(qtexts)\ncodes = np.packbits(D > 0, axis=1)\nqcodes = np.packbits(Q > 0, axis=1)\nprint(\"bytes per article:\", D[0].nbytes, \"as floats,\", codes[0].nbytes, \"as bits\")",
      "note": "Guarde cada artigo duas vezes: os 384 floats, e um bit por coordenada dizendo se ela é positiva. 384 bits são 48 bytes."
    },
    {
      "code": "def first_pass(qc, n):\n    differing = np.unpackbits(codes ^ qc, axis=1).sum(axis=1)\n    return np.argsort(differing, kind=\"stable\")[:n]\n\ndef rerank(candidates, score):\n    return candidates[np.argsort(-score[candidates])]",
      "note": "A primeira passada compara bits: quanto menos bits dois códigos discordam, mais perto eles contam. O reranqueamento pega os candidatos e os ordena de novo por uma nota melhor."
    },
    {
      "code": "print(\"                        @1  @3\")\nexact = [np.argsort(-(D @ q)) for q in Q]\nprint(\"float, every article   \", found(exact, 1), found(exact, 3))\nprint(\"bits only              \", *(found([first_pass(c, 40) for c in qcodes], k) for k in (1, 3)))\nfor n in (5, 10, 20):\n    ranked = [rerank(first_pass(c, n), D @ q) for c, q in zip(qcodes, Q)]\n    print(f\"bits {n:2}, rerank floats \", found(ranked, 1), found(ranked, 3))",
      "note": "Só os bits sobre os 40, depois os 5, 10 ou 20 primeiros pelos bits reordenados pelos vetores float completos."
    },
    {
      "code": "wl = WordLlama.load()\nW, WQ = wl.embed(texts, norm=True), wl.embed(qtexts, norm=True)\nwordllama = [np.argsort(-(W @ q)) for q in WQ]\nprint(\"wordllama only         \", found(wordllama, 1), found(wordllama, 3))\nboth = [rerank(r[:10], D @ q + W @ wq) for r, q, wq in zip(wordllama, Q, WQ)]\nprint(\"wordllama 10, rerank   \", found(both, 1), found(both, 3))",
      "note": "Um segundo experimento: o WordLlama escolhe 10 candidatos, e eles são reordenados pela soma das notas dos dois modelos."
    }
  ],
  "output": "ana@lab:~/emb$ python rerank.py\nbytes per article: 1536 as floats, 48 as bits\n                        @1  @3\nfloat, every article    19 22\nbits only               16 23\nbits  5, rerank floats  19 22\nbits 10, rerank floats  19 22\nbits 20, rerank floats  19 22\nwordllama only          20 24\nwordllama 10, rerank    23 24"
}
```

**Só os bits perdem 3 perguntas na posição 1, e reranquear apenas os 5 primeiros candidatos pelos
vetores completos recupera todas.** Só bits encontra 16 em @1 contra 19 dos floats completos; a
partir de 5, 10 ou 20 candidatos por bits, o reranqueamento encontra 19 de novo. A linha só de bits
também mostra 23 em @3 contra 22 dos floats, uma pergunta que por acaso caiu melhor, e um lembrete
de que com 24 perguntas uma diferença de uma não é uma descoberta. Os bits são 48 bytes por artigo
contra 1.536, então a primeira passada lê um trinta e dois avos dos dados; a aula 18 põe preço nessa
economia em escala.

**O segundo experimento ganha 3 perguntas na posição 1.** O WordLlama sozinho encontra 20 em @1 e o
all-MiniLM-L6-v2 sozinho encontrou 19. Pegar os 10 candidatos do WordLlama e reordená-los pela soma
das notas dos dois modelos encontra 23, e 24 em @3. Os dois modelos erram coisas diferentes, e um
documento que os dois avaliam bem é com mais frequência o certo. Numa coleção deste tamanho isso é
uma pista e não uma lei; meça nas suas próprias perguntas antes de construir em cima disso.

## Onde o reranqueamento entra

O reranqueamento leva a pergunta *quantos* para a primeira etapa, onde k pode ser generoso porque os
candidatos são baratos, e deixa para a segunda etapa decidir a ordem dos poucos que são repassados.
Os dois números são escolhidos separadamente: o primeiro k pela curva de recall da passada rápida, o
segundo pelo que o leitor seguinte consegue usar. Uma nota de corte, se você usar uma, pertence à
segunda etapa, medida nas notas da segunda etapa.

A aula 5 encontrou outro tipo de reordenação, a Maximal Marginal Relevance (MMR), que reordena por
variedade e não por relevância. Ela entra no mesmo lugar do caminho.
