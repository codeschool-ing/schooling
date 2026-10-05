#!/opt/aimodels/bin/python
"""train-sorter: the smallest model Transformers.js will run, trained here, in seconds.

Lesson 13 needs a model on disk and huggingface.co could not be reached from
the machine the course was recorded on. So the lab trains one: a bag of words
and a linear layer (logistic regression) over the first thirty of ana's cases,
exported as the files a Hub repository for Transformers.js carries:
config.json, tokenizer.json, tokenizer_config.json and onnx/model.onnx.
The last ten cases are kept back in cases/held-out.json. Nothing is random:
the weights start at zero, so every run writes the same numbers.
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
