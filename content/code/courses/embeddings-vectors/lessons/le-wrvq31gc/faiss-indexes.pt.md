---
title: Nomes de índice que você vai encontrar
version: 1
---

O FAISS dá nome aos seus índices com strings curtas que a documentação de outros bancos pega
emprestadas, então vale reconhecê-las antes que a aula 15 explique como cada um funciona.
`faiss.index_factory` constrói um índice a partir de uma dessas strings, e este programa constrói
quatro e os compara com a resposta exata.

Os vetores precisam de explicação antes. **Não são 20.000 textos transformados em vetor.** Os textos
do próprio curso dão 310 vetores reais do all-MiniLM-L6-v2, e cada um dos 20.000 é um deles com um
pouco de ruído aleatório somado, normalizado de novo. Isso preserva os agrupamentos que vetores reais
têm, que vetores aleatórios uniformes não teriam, e sai barato. As 100 perguntas são mais cópias
ruidosas.

```schooling-example
{
  "language": "python",
  "file": "factory.py",
  "parts": [
    {
      "code": "import json\nimport faiss\nimport numpy as np\nfrom minilm import embed\n\ntexts = [json.loads(line)[k] for f, k in [(\"help\", \"body\"), (\"tickets\", \"text\"),\n         (\"books\", \"blurb\"), (\"inbox\", \"text\"), (\"week2\", \"text\")]\n         for line in open(f\"data/{f}.jsonl\")]\nbase = embed(texts)\nrng = np.random.default_rng(15)\ndef copies(n):\n    v = base[rng.integers(len(base), size=n)] + rng.normal(scale=0.04, size=(n, 384))\n    return (v / np.linalg.norm(v, axis=1, keepdims=True)).astype(\"float32\")\nX, Q = copies(20000), copies(100)\nprint(len(base), \"real vectors,\", len(X), \"noisy copies,\", len(Q), \"queries\")",
      "note": "310 vetores reais dos textos do curso, cada um copiado muitas vezes com um pouco de ruído aleatório e normalizado de novo: 20.000 vetores que se agrupam como os reais, e mais 100 como perguntas."
    },
    {
      "code": "exact = faiss.IndexFlatIP(384)\nexact.add(X)\n_, truth = exact.search(Q, 10)\nfaiss.write_index(exact, \"random.faiss\")",
      "note": "A resposta exata: um índice plano buscando os 10 mais próximos de cada pergunta. Ele também é gravado em `random.faiss`, que a última seção desta aula lê de volta."
    },
    {
      "code": "for spec in (\"Flat\", \"HNSW32\", \"IVF64,Flat\", \"IVF64,PQ16\"):\n    index = faiss.index_factory(384, spec, faiss.METRIC_INNER_PRODUCT)\n    needs = not index.is_trained\n    index.train(X)\n    index.add(X)\n    _, I = index.search(Q, 10)\n    recall = np.mean([len(set(a) & set(b)) / 10 for a, b in zip(I, truth)])\n    size = faiss.serialize_index(index).nbytes\n    print(f\"{spec:11} needs training: {str(needs):5}  {size:>11,} bytes  recall@10 {recall:.3f}\")",
      "note": "Quatro índices a partir das suas strings de fábrica, todos comparando por produto interno. Cada um é treinado se precisar, preenchido, consultado e medido: o tamanho depois de serializado e quantos dos 10 exatos ele achou."
    }
  ],
  "output": "ana@lab:~/emb$ python factory.py\n310 real vectors, 20000 noisy copies, 100 queries\nFlat        needs training: False   30,720,045 bytes  recall@10 1.000\nHNSW32      needs training: False   36,162,530 bytes  recall@10 1.000\nIVF64,Flat  needs training: True    30,978,955 bytes  recall@10 0.993\nIVF64,PQ16  needs training: True       972,212 bytes  recall@10 0.210"
}
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Dois gráficos de barras lado a lado para quatro índices do FAISS construídos sobre os mesmos 20.000 vetores. Tamanho em megabytes: Flat 30,72, HNSW32 36,16, IVF64,Flat 30,98, IVF64,PQ16 0,97. Recall em 10 contra a resposta exata: Flat 1,000, HNSW32 1,000, IVF64,Flat 0,993, IVF64,PQ16 0,210.\"><text x=\"250\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">tamanho gravado (MB)</text><text x=\"570\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">recall@10 contra a resposta exata</text><text x=\"110\" y=\"72\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">Flat</text><rect x=\"125\" y=\"60\" width=\"192\" height=\"24\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"323\" y=\"72\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">30,72</text><rect x=\"450\" y=\"60\" width=\"220\" height=\"24\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"450\" y=\"60\" width=\"220\" height=\"24\" rx=\"2\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"676\" y=\"72\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">1,000</text><text x=\"110\" y=\"114\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">HNSW32</text><rect x=\"125\" y=\"102\" width=\"226\" height=\"24\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"357\" y=\"114\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">36,16</text><rect x=\"450\" y=\"102\" width=\"220\" height=\"24\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"450\" y=\"102\" width=\"220\" height=\"24\" rx=\"2\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"676\" y=\"114\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">1,000</text><text x=\"110\" y=\"156\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">IVF64,Flat</text><text x=\"110\" y=\"171\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">precisa de treino</text><rect x=\"125\" y=\"144\" width=\"193.6\" height=\"24\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"324.6\" y=\"156\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">30,98</text><rect x=\"450\" y=\"144\" width=\"220\" height=\"24\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"450\" y=\"144\" width=\"218.5\" height=\"24\" rx=\"2\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"676\" y=\"156\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">0,993</text><text x=\"110\" y=\"198\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">IVF64,PQ16</text><text x=\"110\" y=\"213\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">precisa de treino</text><rect x=\"125\" y=\"186\" width=\"6.1\" height=\"24\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"137.1\" y=\"198\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">0,97</text><rect x=\"450\" y=\"186\" width=\"220\" height=\"24\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"450\" y=\"186\" width=\"46.2\" height=\"24\" rx=\"2\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"676\" y=\"198\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">0,210</text></svg>", "caption": "Quatro índices do FAISS sobre as mesmas 20.000 cópias ruidosas de vetores reais, medidos pelo factory.py. A compressão comprou um trigésimo do tamanho e custou a maior parte do recall nesses dados muito agrupados."}
```

