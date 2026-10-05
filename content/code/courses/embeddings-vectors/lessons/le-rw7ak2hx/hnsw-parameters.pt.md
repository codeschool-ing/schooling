---
title: M, ef_construction e ef
version: 1
---

O HNSW tem três parâmetros, e o erro mais comum é tratá-los como um botão só, com a etiqueta
*qualidade*. **Dois deles ficam fixos quando o índice é construído e um é escolhido a cada
consulta**, e eles custam coisas diferentes:

- `M` é quantas ligações cada vetor recebe nas camadas de cima; a camada 0 recebe o dobro. Ele define
  o tamanho do grafo e o quanto ele é bem conectado.
- `ef_construction` é o tamanho da lista de candidatos durante a inserção, quando cada vetor novo
  procura os vizinhos aos quais vai se ligar. Ele define a qualidade dessas ligações.
- `ef` é o tamanho da lista de candidatos na hora da consulta, a lista da seção anterior. Ele pode
  mudar de uma consulta para a outra.

## Os dois que você paga uma vez

`params.py` constrói quatro índices do hnswlib sobre os mesmos 100.000 vetores e busca em cada um
com o mesmo `ef` de 40:

```schooling-example
{
  "language": "python",
  "file": "params.py",
  "parts": [
    {
      "code": "import os\nimport time\nimport hnswlib\nfrom bench import X, Q, recall\n\nprint(f\"{'M':>2} {'ef_construction':>15} {'build':>7} {'bytes/vector':>12} {'recall@10':>9} {'per query':>10}\")\nfor M, ef_construction in ((8, 200), (16, 200), (32, 200), (16, 40)):\n    index = hnswlib.Index(space=\"ip\", dim=384)\n    index.init_index(max_elements=len(X), M=M, ef_construction=ef_construction)\n    start = time.perf_counter()\n    index.add_items(X)\n    built = time.perf_counter() - start",
      "note": "Quatro índices do hnswlib sobre os mesmos vetores: três valores de `M` com o mesmo `ef_construction`, e um construído com uma lista mais curta. `add_items` constrói o grafo usando os quatro núcleos."
    },
    {
      "code": "    index.save_index(f\"m{M}-{ef_construction}.bin\")\n    size = os.path.getsize(f\"m{M}-{ef_construction}.bin\") / len(X)",
      "note": "O arquivo em disco, dividido pelo número de vetores, é o tamanho do índice por vetor: o próprio vetor mais as suas ligações."
    },
    {
      "code": "    index.set_ef(40)\n    index.set_num_threads(1)\n    start = time.perf_counter()\n    I, _ = index.knn_query(Q, k=10)\n    ms = (time.perf_counter() - start) * 1000 / len(Q)\n    print(f\"{M:>2} {ef_construction:>15} {built:>5.1f} s {size:>12,.0f} {recall(I):>9.3f} {ms:>7.3f} ms\")",
      "note": "Todo índice é buscado com o mesmo `ef` de 40 em um núcleo, então as linhas só diferem em como foram construídas."
    }
  ],
  "output": "ana@lab:~/emb$ python params.py\n M ef_construction   build bytes/vector recall@10  per query\n 8             200   8.3 s        1,621     0.887   0.125 ms\n16             200  12.1 s        1,684     0.938   0.138 ms\n32             200  15.1 s        1,812     0.963   0.134 ms\n16              40   2.5 s        1,684     0.842   0.092 ms"
}
```

**Mais ligações compraram recall.** De `M` 8 para 16 para 32, o recall@10 foi de 0,887 para 0,938
para 0,963 com o mesmo `ef`, porque um grafo mais bem conectado tem mais caminhos até cada
vizinhança. A construção demorou mais, de 8,3 s para 15,1 s, e o arquivo cresceu de 1.621 para 1.812
bytes por vetor. O crescimento são as ligações: o hnswlib guarda cada uma como um número de 4 bytes,
e passar de 16 para 32 acrescenta 32 ligações na camada 0, que são os 128 bytes por vetor entre essas
duas linhas. Os tempos de consulta quase não se mexeram nesta execução, e numa máquina dividida com
outros trabalhos a ordem deles não quer dizer nada.

**Uma construção descuidada não se conserta buscando com mais afinco.** A última linha tem o mesmo
`M` de 16 e um `ef_construction` de 40 em vez de 200. Ela ficou pronta em 2,5 s em vez de 12,1 s, e o
arquivo tem os mesmos 1.684 bytes por vetor, porque o número de ligações não mudou; o que mudou é para
quais vetores elas apontam. Com ligações escolhidas de uma lista de candidatos mais curta, o recall com
`ef` 40 caiu de 0,938 para 0,842. O grafo é o que é até ser reconstruído.

