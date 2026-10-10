---
title: Gradientes que desaparecem
version: 1
---

Dos anos 1980 até por volta de 2010, as camadas ocultas da maioria das redes usaram a sigmoid, e
redes com mais de algumas camadas eram conhecidas por treinar mal. A explicação comum era que redes profundas eram
simplesmente difíceis demais. **A regra da cadeia diz exatamente o que estava errado, e é um
produto.** O gradiente que chega à primeira camada foi multiplicado por uma derivada local para cada
camada acima dela, e a derivada local de uma sigmoid é no máximo 0,25. Dez fatores desse tamanho
multiplicados dão quase nada.

O programa monta duas redes de dez camadas que só diferem na função entre as camadas, roda um
backward pass em cada uma antes de qualquer treino, e imprime o tamanho do gradiente dos pesos de
cada camada. Depois treina as duas. Salve como `~/dl/vanish.py`:

```schooling-example
{
  "language": "python",
  "file": "vanish.py",
  "parts": [
    {
      "code": "\"\"\"vanish: the gradient reaching each layer of a ten-layer net, sigmoid against ReLU.\"\"\"\nimport numpy as np\n\nimport digits\nimport tinynet"
    },
    {
      "code": "class Sigmoid:\n    \"\"\"1 / (1 + e^-x) on the way forward; its slope, never above 0.25, on the way back.\"\"\"\n\n    def forward(self, x):\n        self.out = 1 / (1 + np.exp(-x))\n        return self.out\n\n    def backward(self, grad):\n        return grad * self.out * (1 - self.out)",
      "note": "Uma camada sigmoid escrita na interface do `tinynet`: o `forward` guarda o que o `backward` precisa. A inclinação `out·(1−out)` vale 0,25 no centro e menos em qualquer outro lugar."
    },
    {
      "code": "def deep(activation, rng):\n    layers = [tinynet.Linear(64, 32, rng), activation()]\n    for _ in range(8):\n        layers += [tinynet.Linear(32, 32, rng), activation()]\n    return tinynet.Net(*layers, tinynet.Linear(32, 10, rng))",
      "note": "Dez camadas `Linear` de 32 unidades, com uma ativação entre cada par. As duas redes só diferem nessa função: mesmas larguras, mesma semente, mesmos pesos iniciais."
    },
    {
      "code": "(x, y), (x_val, y_val), _ = digits.load()\nnorms = {}\nfor name, activation in ((\"sigmoid\", Sigmoid), (\"relu\", tinynet.ReLU)):\n    net = deep(activation, np.random.default_rng(0))\n    _, grad = tinynet.softmax_cross_entropy(net.forward(x[:64]), y[:64])\n    net.backward(grad)\n    norms[name] = [np.linalg.norm(layer.dW) for layer in net.layers[::2]]\n\nprint(\"layer   sigmoid      relu\")\nfor i, (s, r) in enumerate(zip(norms[\"sigmoid\"], norms[\"relu\"]), start=1):\n    print(f\"{i:5d}  {s:9.2e}  {r:9.2e}\")",
      "note": "Um backward pass em 64 imagens, antes de qualquer treino. A norma do gradiente dos pesos de uma camada é um número só para o quanto essa camada está sendo empurrada a mudar. A camada 1 fica junto da entrada e a 10 junto da perda."
    },
    {
      "code": "for name, activation in ((\"sigmoid\", Sigmoid), (\"relu\", tinynet.ReLU)):\n    rng = np.random.default_rng(0)\n    net = deep(activation, rng)\n    for epoch in range(10):\n        order = rng.permutation(len(y))\n        for start in range(0, len(order), 32):\n            rows = order[start:start + 32]\n            _, grad = tinynet.softmax_cross_entropy(net.forward(x[rows]), y[rows])\n            net.backward(grad)\n            for value, gradient in net.params():\n                value -= 0.1 * gradient\n    accuracy = (net.forward(x_val).argmax(axis=1) == y_val).mean()\n    print(f\"{name:7s} after 10 epochs: val accuracy {accuracy:.3f}\")",
      "note": "E o que isso faz ao treino: o laço do `train.py`, dez épocas, a mesma taxa para as duas."
    }
  ]
}
```

