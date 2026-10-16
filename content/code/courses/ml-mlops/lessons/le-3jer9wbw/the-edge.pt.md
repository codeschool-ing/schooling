---
title: O modelo no aparelho
version: 1
---

O terceiro lugar é o próprio aparelho: um caixa numa loja, um aplicativo de celular, um sensor. **O
modelo é copiado para ele e roda lá**, então responde sem rede e sem servidor. Isso descarta a
maneira como os outros dois o carregaram: um aparelho não tem MLflow, muitas vezes não tem Python e
não tem espaço para um gigabyte de bibliotecas. O que ele precisa é do modelo num **formato
portátil** e de um runtime pequeno que execute esse formato.

**ONNX**, Open Neural Network Exchange, é o mais comum: um arquivo que descreve um modelo como um
grafo de operações padronizadas, que runtimes em muitas linguagens e em muitos aparelhos sabem
executar. O `skl2onnx` converte um pipeline do scikit-learn para ele, com o escalonador e o
codificador incluídos. Salve isto como `export_edge.py`:

```python
"""export_edge.py: the champion as an ONNX file, which runs without Python or scikit-learn."""
import mlflow
from mlflow import MlflowClient
from skl2onnx import to_onnx
from skl2onnx.common.data_types import FloatTensorType, StringTensorType

import features
from project import MODELS, ROOT

mlflow.set_tracking_uri(f"sqlite:///{ROOT / 'mlflow.db'}")
version = MlflowClient().get_model_version_by_alias("lapse", "champion").version
model = mlflow.sklearn.load_model(f"models:/lapse/{version}")

inputs = ([(c, FloatTensorType([None, 1])) for c in features.NUMERIC]
          + [(c, StringTensorType([None, 1])) for c in features.CATEGORICAL])
onnx = to_onnx(model, initial_types=inputs, options={"zipmap": False})
out = MODELS / f"lapse-v{version}.onnx"
out.write_bytes(onnx.SerializeToString())
print(f"{out.name}: {out.stat().st_size} bytes, version {version}")
```

O conversor precisa saber o tipo de cada coluna de entrada, porque um arquivo ONNX declara as suas
entradas: os sete números como floats de 32 bits, as três categorias como strings. `zipmap: False`
faz as probabilidades saírem como uma tabela simples em vez de uma lista de dicionários.

Depois, o lado do aparelho: nada de MLflow, nada de scikit-learn, só o `onnxruntime` e o arquivo.
Salve isto como `edge.py`:

```python
"""edge.py: score members with the ONNX file and onnxruntime alone, as a device would."""
import sys

import numpy as np
import onnxruntime
import pandas as pd

import features
from project import DATA, MODELS

session = onnxruntime.InferenceSession(str(MODELS / sys.argv[1]))
rows = pd.read_csv(DATA / "test.csv").head(3)

feed = {c: rows[[c]].to_numpy(np.float32) for c in features.NUMERIC}
feed |= {c: rows[[c]].to_numpy(str) for c in features.CATEGORICAL}
label, probabilities = session.run(None, feed)
print(rows[["member_id"]].assign(p_lapse=probabilities[:, 1].round(3)).to_string(index=False))
```

```
ana@dev:~/ml$ python export_edge.py
lapse-v1.onnx: 1803 bytes, version 1
ana@dev:~/ml$ python edge.py lapse-v1.onnx
 member_id  p_lapse
         1    0.123
         2    0.090
         3    0.106
```

**O modelo inteiro tem 1.803 bytes**, e as três probabilidades que ele dá são as que o
`champion.py` da lição 7 imprimiu para os mesmos membros pela mesma versão: 0,123, 0,090 e 0,106. A
conversão mudou o formato e não as respostas. Essa conferência, as mesmas linhas pontuadas dos dois
jeitos antes de um arquivo ser enviado, pertence ao passo de exportação toda vez: um conversor que
trata um passo de outro jeito em silêncio é o desvio entre treino e produção levado para dentro de
um aparelho.
