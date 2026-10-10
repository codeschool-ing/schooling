---
title: tinynet.py, as mesmas regras para um lote inteiro
version: 1
---

O `byhand.py` dá nome a cada array, o que serve para nove pesos e é impossível para milhares. **O
módulo abaixo transforma cada uma das quatro regras numa classe com dois métodos, `forward` e
`backward`, e uma rede numa lista dessas classes.** É tudo com que as aulas 3 a 8 treinam: essas
aulas acrescentam a ele um otimizador, dropout e normalização, e nenhuma delas muda este arquivo.
Salve-o como `~/dl/tinynet.py`, ao lado do `digits.py` da aula 1:

```schooling-example
{
  "language": "python",
  "file": "tinynet.py",
  "parts": [
    {
      "code": "\"\"\"tinynet: a neural network in NumPy, small enough to read in one sitting.\"\"\"\nimport numpy as np",
      "note": "O módulo sobre o qual as aulas 3 a 8 se apoiam. Nada nele fica escondido por uma biblioteca: cada gradiente é uma linha que dá para ler."
    },
    {
      "code": "class Linear:\n    \"\"\"y = x @ W + b on the way forward; the gradients of W, b and x on the way back.\"\"\"\n    params = (\"W\", \"b\")\n\n    def __init__(self, n_in, n_out, rng):\n        self.W = rng.normal(0, np.sqrt(2 / n_in), (n_in, n_out)).astype(np.float32)\n        self.b = np.zeros(n_out, dtype=np.float32)\n        self.dW = np.zeros_like(self.W)\n        self.db = np.zeros_like(self.b)\n\n    def forward(self, x):\n        self.x = x\n        return x @ self.W + self.b\n\n    def backward(self, grad):\n        self.dW[...] = self.x.T @ grad\n        self.db[...] = grad.sum(axis=0)\n        return grad @ self.W.T",
      "note": "As regras do `byhand.py` para um lote inteiro. O `forward` guarda a entrada, porque o `backward` precisa dela: `x.T @ grad` é a entrada vezes o gradiente, somado sobre o lote. O viés soma o gradiente sobre as linhas. O que ele devolve, `grad @ W.T`, é o gradiente para a camada de baixo. Os pesos iniciais são aleatórios com dispersão √(2/n_in), uma escolha feita para o ReLU (inicialização de He). `dW[...] =` escreve sempre no mesmo array, então um otimizador pode guardar uma referência a ele."
    },
    {
      "code": "class ReLU:\n    \"\"\"max(0, x), and a gradient that passes only where x was positive.\"\"\"\n\n    def forward(self, x):\n        self.mask = x > 0\n        return x * self.mask\n\n    def backward(self, grad):\n        return grad * self.mask",
      "note": "O `(z > 0)` do `byhand.py`, lembrado do forward pass. Não tem parâmetros, então não tem `params`."
    },
    {
      "code": "class Net:\n    \"\"\"Layers in a row: forward runs them in order, backward in reverse.\"\"\"\n\n    def __init__(self, *layers):\n        self.layers = layers\n\n    def forward(self, x):\n        for layer in self.layers:\n            x = layer.forward(x)\n        return x\n\n    def backward(self, grad):\n        for layer in reversed(self.layers):\n            grad = layer.backward(grad)\n\n    def mode(self, training):\n        for layer in self.layers:\n            layer.training = training\n\n    def params(self):\n        \"\"\"(value, gradient) pairs: the arrays an optimiser changes in place.\"\"\"\n        return [(getattr(layer, k), getattr(layer, \"d\" + k))\n                for layer in self.layers for k in getattr(layer, \"params\", ())]",
      "note": "O backpropagation é o `reversed`. Cada camada recebe o gradiente da sua saída e devolve o gradiente da sua entrada, então uma rede de qualquer profundidade é um laço. O `mode` ainda não faz nada; o dropout da aula 7 lê a marcação que ele põe. O `params` junta cada array ao seu gradiente."
    },
    {
      "code": "def softmax_cross_entropy(logits, y):\n    \"\"\"The mean loss over a batch, and its gradient with respect to the logits.\"\"\"\n    z = logits - logits.max(axis=1, keepdims=True)\n    p = np.exp(z) / np.exp(z).sum(axis=1, keepdims=True)\n    rows = np.arange(len(y))\n    loss = -np.log(p[rows, y]).mean()\n    grad = p.copy()\n    grad[rows, y] -= 1\n    return loss, grad / len(y)",
      "note": "A perda para dez classes, aceita aqui como está: a aula 4 trata dela. Ela transforma as dez saídas em probabilidades e pontua a probabilidade do dígito certo. O que importa agora é que ela devolve o gradiente que começa o backward pass, como o `d_out` fazia no `byhand.py`."
    }
  ]
}
```

