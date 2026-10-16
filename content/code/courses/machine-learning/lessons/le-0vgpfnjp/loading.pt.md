---
title: Carregando, e o que o arquivo não contém
version: 1
---

Um modelo gravado só vale alguma coisa se o modelo que volta for o que entrou. O teste é direto:
carregá-lo num processo novo, pontuar as 13.154 linhas do `churn_2026.csv` e comparar as chances com um
modelo ajustado de novo do zero. Salve isto como `load_model.py`:

```python
# load_model.py
import numpy as np

import stored
from churn_model import build
from feira import load_churn

model, card = stored.load("churn-2025-12")
new = load_churn("data/churn_2026.csv")
loaded = model.predict_proba(new)[:, 1]

history = load_churn()
refitted = build().fit(history, history["churned"]).predict_proba(new)[:, 1]
print(f"{card['name']}, fitted on {card['data']} {card['sha256'][:12]}")
print(f"{len(new):,} chances from the file and from a fresh fit, identical: {np.array_equal(loaded, refitted)}")
```

```
ana@lab:~/ml$ python load_model.py
churn-2025-12, fitted on data/churn.csv 500d90cc1cfd
13,154 chances from the file and from a fresh fit, identical: True
```

**Idênticas, não parecidas.** `np.array_equal` compara cada um dos 13.154 números até o último bit. Uma
regressão logística com os mesmos dados e as mesmas versões sai igual toda vez, e o arquivo guarda
exatamente o que foi ajustado.

Agora o mesmo arquivo a partir de outro lugar. `joblib.load` de dentro de `/tmp`, que tem o caminho
completo do arquivo mas não os programas do curso:

```
ana@lab:~/ml$ cd /tmp
ana@lab:/tmp$ python -c 'import joblib; joblib.load("/home/ana/ml/models/churn-2025-12.joblib")'
Traceback (most recent call last):
  File "<string>", line 1, in <module>
  File "/home/ana/ml/.venv/lib/python3.12/site-packages/joblib/numpy_pickle.py", line 755, in load
    obj = _unpickle(
          ^^^^^^^^^^
  File "/home/ana/ml/.venv/lib/python3.12/site-packages/joblib/numpy_pickle.py", line 632, in _unpickle
    obj = unpickler.load()
          ^^^^^^^^^^^^^^^^
  File "/usr/lib/python3.12/pickle.py", line 1205, in load
    dispatch[key[0]](self)
  File "/usr/lib/python3.12/pickle.py", line 1530, in load_stack_global
    self.append(self.find_class(module, name))
                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/usr/lib/python3.12/pickle.py", line 1572, in find_class
    __import__(module, level=0)
ModuleNotFoundError: No module named 'churn_model'
```

`No module named 'churn_model'`. **O arquivo guarda os números aprendidos e os nomes do código, não o
código.** O pipeline da aula 15 começa com `FunctionTransformer(add_shapes)`, e o que foi gravado para
essa etapa é o nome `churn_model.add_shapes`, a ser importado quando o arquivo for carregado. O mesmo vale
para toda classe do scikit-learn ali dentro: o arquivo diz `sklearn.linear_model.LogisticRegression` e
confia que o que responder por esse nome depois é a mesma coisa. É por isso que o `stored.load` confere as
versões, e é por isso que a ficha não substitui guardar o `churn_model.py` no commit que ajustou o
modelo: o arquivo e o código que ele nomeia andam juntos, ou o arquivo vira um enigma.

Há uma consequência mais séria. Carregar o arquivo **importa e roda o código que ele nomeia**; foi assim
que o `churn_model` chegou a ser procurado. Arquivos do `joblib`, como os arquivos `pickle` do Python por
baixo deles, são programas tanto quanto dados. **Carregue só arquivos que você fez, ou de alguém a quem
você deixaria rodar um programa na sua máquina.** Um modelo baixado de um desconhecido é um programa de um
desconhecido. Formatos que guardam só números existem exatamente por isso; para um modelo que você ajustou
e guarda você mesmo, o `joblib` é a escolha comum.
