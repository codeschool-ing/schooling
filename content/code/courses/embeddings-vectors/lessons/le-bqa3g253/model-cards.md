---
title: Reading a model card
version: 1
---

A hosted provider tells you its limits on a pricing page. An open model tells you on its **model
card**, the page of text published with the weights on Hugging Face. It is the only description of
what the model was trained to do, and most of the mistakes made with open models are things the
card said.

These are the lines worth reading, with what all-MiniLM-L6-v2's card says for each:

| what to look for | why it matters | all-MiniLM-L6-v2 |
|---|---|---|
| dimension | storage, and what it can be compared with | 384 |
| maximum sequence length | where the silent cut falls | 256 word pieces |
| languages | lesson 1's Portuguese title, scored as unrelated | English |
| training data | what *close* means to it | over a billion sentence pairs |
| pooling and normalisation | what you must do if you run it yourself | mean pooling, then normalise |
| prefixes or instructions | whether queries and documents are marked | none |
| licence | whether you may use it commercially | Apache 2.0 |

## The files disagree with each other, and the card decides

The weights arrive with configuration files, and it is tempting to read the limits off them
instead. Here is what three of the files `setup.sh` downloaded in lesson 1 say:

```
ana@lab:~/emb$ jq "{vocab_size, hidden_size, num_hidden_layers, max_position_embeddings}" $MINILM_DIR/config.json
{
  "vocab_size": 30522,
  "hidden_size": 384,
  "num_hidden_layers": 6,
  "max_position_embeddings": 512
}
ana@lab:~/emb$ jq .model_max_length $MINILM_DIR/tokenizer_config.json
512
ana@lab:~/emb$ jq -c "{truncation: .truncation.max_length, padding: .padding.strategy}" $MINILM_DIR/tokenizer.json
{"truncation":128,"padding":{"Fixed":128}}
```

**There are three different lengths in them, and none is 256.** 512 is the room the architecture
has, the number of positions it holds a learned vector for. 512 again is what the tokenizer's
configuration allows. 128 is what `tokenizer.json` truncates and pads to if nobody changes it.
`minilm.py` and Chroma both change it to 256, and Chroma's source remarks on it in a comment: *for
some reason sentence-transformers uses 256 even though the HF config has a max length of 128*. The
256 is the model card's number and the one sentence-transformers applies, so it is the one this
course uses.

This goes for every open model. **A number in a configuration file describes the file; the card
describes how the model was meant to be used.** Where the two disagree, a library that reads only
the file can run the model with a different limit from the one it was published with. Every text
longer than the smaller limit then gets a different vector, and nothing says so.

## Prefixes: task types for open models

all-MiniLM-L6-v2 is symmetric, so it takes no prefix. Many newer open models are trained
asymmetrically, like the providers' models in lesson 8, and since there is no API parameter to carry
the role, **the role goes into the text itself.** The E5 family expects every query to start with
`query: ` and every document with `passage: `; Nomic's embedding models use `search_query: ` and
`search_document: `; the BGE models put an instruction in front of the query only. The card says
which, and a model given texts without its prefix still returns vectors, just not the ones it was
trained to produce.

None of these models was run here, because all of them are downloaded from Hugging Face. They are
described so that you recognise the requirement when a card states it.

## Choosing a model to try

The **MTEB leaderboard**, the Massive Text Embedding Benchmark, is where most people start. It runs
hundreds of open and hosted models through the same tasks — retrieval, classification, clustering
and more — in many languages, and ranks them. It is the right first filter: it removes models that
are poor at everything. It is not the last one, because its tasks are other people's data, and the
next section measures what happens when two models meet yours.
