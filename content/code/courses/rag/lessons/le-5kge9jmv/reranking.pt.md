---
title: Reordenação
version: 2
---

Todos os métodos até aqui pontuam um pedaço sem olhar a pergunta e o pedaço juntos. A busca vetorial
compara dois vetores calculados separadamente, um por texto; a BM25 conta palavras. É isso que os torna
rápidos o bastante para rodar sobre milhões de pedaços, e é também o limite deles: o vetor do pedaço foi
fixado antes de alguém perguntar qualquer coisa.

Um **reordenador** (reranker) é um segundo modelo, mais lento, que lê a pergunta e cada candidato juntos
e os pontua de novo. Por ser lento, ele nunca vê o índice inteiro: a busca rápida devolve vinte ou
cinquenta candidatos, e o reordenador os reordena. **Ele não consegue achar o que a primeira busca
perdeu.** O trabalho dele é pôr o melhor dos candidatos em primeiro.

## O reordenador que este curso consegue rodar

O reordenador padrão é um **cross-encoder**: um transformer que recebe a pergunta e o pedaço como uma
entrada só e devolve uma única nota de relevância, treinado em milhões de pares de perguntas e trechos
marcados como relevantes ou não. Os pequenos mais comuns estão no Hugging Face, e o Ollama não os
serve, então este curso não usa nenhum.

O que este curso consegue rodar é o modelo que já tem. **Um modelo de linguagem que recebe a pergunta
e um candidato juntos, e a quem se pergunta o quanto um responde o outro, é um reordenador**: ele lê os
dois de uma vez, que é toda a diferença em relação à primeira busca, e custa uma chamada por
candidato. É uma técnica conhecida com um nome simples, reordenação pontual com LLM, e o custo dela é
o motivo de ser usada em vinte candidatos e nunca no índice.

```schooling-example
{
  "language": "python",
  "parts": [
    {
      "code": "JUDGE = \"\"\"Question: {question}\n\nPassage:\n{passage}\n\nHow well does the passage answer the question? Reply with one whole number from 0 (not at all) to 10 (completely), and nothing else.\"\"\"",
      "note": "A instrução, a mesma para todo candidato. A pergunta vem primeiro, para que as vinte requisições de uma pergunta compartilhem o começo do prompt."
    },
    {
      "code": "def rerank(question, candidates, k=3):\n    \"\"\"The generator reads the question with each candidate and gives it a mark; the marks decide the order.\"\"\"\n    scores = []\n    for _, path, text, _ in candidates:\n        reply = client.chat.completions.create(model=\"llama3.2:3b\", temperature=0, max_tokens=4, messages=[\n            {\"role\": \"user\", \"content\": JUDGE.format(question=question, passage=path + \"\\n\" + text)}])\n        found = re.search(r\"\\d+\", reply.choices[0].message.content)\n        scores.append(int(found.group()) if found else 0)\n    order = np.argsort(-np.array(scores), kind=\"stable\")[:k]\n    return [(*candidates[i][:3], scores[i]) for i in order]",
      "note": "Uma chamada por candidato, no máximo quatro tokens de resposta, e uma resposta sem número conta como 0. A ordenação é estável, então candidatos com a mesma nota mantêm a ordem que a primeira busca lhes deu, o que com notas de 0 a 10 acontece com frequência."
    }
  ]
}
```

Duas ressalvas, ditas com todas as letras. **O llama3.2:3b não foi treinado para dar nota a trechos**,
e uma nota de 0 a 10 é um instrumento grosseiro: muitos candidatos recebem a mesma. E **vinte chamadas
por pergunta é lento** numa máquina sem placa de vídeo, vários segundos para cada pergunta; a medição
no fim desta seção faz mais de seiscentas delas. Trate o que vem a seguir como o comportamento de um
reordenador, não como a qualidade de um bom.

## O que ele reordena

O `reorder.py` pega os vinte primeiros da busca híbrida para uma pergunta, reordena os mesmos vinte e
marca o pedaço que tem a resposta:

