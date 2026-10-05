"""minilm: the sentence embedding model this course runs, in fifty lines.

all-MiniLM-L6-v2 is a small transformer (six layers, 384 numbers out)
published by the sentence-transformers project. The weights here are the
ONNX export Chroma distributes as its default embedding function, so the
model runs with onnxruntime and nothing else: no PyTorch, no network.

What sentence-transformers does with this model, and what this file does:

  1. tokenise into WordPiece pieces, lower-cased, at most 256 of them
     (the model card's max_seq_length; anything longer is cut off)
  2. run the transformer: one vector of 384 numbers per piece
  3. mean pooling: average the pieces' vectors, ignoring padding
  4. normalise: divide by the length, so every vector has length 1

    from minilm import embed, pieces
    vectors = embed(["a sentence", "another one"])   # shape (2, 384)
"""
import os

import numpy as np
import onnxruntime
from tokenizers import Tokenizer

MODEL_DIR = os.environ.get("MINILM_DIR", "/opt/emb/share/all-MiniLM-L6-v2")
MAX_PIECES = 256
DIM = 384

_tok = Tokenizer.from_file(os.path.join(MODEL_DIR, "tokenizer.json"))
_tok.enable_truncation(MAX_PIECES)
_tok.enable_padding(pad_id=0, pad_token="[PAD]")
_opts = onnxruntime.SessionOptions()
_opts.intra_op_num_threads = 1
_opts.inter_op_num_threads = 1
_model = onnxruntime.InferenceSession(os.path.join(MODEL_DIR, "model.onnx"), _opts,
                                      providers=["CPUExecutionProvider"])


def pieces(text):
    """The WordPiece pieces the model reads for TEXT, before truncation."""
    t = Tokenizer.from_file(os.path.join(MODEL_DIR, "tokenizer.json"))
    t.no_truncation()
    t.no_padding()
    return t.encode(text).tokens


def embed(texts, batch=32):
    """One unit-length vector of 384 float32 numbers per text."""
    if isinstance(texts, str):
        texts = [texts]
    out = []
    for i in range(0, len(texts), batch):
        enc = _tok.encode_batch(list(texts[i:i + batch]))
        ids = np.array([e.ids for e in enc], dtype=np.int64)
        mask = np.array([e.attention_mask for e in enc], dtype=np.int64)
        hidden = _model.run(None, {"input_ids": ids, "attention_mask": mask,
                                   "token_type_ids": np.zeros_like(ids)})[0]
        m = mask[:, :, None].astype(np.float32)
        mean = (hidden * m).sum(axis=1) / np.clip(m.sum(axis=1), 1e-9, None)
        out.append(mean / np.linalg.norm(mean, axis=1, keepdims=True))
    return np.concatenate(out).astype(np.float32)
