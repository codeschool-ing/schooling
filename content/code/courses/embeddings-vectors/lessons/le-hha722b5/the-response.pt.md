---
title: A resposta
version: 1
---

Uma resposta é um envelope pequeno em volta de uma lista. A lista, `data`, tem um objeto de
embedding por texto de entrada; em volta dela ficam o nome do modelo e uma contagem em `usage`.
Mandar três textos mostra tudo:

```schooling-example
{
  "language": "python",
  "file": "response.py",
  "parts": [
    {
      "code": "import base64\nimport numpy as np\nfrom openai import OpenAI\n\nclient = OpenAI()\ntexts = [\"When your refund arrives\", \"Tracking a parcel\", \"Two-step sign-in\"]",
      "note": "Três textos numa requisição."
    },
    {
      "code": "r = client.embeddings.create(model=\"lab-minilm\", input=texts)\nprint(r.object, r.model, r.usage)\nfor d in r.data:\n    print(\" \", d.object, d.index, len(d.embedding), texts[d.index])",
      "note": "A resposta é uma lista de objetos de embedding, cada um com seu `index`: a posição do texto dele em `input`. Imprima cada um ao lado do texto a que pertence."
    },
    {
      "code": "raw = client.embeddings.with_raw_response.create(model=\"lab-minilm\", input=texts[0])\nprint(raw.http_request.content.decode())\nwire = raw.http_response.json()[\"data\"][0][\"embedding\"]\nprint(wire[:40], \"...\", len(wire), \"characters\")",
      "note": "`with_raw_response` guarda a troca HTTP que o SDK normalmente esconde. O corpo da requisição mostra o que o SDK acrescentou por conta própria, e o da resposta mostra o que voltou pela rede."
    },
    {
      "code": "v = np.frombuffer(base64.b64decode(wire), dtype=\"<f4\")\nprint(v.shape, v.dtype, \"largest difference from the SDK's list:\",\n      np.abs(v - raw.parse().data[0].embedding).max())",
      "note": "Decodifique essa string como floats de quatro bytes little-endian e compare com a lista que o SDK entregou."
    }
  ]
}
```

```
ana@lab:~/emb$ python response.py
list lab-minilm Usage(prompt_tokens=14, total_tokens=14)
  embedding 0 384 When your refund arrives
  embedding 1 384 Tracking a parcel
  embedding 2 384 Two-step sign-in
{"model":"lab-minilm","input":"When your refund arrives","encoding_format":"base64"}
/DixvTxsabzYtpK7rhQePU+9Jj3W8qw88OqPPbXB ... 2048 characters
(384,) float32 largest difference from the SDK's list: 0.0
```

## Case pelo índice, não pela posição

Cada objeto de embedding traz um **`index`**, a posição do texto dele na lista `input`. As linhas
acima voltaram em ordem, 0, 1, 2, e é tentador contar com isso e juntar `data` com as entradas pela
posição. Isso é contar com um arranjo; o índice é o campo cujo trabalho é dizer a qual texto um
vetor pertence. Ordenar por ele, ou buscar os textos por ele como faz `response.py`, custa uma linha
e elimina um jeito de arquivar um vetor no artigo errado sem erro nenhum. A função de lotes da
próxima seção faz exatamente isso.

**`usage.prompt_tokens`** é a base da cobrança. Um embedding não tem tokens de saída, então
`total_tokens` é o mesmo número. A seção sobre custo volta ao modo como esses tokens são contados.

## O que de fato passou pela rede

A segunda parte do programa pediu a troca HTTP crua, e a primeira linha dela mostra algo que o
código nunca pediu: o SDK acrescentou **`"encoding_format": "base64"`** ao corpo da requisição. O
registro do labembed disse a mesma coisa na seção anterior.

Então o servidor não mandou 384 números decimais. Mandou os 1.536 bytes de `float32` do vetor,
codificados como texto base64, e o SDK os decodificou de volta numa lista de floats antes de
entregá-la. A última linha confere: os bytes decodificados e a lista do SDK não diferem em nada.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 190\" role=\"img\" aria-label=\"Quatro caixas da esquerda para a direita, o caminho de um vetor. Os 384 números float32 do servidor, 1.536 bytes, são escritos como 2048 caracteres de base64 dentro da resposta JSON. O SDK decodifica o base64 de volta em 1.536 bytes e os lê como float32 little-endian, entregando uma lista de 384 floats.\"><defs><marker id=\"wirept-ah0\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"40\" width=\"140\" height=\"56\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"90\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">no servidor</text><text x=\"90\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">384 float32</text><rect x=\"200\" y=\"40\" width=\"140\" height=\"56\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"270\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">no JSON</text><text x=\"270\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">2048 caracteres</text><rect x=\"380\" y=\"40\" width=\"140\" height=\"56\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"450\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">decodificado</text><text x=\"450\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">1.536 bytes</text><rect x=\"560\" y=\"40\" width=\"140\" height=\"56\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"630\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">o que você recebe</text><text x=\"630\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">lista de 384 floats</text><path d=\"M162 68 L198 68\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#wirept-ah0)\"></path><text x=\"180\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">base64</text><path d=\"M342 68 L378 68\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#wirept-ah0)\"></path><text x=\"360\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">decodifica base64</text><path d=\"M522 68 L558 68\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#wirept-ah0)\"></path><text x=\"540\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">lê como &lt;f4</text><path d=\"M 362 130 L 362 140 L 718 140 L 718 130\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"540\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">o SDK faz estes dois passos</text><path d=\"M 162 130 L 162 140 L 198 140 L 198 130\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"180\" y=\"175\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">o servidor faz este</text></svg>", "caption": "O que a codificação padrão do SDK faz com um vetor do lab-minilm. Os mesmos 1.536 bytes saem do servidor e chegam à sua lista; o base64 é só o jeito de viajarem dentro do JSON.", "same": ["base64", "384 float32"]}
```

O motivo é tamanho. Mandando a mesma requisição com `curl`, uma vez no padrão e outra pedindo
base64:

```
ana@lab:~/emb$ curl -s $OPENAI_BASE_URL/embeddings -H "Authorization: Bearer $OPENAI_API_KEY" -H "Content-Type: application/json" -d @request.json | wc -c
8594
ana@lab:~/emb$ curl -s $OPENAI_BASE_URL/embeddings -H "Authorization: Bearer $OPENAI_API_KEY" -H "Content-Type: application/json" -d @request-b64.json | wc -c
2203
```

A resposta em números decimais tem 8.594 bytes; em base64, 2.203, cerca de um quarto. Escrito
como texto, cada número ocupa mais de vinte caracteres; em base64, menos de seis.
Multiplique isso por cada vetor de um lote de dois mil textos, depois por cada lote, e a economia é
o motivo de o SDK pedir base64 sem que ninguém mande. Se você chamar o endpoint sem o SDK, peça
base64 você mesmo e decodifique como `float32` little-endian, como fez `response.py`.
