---
title: Normalização em lote, escrita para o tinynet
version: 1
---

Em 2015 Sergey Ioffe e Christian Szegedy levaram a padronização para dentro da rede. **Numa camada,
pegue as somas que o lote produziu e, para cada unidade, subtraia a média e divida pelo desvio-padrão,
medidos naquele lote.** Eles argumentaram que isso resolvia o que chamaram de internal covariate
shift: as entradas de cada camada mudam o tempo todo conforme as camadas anteriores aprendem. Um
artigo de 2018 de Santurkar e colegas achou essa explicação fraca e atribuiu o ganho a uma perda mais
suave, em que passos maiores são seguros. O efeito não está em discussão, e a próxima seção o mede.

A camada faz quatro coisas com cada atributo, que é uma coluna do lote:

1. mede a média e a variância da coluna sobre as linhas do lote;
2. subtrai a média e divide pelo desvio-padrão, o que dá `xhat`, com média 0 e variância 1;
3. multiplica por um `gamma` aprendido e soma um `beta` aprendido, um de cada por atributo;
4. durante o treino, guarda médias acumuladas da média e da variância para depois.

**O passo 3 devolve o que o passo 2 tirou.** Uma coluna forçada a média 0 e variância 1 perdeu
opções: um ReLU depois dela cortaria metade de toda coluna, sempre. Com `gamma` e `beta` a rede pode
aprender qualquer média e dispersão para cada unidade, e a dispersão passa a ser um parâmetro que a
rede escolheu em vez de um acaso dos pesos anteriores. O passo 4 existe porque uma previsão feita
depois do treino pode chegar sozinha, sem lote para medir. Salve como `~/dl/batchnorm.py`:

```schooling-example
{
  "language": "python",
  "file": "batchnorm.py",
  "parts": [
    {
      "code": "\"\"\"batchnorm: batch normalisation, as a layer tinynet can stack.\"\"\"\nimport numpy as np\n\n\nclass BatchNorm:\n    \"\"\"Each feature to mean 0 and variance 1 over the batch, then scaled by gamma and shifted by beta.\"\"\"\n    params = (\"gamma\", \"beta\")\n\n    def __init__(self, n, momentum=0.1, eps=1e-5):\n        self.gamma = np.ones(n, dtype=np.float32)\n        self.beta = np.zeros(n, dtype=np.float32)\n        self.dgamma = np.zeros_like(self.gamma)\n        self.dbeta = np.zeros_like(self.beta)",
      "note": "Dois parâmetros por atributo, declarados em `params` como o `Linear` declara `W` e `b`, para que o `Net.params()` os entregue ao otimizador com os gradientes. Começam em 1 e 0, o que deixa o valor normalizado intacto."
    },
    {
      "code": "        self.running_mean = np.zeros(n, dtype=np.float32)\n        self.running_var = np.ones(n, dtype=np.float32)\n        self.momentum, self.eps = momentum, eps\n        self.training = True",
      "note": "As estatísticas acumuladas não são parâmetros: nenhum gradiente as move. São médias guardadas para depois, quando não houver lote para medir. `training` é a flag que o `Net.mode` liga em toda camada."
    },
    {
      "code": "    def forward(self, x):\n        if self.training:\n            mean, var = x.mean(axis=0), x.var(axis=0)\n            m = self.momentum\n            self.running_mean = (1 - m) * self.running_mean + m * mean\n            self.running_var = (1 - m) * self.running_var + m * var",
      "note": "No treino, a média e a variância de cada coluna, sobre as linhas deste lote. Cada lote também move as médias acumuladas 10% do caminho em direção ao que mediu, que é o que `momentum=0.1` quer dizer no PyTorch também."
    },
    {
      "code": "        else:\n            mean, var = self.running_mean, self.running_var\n        self.std = np.sqrt(var + self.eps)\n        self.xhat = (x - mean) / self.std\n        return self.gamma * self.xhat + self.beta",
      "note": "Na avaliação, as médias guardadas fazem as vezes do lote. O `eps` impede que uma coluna sem dispersão divida por zero. Depois cada atributo é escalado e deslocado pelos seus próprios `gamma` e `beta`, e a rede pode aprender a média e a dispersão de que precisar."
    },
    {
      "code": "    def backward(self, grad):\n        self.dgamma[...] = (grad * self.xhat).sum(axis=0)\n        self.dbeta[...] = grad.sum(axis=0)\n        g = grad * self.gamma\n        return (g - g.mean(axis=0) - self.xhat * (g * self.xhat).mean(axis=0)) / self.std",
      "note": "`gamma` e `beta` recebem os mesmos gradientes que um peso e um viés recebem. O gradiente da entrada tem dois termos a mais porque a média e a variância saíram de todas as linhas: mexer numa entrada mexe nas estatísticas pelas quais todas as outras saídas foram divididas."
    }
  ]
}
```

