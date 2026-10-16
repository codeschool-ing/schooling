---
title: Dados tabulares, e três modelos numa tabela
version: 1
---

Dezenove aulas treinaram redes, e seria fácil sair delas acreditando que a rede é o modelo forte, o
que se pega quando o problema importa. **Numa tabela de linhas e colunas, essa crença não sobrevive a
uma medição.** Esta seção faz a medição, com dados reais, com os modelos que `machine-learning`
ensinou ao lado de uma rede deste curso.

Tabela aqui quer dizer o mesmo que numa planilha ou num banco de dados: uma linha por caso, uma
coluna por grandeza medida, e cada coluna significando algo por si só. Registros de venda, pedidos de
empréstimo, leituras de sensores, medidas de pacientes. A maior parte dos dados que uma empresa
guarda tem essa cara, e a maior parte dos modelos que uma empresa roda é treinada neles.

O programa abaixo é a bancada desta seção e da próxima. Ele roda três modelos na mesma tabela:
regressão logística, o `HistGradientBoostingClassifier` do scikit-learn, que é o gradient boosting
que a aula 8 de `machine-learning` ensinou, e uma rede densa em PyTorch. Cada um é avaliado por
validação cruzada em cinco dobras, o método da aula 3 de `machine-learning`, e cronometrado. Ele
precisa do `loop.py` da aula 9 ao lado. Salve como `~/dl/bench.py`:

```schooling-example
{
  "language": "python",
  "file": "bench.py",
  "parts": [
    {
      "code": "\"\"\"bench: three models on one table, five folds each, accuracy and the time it took.\"\"\"\nimport time\n\nimport numpy as np\nimport torch\nimport torch.nn as nn\nfrom sklearn.ensemble import HistGradientBoostingClassifier\nfrom sklearn.linear_model import LogisticRegression\nfrom sklearn.model_selection import StratifiedKFold\nfrom sklearn.pipeline import make_pipeline\nfrom sklearn.preprocessing import StandardScaler\nfrom threadpoolctl import threadpool_limits\n\nimport loop\n\ntorch.set_num_threads(1)\nthreadpool_limits(1)",
      "note": "Todo modelo recebe um processador. O PyTorch e o scikit-learn espalhariam o trabalho pelos quatro, e o quanto uma biblioteca faz isso bem não é o que este programa mede. O `threadpoolctl` veio junto com o scikit-learn, então nada novo é instalado."
    },
    {
      "code": "class TorchMLP:\n    \"\"\"A dense network with scikit-learn's fit and predict, so it can sit in the same loop.\"\"\"\n\n    def __init__(self, steps=200):\n        self.steps = steps",
      "note": "Os modelos do scikit-learn atendem por `fit` e `predict`. Dar à rede os mesmos dois métodos deixa um único laço tratar os três do mesmo jeito."
    },
    {
      "code": "    def fit(self, X, y):\n        self.scale = StandardScaler().fit(X)\n        x = torch.tensor(self.scale.transform(X), dtype=torch.float32)\n        t = torch.tensor(y)\n        torch.manual_seed(0)\n        d, k = x.shape[1], int(y.max()) + 1\n        self.net = nn.Sequential(nn.Linear(d, 64), nn.ReLU(),\n                                 nn.Linear(64, 64), nn.ReLU(), nn.Linear(64, k))",
      "note": "As colunas são padronizadas só com a dobra de treino, como a aula 8 pediu das entradas de uma rede. Depois, duas camadas ocultas de 64: uma rede comum e razoável para uma tabela, não uma rede ajustada."
    },
    {
      "code": "        opt = torch.optim.Adam(self.net.parameters(), lr=0.01)\n        loop.fit(self.net, opt, (x, t), (x, t), self.steps, batch_size=len(t), every=10**9)\n        return self",
      "note": "O `loop.py` da aula 9, com a dobra inteira num único lote, então 200 épocas são 200 passos de Adam. Ele quer um conjunto para relatar e recebe a dobra de treino; `every` é tão grande que nunca imprime, e nada é escolhido a partir dele."
    },
    {
      "code": "    def predict(self, X):\n        x = torch.tensor(self.scale.transform(X), dtype=torch.float32)\n        self.net.eval()\n        with torch.no_grad():\n            return self.net(x).argmax(dim=1).numpy()"
    },
    {
      "code": "def models():\n    return {\n        \"logistic regression\": make_pipeline(StandardScaler(), LogisticRegression(max_iter=1000)),\n        \"gradient boosting\": HistGradientBoostingClassifier(random_state=0),\n        \"MLP, PyTorch\": TorchMLP(),\n    }",
      "note": "Regressão logística e gradient boosting exatamente como `machine-learning` os deixou, e o boosting com os padrões do scikit-learn, sem mexer em nada."
    },
    {
      "code": "def run(X, y):\n    folds = StratifiedKFold(n_splits=5, shuffle=True, random_state=0)\n    for name, model in models().items():\n        scores, start = [], time.perf_counter()\n        for train, test in folds.split(X, y):\n            model.fit(X[train], y[train])\n            scores.append((model.predict(X[test]) == y[test]).mean())\n        seconds = time.perf_counter() - start\n        print(f\"{name:20s} accuracy {np.mean(scores):.3f}  worst fold {min(scores):.3f}  {seconds:6.2f} s\")",
      "note": "Cinco dobras em vez de um conjunto de validação, porque com poucas centenas de linhas uma divisão está a meia dúzia de exemplos de outra resposta. Todo modelo vê as mesmas cinco divisões, e o relógio cobre os cinco treinos."
    }
  ]
}
```

