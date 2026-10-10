---
title: Passos e épocas, os dois relógios de uma execução
version: 1
---

Uma execução é descrita em épocas, e é tentador ler uma época como um movimento dos pesos. **Não é.
Uma época é uma passada por todas as imagens de treino; um passo é uma atualização dos pesos**, feita
a partir de um lote. Quantos passos cabem numa época depende do tamanho do lote, e é esse número que
muda quando o tamanho do lote muda.

O laço do `fit.py` da aula 5 diz isso numa linha: `for start in range(0, len(y), batch_size)` corta o
conjunto de treino embaralhado em lotes, e cada lote recebe um forward, um backward e uma chamada a
`opt.step()`. O programa abaixo calcula a contagem para quatro tamanhos de lote e depois a confere
contando. Salve-o como `~/dl/steps.py`, ao lado do `digits.py` da aula 1, do `tinynet.py` da aula 3 e
do `optim.py` e do `fit.py` da aula 5:

```schooling-example
{
  "language": "python",
  "file": "steps.py",
  "parts": [
    {
      "code": "\"\"\"steps: how many steps make an epoch, worked out and then counted.\"\"\"\nimport math\n\nimport numpy as np\n\nimport digits\nfrom fit import fit\nfrom optim import SGD\nfrom tinynet import Linear, Net, ReLU\n\ntrain, val, _ = digits.load()\nn = len(train[1])\nfor batch in (1, 32, 100, 1077):\n    steps = math.ceil(n / batch)\n    print(f\"batch {batch:4d}: {steps:4d} steps an epoch, the last one {n - (steps - 1) * batch} images\")",
      "note": "Primeiro a aritmética. Uma época corta as 1.077 imagens de treino em lotes, e o último lote fica com o que sobrar, então o número de passos é a divisão arredondada para cima."
    },
    {
      "code": "class Counting(SGD):\n    \"\"\"SGD that also counts how many times it was asked to step.\"\"\"\n\n    def __init__(self, params, lr):\n        super().__init__(params, lr)\n        self.steps = 0\n\n    def step(self):\n        super().step()\n        self.steps += 1",
      "note": "Depois, uma conferência que não confia na aritmética. Este otimizador é o SGD da aula 5 com um contador a mais, e o `fit` chama `step` uma vez por lote sem perceber a diferença."
    },
    {
      "code": "rng = np.random.default_rng(0)\nnet = Net(Linear(64, 64, rng), ReLU(), Linear(64, 10, rng))\nopt = Counting(net.params(), 0.1)\nfit(net, opt, train, val, epochs=3)\nprint(\"steps counted in 3 epochs:\", opt.steps)",
      "note": "A rede que todas as execuções desta aula treinam: 64 entradas, 64 unidades ocultas, 10 saídas. O `fit` fica com o lote padrão de 32."
    }
  ]
}
```

```
PENDING steps
```

**Com lote de 32, uma época tem 34 passos**, e três épocas fizeram 102 chamadas a `step`, exatamente
3 × 34. 1.077 não é múltiplo de 32, então 33 lotes cheios levam 1.056 imagens e **o último lote fica
com as 21 que sobram**. Com lote de 100 a sobra é 77, e com lote de 1 não há sobra, porque cada lote é
uma imagem só.

## O que a sobra faz

O lote de 21 imagens recebe um passo inteiro, na mesma taxa dos outros. O gradiente dele é uma média
sobre 21 imagens em vez de 32, então é uma estimativa um pouco mais ruidosa, e nada mais nele é
especial. O `fit` também informa a perda de treino como a média simples das 34 perdas de lote, então
essas 21 imagens pesam tanto quanto um lote cheio de 32 nesse número. Os dois efeitos são pequenos com
34 passos por época. Alguns laços descartam o lote curto, e o `DataLoader` do PyTorch tem uma opção
para isso que a aula 10 usa.

**O `fit` embaralha de novo no começo de cada época.** `rng.permutation(len(y))` roda uma vez por
passada, então a época 2 não repete os 34 lotes da época 1: toda imagem volta, em outra companhia. Sem
o novo embaralhamento, a rede veria para sempre as mesmas 34 médias, na mesma ordem.

## Qual relógio citar

Épocas dizem quantas vezes a rede viu cada imagem. Passos dizem quantas vezes os pesos se moveram.
Enquanto o tamanho do lote fica fixo, os dois são o mesmo relógio em unidades diferentes: dez épocas
com lote 32 são sempre 340 passos. **No momento em que o tamanho do lote muda, eles deixam de
concordar**, e "treinou por dez épocas" já não diz quanto treinamento houve. A próxima seção muda o
lote.