```
ana@vm:~/dl$ python vanish.py
layer   sigmoid      relu
    1   2.05e-05   1.21e+00
    2   4.32e-05   7.12e-01
    3   1.33e-04   5.92e-01
    4   4.27e-04   1.10e+00
    5   1.53e-03   8.41e-01
    6   4.41e-03   7.24e-01
    7   2.00e-02   7.71e-01
    8   7.27e-02   7.34e-01
    9   2.94e-01   9.00e-01
   10   8.44e-01   5.89e-01
sigmoid after 10 epochs: val accuracy 0.106
relu    after 10 epochs: val accuracy 0.850
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 640 330\" role=\"img\" aria-label=\"Norma do gradiente de cada uma das dez camadas antes do treino, em escala logarítmica. Os dez valores da rede ReLU ficam entre cerca de 0,6 e 1,2. Os da rede sigmoid caem numa linha quase reta na escala log, de 0,844 na camada 10 a 0,0000205 na camada 1.\"><path d=\"M90 260.0 L560 260.0\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"80\" y=\"260.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">1e-5</text><path d=\"M90 223.33333333333334 L560 223.33333333333334\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"80\" y=\"223.33333333333334\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">1e-4</text><path d=\"M90 186.66666666666666 L560 186.66666666666666\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"80\" y=\"186.66666666666666\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">1e-3</text><path d=\"M90 150.0 L560 150.0\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"80\" y=\"150.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">1e-2</text><path d=\"M90 113.33333333333333 L560 113.33333333333333\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"80\" y=\"113.33333333333333\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">1e-1</text><path d=\"M90 76.66666666666666 L560 76.66666666666666\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"80\" y=\"76.66666666666666\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">1e0</text><path d=\"M90 40.0 L560 40.0\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"80\" y=\"40.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">1e1</text><text x=\"90.0\" y=\"278\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">1</text><text x=\"142.22222222222223\" y=\"278\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">2</text><text x=\"194.44444444444446\" y=\"278\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">3</text><text x=\"246.66666666666666\" y=\"278\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">4</text><text x=\"298.8888888888889\" y=\"278\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">5</text><text x=\"351.1111111111111\" y=\"278\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">6</text><text x=\"403.3333333333333\" y=\"278\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">7</text><text x=\"455.55555555555554\" y=\"278\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">8</text><text x=\"507.77777777777777\" y=\"278\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">9</text><text x=\"560.0\" y=\"278\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">10</text><path d=\"M90 40 L90 260\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M90 260 L560 260\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M90.0 248.6 L142.2 236.7 L194.4 218.8 L246.7 200.2 L298.9 179.9 L351.1 163.0 L403.3 139.0 L455.6 118.4 L507.8 96.2 L560.0 79.4\" stroke=\"var(--amber)\" stroke-width=\"2.2\" fill=\"none\"></path><circle cx=\"90.0\" cy=\"248.6\" r=\"3.5\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></circle><circle cx=\"142.2\" cy=\"236.7\" r=\"3.5\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></circle><circle cx=\"194.4\" cy=\"218.8\" r=\"3.5\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></circle><circle cx=\"246.7\" cy=\"200.2\" r=\"3.5\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></circle><circle cx=\"298.9\" cy=\"179.9\" r=\"3.5\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></circle><circle cx=\"351.1\" cy=\"163.0\" r=\"3.5\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></circle><circle cx=\"403.3\" cy=\"139.0\" r=\"3.5\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></circle><circle cx=\"455.6\" cy=\"118.4\" r=\"3.5\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></circle><circle cx=\"507.8\" cy=\"96.2\" r=\"3.5\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></circle><circle cx=\"560.0\" cy=\"79.4\" r=\"3.5\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></circle><text x=\"365.1111111111111\" y=\"177.0372517195126\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">sigmoid</text><path d=\"M90.0 73.6 L142.2 82.1 L194.4 85.0 L246.7 75.1 L298.9 79.4 L351.1 81.8 L403.3 80.8 L455.6 81.6 L507.8 78.3 L560.0 85.1\" stroke=\"var(--phosphor)\" stroke-width=\"2.2\" fill=\"none\"></path><circle cx=\"90.0\" cy=\"73.6\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></circle><circle cx=\"142.2\" cy=\"82.1\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></circle><circle cx=\"194.4\" cy=\"85.0\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></circle><circle cx=\"246.7\" cy=\"75.1\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></circle><circle cx=\"298.9\" cy=\"79.4\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></circle><circle cx=\"351.1\" cy=\"81.8\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></circle><circle cx=\"403.3\" cy=\"80.8\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></circle><circle cx=\"455.6\" cy=\"81.6\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></circle><circle cx=\"507.8\" cy=\"78.3\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></circle><circle cx=\"560.0\" cy=\"85.1\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></circle><text x=\"168.33333333333331\" y=\"57.63120308839683\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">ReLU</text><text x=\"325.0\" y=\"304\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">camada: a 1 fica junto da entrada, a 10 junto da perda</text><text x=\"30\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">norma do gradiente, escala log</text></svg>", "caption": "Antes de qualquer treino, o gradiente que chega a cada camada. Pelas sigmoids ele encolhe a cada camada que atravessa; pelos ReLUs ele mantém o tamanho."}
```