**Todo modelo fica preso a um processador**, e isso é uma decisão de justiça, não de velocidade. Com
quatro processadores, cada biblioteca divide o trabalho do seu jeito, e numa máquina ocupada com
outra coisa a divisão pode custar mais que o trabalho. Um processador para cada um faz o relógio
medir quanto trabalho um modelo faz.

A primeira tabela é o conjunto de câncer de mama do scikit-learn: 569 tumores, 30 medidas cada um, e
se ele era maligno ou benigno. Salve como `~/dl/cancer.py` e rode:

```schooling-example
{
  "language": "python",
  "file": "cancer.py",
  "parts": [
    {
      "code": "\"\"\"cancer: the breast cancer table that ships with scikit-learn, through bench.py.\"\"\"\nfrom sklearn.datasets import load_breast_cancer\n\nimport bench\n\nX, y = load_breast_cancer(return_X_y=True)",
      "note": "569 tumores, cada um descrito por 30 medidas tiradas de uma imagem de células, e um rótulo: maligno ou benigno. Como os dígitos, vem dentro do scikit-learn."
    },
    {
      "code": "print(X.shape[0], \"rows,\", X.shape[1], \"columns,\", f\"{y.mean():.0%} benign\")\nbench.run(X, y)",
      "note": "A fatia da classe majoritária é a acurácia de um modelo que sempre responde \"benigno\", a linha de base que todo número abaixo precisa superar."
    }
  ]
}
```

```
ana@vm:~/dl$ python cancer.py
569 rows, 30 columns, 63% benign
logistic regression  accuracy 0.979  worst fold 0.956    0.04 s
gradient boosting    accuracy 0.970  worst fold 0.956    1.06 s
MLP, PyTorch         accuracy 0.967  worst fold 0.930    3.90 s
```

**Os três ficam a 1,2 ponto um do outro, e a rede fica em último.** A regressão logística chega a
0,979, o boosting a 0,970 e a rede a 0,967. Cada dobra tem uns 114 tumores, então um tumor vale quase
um ponto, e esses três diferem por um ou dois tumores por dobra. A rede também teve a pior dobra,
0,930. A aula 18 trata de separar uma diferença de ruído, e esta não se qualifica. O que não está em
dúvida é que a rede não comprou nada.

**O relógio separa os três mais do que a acurácia.** A regressão logística levou 0,04 segundo para
as cinco dobras, o boosting 1,06 e a rede 3,90: a rede várias vezes o boosting, e o boosting muitas
vezes a regressão logística. Esses segundos serão outros na sua máquina, e mudam de uma execução
para outra. A ordem é o que se deve ler.

Repare em qual modelo venceu. As 30 colunas desta tabela são medidas que um patologista escolheu
porque separam as duas classes, e uma soma ponderada delas quase basta. **Quando alguém já fez a
engenharia de atributos, sobra pouco para uma rede aprender**, e um modelo linear com 30 pesos é
difícil de vencer. A próxima seção monta uma tabela em que isso não vale, e a resposta muda, mas não
a favor da rede.