## Lendo os nomes

**`Flat`** guarda cada vetor como ele é e compara a pergunta com todos. É a resposta exata, recall
1,000 por definição, e não precisa de treino. Os seus 30.720.045 bytes são 20.000 vetores de 1.536
bytes e um cabeçalho de 45 bytes: só os vetores.

**`HNSW32`** constrói um grafo em que cada vetor fica ligado a alguns dos seus vizinhos, e uma busca
percorre o grafo em vez de ler tudo; o 32 define quantas ligações cada vetor recebe. Ele achou os dez
vizinhos exatos de todas as perguntas nestes dados, e é o maior dos quatro, com 36.162.530 bytes: os
vetores mais as ligações. A aula 15 constrói o grafo.

**`IVF64,Flat`** divide o espaço em 64 células e busca só na célula mais próxima da pergunta. Achar
as células exige antes um agrupamento de vetores de exemplo, que é o **treino** da segunda coluna: um
índice que precisa de treino não aceita um vetor antes de ver dados parecidos com os que vai guardar.
Recall de 0,993, porque alguns vizinhos de verdade estavam numa célula ao lado.

**`IVF64,PQ16`** usa as mesmas células e comprime cada vetor em 16 bytes em vez de 1.536, por
quantização de produto. O índice inteiro tem 972.212 bytes, cerca de um trigésimo do `Flat`. O recall dele
aqui, 0,210, é o preço: as cópias ruidosas de um texto ficam tão juntas que 16 bytes não conseguem
mantê-las na ordem certa. A aula 15 mede a quantização de produto em vários tamanhos, com outro
conjunto, e ali 16 bytes também perdem a maior parte da ordem.

**Esses recalls pertencem a estes dados e às configurações de busca padrão do FAISS**, que visitam
uma célula de um índice IVF e mantêm 16 candidatos numa busca HNSW. Cada um dos índices aproximados
tem um botão que troca tempo por recall, que é o assunto da aula 15, e os bytes são da aula 18. Por
ora, quando a documentação de um banco disser que ele usa HNSW, IVF ou PQ, você já sabe qual destas
quatro ideias ela quer dizer.
