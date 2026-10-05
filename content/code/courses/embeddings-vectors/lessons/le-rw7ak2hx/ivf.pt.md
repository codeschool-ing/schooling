---
title: IVF, buscando em poucas células
version: 1
---

O primeiro jeito de pular vetores é o que uma bibliotecária inventaria. Separe a coleção em grupos
de vetores parecidos uma vez, com antecedência. Quando chega uma consulta, ache os grupos mais
próximos dela e busque só neles. O FAISS chama isso de **arquivo invertido**, IVF, por causa das
listas de documentos por palavra que a busca por palavra-chave mantém; aqui cada lista guarda os
vetores de um grupo, e os grupos se chamam **células**.

Os grupos vêm do **k-means**: escolha `nlist` pontos centrais de modo que todo vetor fique perto de
um deles, e arquive cada vetor sob o centro mais próximo. Uma consulta é comparada com os `nlist`
centros, o que é barato, e depois buscada de forma exata contra os vetores das suas `nprobe` células
mais próximas.

## O treino vem primeiro

`ivf.py` constrói um índice IVF com 1.024 células sobre os 100.000 vetores e gira o `nprobe` de 1 a
64:

```schooling-example
{
  "language": "python",
  "file": "ivf.py",
  "parts": [
    {
      "code": "import time\nimport faiss\nimport numpy as np\nfrom bench import X, recall, timed\n\ncells = faiss.IndexFlatIP(384)\nivf = faiss.IndexIVFFlat(cells, 384, 1024, faiss.METRIC_INNER_PRODUCT)\ntry:\n    ivf.add(X)\nexcept RuntimeError as e:\n    print(\"add before train:\", str(e).splitlines()[-1])",
      "note": "Um índice IVF precisa de um pequeno índice exato só para guardar os centros das células. Adicionar vetores antes do treino gera um erro, e o programa imprime a última linha dele."
    },
    {
      "code": "start = time.perf_counter()\nivf.train(X)\nivf.add(X)\nprint(f\"k-means into 1024 cells, then add: {time.perf_counter() - start:.1f} s\")\nsizes = np.array([ivf.invlists.list_size(i) for i in range(1024)])\nprint(f\"vectors per cell: smallest {sizes.min()}, median {np.median(sizes):.0f}, largest {sizes.max()}\")",
      "note": "`train` roda o k-means e `add` arquiva cada vetor na sua célula. `invlists` guarda as células, e os tamanhos mostram como elas são desiguais."
    },
    {
      "code": "print(f\"{'nprobe':>6} {'recall@10':>9} {'per query':>10} {'compared':>9}\")\nfor nprobe in (1, 2, 4, 8, 16, 32, 64):\n    ivf.nprobe = nprobe\n    faiss.cvar.indexIVF_stats.reset()\n    I, ms = timed(lambda Q: ivf.search(Q, 10)[1])\n    compared = faiss.cvar.indexIVF_stats.ndis / 1000\n    print(f\"{nprobe:>6} {recall(I):>9.3f} {ms:>7.3f} ms {compared:>9,.0f}\")",
      "note": "As mesmas 1.000 consultas em sete valores de `nprobe`. O FAISS conta em `indexIVF_stats` quantos vetores guardados comparou, e a última coluna divide isso pelo número de consultas."
    }
  ],
  "output": "ana@lab:~/emb$ python ivf.py\nadd before train: Error in virtual void faiss::IndexIVFFlat::add_core(faiss::idx_t, const float*, const faiss::idx_t*, const faiss::idx_t*, void*) at /project/faiss/IndexIVFFlat.cpp:66: Error: 'is_trained' failed\nk-means into 1024 cells, then add: 10.1 s\nvectors per cell: smallest 1, median 60, largest 558\nnprobe recall@10  per query  compared\n     1     0.749   0.054 ms       206\n     2     0.931   0.066 ms       302\n     4     0.990   0.100 ms       515\n     8     0.998   0.132 ms       982\n    16     0.999   0.219 ms     1,930\n    32     1.000   0.402 ms     3,742\n    64     1.000   0.761 ms     7,203"
}
```

**O índice recusou os vetores antes de ser treinado.** Ele não tem onde arquivá-los enquanto os
centros não existem, e `train` é o que os encontra: k-means sobre vetores de exemplo, aqui a própria
coleção, 10,1 s em quatro núcleos contando o `add`. Um índice que precisa de treino precisa de dados
antes de começar, e essa é a primeira diferença prática em relação ao grafo da próxima seção.

As células não são iguais. O k-means põe os centros onde os vetores estão, mas a menor célula guarda
1 vetor, a mediana 60 e a maior 558. Uma consulta que cai numa região densa busca em células
grandes, e é por isso que a média de vetores comparados com `nprobe` 1 é 206, e não 60.

## O botão é o nprobe

