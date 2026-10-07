---
title: Setting up
version: 1
---

Four steps, in this order: the system packages, the database, the Python environment with its two
models, and the one program every lesson imports. The commands are typed in a terminal on Ubuntu
24.04, whichever of the three paths you took.

## The system packages and the database

```bash
sudo apt update
sudo apt install -y python3-venv curl jq postgresql-16 postgresql-16-pgvector
sudo -u postgres createuser --superuser $USER
createdb shop
mkdir -p ~/emb/data
cd ~/emb
```

`python3-venv` lets Python make an isolated environment, which Ubuntu insists on before it lets
`pip` install anything. `jq` reads JSON on the command line, and a few lessons use it to look inside
files. `postgresql-16-pgvector` is **pgvector**, the extension that teaches PostgreSQL to store
and compare vectors; lessons 2 and 14 to 18 use it.

The third line creates a PostgreSQL role with your login name, so that `psql` and Python can
connect as you without a password, and the fourth creates the database the course works in,
`shop`. Everything the course writes lives in `~/emb`, and every command from here on is typed
there.

## The Python environment and the models

Save this as `~/emb/setup.sh`:

```bash
#!/usr/bin/env bash
# setup.sh: the Python environment and the two models this course runs.
# Run it once, as yourself:  bash setup.sh
set -euo pipefail

VENV=~/.venvs/emb
MODELS=~/models

# 1. A virtual environment with every library the course imports, at the
#    versions the course was recorded with.
python3 -m venv $VENV
$VENV/bin/pip install --quiet --disable-pip-version-check \
  numpy==2.4.6 onnxruntime==1.30.0 tokenizers==0.23.2 wordllama==0.4.0.post1 \
  chromadb==1.5.9 faiss-cpu==1.15.1 lancedb==0.39.0 pyarrow==25.0.1 \
  qdrant-client==1.19.1 hnswlib==0.8.0 scikit-learn==1.9.1 \
  "psycopg[binary]==3.3.6" pgvector==0.5.0 \
  openai==3.24.0 google-genai==2.28.0 cohere==7.2.0 tiktoken==0.14.0

# 2. all-MiniLM-L6-v2, exported to ONNX, from the bucket Chroma downloads it
#    from, checked against the SHA-256 that Chroma's own code carries.
mkdir -p $MODELS
curl -sSfL -o $MODELS/minilm.tar.gz \
  https://chroma-onnx-models.s3.amazonaws.com/all-MiniLM-L6-v2/onnx.tar.gz
echo "913d7300ceae3b2dbc2c50d1de4baacab4be7b9380491c27fab7418616a16ec3  $MODELS/minilm.tar.gz" |
  sha256sum -c
tar -xzf $MODELS/minilm.tar.gz -C $MODELS
rm -rf $MODELS/all-MiniLM-L6-v2
mv $MODELS/onnx $MODELS/all-MiniLM-L6-v2
rm $MODELS/minilm.tar.gz

# 3. WordLlama's package carries its tokeniser's configuration, but looks for
#    it in a cache directory, and downloads it from huggingface.co when the
#    file is not there. Copy it to where it looks.
pkg=$($VENV/bin/python -c 'import os, wordllama; print(os.path.dirname(wordllama.__file__))')
mkdir -p ~/.cache/wordllama/tokenizers
cp $pkg/tokenizers/l2_supercat_tokenizer_config.json ~/.cache/wordllama/tokenizers/

# 4. Three settings every new terminal needs, added to ~/.bashrc once.
if ! grep -q '# embeddings course' ~/.bashrc; then
  cat >> ~/.bashrc <<'END'
# embeddings course
export PATH=~/.venvs/emb/bin:$PATH
export MINILM_DIR=~/models/all-MiniLM-L6-v2
export PGDATABASE=shop
END
fi
echo "Ready. Open a new terminal, or type: source ~/.bashrc"
```

and run it:

```
ana@lab:~/emb$ bash setup.sh
/home/ana/models/minilm.tar.gz: OK
Ready. Open a new terminal, or type: source ~/.bashrc
ana@lab:~/emb$ du -sh ~/.venvs/emb ~/models ~/.cache/pip
1.3G	/home/ana/.venvs/emb
88M	/home/ana/models
360M	/home/ana/.cache/pip
```

It takes a few minutes, most of them in `pip`, which downloads about 360 MB of packages and keeps
them in a cache; `du` measured that last, and `rm -rf ~/.cache/pip` gives the space back once the
setup has worked. What it leaves behind:

- `~/.venvs/emb`, a **virtual environment**: a private copy of Python with every library the course
  imports, at the exact versions its transcripts were recorded with. A newer version of a library
  usually works, and sometimes prints a number that differs in the last digit from the page;
  pinning them is what makes your output and the lesson's agree.
- `~/models/all-MiniLM-L6-v2`, the embedding model most lessons run. It is downloaded from the
  storage Chroma, the vector database of lesson 12, fetches it from, and `sha256sum -c` refuses the
  file unless it is byte for byte the one Chroma's own code expects. `OK` is that check passing.
- the configuration file WordLlama's tokeniser needs, copied out of the package itself. Without it
  WordLlama tries to fetch the file from huggingface.co the first time it loads.
- three lines at the end of `~/.bashrc`. They put the environment's `python` first on your `PATH`,
  tell `minilm.py` where the model is, and make `shop` the database `psql` opens. A terminal
  reads `~/.bashrc` when it starts, so open a new one, or type `source ~/.bashrc` in this one.

## The program every lesson imports

The last file is the one the first lesson needs straight away. Save it as `~/emb/minilm.py`:

```python
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

MODEL_DIR = os.environ.get("MINILM_DIR", os.path.expanduser("~/models/all-MiniLM-L6-v2"))
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
```

It turns a list of texts into a list of vectors with all-MiniLM-L6-v2, and that is all the first
eight lessons need to know about it. Lesson 9 opens it up and says what each of its four steps is
for.

## Checking it worked

```
ana@lab:~/emb$ python --version
Python 3.12.3
ana@lab:~/emb$ python -c "from minilm import embed; print(embed(\"hello\").shape)"
(1, 384)
ana@lab:~/emb$ psql -Atc "SELECT current_user, current_database()"
ana|shop
```

Python 3.12 is the environment's, the vector has the shape the next sections explain, and
PostgreSQL answers as you, in `shop`. If any of the three lines says something else, the section
*When the setup fails* is next to this one.