Três coisas para notar antes de usá-lo.

**Uma camada guarda o que o backward pass vai precisar.** O `Linear` guarda a entrada, o `ReLU`
guarda a máscara. Esse é o custo do backpropagation de que ninguém fala: cada valor intermediário do
forward pass fica na memória até o backward pass usá-lo. A aula 19 mede essa memória num modelo de
verdade.

**O lote é somado dentro do produto.** `self.x.T @ grad` é uma matriz de 64 por 32 vezes uma de 32
por 16, para um lote de 32 imagens entrando em 16 unidades. Cada elemento é o gradiente de um peso,
somado sobre as 32 imagens. Para um lote de uma imagem, é o produto externo que o `byhand.py`
escreveu.

**O `softmax_cross_entropy` é usado como está.** É a perda para escolher uma de dez classes, e a aula
4 trata de por que é a certa. O que importa aqui é o segundo valor que ele devolve, o gradiente que
começa o backward pass, como o `d_out` fazia.

Para ver que o módulo calcula o mesmo que a mão, monte a rede do `byhand.py` com ele e troque os
pesos aleatórios pelos escolhidos à mão. Salve como `~/dl/again.py`:

```schooling-example
{
  "language": "python",
  "file": "again.py",
  "parts": [
    {
      "code": "\"\"\"again: byhand.py's network, built from tinynet, gives the same gradients.\"\"\"\nimport numpy as np\n\nimport tinynet\n\nrng = np.random.default_rng(0)\nnet = tinynet.Net(tinynet.Linear(2, 2, rng), tinynet.ReLU(), tinynet.Linear(2, 1, rng))\nfirst, _, second = net.layers\nfirst.W[...] = [[0.5, -0.5], [0.25, 0.25]]\nfirst.b[...] = [0.0, -1.0]\nsecond.W[...] = [[1.5], [1.0]]\nsecond.b[...] = [0.25]",
      "note": "A mesma rede 2-2-1, com os pesos aleatórios trocados pelos do `byhand.py`. Os pesos da camada de saída aqui são uma coluna, porque o `Linear` sempre tem uma coluna por unidade."
    },
    {
      "code": "out = net.forward(np.array([[1.0, 2.0]], dtype=np.float32))\nnet.backward(2 * (out - 1.0))\nfor value, gradient in net.params():\n    print(value.shape, gradient.ravel())",
      "note": "Um lote de uma imagem só. O gradiente do erro quadrático é escrito à mão, já que o `tinynet` só traz a perda para classes."
    }
  ]
}
```

```
ana@vm:~/dl$ python again.py
(2, 2) [2.25 0.   4.5  0.  ]
(2,) [2.25 0.  ]
(2, 1) [1.5 0. ]
(1,) [1.5]
```

**Os mesmos números.** O gradiente dos pesos da primeira camada, achatado linha por linha, é 2,25,
0, 4,5, 0; o do viés é 2,25 e 0; os da camada de saída são 1,5 e 0, e 1,5. A diferença está nos
formatos: os pesos da saída aqui são uma coluna de 2 por 1, porque o `Linear` sempre tem uma coluna
por unidade.
