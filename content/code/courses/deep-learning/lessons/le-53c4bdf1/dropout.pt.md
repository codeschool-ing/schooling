---
title: Dropout, e o sinal de treino
version: 1
---

Uma camada larga pode deixar suas unidades dividirem o trabalho em arranjos particulares: uma unidade
dispara para um traço específico porque outras três sempre disparam com ela. Com 100 imagens, um arranjo
desses pode ajustar uma figura e mais nada. **O dropout os quebra tirando unidades ao acaso durante o
treino.** A cada passo, cada unidade de uma camada oculta é desligada com probabilidade `p`, um conjunto
diferente a cada vez, e assim nenhuma unidade pode contar com a presença de outra.

Dois detalhes o fazem funcionar, e os dois estão na camada abaixo.

**As sobreviventes são ampliadas.** Com `p = 0.5`, metade das unidades está desligada, então a camada
seguinte recebe mais ou menos metade da soma que receberia sem dropout. Dividir as sobreviventes por
`1 - p` põe a soma esperada de volta onde estava. Isso é o dropout *invertido*, a versão que os frameworks
usam, porque não deixa nada a corrigir na avaliação.

**Na avaliação, nada é descartado.** A rede que você mede e coloca em produção usa todas as unidades. É
para isso que serve o sinal `training`: o `Net.mode` da aula 3 o põe em cada camada, e o `fit` da aula 5 o
desliga enquanto avalia e o religa para treinar. Esqueça a troca e os seus números de validação vêm de uma
rede que joga fora metade de si mesma ao acaso.

Salve como `~/dl/dropout.py`:

```schooling-example
{
  "language": "python",
  "file": "dropout.py",
  "parts": [
    {
      "code": "\"\"\"dropout: a layer that switches off a random share of units while training.\"\"\"\nimport numpy as np\n\nfrom tinynet import Linear, Net, ReLU",
      "note": "Nada novo para importar: a camada só precisa do NumPy."
    },
    {
      "code": "class Dropout:\n    def __init__(self, p, rng):\n        self.p, self.rng, self.training = p, rng, True\n\n    def forward(self, x):\n        if not self.training:\n            return x\n        self.mask = (self.rng.random(x.shape) >= self.p) / (1 - self.p)\n        return x * self.mask\n\n    def backward(self, grad):\n        return grad * self.mask",
      "note": "Uma camada com a interface do tinynet e sem parâmetros. `training` é o atributo que `Net.mode` põe em cada camada, e o `fit` o desliga enquanto avalia. No treino, cada unidade sobrevive com probabilidade `1 - p`, e as sobreviventes são divididas por `1 - p` para que a soma esperada que chega à próxima camada seja a mesma de sem dropout. O backward deixa o gradiente passar pelas mesmas unidades, com a mesma escala."
    },
    {
      "code": "def wide_dropout(p, seed=0):\n    \"\"\"small.wide(), with a Dropout after each hidden layer.\"\"\"\n    rng = np.random.default_rng(seed)\n    return Net(Linear(64, 512, rng), ReLU(), Dropout(p, rng),\n               Linear(512, 512, rng), ReLU(), Dropout(p, rng),\n               Linear(512, 10, rng))",
      "note": "A mesma rede do `small.wide()`, com um `Dropout` depois de cada ReLU oculto. O Dropout não sorteia nada ao ser criado, então com a mesma semente os pesos iniciais são os mesmos do `small.wide()`."
    },
    {
      "code": "if __name__ == \"__main__\":\n    import small\n    from fit import evaluate, fit\n    from optim import SGD\n\n    train, val = small.data()\n    for p in (0.0, 0.2, 0.5, 0.8):\n        net = wide_dropout(p)\n        fit(net, SGD(net.params(), lr=0.2), train, val, epochs=300, every=1000)\n        loss, acc = evaluate(net, *val)\n        print(f\"dropout {p:.1f}  train acc {evaluate(net, *train)[1]:.3f}  \"\n              f\"val loss {loss:.4f}  val acc {acc:.3f}\")",
      "note": "Quatro taxas de dropout, sendo 0,0 nenhum dropout. A acurácia de treino é medida com a camada desligada, como o `evaluate` faz."
    }
  ]
}
```

```
PENDING dropout
```

A linha de 0.0 é a execução do `overfit.py` de novo, número por número, e é a prova de que a camada não faz
nada quando não descarta nada.

**Com 0.2 e 0.5 a acurácia sobe um pouco e a perda sobe também.** A acurácia de validação chega a 0,906 e
depois a 0,911, três e depois oito imagens a mais que sem dropout, em 360; a perda sobe de 0,3281 para
0,3328 e 0,3798. A acurácia de treino continua 1,000 nos dois. O dropout fez a rede aprender algo um pouco
mais geral, e não fez nada para impedir 300 épocas de confiança crescente. Com 0.8 ele tira tanto que a
rede não consegue ajustar o próprio conjunto de treino, 0,900, e a acurácia de validação cai para 0,739.

Se três ou oito imagens são uma melhora de verdade é uma pergunta justa, e a última seção desta aula a
responde com uma execução que só muda a semente. O dropout rende mais em redes maiores, treinadas com mais
dados do que estas, onde foi apresentado, em 2014, e é um dos motivos de os transformers da aula 15 ainda
o carregarem.