**Com uma célula, o recall foi 0,749.** Buscar em 206 vetores em vez de 100.000 achou três quartos
dos vizinhos verdadeiros em 0,054 ms. Quatro células chegaram a 0,990 comparando 515 vetores em
0,100 ms, contra 2,492 ms da busca exata. Daí em diante, cada vez que o `nprobe` dobra, os vetores
comparados e o tempo mais ou menos dobram, por cada vez menos recall: 64 células, 7.203 vetores,
1,000.

As perdas com `nprobe` pequeno têm uma causa só, e a figura a desenha. **Uma célula tem fronteiras, e
uma consulta perto de uma fronteira tem vizinhos do outro lado.** É o centro mais próximo que decide
qual célula é buscada, e não onde estão os vetores mais próximos.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 370\" role=\"img\" aria-label=\"Um plano dividido em sete células, cada uma em volta de um ponto central, com vetores espalhados como pontos pequenos. Uma consulta fica perto da fronteira entre duas células. O centro mais próximo dela está à esquerda, então com nprobe 1 só a célula da esquerda é buscada; dois dos seus três vizinhos mais próximos de verdade ficam logo do outro lado da fronteira, na célula da direita, e só são achados quando nprobe 2 acrescenta essa célula.\"><defs><marker id=\"cellspt-ah0\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M20.0 20.0 L171.4 20.0 L186.1 122.5 L127.7 178.3 L20.0 165.6 Z\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M171.4 20.0 L340.0 20.0 L301.8 153.7 L186.1 122.5 Z\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M340.0 20.0 L470.0 20.0 L470.0 194.7 L414.7 203.5 L302.7 155.5 L301.8 153.7 Z\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M210.1 350.0 L20.0 350.0 L20.0 165.6 L127.7 178.3 Z\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M218.2 350.0 L210.1 350.0 L127.7 178.3 L186.1 122.5 L301.8 153.7 L302.7 155.5 Z\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"var(--scan)\"></path><path d=\"M333.3 350.0 L218.2 350.0 L302.7 155.5 L414.7 203.5 Z\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"var(--scan)\" stroke-dasharray=\"6 4\"></path><path d=\"M470.0 194.7 L470.0 350.0 L333.3 350.0 L414.7 203.5 Z\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><circle cx=\"445.1\" cy=\"33.6\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"346.5\" cy=\"79\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"454.1\" cy=\"35.2\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"408.2\" cy=\"241.2\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"133.1\" cy=\"134.8\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"334.5\" cy=\"117\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"143.2\" cy=\"100.9\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"398.9\" cy=\"301.1\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"373\" cy=\"99.3\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"427.7\" cy=\"188.5\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"129.5\" cy=\"171.2\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"210.5\" cy=\"54.5\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"272.8\" cy=\"141.6\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"274.9\" cy=\"318.4\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"307.6\" cy=\"155.6\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"38.1\" cy=\"73.5\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"104\" cy=\"320.8\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"153.2\" cy=\"183.4\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"411.4\" cy=\"61\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"80\" cy=\"44.7\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"231.5\" cy=\"290.5\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"268.6\" cy=\"154.5\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"245.9\" cy=\"85.6\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"437.7\" cy=\"139.7\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"131.2\" cy=\"126.5\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"384.7\" cy=\"128.7\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"419.1\" cy=\"134.2\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"219.9\" cy=\"53\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"420.2\" cy=\"276.8\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"234\" cy=\"65.8\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"241.8\" cy=\"146.6\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"391.2\" cy=\"317.7\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"348.7\" cy=\"119\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"47.8\" cy=\"307.1\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"436.1\" cy=\"79.1\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"245\" cy=\"179.1\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"449.9\" cy=\"43.3\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"56.5\" cy=\"291.6\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"274.9\" cy=\"173.3\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"364.4\" cy=\"213.9\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"327.7\" cy=\"109.2\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"66.5\" cy=\"32.8\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"173.2\" cy=\"231\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"193.3\" cy=\"137.7\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"296\" cy=\"248.6\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"286\" cy=\"126.6\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"383.3\" cy=\"278.2\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"36.5\" cy=\"237.4\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"179.7\" cy=\"150.4\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"172.3\" cy=\"313\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"324.3\" cy=\"127.6\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"167\" cy=\"217.5\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"331.9\" cy=\"135.4\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"55.4\" cy=\"83.4\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"400.1\" cy=\"255.9\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"76.6\" cy=\"288.9\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"277.6\" cy=\"133.8\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"414.4\" cy=\"69.9\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"72.2\" cy=\"136.5\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"347.2\" cy=\"199.8\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"238.2\" cy=\"311.1\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"199.4\" cy=\"274.3\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"32\" cy=\"272.7\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"268\" cy=\"203\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"268\" cy=\"203\" r=\"7\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></circle><circle cx=\"290\" cy=\"226\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"290\" cy=\"226\" r=\"7\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></circle><circle cx=\"297\" cy=\"205\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"297\" cy=\"205\" r=\"7\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></circle><path d=\"M104 84 L116 96 M104 96 L116 84\" stroke=\"var(--paper)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M244 64 L256 76 M244 76 L256 64\" stroke=\"var(--paper)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M384 104 L396 116 M384 116 L396 104\" stroke=\"var(--paper)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M84 254 L96 266 M84 266 L96 254\" stroke=\"var(--paper)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M209 194 L221 206 M209 206 L221 194\" stroke=\"var(--paper)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M324 244 L336 256 M324 256 L336 244\" stroke=\"var(--paper)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M414 294 L426 306 M414 306 L426 294\" stroke=\"var(--paper)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M270 204 L278 212 L270 220 L262 212 Z\" stroke=\"none\" stroke-width=\"0\" fill=\"var(--amber)\"></path><path d=\"M270 212 L215 200\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\"></path><text x=\"120\" y=\"330\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">nprobe 1 busca esta célula</text><path d=\"M178 318 L198 232\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#cellspt-ah0)\"></path><text x=\"460\" y=\"336\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">nprobe 2 acrescenta esta</text><path d=\"M392 324 L352 286\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#cellspt-ah0)\"></path><path d=\"M489 44 L501 56 M489 56 L501 44\" stroke=\"var(--paper)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"513\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">centro de célula</text><circle cx=\"495\" cy=\"80\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><text x=\"513\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">um vetor guardado</text><path d=\"M495 102 L503 110 L495 118 L487 110 Z\" stroke=\"none\" stroke-width=\"0\" fill=\"var(--amber)\"></path><text x=\"513\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">a consulta</text><circle cx=\"495\" cy=\"140\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"495\" cy=\"140\" r=\"7\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></circle><text x=\"513\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">os 3 vizinhos mais próximos</text></svg>", "caption": "O IVF busca as células cujos centros estão mais perto da consulta, e não as células que guardam os vetores mais próximos dela. Perto de uma fronteira as duas coisas diferem, e é daí que vêm as perdas com nprobe 1."}
```

## Sem estrutura, falha

A seção sobre busca exata prometeu uma medida de vetores aleatórios. `uniform.py` constrói o mesmo
índice sobre 100.000 vetores unitários uniformemente aleatórios:

```python
import faiss
import numpy as np