## O que você escolhe a cada consulta

`ef_sweep.py` carrega o índice com `M` 16 e `ef_construction` 200 e gira o `ef`:

```schooling-example
{
  "language": "python",
  "file": "ef_sweep.py",
  "parts": [
    {
      "code": "import time\nimport hnswlib\nfrom bench import X, Q, recall\n\nindex = hnswlib.Index(space=\"ip\", dim=384)\nindex.load_index(\"m16-200.bin\")\nindex.set_num_threads(1)\nprint(f\"{'ef':>4} {'recall@10':>9} {'per query':>10}\")\nfor ef in (10, 20, 40, 80, 160, 320):\n    index.set_ef(ef)\n    start = time.perf_counter()\n    I, _ = index.knn_query(Q, k=10)\n    ms = (time.perf_counter() - start) * 1000 / len(Q)\n    print(f\"{ef:>4} {recall(I):>9.3f} {ms:>7.3f} ms\")",
      "note": "O índice que `params.py` salvou com `M` 16 e `ef_construction` 200, carregado em vez de construído de novo, e buscado em um núcleo com seis valores de `ef`."
    }
  ],
  "output": "ana@lab:~/emb$ python ef_sweep.py\n  ef recall@10  per query\n  10     0.772   0.076 ms\n  20     0.880   0.093 ms\n  40     0.938   0.141 ms\n  80     0.968   0.167 ms\n 160     0.993   0.289 ms\n 320     1.000   0.560 ms"
}
```

**O botão vai de 0,772 com `ef` 10 a 1,000 com 320**, e o tempo por consulta de 0,076 ms a 0,560 ms.
Com 320 o índice devolveu exatamente o que a busca exata devolveu para as 1.000 consultas, em menos de
um quarto dos 2,492 ms da busca exata. O padrão do próprio hnswlib é 10, a linha mais barata desta
tabela. Um `ef` abaixo de `k` é um caso à parte, e a aula 16 mostra como duas bibliotecas o tratam
de jeitos diferentes.

