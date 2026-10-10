---
title: Módulos, as camadas que guardam os próprios parâmetros
version: 1
---

Na aula 3, uma camada era uma classe com `forward`, `backward` e os seus arrays, e o `Net.params()`
juntava os arrays para o otimizador. **Um `nn.Module` é a mesma ideia sem o passo para trás**,
porque o autograd o faz. O que sobra é um método forward e uma lista de parâmetros que o módulo
guarda por você, incluindo os de cada módulo dentro dele.

A rede que esta aula treina tem uma camada oculta de 32 unidades. Salve-a como `~/dl/mlp.py`, já que
três programas a usam:

```schooling-example
{
  "language": "python",
  "file": "mlp.py",
  "parts": [
    {
      "code": "\"\"\"mlp: the dense network this lesson trains on the digits, 64 pixels in and 10 scores out.\"\"\"\nimport torch.nn as nn\n\n\ndef make_mlp(hidden=32):\n    return nn.Sequential(nn.Linear(64, hidden), nn.ReLU(), nn.Linear(hidden, 10))",
      "note": "O `nn.Sequential` roda seus módulos em ordem, como o `tinynet.Net` fazia na aula 3. Uma camada oculta de 32 unidades, ReLU e dez saídas, uma pontuação por dígito. Nada de softmax no fim: a perda o aplica."
    }
  ]
}
```

Depois olhe para ela de fora. Salve como `~/dl/modules.py`:

```schooling-example
{
  "language": "python",
  "file": "modules.py",
  "parts": [
    {
      "code": "\"\"\"modules: the same network as a class, its parameters counted, and what it computes.\"\"\"\nimport torch\nimport torch.nn as nn\n\nimport tdigits\nfrom mlp import make_mlp\n\n\nclass MLP(nn.Module):\n    def __init__(self, hidden=32):\n        super().__init__()\n        self.hidden = nn.Linear(64, hidden)\n        self.out = nn.Linear(hidden, 10)\n\n    def forward(self, x):\n        return self.out(torch.relu(self.hidden(x)))",
      "note": "A forma mais longa de escrever a mesma rede, e a que qualquer rede com um desvio ou um atalho precisa. Camadas atribuídas como atributos no `__init__` ficam registradas como filhas do módulo, e o `forward` diz o que fazer com elas. Chamar `model(x)` roda o `forward`."
    },
    {
      "code": "torch.manual_seed(0)\nmodel = make_mlp()\nprint(model)\nfor name, p in model.named_parameters():\n    print(f\"{name:9s} {str(tuple(p.shape)):9s} {p.numel():5d}\")\nprint(\"parameters:\", sum(p.numel() for p in model.parameters()))\nprint(\"as a class:\", sum(p.numel() for p in MLP().parameters()))",
      "note": "Todo módulo conhece seus parâmetros, incluindo os dos filhos, e o `parameters()` entrega todos a um otimizador numa chamada. Os nomes vêm da posição no `Sequential`, ou dos nomes dos atributos na classe."
    },
    {
      "code": "(x, _), _, _ = tdigits.load()\nfirst, last = model[0], model[2]\nby_hand = torch.relu(x[:5] @ first.weight.T + first.bias) @ last.weight.T + last.bias\nprint(\"output for 5 images:\", tuple(model(x[:5]).shape), \" by hand:\", torch.allclose(model(x[:5]), by_hand))",
      "note": "O que um `Linear` calcula, por extenso. O PyTorch guarda o peso como saídas por entradas, a transposta do `W` da aula 1, então o produto é `x @ weight.T`."
    }
  ]
}
```

```
ana@vm:~/dl$ python modules.py
Sequential(
  (0): Linear(in_features=64, out_features=32, bias=True)
  (1): ReLU()
  (2): Linear(in_features=32, out_features=10, bias=True)
)
0.weight  (32, 64)   2048
0.bias    (32,)        32
2.weight  (10, 32)    320
2.bias    (10,)        10
parameters: 2410
as a class: 2410
output for 5 images: (5, 10)  by hand: True
```

## Contando

**`sum(p.numel() for p in model.parameters())` é a linha para guardar**, e aqui ela responde 2.410:
64 × 32 + 32 para a camada oculta e 32 × 10 + 10 para a saída. A versão em classe conta o mesmo,
porque guarda as mesmas duas camadas sob outros nomes, `hidden` e `out` em vez de `0` e `2`. O ReLU
não tem parâmetros e não ganha linha.

Duas coisas no `nn.Linear` diferem da aula 1. O peso é guardado como **saídas por entradas**,
`(32, 64)`, então a camada calcula `x @ weight.T + bias`, e a última linha confirma que escrever isso
à mão dá os mesmos números. E ele parte da sua própria inicialização aleatória, não da do
`tinynet.Linear`, então uma execução em PyTorch e uma em NumPy com o mesmo formato não partem dos
mesmos pesos.

## Sequential ou uma classe

O `nn.Sequential` serve para uma rede que é uma linha reta de camadas, que é toda rede desta aula.
**Uma classe é necessária no momento em que os dados não correm numa linha só**: duas entradas, um
desvio cuja saída é somada de volta depois, uma camada usada duas vezes. As conexões residuais da
aula 12 são o primeiro desses casos. Os parâmetros são encontrados do mesmo jeito nos dois, percorrendo
os módulos atribuídos como atributos, e é por isso que uma camada guardada numa lista comum do Python
fica invisível para o `parameters()` e nunca é treinada. O `nn.ModuleList` é a lista que registra o
que contém.
