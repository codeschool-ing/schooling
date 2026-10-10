---
title: "optim.py e fit.py: três regras, e o laço que as roda"
version: 1
---

As três últimas seções escreveram cada regra para um brinquedo de dois ou três números. Uma rede
guarda arrays de muitos formatos, e toda aula em NumPy daqui até a aula 8 treina uma. **Estes dois
arquivos são aquilo com que elas a treinam**: o `optim.py` escreve as três regras uma vez, para
qualquer lista de pares de valor e gradiente, e o `fit.py` é o laço que entrega lotes a elas. Salve
os dois em `~/dl`, começando por `~/dl/optim.py`:

```schooling-example
{
  "language": "python",
  "file": "optim.py",
  "parts": [
    {
      "code": "\"\"\"optim: three ways to turn a gradient into a step, each changing the arrays in place.\"\"\"\nimport numpy as np",
      "note": "Todo otimizador aqui recebe `net.params()`, os pares de valor e gradiente da aula 3, e altera os valores no lugar com `-=`. Escrever `p = p - ...` criaria um array novo e deixaria os pesos da própria rede intocados."
    },
    {
      "code": "class SGD:\n    def __init__(self, params, lr):\n        self.params, self.lr = params, lr\n\n    def step(self):\n        for p, g in self.params:\n            p -= self.lr * g",
      "note": "A regra da aula 2, para cada array da rede: um passo contra o gradiente, escalado pela taxa. `lr` é um atributo comum, e é isso que permite a um agendamento mudá-lo entre épocas."
    },
    {
      "code": "class Momentum:\n    def __init__(self, params, lr, beta=0.9):\n        self.params, self.lr, self.beta = params, lr, beta\n        self.v = [np.zeros_like(p) for p, _ in params]\n\n    def step(self):\n        for (p, g), v in zip(self.params, self.v):\n            v *= self.beta\n            v += g\n            p -= self.lr * v",
      "note": "Um array de velocidade por parâmetro, do mesmo formato, começando em zero. A cada passo ele guarda `beta` de si mesmo e soma o gradiente novo, e o parâmetro anda ao longo dele. Um gradiente que nunca muda faz `v` crescer até perto de dez vezes o seu tamanho, 1 / (1 - 0,9)."
    },
    {
      "code": "class Adam:\n    def __init__(self, params, lr=0.001, beta1=0.9, beta2=0.999, eps=1e-8):\n        self.params, self.lr, self.b1, self.b2, self.eps = params, lr, beta1, beta2, eps\n        self.m = [np.zeros_like(p) for p, _ in params]\n        self.v = [np.zeros_like(p) for p, _ in params]\n        self.t = 0\n\n    def step(self):\n        self.t += 1\n        for (p, g), m, v in zip(self.params, self.m, self.v):\n            m *= self.b1\n            m += (1 - self.b1) * g\n            v *= self.b2\n            v += (1 - self.b2) * g * g\n            m_hat = m / (1 - self.b1 ** self.t)\n            v_hat = v / (1 - self.b2 ** self.t)\n            p -= self.lr * m_hat / (np.sqrt(v_hat) + self.eps)",
      "note": "O `adam_steps.py`, para cada array de uma rede: duas médias corridas por parâmetro, ambas corrigidas por `1 - beta ** t`, e um passo de `m_hat` dividido pela raiz de `v_hat`. `self.t` conta os passos, e `eps` só evita uma divisão por zero."
    }
  ]
}
```

**As três classes têm a mesma interface**: são construídas a partir de `net.params()` e de uma taxa,
e o `step()` delas usa os gradientes que a passada para trás acabou de deixar nos arrays. Os
otimizadores do PyTorch, na aula 9, têm exatamente esse formato. Lá, os gradientes são somados ao que
já está guardado, então um laço precisa zerá-los antes de cada passada para trás. Aqui o
`Linear.backward` sobrescreve `dW` e `db` com `[...] =`, e é por isso que nada nestes arquivos zera
coisa alguma.

Depois, o `~/dl/fit.py`:

