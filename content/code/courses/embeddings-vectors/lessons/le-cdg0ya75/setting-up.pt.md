---
title: Preparando o ambiente
version: 1
---

Quatro passos, nesta ordem: os pacotes do sistema, o banco de dados, o ambiente Python com os seus
dois modelos, e o programa que toda aula importa. Os comandos são digitados num terminal do Ubuntu
24.04, qualquer que tenha sido o caminho que você escolheu entre os três.

## Os pacotes do sistema e o banco de dados

```bash
sudo apt update
sudo apt install -y python3-venv curl jq postgresql-16 postgresql-16-pgvector
sudo -u postgres createuser --superuser $USER
createdb shop
mkdir -p ~/emb/data
cd ~/emb
```

`python3-venv` deixa o Python criar um ambiente isolado, que o Ubuntu exige antes de deixar o `pip`
instalar qualquer coisa. `jq` lê JSON na linha de comando, e algumas aulas o usam para olhar dentro
de arquivos. `postgresql-16-pgvector` é o **pgvector**, a extensão que ensina o PostgreSQL a guardar
e comparar vetores; as aulas 2 e 14 a 18 o usam.

A terceira linha cria no PostgreSQL um papel com o seu nome de login, para que o `psql` e o Python
se conectem como você sem senha, e a quarta cria o banco em que o curso trabalha, `shop`. Tudo o que
o curso escreve fica em `~/emb`, e todo comando daqui em diante é digitado ali.

## O ambiente Python e os modelos

Salve isto como `~/emb/setup.sh`:

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

e rode:

```
ana@lab:~/emb$ bash setup.sh
/home/ana/models/minilm.tar.gz: OK
Ready. Open a new terminal, or type: source ~/.bashrc
ana@lab:~/emb$ du -sh ~/.venvs/emb ~/models ~/.cache/pip
1.3G	/home/ana/.venvs/emb
88M	/home/ana/models
360M	/home/ana/.cache/pip
```

Leva alguns minutos, quase todos no `pip`, que baixa cerca de 360 MB de pacotes e os guarda num
cache; o `du` mediu isso por último, e `rm -rf ~/.cache/pip` devolve o espaço depois que a
preparação deu certo. O que fica para trás:

- `~/.venvs/emb`, um **ambiente virtual**: uma cópia particular do Python com todas as bibliotecas
  que o curso importa, nas versões exatas com que as transcrições foram gravadas. Uma versão mais
  nova de uma biblioteca costuma funcionar, e às vezes imprime um número que difere da página no
  último dígito; fixar as versões é o que faz a sua saída e a da aula coincidirem.
- `~/models/all-MiniLM-L6-v2`, o modelo de embedding que a maioria das aulas roda. Ele é baixado do
  armazenamento de onde o Chroma, o banco vetorial da aula 12, o busca, e o `sha256sum -c` recusa o
  arquivo se ele não for, byte a byte, o que o código do próprio Chroma espera. O `OK` é essa
  conferência passando.
- o arquivo de configuração de que o tokenizador do WordLlama precisa, copiado de dentro do próprio
  pacote. Sem ele, o WordLlama tenta buscar o arquivo no huggingface.co na primeira vez que carrega.
- três linhas no fim do `~/.bashrc`. Elas põem o `python` do ambiente em primeiro lugar no seu
  `PATH`, dizem ao `minilm.py` onde está o modelo e fazem do `shop` o banco que o `psql` abre. Um
  terminal lê o `~/.bashrc` quando começa, então abra um novo, ou digite `source ~/.bashrc` neste.

## O programa que toda aula importa

O último arquivo é o de que a primeira aula precisa logo. Salve-o como `~/emb/minilm.py`:

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

Ele transforma uma lista de textos numa lista de vetores com o all-MiniLM-L6-v2, e é só isso que as
oito primeiras aulas precisam saber dele. A aula 9 o abre e diz para que serve cada um dos seus
quatro passos.

## Conferindo se deu certo

```
ana@lab:~/emb$ python --version
Python 3.12.3
ana@lab:~/emb$ python -c "from minilm import embed; print(embed(\"hello\").shape)"
(1, 384)
ana@lab:~/emb$ psql -Atc "SELECT current_user, current_database()"
ana|shop
```

O Python 3.12 é o do ambiente, o vetor tem a forma que as próximas seções explicam, e o
PostgreSQL responde como você, no `shop`. Se alguma das três linhas disser outra coisa, a seção
*Quando a instalação falha* vem logo depois desta.
