---
title: Reordenação
version: 1
---

Todos os métodos até aqui pontuam um pedaço sem olhar a pergunta e o pedaço juntos. A busca vetorial
compara dois vetores calculados separadamente, um por texto; a BM25 conta palavras. É isso que os torna
rápidos o bastante para rodar sobre milhões de pedaços, e é também o limite deles: o vetor do pedaço foi
fixado antes de alguém perguntar qualquer coisa.

Um **reordenador** (reranker) é um segundo modelo, mais lento, que lê a pergunta e cada candidato juntos
e os pontua de novo. Por ser lento, ele nunca vê o índice inteiro: a busca rápida devolve vinte ou
cinquenta candidatos, e o reordenador os reordena. **Ele não consegue achar o que a primeira busca
perdeu.** O trabalho dele é pôr o melhor dos candidatos em primeiro.

## O reordenador que este laboratório consegue rodar

O reordenador padrão é um **cross-encoder**: um transformer que recebe a pergunta e o pedaço como uma
entrada só e devolve uma única nota de relevância, treinado em milhões de pares de perguntas e trechos
marcados como relevantes ou não. Os pequenos mais comuns estão no Hugging Face, que este laboratório não
conseguiu alcançar, então nenhum foi rodado.

O que o laboratório consegue rodar é um reordenador construído a partir do modelo de embeddings que já
tem, por **interação tardia** (late interaction), a ideia por trás do ColBERT. O MiniLM produz um vetor
para cada pedaço de palavra antes de tirar a média deles. A interação tardia guarda os pedaços e compara
cada pedaço da pergunta com todos os pedaços do texto:

```schooling-example
{
  "language": "python",
  "file": "search.py",
  "parts": [
    {
      "code": "def token_vectors(texts):\n    \"\"\"One unit vector per word piece, from the same MiniLM, before it averages them.\"\"\"\n    enc = minilm._tok.encode_batch(list(texts))\n    ids = np.array([e.ids for e in enc], dtype=np.int64)\n    mask = np.array([e.attention_mask for e in enc], dtype=np.int64)\n    hidden = minilm._model.run(None, {\"input_ids\": ids, \"attention_mask\": mask,\n                                      \"token_type_ids\": np.zeros_like(ids)})[0]\n    out = []\n    for h, m in zip(hidden, mask):\n        h = h[m.astype(bool)][1:-1]\n        out.append(h / np.linalg.norm(h, axis=1, keepdims=True))\n    return out",
      "note": "O MiniLM produz um vetor por pedaço de palavra antes de tirar a média; o `embed` devolve a média, e isto guarda os pedaços. Os marcadores das pontas são descartados, e o vetor de cada pedaço fica com comprimento 1."
    },
    {
      "code": "def rerank(question, candidates, k=3):\n    \"\"\"Late interaction: each question piece takes its best match in the chunk, and the matches add up.\"\"\"\n    q = token_vectors([question])[0]\n    chunks = token_vectors([path + \"\\n\" + text for _, path, text, _ in candidates])\n    scores = [float((q @ c.T).max(axis=1).sum()) for c in chunks]\n    order = np.argsort(-np.array(scores), kind=\"stable\")[:k]\n    return [(*candidates[i][:3], scores[i]) for i in order]",
      "note": "Para cada pedaço da pergunta, o melhor par em qualquer lugar do pedaço de texto; a nota é a soma desses melhores pares. Um pedaço que tem um bom par para cada parte da pergunta vence um que combina muito bem com poucas partes."
    }
  ]
}
```

É uma reordenação de verdade num modelo de verdade, com uma ressalva dita com todas as letras: **o
all-MiniLM-L6-v2 não foi treinado para ser usado assim.** Os modelos ColBERT são treinados para que os
vetores por pedaço sejam bons nessa comparação; os do MiniLM são um subproduto do treinamento da média.
Trate o que vem a seguir como o comportamento de um reordenador, não como a qualidade de um bom.

## O que ele reordena

O `reorder.py` pega os vinte primeiros da busca híbrida para uma pergunta, reordena os mesmos vinte e
marca o pedaço que tem a resposta:

