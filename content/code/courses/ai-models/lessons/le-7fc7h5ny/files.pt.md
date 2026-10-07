---
title: O modelo são quatro arquivos
version: 1
---

Um modelo para o Transformers.js é um repositório do Hub com um formato conhecido, e a seção 03 da
aula 12 disse o que há num deles. **O huggingface.co estava fora de alcance na máquina em que este
curso foi gravado**, então o modelo da ana não vem do Hub: ela treina um, em segundos, com o
`train_sorter.py`. Ele lê os trinta primeiros dos quarenta casos dela, aprende que palavras apontam
para que rótulo e grava o resultado no formato que o Transformers.js espera. Os dez últimos casos
ficam de fora, intocados, para a seção 04. Ele precisa de duas bibliotecas que a mesa ainda não tem,
o NumPy para a conta e o `onnx` para gravar o arquivo:

```python
"""train_sorter.py: the smallest model Transformers.js will run, trained here, in seconds.

A bag of words and a linear layer (logistic regression) over the first thirty of
ana's cases, written out as the files a Hub repository for Transformers.js
carries: config.json, tokenizer.json, tokenizer_config.json and onnx/model.onnx.
The last ten cases are kept back in cases/held-out.json. Nothing is random: the
weights start at zero, so every run writes the same numbers.
"""
import json
import os
import re

import numpy as np
import onnx
from onnx import TensorProto, helper, numpy_helper

LABELS = ["order-status", "refund", "address-change", "product-question", "other"]
OUT = "models/lantern-sorter"
cases = [json.loads(line) for line in open("cases/triage.jsonl")]
train, test = cases[:30], cases[30:]


def words(text):
    return re.findall(r"[a-z]+", text.lower())


vocab = ["[PAD]", "[UNK]", "[CLS]", "[SEP]"] + sorted({w for c in train for w in words(c["text"])})
index = {w: i for i, w in enumerate(vocab)}

# A bag of words and a linear layer: logistic regression, trained by gradient descent.
X = np.zeros((len(train), len(vocab)), dtype=np.float32)
for row, c in enumerate(train):
    for w in words(c["text"]):
        X[row, index[w]] += 1
y = np.array([LABELS.index(c["label"]) for c in train])
W = np.zeros((len(vocab), len(LABELS)), dtype=np.float32)
b = np.zeros(len(LABELS), dtype=np.float32)
for _ in range(500):
    z = X @ W + b
    p = np.exp(z - z.max(1, keepdims=True)); p /= p.sum(1, keepdims=True)
    p[np.arange(len(y)), y] -= 1
    W -= 0.5 * (X.T @ p / len(y) + 0.001 * W); b -= 0.5 * p.mean(0)
W[:4] = 0  # padding and markers carry no evidence

# The same arithmetic as an ONNX graph: look each token's row up, sum them, add the bias.
graph = helper.make_graph(
    [helper.make_node("Gather", ["weights", "input_ids"], ["rows"]),
     helper.make_node("Cast", ["attention_mask"], ["mask"], to=TensorProto.FLOAT),
     helper.make_node("Unsqueeze", ["mask", "axis"], ["mask3"]),
     helper.make_node("Mul", ["rows", "mask3"], ["kept"]),
     helper.make_node("ReduceSum", ["kept", "seq_axis"], ["summed"], keepdims=0),
     helper.make_node("Add", ["summed", "bias"], ["logits"])],
    "lantern_sorter",
    [helper.make_tensor_value_info("input_ids", TensorProto.INT64, ["batch", "sequence"]),
     helper.make_tensor_value_info("attention_mask", TensorProto.INT64, ["batch", "sequence"])],
    [helper.make_tensor_value_info("logits", TensorProto.FLOAT, ["batch", len(LABELS)])],
    [numpy_helper.from_array(W, "weights"), numpy_helper.from_array(b, "bias"),
     numpy_helper.from_array(np.array([2], dtype=np.int64), "axis"),
     numpy_helper.from_array(np.array([1], dtype=np.int64), "seq_axis")])
model = helper.make_model(graph, opset_imports=[helper.make_opsetid("", 17)])
model.ir_version = 8
onnx.checker.check_model(model)
os.makedirs(f"{OUT}/onnx", exist_ok=True)
onnx.save(model, f"{OUT}/onnx/model.onnx")

json.dump({"model_type": "bert", "architectures": ["BertForSequenceClassification"],
           "id2label": dict(enumerate(LABELS)), "label2id": {l: i for i, l in enumerate(LABELS)}},
          open(f"{OUT}/config.json", "w"), indent=1)
print(file=open(f"{OUT}/config.json", "a"))
json.dump({"tokenizer_class": "BertTokenizer", "do_lower_case": True, "model_max_length": 512},
          open(f"{OUT}/tokenizer_config.json", "w"), indent=1)
print(file=open(f"{OUT}/tokenizer_config.json", "a"))
json.dump({"version": "1.0", "truncation": None, "padding": None, "added_tokens": [
              {"id": i, "content": t, "single_word": False, "lstrip": False, "rstrip": False,
               "normalized": False, "special": True} for i, t in enumerate(vocab[:4])],
           "normalizer": {"type": "BertNormalizer", "clean_text": True, "handle_chinese_chars": True,
                          "strip_accents": None, "lowercase": True},
           "pre_tokenizer": {"type": "BertPreTokenizer"},
           "post_processor": {"type": "TemplateProcessing",
                              "single": [{"SpecialToken": {"id": "[CLS]", "type_id": 0}},
                                         {"Sequence": {"id": "A", "type_id": 0}},
                                         {"SpecialToken": {"id": "[SEP]", "type_id": 0}}],
                              "pair": [], "special_tokens": {
                                  "[CLS]": {"id": "[CLS]", "ids": [2], "tokens": ["[CLS]"]},
                                  "[SEP]": {"id": "[SEP]", "ids": [3], "tokens": ["[SEP]"]}}},
           "decoder": None,
           "model": {"type": "WordPiece", "unk_token": "[UNK]", "continuing_subword_prefix": "##",
                     "max_input_chars_per_word": 100, "vocab": index}},
          open(f"{OUT}/tokenizer.json", "w"))
json.dump(test, open("cases/held-out.json", "w"))
print(f"{len(vocab)} words in the vocabulary, {W.size + b.size} numbers in the model")
print(f"trained on {len(train)} cases, {len(test)} kept back")
```

