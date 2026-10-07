---
title: The model is four files
version: 1
---

A model for Transformers.js is a Hub repository with a known layout, and lesson 12 section 03
said what is in one. **huggingface.co could not be reached from the machine this course was
recorded on**, so ana's model does not come from the Hub. The lab trains one instead: `train-sorter`
reads the first thirty of her forty cases, learns which words point at which label, and writes the
result in the layout Transformers.js expects. The last ten cases are kept back, untouched, for
section 04.

```
ana@desk:~/desk$ train-sorter
224 words in the vocabulary, 1125 numbers in the model
trained on 30 cases, 10 kept back
```

It is the smallest thing that still counts as a model: a **bag of words** and one linear layer,
which is logistic regression. Every word in the training e-mails gets five numbers, one per label;
an e-mail's score for a label is the sum of its words' numbers plus a bias. 224 words times five,
plus five biases, is the 1,125. A real model of the kind lesson 12 section 02 had in mind has
millions of numbers, and none of what follows changes with the count.

```
ana@desk:~/desk$ find models -type f | sort | xargs wc -c
 326 models/lantern-sorter/config.json
4949 models/lantern-sorter/onnx/model.onnx
4303 models/lantern-sorter/tokenizer.json
  90 models/lantern-sorter/tokenizer_config.json
9668 total
```

Four files, under ten kilobytes in all:

| file | what the library reads in it |
|---|---|
| `config.json` | the architecture to load, and the names of the labels |
| `tokenizer.json` | how text becomes numbers: the vocabulary and the rules around it |
| `tokenizer_config.json` | settings the tokenizer starts with |
| `onnx/model.onnx` | the computation and the weights, at 32-bit precision |

```
ana@desk:~/desk$ cat models/lantern-sorter/config.json
{
 "model_type": "bert",
 "architectures": [
  "BertForSequenceClassification"
 ],
 "id2label": {
  "0": "order-status",
  "1": "refund",
  "2": "address-change",
  "3": "product-question",
  "4": "other"
 },
 "label2id": {
  "order-status": 0,
  "refund": 1,
  "address-change": 2,
  "product-question": 3,
  "other": 4
 }
}
```

`id2label` is what turns the model's fourth number into `product-question`. `model_type: bert` is a
**claim**, and not a true one: this is no BERT. It tells Transformers.js which loading code to use,
and the library believes it, because all that code needs from the graph is two inputs and an
output with the right names:

```
ana@desk:~/desk$ python -c "import onnx; g = onnx.load(\"models/lantern-sorter/onnx/model.onnx\").graph; print(*[n.op_type for n in g.node]); print([i.name for i in g.input], \"->\", [o.name for o in g.output])"
Gather Cast Unsqueeze Mul ReduceSum Add
['input_ids', 'attention_mask'] -> ['logits']
```

Six operations: look up each token's row of numbers, zero the padding, add the rows up, add the
bias. That is the whole model.

## What the tokenizer does to an e-mail

The tokenizer runs before any of it, and it decides what the model ever gets to see.
`tokens.mjs` asks it, through Transformers.js, to encode one sentence and decode it again:

```js
import { AutoTokenizer, env } from "@huggingface/transformers";
env.allowRemoteModels = false;
env.localModelPath = process.cwd() + "/models/";

const tokenizer = await AutoTokenizer.from_pretrained("lantern-sorter");
const text = process.argv[2];
const ids = tokenizer.encode(text);
console.log(ids.join(" "));
console.log(tokenizer.decode(ids));
```

```
ana@desk:~/desk$ node tokens.mjs "Where is my order LB-20488? It has not arrived."
2 211 90 109 127 95 1 1 1 91 73 117 13 1 3
[CLS] where is my order lb [UNK] [UNK] [UNK] it has not arrived [UNK] [SEP]
```

Fifteen ids. `[CLS]` and `[SEP]` mark the start and the end. The order number `20488`, the hyphen
and both punctuation marks became `[UNK]`, the token for anything outside the vocabulary, which
carries no evidence. **A word the model never saw in training is a word it cannot read**, and that
is true of every model at every size. The tokenizer in lesson 1 section 06's box is the same idea
with a far larger vocabulary, cut into pieces of words so that fewer things fall outside it.