```schooling-example
{
  "language": "python",
  "file": "fit.py",
  "parts": [
    {
      "code": "\"\"\"fit: the training loop every NumPy lesson from here on runs.\"\"\"\nimport numpy as np\n\nfrom tinynet import softmax_cross_entropy",
      "note": "A perda é a entropia cruzada com softmax do tinynet, a que a aula 4 desmonta. Ela devolve a perda média de um lote e o gradiente que começa a passada para trás."
    },
    {
      "code": "def evaluate(net, x, y):\n    \"\"\"Loss and accuracy on a whole set, with the network in evaluation mode.\"\"\"\n    net.mode(False)\n    logits = net.forward(x)\n    net.mode(True)\n    loss, _ = softmax_cross_entropy(logits, y)\n    return float(loss), float((logits.argmax(axis=1) == y).mean())",
      "note": "Uma passada para a frente sobre um conjunto inteiro, sem passada para trás e sem passo. `net.mode(False)` não muda nada nas camadas do tinynet; está ali para as camadas que as aulas 7 e 8 acrescentam, que se comportam de outro jeito durante o treino."
    },
    {
      "code": "def fit(net, opt, train, val, epochs, batch_size=32, seed=0, every=1):\n    \"\"\"Shuffle, cut into batches, step once per batch; report every `every` epochs.\"\"\"\n    x, y = train\n    rng = np.random.default_rng(seed)\n    history = []\n    net.mode(True)\n    for epoch in range(1, epochs + 1):\n        order = rng.permutation(len(y))\n        losses = []\n        for start in range(0, len(y), batch_size):\n            idx = order[start:start + batch_size]\n            loss, grad = softmax_cross_entropy(net.forward(x[idx]), y[idx])\n            net.backward(grad)\n            opt.step()\n            losses.append(loss)\n        val_loss, val_acc = evaluate(net, *val)\n        history.append((epoch, float(np.mean(losses)), val_loss, val_acc))\n        if epoch % every == 0:\n            print(f\"epoch {epoch:3d}  train loss {np.mean(losses):.4f}  \"\n                  f\"val loss {val_loss:.4f}  val acc {val_acc:.3f}\")\n    return history",
      "note": "Cada época embaralha o conjunto de treino com o seu próprio gerador com semente, corta-o em lotes e dá um passo por lote: para a frente, perda, para trás, `opt.step()`. Com 1.077 imagens e lotes de 32 são 34 passos, o último com 21 imagens. `history` guarda uma tupla por época, e `every` decide de quanto em quanto se imprime uma linha."
    }
  ]
}
```

Um programa curto junta os dois e treina a rede dos dígitos com momentum. Salve como `~/dl/train.py`:

```schooling-example
{
  "language": "python",
  "file": "train.py",
  "parts": [
    {
      "code": "\"\"\"train: the digits network, trained by fit with an optimiser from optim.\"\"\"\nimport numpy as np\n\nimport digits\nimport optim\nfrom fit import fit\nfrom tinynet import Linear, ReLU, Net",
      "note": "Os imports são todo o kit das aulas em NumPy: os dados da aula 1, a rede da aula 3 e os dois módulos desta."
    },
    {
      "code": "train, val, _ = digits.load()\nrng = np.random.default_rng(0)\nnet = Net(Linear(64, 32, rng), ReLU(), Linear(32, 10, rng))\nopt = optim.Momentum(net.params(), lr=0.1)\nhistory = fit(net, opt, train, val, epochs=10)",
      "note": "A mesma rede do `noise.py`, entregue ao momentum com taxa de 0,1 por dez épocas. Trocar de otimizador é mudar um nome na linha `opt =`."
    }
  ]
}
```

```
ana@vm:~/dl$ python train.py
epoch   1  train loss 1.2015  val loss 0.3860  val acc 0.875
epoch   2  train loss 0.2865  val loss 0.2014  val acc 0.931
epoch   3  train loss 0.1590  val loss 0.2189  val acc 0.925
epoch   4  train loss 0.1596  val loss 0.1243  val acc 0.953
epoch   5  train loss 0.1136  val loss 0.1915  val acc 0.925
epoch   6  train loss 0.1447  val loss 0.1363  val acc 0.964
epoch   7  train loss 0.0946  val loss 0.1449  val acc 0.944
epoch   8  train loss 0.0728  val loss 0.1320  val acc 0.942
epoch   9  train loss 0.0622  val loss 0.1258  val acc 0.958
epoch  10  train loss 0.0581  val loss 0.1032  val acc 0.969
```

**Dez épocas levam a acurácia de validação de 0,875 a 0,969**, e duas coisas no registro valem a
leitura antes que surpreendam você.

**Na primeira época a perda de treino, 1,2015, fica muito acima da perda de validação, 0,3860.** Não
é um bug, e não é a rede indo melhor em dígitos que nunca viu. A perda de treino é a média de 34
perdas de lote tiradas enquanto os pesos ainda mudavam, a maioria delas antes de a rede ter aprendido
muita coisa. A perda de validação é medida uma vez, no fim da época, com os pesos com que a época
terminou.

**A acurácia de validação não sobe de forma constante.** Ela vai 0,931, 0,925, 0,953, 0,925, 0,964:
para cima e para baixo em até 0,039 entre épocas vizinhas. É o ruído do SGD e o balanço do momentum,
vistos de fora. O que uma curva dessas diz, e quando parar, é assunto da aula 6.