```
ana@lab:~/rag$ python reorder.py "How much is express delivery?" "9.90"
hybrid
  1  Shipping and delivery > Delivery options and costs
  2  Shipping and delivery > Addresses
  3  Shipping and delivery > Delivery options and costs
  4  Shipping and delivery > Parcels that are late or lost
  5  Shipping and delivery > Delivery options and costs  <- the answer
reranked
  1  Shipping and delivery > Delivery options and costs
  2  Shipping and delivery > Delivery options and costs  <- the answer
  3  Shipping and delivery > Delivery options and costs
  4  Shipping and delivery > Parcels that are late or lost
  5  Shipping and delivery > Addresses
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 760 300\" role=\"img\" aria-label=\"Duas colunas com cinco pedaços em ordem para a pergunta How much is express delivery. Na busca híbrida, o pedaço com o preço, um pedaço de Delivery options and costs, está em quinto. Depois de reordenar os mesmos vinte candidatos ele fica em segundo, e o pedaço de Addresses cai de segundo para quinto.\"><defs><marker id=\"rg-017094\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 5 L0 10 z\" fill=\"var(--wire)\"></path></marker></defs><text x=\"30\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">busca híbrida, os cinco primeiros de vinte</text><text x=\"450\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">os mesmos vinte, reordenados</text><rect x=\"30\" y=\"40\" width=\"280\" height=\"36\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"42\" y=\"58\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">1</text><text x=\"62\" y=\"58\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Delivery options and costs</text><rect x=\"450\" y=\"40\" width=\"280\" height=\"36\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"462\" y=\"58\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">1</text><text x=\"482\" y=\"58\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Delivery options and costs</text><rect x=\"30\" y=\"90\" width=\"280\" height=\"36\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"42\" y=\"108\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">2</text><text x=\"62\" y=\"108\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Addresses</text><rect x=\"450\" y=\"90\" width=\"280\" height=\"36\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"462\" y=\"108\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">2</text><text x=\"482\" y=\"108\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Delivery options and costs  (a resposta)</text><rect x=\"30\" y=\"140\" width=\"280\" height=\"36\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"42\" y=\"158\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">3</text><text x=\"62\" y=\"158\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Delivery options and costs</text><rect x=\"450\" y=\"140\" width=\"280\" height=\"36\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"462\" y=\"158\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">3</text><text x=\"482\" y=\"158\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Delivery options and costs</text><rect x=\"30\" y=\"190\" width=\"280\" height=\"36\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"42\" y=\"208\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">4</text><text x=\"62\" y=\"208\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Parcels that are late or lost</text><rect x=\"450\" y=\"190\" width=\"280\" height=\"36\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"462\" y=\"208\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">4</text><text x=\"482\" y=\"208\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Parcels that are late or lost</text><rect x=\"30\" y=\"240\" width=\"280\" height=\"36\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"42\" y=\"258\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">5</text><text x=\"62\" y=\"258\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Delivery options and costs  (a resposta)</text><rect x=\"450\" y=\"240\" width=\"280\" height=\"36\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"462\" y=\"258\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">5</text><text x=\"482\" y=\"258\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Addresses</text><path d=\"M314 58 C382 58 378 58 444 58\" stroke=\"var(--wire)\" stroke-width=\"1.1\" fill=\"none\" marker-end=\"url(#rg-017094)\"></path><path d=\"M314 108 C382 108 378 258 444 258\" stroke=\"var(--wire)\" stroke-width=\"1.1\" fill=\"none\" marker-end=\"url(#rg-017094)\"></path><path d=\"M314 158 C382 158 378 158 444 158\" stroke=\"var(--wire)\" stroke-width=\"1.1\" fill=\"none\" marker-end=\"url(#rg-017094)\"></path><path d=\"M314 208 C382 208 378 208 444 208\" stroke=\"var(--wire)\" stroke-width=\"1.1\" fill=\"none\" marker-end=\"url(#rg-017094)\"></path><path d=\"M314 258 C382 258 378 108 444 108\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#rg-017094)\"></path></svg>", "caption": "Reordenar reordena, não busca. Os vinte candidatos são os da busca híbrida; o reordenador pontua cada um contra a pergunta de novo, e o pedaço com o preço da entrega expressa vai de quinto para segundo. Os títulos em fonte mono são os caminhos dos pedaços, como o reorder.py os imprimiu."}
```

**A tabela de preços foi de quinto para segundo**, e o pedaço *Addresses*, que só compartilha a palavra
*express*, caiu de segundo para quinto. É o tipo de correção para que um reordenador existe: lendo a
pergunta inteira contra o pedaço inteiro, ele vê que um deles trata de custo e o outro não.

```
ana@lab:~/rag$ python reorder.py "How many days do I have to return a printed book?" "30 days from delivery"
hybrid
  1  Returns and refunds policy > The return window  <- the answer
  2  Returns policy > Returning a book
  3  Returns and refunds policy > Damaged, faulty and wrong items
  4  Returns and refunds policy > Damaged, faulty and wrong items
  5  Returns and refunds policy > The return window
reranked
  1  Returns policy > Returning a book
  2  Returns and refunds policy > The return window  <- the answer
  3  Returns and refunds policy > Damaged, faulty and wrong items
  4  Terms of sale > 6. The right of withdrawal
  5  Returns and refunds policy > Damaged, faulty and wrong items
```

O mesmo reordenador piorou esta. A *return window* do regulamento atual estava em primeiro e a
*Returning a book* do regulamento de 2025 em segundo; reordenadas, trocaram de lugar. Os dois pedaços
tratam exatamente do que a pergunta pede, o antigo em palavras um pouco mais parecidas, e **nenhum
reordenador consegue saber que um documento foi substituído** — ele pontua relevância, e o regulamento
antigo é relevante. Isso é trabalho para um filtro, duas seções adiante.

## Medido

De volta à última linha da tabela da seção anterior:

| | perguntas de cliente, primeiro | três primeiros | identificadores, primeiro | três primeiros |
| --- | --- | --- | --- | --- |
| híbrida | 20 de 26 | 24 de 26 | 4 de 6 | 5 de 6 |
| híbrida, reordenada | 19 de 26 | 26 de 26 | 4 de 6 | 4 de 6 |

Reordenar os vinte primeiros da híbrida recuperou as duas perguntas de cliente que a híbrida tinha
empurrado para fora dos três primeiros, perdeu um primeiro lugar e perdeu uma pergunta de
identificador. **Neste corpus, com um reordenador não treinado para o trabalho, dá mais ou menos
empate.** Espera-se que um cross-encoder treinado se saia melhor, e comparações publicadas mostram que
ele se sai na maioria dos corpora, e por isso pipelines em produção usam um; mas o hábito que esta aula
ensina é o que o pegaria se não se saísse no seu: medir a lista reordenada contra a anterior, nas suas
próprias perguntas, antes de pagar por ela.