```schooling-example
{
  "language": "python",
  "file": "reorder.py",
  "parts": [
    {
      "code": "import sys\n\nfrom search import hybrid, rerank\n\nquestion, fact = sys.argv[1], sys.argv[2]\nbefore = hybrid(question, 20)\nafter = rerank(question, before, 20)\nfor label, rows in ((\"hybrid\", before), (\"reranked\", after)):\n    print(label)\n    for rank, (id, path, text, score) in enumerate(rows[:5], 1):\n        mark = \"  <- the answer\" if fact in \" \".join(text.split()) else \"\"\n        print(f\"  {rank}  {path}{mark}\")",
      "note": "Os vinte primeiros do híbrido, os mesmos vinte reordenados, e os cinco primeiros de cada, com o pedaço que tem a resposta marcado."
    }
  ]
}
```

```
ana@vm:~/rag$ python reorder.py "How much is express delivery?" "9.90"
hybrid
  1  Shipping and delivery > Delivery options and costs
  2  Shipping and delivery > Addresses
  3  Shipping and delivery > Delivery options and costs
  4  Shipping and delivery > Parcels that are late or lost
  5  Shipping and delivery > Delivery options and costs  <- the answer
reranked
  1  Shipping and delivery > Delivery options and costs  <- the answer
  2  Returns and refunds policy > How to start a return
  3  Shipping and delivery > Delivery options and costs
  4  Shipping and delivery > Addresses
  5  Shipping and delivery > Delivery options and costs
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 760 300\" role=\"img\" aria-label=\"Duas colunas de cinco pedaços ordenados para a pergunta How much is express delivery. Na busca híbrida, o pedaço com o preço, um pedaço de Delivery options and costs, está em quinto. Depois de o modelo reordenar os mesmos vinte candidatos ele fica em primeiro, um pedaço de How to start a return fica em segundo, e o pedaço de Addresses cai de segundo para quarto.\"><defs><marker id=\"rg-5f1a2c\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 5 L0 10 z\" fill=\"var(--wire)\"></path></marker></defs><text x=\"30\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">busca híbrida, os cinco primeiros de vinte</text><text x=\"450\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">os mesmos vinte, reordenados</text><rect x=\"30\" y=\"40\" width=\"280\" height=\"36\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"42\" y=\"58\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">1</text><text x=\"62\" y=\"58\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Delivery options and costs</text><rect x=\"30\" y=\"90\" width=\"280\" height=\"36\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"42\" y=\"108\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">2</text><text x=\"62\" y=\"108\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Addresses</text><rect x=\"30\" y=\"140\" width=\"280\" height=\"36\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"42\" y=\"158\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">3</text><text x=\"62\" y=\"158\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Delivery options and costs</text><rect x=\"30\" y=\"190\" width=\"280\" height=\"36\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"42\" y=\"208\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">4</text><text x=\"62\" y=\"208\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Parcels that are late or lost</text><rect x=\"30\" y=\"240\" width=\"280\" height=\"36\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"42\" y=\"258\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">5</text><text x=\"62\" y=\"258\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Delivery options and costs  (a resposta)</text><rect x=\"450\" y=\"40\" width=\"280\" height=\"36\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"462\" y=\"58\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">1</text><text x=\"482\" y=\"58\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Delivery options and costs  (a resposta)</text><rect x=\"450\" y=\"90\" width=\"280\" height=\"36\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"462\" y=\"108\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">2</text><text x=\"482\" y=\"108\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">How to start a return</text><rect x=\"450\" y=\"140\" width=\"280\" height=\"36\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"462\" y=\"158\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">3</text><text x=\"482\" y=\"158\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Delivery options and costs</text><rect x=\"450\" y=\"190\" width=\"280\" height=\"36\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"462\" y=\"208\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">4</text><text x=\"482\" y=\"208\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Addresses</text><rect x=\"450\" y=\"240\" width=\"280\" height=\"36\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"462\" y=\"258\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">5</text><text x=\"482\" y=\"258\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Delivery options and costs</text><path d=\"M314 258 C382 258 378 58 444 58\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#rg-5f1a2c)\"></path><path d=\"M314 108 C382 108 378 208 444 208\" stroke=\"var(--wire)\" stroke-width=\"1.1\" fill=\"none\" marker-end=\"url(#rg-5f1a2c)\"></path></svg>", "caption": "Reordenar reordena, não busca. Os vinte candidatos são os da busca híbrida; o modelo dá uma nota a cada um contra a pergunta, e o pedaço com o preço da entrega expressa vai de quinto para primeiro. As setas seguem os dois pedaços que dá para distinguir pelo caminho. Os títulos em fonte mono são os caminhos dos pedaços, como o reorder.py os imprimiu."}
```