A figura põe esta curva ao lado da do IVF, da seção anterior, com o recall subindo e o tempo por
consulta numa escala em que cada passo dobra.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 420\" role=\"img\" aria-label=\"Um gráfico de recall@10 contra milissegundos por consulta numa escala que dobra a cada passo, para as mesmas 1.000 consultas sobre 100.000 vetores. O IVF com 1.024 células sobe de 0,749 com nprobe 1 (0,054 ms) para 0,990 com nprobe 4 (0,100 ms) e 1,000 a partir de nprobe 32. O HNSW com M 16 sobe de 0,772 com ef 10 (0,076 ms) para 0,993 com ef 160 (0,289 ms) e 1,000 com ef 320 (0,560 ms). A busca exata fica em recall 1 e 2,492 ms. As duas curvas sobem rápido e depois achatam.\"><path d=\"M80 330 L690 330\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"70\" y=\"330\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0,7</text><path d=\"M80 233.3 L690 233.3\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"70\" y=\"233.3\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0,8</text><path d=\"M80 136.7 L690 136.7\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"70\" y=\"136.7\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0,9</text><path d=\"M80 40 L690 40\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"70\" y=\"40\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1,0</text><path d=\"M80 330 L690 330\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M80 330 L80 30\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M139.1 330 L139.1 335\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"139.1\" y=\"347\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0,0625</text><path d=\"M230.9 330 L230.9 335\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"230.9\" y=\"347\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0,125</text><path d=\"M322.7 330 L322.7 335\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"322.7\" y=\"347\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0,25</text><path d=\"M414.6 330 L414.6 335\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"414.6\" y=\"347\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0,5</text><path d=\"M506.4 330 L506.4 335\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"506.4\" y=\"347\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1</text><path d=\"M598.2 330 L598.2 335\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"598.2\" y=\"347\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2</text><path d=\"M690 330 L690 335\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"690\" y=\"347\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">4</text><text x=\"385\" y=\"368\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">milissegundos por consulta, um núcleo (cada passo dobra)</text><text x=\"20\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">recall@10</text><path d=\"M119.8 282.6 L146.3 106.7 L201.4 49.7 L238.1 41.9 L305.2 41.0 L385.7 40.0 L470.2 40.0\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><rect x=\"115.3\" y=\"278.1\" width=\"9\" height=\"9\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"113.8\" y=\"270.6\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">1</text><rect x=\"141.8\" y=\"102.2\" width=\"9\" height=\"9\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"140.3\" y=\"94.7\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">2</text><rect x=\"196.9\" y=\"45.2\" width=\"9\" height=\"9\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"195.4\" y=\"37.7\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">4</text><rect x=\"233.6\" y=\"37.4\" width=\"9\" height=\"9\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"232.1\" y=\"29.9\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">8</text><rect x=\"300.7\" y=\"36.5\" width=\"9\" height=\"9\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"299.2\" y=\"29\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">16</text><rect x=\"381.2\" y=\"35.5\" width=\"9\" height=\"9\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"379.7\" y=\"28\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">32</text><rect x=\"465.7\" y=\"35.5\" width=\"9\" height=\"9\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"464.2\" y=\"28\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">64</text><path d=\"M165.0 260.4 L191.8 156.0 L246.9 99.9 L269.3 70.9 L341.9 46.8 L429.6 40.0\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\" stroke-dasharray=\"6 4\"></path><circle cx=\"165\" cy=\"260.4\" r=\"4.5\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.8\"></circle><text x=\"172\" y=\"274.4\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">10</text><circle cx=\"191.8\" cy=\"156\" r=\"4.5\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.8\"></circle><text x=\"198.8\" y=\"170\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">20</text><circle cx=\"246.9\" cy=\"99.9\" r=\"4.5\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.8\"></circle><text x=\"253.9\" y=\"113.9\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">40</text><circle cx=\"269.3\" cy=\"70.9\" r=\"4.5\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.8\"></circle><text x=\"276.3\" y=\"84.9\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">80</text><circle cx=\"341.9\" cy=\"46.8\" r=\"4.5\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.8\"></circle><text x=\"348.9\" y=\"60.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">160</text><circle cx=\"429.6\" cy=\"40\" r=\"4.5\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.8\"></circle><text x=\"436.6\" y=\"54\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">320</text><circle cx=\"627.3\" cy=\"40\" r=\"5.5\" fill=\"var(--paper)\" stroke=\"none\" stroke-width=\"1.2\"></circle><text x=\"627.3\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">exata 2,492</text><path d=\"M430 250 L439 250\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M451 250 L460 250\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><rect x=\"440.5\" y=\"245.5\" width=\"9\" height=\"9\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"468\" y=\"250\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">IVF, 1.024 células: nprobe</text><path d=\"M430 276 L460 276\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\" stroke-dasharray=\"6 4\"></path><circle cx=\"445\" cy=\"276\" r=\"4.5\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.8\"></circle><text x=\"468\" y=\"276\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">HNSW, M 16: ef</text></svg>", "caption": "Recall contra tempo para as mesmas 1.000 consultas, como ivf.py e ef_sweep.py mediram; os números pequenos são nprobe e ef. Os dois índices sobem rápido e depois achatam, e nestes vetores o IVF chegou a 0,99 antes.", "same": ["recall@10", "HNSW, M 16: ef"]}
```

**Neste conjunto, o IVF ganhou.** Quatro células deram 0,990 em 0,100 ms; o HNSW precisou de `ef`
160 para 0,993 em 0,289 ms. Não leve isso para casa como regra. Estes vetores são misturas de 334
vetores reais, uma estrutura que as células do k-means capturam excepcionalmente bem, e em outros
dados a ordem pode se inverter. O que as curvas mostram em geral é a forma: o recall sobe rápido e
depois achata, então os últimos milésimos custam tanto tempo quanto tudo o que veio antes. O HNSW
continua sendo o padrão que a maioria dos sistemas escolhe, por motivos que este gráfico não mostra:
ele não precisa de treino, recebe vetores um de cada vez enquanto a coleção existir e não tem células
que envelhecem quando os dados mudam de perfil.

## Os mesmos três em outros lugares

Cada biblioteca escreve os nomes do seu jeito:

| | FAISS | hnswlib | pgvector |
|---|---|---|---|
| ligações por vetor | `M`, em `IndexHNSWFlat(d, M)` | `M` | `m` |
| lista durante a construção | `efConstruction` | `ef_construction` | `ef_construction` |
| lista durante a busca | `efSearch` | `ef`, via `set_ef` | `hnsw.ef_search` |
| células | `nlist` | — | `lists` |
| células buscadas | `nprobe` | — | `ivfflat.probes` |

O pgvector lê os dois parâmetros de busca da sessão, e um banco vazio mostra os padrões deles:

```
ana@lab:~/emb$ psql -c "CREATE EXTENSION vector" -c "SHOW hnsw.ef_search" -c "SHOW ivfflat.probes"
CREATE EXTENSION
 hnsw.ef_search 
----------------
 40
(1 row)

 ivfflat.probes 
----------------
 1
(1 row)
```

A documentação do pgvector dá 16 para `m` e 64 para `ef_construction` quando o `CREATE INDEX` não
cita nenhum dos dois. Os dois vão na cláusula `WITH (...)`, e os dois ficam decididos enquanto o
índice existir.