O backward é a parte que as pessoas copiam sem ler. **Numa camada comum cada saída depende da própria
linha; aqui cada saída de uma coluna depende também de todas as outras linhas**, pela média e pela
variância que todas dividiram. É daí que vêm os dois termos subtraídos. Uma fórmula assim se confere
em vez de se confiar nela, com as diferenças finitas da aula 3. Salve como `~/dl/checknorm.py`:

```schooling-example
{
  "language": "python",
  "file": "checknorm.py",
  "parts": [
    {
      "code": "\"\"\"checknorm: a normalising layer's backward, against the slope measured by nudging.\"\"\"\nimport numpy as np\n\nfrom batchnorm import BatchNorm\n\n\ndef check(layer, axis):\n    rng = np.random.default_rng(0)\n    x = rng.normal(3, 2, (8, 5))\n    layer.gamma[...] = rng.normal(1, 0.3, 5)\n    layer.beta[...] = rng.normal(0, 0.3, 5)\n    w = rng.normal(0, 1, (8, 5))",
      "note": "Um lote de 8 linhas e 5 atributos, centrado em 3 e não em 0, para haver o que normalizar. `gamma` e `beta` recebem valores aleatórios, porque em 1 e 0 um erro que os envolvesse não apareceria."
    },
    {
      "code": "    def loss(x):\n        return (layer.forward(x) * w).sum()\n\n    loss(x)\n    dx = layer.backward(w)",
      "note": "Uma perda inventada: cada saída vezes um peso aleatório fixo, tudo somado. O gradiente dela em relação às saídas é o próprio `w`, então `backward(w)` dá o gradiente desta perda em relação a `x`."
    },
    {
      "code": "    print(\"x     mean\", np.round(x.mean(axis=axis), 2), \" std\", np.round(x.std(axis=axis), 2))\n    xhat = layer.xhat\n    print(\"xhat  mean\", np.round(xhat.mean(axis=axis), 2) + 0, \" std\", np.round(xhat.std(axis=axis), 2))",
      "note": "As estatísticas antes e depois de normalizar, no eixo em que a camada trabalha. O `+ 0` transforma um `-0.` impresso em `0.`."
    },
    {
      "code": "    numeric = np.zeros_like(x)\n    for i in np.ndindex(x.shape):\n        up, down = x.copy(), x.copy()\n        up[i] += 1e-5\n        down[i] -= 1e-5\n        numeric[i] = (loss(up) - loss(down)) / 2e-5\n    error = np.abs(dx - numeric).max() / np.abs(numeric).max()\n    print(f\"relative error of the input gradient: {error:.1e}\")\n\n\nif __name__ == \"__main__\":\n    check(BatchNorm(5), axis=0)",
      "note": "A verificação de gradiente da aula 3: empurra cada uma das 40 entradas para cima e para baixo e mede quanto a perda se mexeu. O `if` roda a verificação só quando o arquivo é executado, não quando outro programa importa o `check` dele."
    }
  ]
}
```

```
ana@vm:~/dl$ python checknorm.py
x     mean [2.61 3.11 2.27 3.2  3.21]  std [0.98 1.56 1.88 0.97 1.95]
xhat  mean [0. 0. 0. 0. 0.]  std [1. 1. 1. 1. 1.]
relative error of the input gradient: 8.6e-11
```

As cinco colunas de `x` tinham médias entre 2,27 e 3,21 e desvios-padrão entre 0,97 e 1,95. Depois da
camada, toda coluna de `xhat` tem média 0 e desvio-padrão 1. **O backward concorda com a inclinação
medida com erro relativo de 8,6e-11**, que é mais ou menos o mais perto que empurrões de 1e-5 em
float64 conseguem medir.

**A camada fica entre um `Linear` e a sua ativação**: `Linear`, depois `BatchNorm`, depois `ReLU`,
que é onde o artigo original a pôs. Nesse lugar o viés do `Linear` não faz nada. Subtrair a média do
lote remove qualquer constante somada logo antes, e o `beta` faz o trabalho do viés depois dela. O
`Linear` do tinynet sempre tem viés, e aqui ele custa 64 números que nunca mudam o resultado. O PyTorch
permite desligá-lo, o que a aula 9 mostra.

Uma propriedade explica quase tudo o que a camada faz pelo treino. **Multiplique os pesos de uma
unidade por qualquer número positivo e as somas, a média delas e o desvio-padrão delas crescem todos
por esse número, então o `xhat` não muda nada.** O que quer que um passo grande faça com a escala dos
pesos antes de uma camada de batch norm, as camadas depois dela veem a mesma escala.
