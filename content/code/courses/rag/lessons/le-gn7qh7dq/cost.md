---
title: What each one costs
version: 1
---

The two approaches put their cost in different places. Retrieval pays a little on every question,
for the retrieved text it adds to the prompt. Fine-tuning pays a lot up front, for training, and again
every time the facts change. Which is cheaper depends on how many questions there are and how often
the knowledge moves, and both can be measured.

## The cost of retrieval: the context

`context_tokens.py` runs the search for every question in the test set and counts the tokens of the
three sections it would put in the prompt:

```
ana@lab:~/rag$ python context_tokens.py
questions: 30
retrieved tokens per question, mean: 332
smallest: 191  largest: 502
```

**332 tokens per question on average**, the price of three whole sections. That is the number a
retrieval system adds to every prompt, and the one lessons 4 and 12 spend most of their effort
reducing.

## The cost of fine-tuning: training, and retraining

A training run is billed by the tokens it trains on, times the number of passes over the data,
called **epochs**. `dataset.py` produced 968 tokens of examples, and three epochs is a common default.

`costs.py` puts the two side by side for a month, with **illustrative prices typed on the command
line, not any provider's**: 3 per million input tokens and 25 per million training tokens. It
assumes 30,000 questions a month and four policy changes, so four retraining runs:

```
ana@lab:~/rag$ python costs.py --questions 30000 --context 332 --train-tokens 968 --epochs 3 --retrains 4 --input-price 3 --train-price 25
RAG, extra context:       29.88 a month
fine-tuning, training:     0.29 a month
ana@lab:~/rag$ python costs.py --questions 30000 --context 332 --train-tokens 968000 --epochs 3 --retrains 4 --input-price 3 --train-price 25
RAG, extra context:       29.88 a month
fine-tuning, training:   290.40 a month
```

The first run makes fine-tuning look almost free, and it is misleading in the way a small example
always is. **Twenty-six examples do not teach a model a corpus.** The section on what fine-tuning
changes said why: each fact needs many phrasings to be held reliably. The second run multiplies the
dataset by a thousand, to 968,000 tokens, as an illustration of the growth that argument calls for:
many phrasings of every question, for every fact. The training bill rises to 290.40 a month, almost
ten times the retrieval cost.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"A chart of monthly cost against questions a month, from 0 to 500 thousand. The retrieval line rises from zero, at 29.88 for 30 thousand questions. The fine-tuning line is flat at 290.40. They cross near 292 thousand questions a month.\"><path d=\"M90 270 L680 270\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M90 270 L90 40\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M90.0 270 L90.0 275\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"90.0\" y=\"288\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0k</text><path d=\"M208.0 270 L208.0 275\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"208.0\" y=\"288\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">100k</text><path d=\"M326.0 270 L326.0 275\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"326.0\" y=\"288\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">200k</text><path d=\"M444.0 270 L444.0 275\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"444.0\" y=\"288\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">300k</text><path d=\"M562.0 270 L562.0 275\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"562.0\" y=\"288\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">400k</text><path d=\"M680.0 270 L680.0 275\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"680.0\" y=\"288\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">500k</text><path d=\"M85 270.0 L90 270.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"81\" y=\"270.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><path d=\"M85 224.0 L90 224.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"81\" y=\"224.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">100</text><path d=\"M85 178.0 L90 178.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"81\" y=\"178.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">200</text><path d=\"M85 132.0 L90 132.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"81\" y=\"132.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">300</text><path d=\"M85 86.0 L90 86.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"81\" y=\"86.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">400</text><path d=\"M85 40.0 L90 40.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"81\" y=\"40.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">500</text><text x=\"385.0\" y=\"312\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">questions a month</text><text x=\"90\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">cost a month, at the illustrative prices</text><path d=\"M90.0 270.0 L680.0 40.91999999999999\" stroke=\"var(--phosphor)\" stroke-width=\"2.2\" fill=\"none\"></path><path d=\"M90.0 136.416 L680.0 136.416\" stroke=\"var(--amber)\" stroke-width=\"2.2\" fill=\"none\"></path><circle cx=\"434.0\" cy=\"136.4\" r=\"4.5\" fill=\"var(--paper)\"></circle><text x=\"446.04788\" y=\"156.416\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">they cross near 292k</text><text x=\"131.4\" y=\"242.2552\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">30k: 29.88</text><circle cx=\"125.4\" cy=\"256.3\" r=\"4\" fill=\"var(--phosphor)\"></circle><text x=\"597.4\" y=\"56.99120000000002\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">retrieval: 332 tokens a question</text><text x=\"99.44\" y=\"124.416\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">fine-tuning: four retrains of 968,000 tokens</text></svg>", "caption": "Retrieval costs in proportion to the questions; fine-tuning costs in proportion to the changes. With 332 tokens of context, four retraining runs a month and the illustrative prices, the lines cross near 292,000 questions a month."}
```

The two lines cross where the retrieval cost equals the training cost: 290.40 divided by the cost of
332 tokens at 3 per million, about 292,000 questions a month. Below that, at these prices and this
rate of change, retrieval is cheaper; above it, the fine-tuned model is.

## What the arithmetic leaves out

The comparison above is honest and incomplete, and the parts it leaves out mostly favour retrieval.

**A fine-tuned model is usually dearer to run per token** than the base model it was trained from,
on the providers that offer both. That is a price per question too, and it was left at zero above.

**Retraining is not only the training bill.** Each run needs its dataset rebuilt, its model
evaluated and its deployment switched, which is people's time, and people's time costs more than
either line in the figure.

**Retrieval has a fixed cost too**: the vector database, the embedding of the corpus and its
re-embedding when the model changes. For thirteen documents it is negligible; for millions it is the
largest line. `embeddings-vectors` lesson 18 measured what storage and re-indexing cost.

And the axis that matters most is not on the figure: how often the knowledge changes. Double the
number of policy changes and the fine-tuning line doubles; the retrieval line does not move.