**Pelas sigmoids, a camada 1 recebe um gradiente de 2.05e-05, onde a camada 10 recebe 8.44e-01**:
umas 41.000 vezes menor, e menor de novo a cada camada no caminho para baixo. Com a mesma taxa para
todas as camadas, as primeiras quase não se mexem, e são elas que transformam pixels em
características. **Depois de dez épocas, a rede sigmoid marca 0,106, que é o acaso para dez
classes.** Ela não aprendeu nada.

**Pelos ReLUs, o gradiente de cada camada fica entre 5.89e-01 e 1.21e+00.** A derivada local do ReLU
é exatamente 1 onde a unidade está ligada, então ele passa o gradiente para baixo sem encolhê-lo. As
mesmas dez camadas chegam a 0,850 nas mesmas dez épocas. Isso ainda fica abaixo do 0,939 que as duas
camadas do `train.py` tinham alcançado na época 10, então a profundidade não sai de graça mesmo quando
o gradiente chega; a aula 12 mostra uma rede mais funda treinando pior que uma rasa, e o que resolveu
isso.

**A imagem no espelho é o gradiente que explode.** Se os fatores passam de 1, porque os pesos são
grandes, o produto cresce camada a camada, e um passo pode jogar os pesos tão longe que o
treino diverge, muitas vezes até virar `nan`.
A proteção comum é o gradient clipping, que limita o tamanho do gradiente antes do passo.

Quase tudo o que tornou redes profundas treináveis depois de 2010 mira em manter esse produto perto
de 1:

| | o que faz | onde |
| --- | --- | --- |
| **ReLU** | uma derivada local de 1 do lado ativo | esta aula |
| **inicialização** | pesos iniciais em escala tal que um sinal mantém o tamanho ao atravessar uma camada; o `Linear` do `tinynet` usa a dispersão √(2/n_in), escolhida para o ReLU | o `tinynet.py` desta aula |
| **normalização** | reescalar as saídas de cada camada durante o treino | aula 8 |
| **conexões residuais** | um caminho em volta de cada bloco, pelo qual o gradiente chega sem ser multiplicado | aula 12 |

Redes recorrentes encontram o mesmo produto ao longo do tempo em vez da profundidade, um fator por
passo da sequência, e a aula 14 o mede lá.