```
ana@desk:~/desk$ pip install -q numpy==2.4.6 onnx==1.23.1
ana@desk:~/desk$ python train_sorter.py
224 words in the vocabulary, 1125 numbers in the model
trained on 30 cases, 10 kept back
```

É a menor coisa que ainda conta como modelo: um **saco de palavras** e uma camada linear, o que é
regressão logística. Cada palavra dos e-mails de treino ganha cinco números, um por rótulo; a nota
de um e-mail para um rótulo é a soma dos números das palavras dele mais um viés. 224 palavras vezes
cinco, mais cinco vieses, dá os 1.125. Um modelo de verdade do tipo que a seção 02 da aula 12 tinha
em mente tem milhões de números, e nada do que vem a seguir muda com a contagem.

```
ana@desk:~/desk$ find models -type f | sort | xargs wc -c
 326 models/lantern-sorter/config.json
4949 models/lantern-sorter/onnx/model.onnx
4303 models/lantern-sorter/tokenizer.json
  90 models/lantern-sorter/tokenizer_config.json
9668 total
```

Quatro arquivos, menos de dez kilobytes ao todo:

| arquivo | o que a biblioteca lê nele |
|---|---|
| `config.json` | a arquitetura a carregar e os nomes dos rótulos |
| `tokenizer.json` | como texto vira número: o vocabulário e as regras em volta dele |
| `tokenizer_config.json` | ajustes com que o tokenizador começa |
| `onnx/model.onnx` | a computação e os pesos, em precisão de 32 bits |

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

`id2label` é o que transforma o quarto número do modelo em `product-question`. `model_type: bert` é
uma **afirmação**, e não verdadeira: isto não é um BERT. Ela diz ao Transformers.js que código de
carregamento usar, e a biblioteca acredita, porque tudo de que esse código precisa do grafo são duas
entradas e uma saída com os nomes certos:

```
ana@desk:~/desk$ python -c "import onnx; g = onnx.load(\"models/lantern-sorter/onnx/model.onnx\").graph; print(*[n.op_type for n in g.node]); print([i.name for i in g.input], \"->\", [o.name for o in g.output])"
Gather Cast Unsqueeze Mul ReduceSum Add
['input_ids', 'attention_mask'] -> ['logits']
```

Seis operações: buscar a linha de números de cada token, zerar o preenchimento, somar as linhas,
somar o viés. Esse é o modelo inteiro.

## O que o tokenizador faz com um e-mail

O tokenizador roda antes de tudo isso, e decide o que o modelo chega a ver. O `tokens.mjs` pede a
ele, pelo Transformers.js, que codifique uma frase e a decodifique de volta:

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

Quinze ids. `[CLS]` e `[SEP]` marcam o começo e o fim. O número do pedido `20488`, o hífen e os dois
sinais de pontuação viraram `[UNK]`, o token para qualquer coisa fora do vocabulário, que não
carrega evidência nenhuma. **Uma palavra que o modelo nunca viu no treino é uma palavra que ele não
sabe ler**, e isso vale para todo modelo de todo tamanho. O tokenizador da caixa da seção 06 da aula
1 é a mesma ideia com um vocabulário muito maior, cortado em pedaços de palavras para que menos
coisas fiquem de fora.