rng = np.random.default_rng(15)
def uniform(n):
    v = rng.normal(size=(n, 384))
    return (v / np.linalg.norm(v, axis=1, keepdims=True)).astype("float32")
X, Q = uniform(100_000), uniform(1_000)

exact = faiss.IndexFlatIP(384)
exact.add(X)
scores, truth = exact.search(Q, 10)
print(f"best score per query, median: {np.median(scores[:, 0]):.3f}")

ivf = faiss.IndexIVFFlat(faiss.IndexFlatIP(384), 384, 1024, faiss.METRIC_INNER_PRODUCT)
ivf.train(X)
ivf.add(X)
for nprobe in (1, 8, 64):
    ivf.nprobe = nprobe
    _, I = ivf.search(Q, 10)
    r = np.mean([len(set(a) & set(b)) / 10 for a, b in zip(I, truth)])
    print(f"nprobe {nprobe:>2}: recall@10 {r:.3f}")
```

```
ana@lab:~/emb$ python uniform.py
best score per query, median: 0.219
nprobe  1: recall@10 0.012
nprobe  8: recall@10 0.055
nprobe 64: recall@10 0.241
```

**Buscando 64 de 1.024 células, o recall foi 0,241.** A melhor correspondência da busca exata teve
nota mediana de 0,219: todo vetor está quase tão longe da consulta quanto qualquer outro, então as
células não conseguem juntar vizinhos, porque não há vizinhanças. Medido em vetores assim, todo
índice aproximado parece quebrado. Medido em embeddings, o mesmo índice chegou a 0,990 com quatro
células.

## O que o treino amarra

Os centros ficam fixos quando o índice é treinado. Todo vetor adicionado depois é arquivado sob um
dos centros antigos, pareça ou não com aquilo em que o índice foi treinado. Se a coleção muda de
perfil, como na semana de mensagens sobre assinatura da aula 6, os vetores novos se amontoam em
poucas células desenhadas para outra coisa, essas células crescem e buscar nelas fica mais lento. O
conserto é treinar de novo, o que significa reconstruir o índice.

O `ivfflat` do pgvector é o mesmo índice. O `lists` dele é o `nlist` e o `ivfflat.probes` é o
`nprobe`, com padrão 1. A documentação sugere começar com `lists` igual ao número de linhas dividido
por 1.000, para até um milhão de linhas, e `probes` igual à raiz quadrada de `lists`, e construir o
índice depois que a tabela já tem os dados, para que o treino os veja.