**A tabela de preços foi de quinto para primeiro.** O modelo, lendo a pergunta e o trecho juntos, deu
ao pedaço com `9.90` uma nota melhor que a de qualquer outro dos vinte, e *Addresses*, que só
compartilha a palavra *express*, caiu de segundo para quarto. É o tipo de correção para que um
reordenador existe: ele vê que um pedaço trata de custo e o outro não. Também trouxe um pedaço que o
híbrido não tinha posto entre os cinco primeiros, *How to start a return*, em segundo, que não tem
nada a ver com entrega expressa; com notas de 0 a 10 e muitos empates, a ordem abaixo do primeiro é
grosseira.

```
ana@vm:~/rag$ python reorder.py "How many days do I have to return a printed book?" "30 days from delivery"
hybrid
  1  Returns and refunds policy > The return window  <- the answer
  2  Returns policy > Returning a book
  3  Returns and refunds policy > Damaged, faulty and wrong items
  4  Returns and refunds policy > Damaged, faulty and wrong items
  5  Returns and refunds policy > The return window
reranked
  1  Returns and refunds policy > The return window  <- the answer
  2  Returns policy > Returning a book
  3  Returns and refunds policy > Damaged, faulty and wrong items
  4  Returns and refunds policy > Damaged, faulty and wrong items
  5  Terms of sale > 6. The right of withdrawal
```

Para o prazo de devolução, o reordenador não mudou nada nos quatro primeiros: a *return window* do
regulamento atual em primeiro, a *Returning a book* do regulamento de 2025 em segundo. Os dois pedaços
tratam exatamente do que a pergunta pede, e **nenhum reordenador consegue saber que um documento foi
substituído**: ele pontua relevância, e o regulamento antigo é relevante. Isso é trabalho para um
filtro, duas seções adiante.

## Medido

De volta à última linha da tabela da seção anterior:

| | perguntas de clientes, primeiro | três primeiros | identificadores, primeiro | três primeiros |
| --- | --- | --- | --- | --- |
| híbrida | 20 de 26 | 24 de 26 | 4 de 6 | 5 de 6 |
| híbrida, reordenada | 19 de 26 | 26 de 26 | 0 de 6 | 4 de 6 |

Reordenar os vinte primeiros do híbrido recuperou as duas perguntas de clientes que o híbrido tinha
empurrado para fora dos três primeiros e perdeu um primeiro lugar. Nos identificadores fez estrago:
**o pedaço com a resposta veio em primeiro em nenhuma das seis**, onde o híbrido tinha quatro. Um
modelo que lê `E-4102` e `E-4104` como quase a mesma coisa dá a um trecho sobre o erro errado uma nota
tão alta quanto a um sobre o erro certo, e a correspondência exata que fazia a busca lexical boa
nessas perguntas não conta nada na nota dele. Foram precisas mais de seiscentas chamadas ao modelo
para descobrir isso.

**Neste corpus, com um modelo não treinado para reordenar, é um ganho nas perguntas de clientes e uma
perda nos identificadores**, comprado a vinte chamadas por pergunta. Espera-se que um cross-encoder
treinado se saia melhor, e as comparações publicadas mostram que sim na maioria dos corpora, e é por
isso que pipelines em produção usam um. O hábito que esta aula ensina é o que pegou a perda aqui: medir
a lista reordenada contra a de antes, nas suas próprias perguntas, dos dois tipos, antes de pagar por
ela.
