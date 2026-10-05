---
title: Construindo o índice
version: 1
---

Uma busca por significado tem duas metades que rodam em momentos diferentes, e mantê-las separadas
é a maior parte do projeto:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"Duas linhas. Antes, uma vez por artigo: os 40 artigos de ajuda viram vetores com o all-MiniLM-L6-v2 e são guardados em index.npy, uma matriz com uma linha por artigo, ao lado de ids.json, que diz de qual artigo é cada linha. Para cada pergunta: a pergunta vira vetor com o mesmo modelo, é multiplicada pela matriz guardada para dar uma nota por artigo, as notas são ordenadas e os números das k primeiras linhas voltam a ser artigos por meio de ids.json.\"><defs><marker id=\"pipept-ah0\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"pipept-ah1\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"20\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\" font-weight=\"600\">antes, uma vez por artigo</text><text x=\"20\" y=\"192\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\" font-weight=\"600\">a cada pergunta</text><rect x=\"20\" y=\"42\" width=\"130\" height=\"50\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"85\" y=\"59\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">help.jsonl</text><text x=\"85\" y=\"77\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">40 artigos</text><path d=\"M150 67 L196 67\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pipept-ah0)\"></path><rect x=\"198\" y=\"42\" width=\"150\" height=\"50\" rx=\"6\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"273\" y=\"59\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">embed()</text><text x=\"273\" y=\"77\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">all-MiniLM-L6-v2</text><path d=\"M348 67 L394 67\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pipept-ah0)\"></path><rect x=\"396\" y=\"34\" width=\"150\" height=\"40\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"471\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">index.npy</text><text x=\"471\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">uma linha por artigo</text><rect x=\"396\" y=\"80\" width=\"150\" height=\"40\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"471\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">ids.json</text><text x=\"471\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">qual linha é qual</text><rect x=\"20\" y=\"220\" width=\"110\" height=\"44\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"75\" y=\"242\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">uma pergunta</text><path d=\"M130 242 L156 242\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pipept-ah0)\"></path><rect x=\"158\" y=\"220\" width=\"110\" height=\"44\" rx=\"6\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"213\" y=\"234\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">embed()</text><text x=\"213\" y=\"251\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">mesmo modelo</text><path d=\"M268 242 L294 242\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pipept-ah0)\"></path><rect x=\"296\" y=\"220\" width=\"110\" height=\"44\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"351\" y=\"234\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">D @ q</text><text x=\"351\" y=\"251\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">40 notas</text><path d=\"M406 242 L432 242\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pipept-ah0)\"></path><rect x=\"434\" y=\"220\" width=\"120\" height=\"44\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"494\" y=\"234\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">argsort</text><text x=\"494\" y=\"251\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">ordena, fica com k</text><path d=\"M554 242 L580 242\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pipept-ah0)\"></path><rect x=\"582\" y=\"220\" width=\"120\" height=\"44\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"642\" y=\"234\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">ids[i]</text><text x=\"642\" y=\"251\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">linha → artigo</text><path d=\"M396 42 C351 42 351 140 351 218\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pipept-ah1)\" stroke-dasharray=\"5 4\"></path><path d=\"M546 100 C640 100 642 150 642 218\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pipept-ah1)\" stroke-dasharray=\"5 4\"></path></svg>", "caption": "A metade lenta roda uma vez por artigo e fica guardada; a metade rápida roda a cada pergunta e lê o que foi guardado. A matriz e os ids são dois arquivos que só funcionam juntos.", "same": ["all-MiniLM-L6-v2"]}
```

**Os documentos viram vetores uma vez, antes.** Calcular o embedding é o passo lento e caro, e um
artigo que não mudou tem o mesmo vetor amanhã (aula 1). Então os vetores são calculados quando um
artigo é escrito ou editado, e guardados. Só a pergunta vira vetor na hora da busca.

```schooling-example
{
  "language": "python",
  "file": "index.py",
  "parts": [
    {
      "code": "import json\nimport time\nimport numpy as np\nfrom minilm import embed\n\nhelp = [json.loads(line) for line in open(\"data/help.jsonl\")]\ntexts = [h[\"title\"] + \". \" + h[\"body\"] for h in help]",
      "note": "Cada artigo vira vetor como título e corpo juntos, como na aula 1."
    },
    {
      "code": "start = time.perf_counter()\nD = embed(texts)\nprint(f\"embedded {len(texts)} articles in {time.perf_counter() - start:.2f} s\")",
      "note": "Transforme os 40 em vetores numa chamada só, e meça o tempo."
    },
    {
      "code": "np.save(\"index.npy\", D)\njson.dump([h[\"id\"] for h in help], open(\"ids.json\", \"w\"))\nprint(D.shape, D.dtype)",
      "note": "Guarde a matriz num arquivo do NumPy e, ao lado, os ids na mesma ordem."
    }
  ]
}
```

```
ana@lab:~/emb$ python index.py
embedded 40 articles in 0.77 s
(40, 384) float32
ana@lab:~/emb$ ls -l index.npy ids.json
-rw-r--r-- 1 ana ana   280 Oct  5 14:20 ids.json
-rw-r--r-- 1 ana ana 61568 Oct  5 14:20 index.npy
```

A central de ajuda inteira levou 0,77 segundo nesta máquina. Isso não é nada para 40 artigos e é um custo de verdade para quatro milhões. Então a metade cara
fica fora da hora da busca, onde pode ser feita em lotes e repetida sem um cliente esperando; a
aula 7 a manda para um provedor em lotes.

## Dois arquivos que precisam andar juntos

`index.npy` é a matriz de 40 × 384 números float32: 40 × 384 × 4 = 61.440 bytes, mais os 128 bytes
do cabeçalho do NumPy, o que dá os 61.568 que o `ls` imprimiu. A linha 0 é o vetor do primeiro
artigo, a linha 1 o do segundo, e assim por diante, mas **a matriz não sabe de qual artigo é cada
linha**. É para isso que existe `ids.json`. Uma busca devolve números de linha, e os ids os
transformam de volta em artigos.

Então os dois arquivos são escritos juntos, na mesma ordem, e trocados juntos. Uma reconstrução que
grava uma matriz nova e esquece os ids deixa toda busca devolvendo o artigo errado com uma nota
perfeitamente boa. Mais dois fatos pertencem ao lado deles, mesmo num projeto deste tamanho:

- **qual modelo fez os vetores**, porque uma pergunta transformada em vetor por qualquer outro
  modelo não pode ser comparada com eles (aula 1, *O que um embedding não é*);
- **se eles estão normalizados**. Os do all-MiniLM-L6-v2 já estão, então o produto escalar simples
  é o cosseno. Com um modelo cujos vetores não estão, é aqui que você divide pelo comprimento, uma
  vez (aula 2).

Um banco de vetores guarda o vetor, o id e o que mais houver sobre o documento num registro só, de
modo que eles não se desencontram. A aula 11 mostra o que mais ele acrescenta; dois arquivos bastam
para ver a ideia.
