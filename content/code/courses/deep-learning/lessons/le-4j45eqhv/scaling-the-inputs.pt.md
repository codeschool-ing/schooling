---
title: A escala das entradas
version: 1
---

Uma crença comum é que a escala das entradas é um detalhe que a rede absorve: se os pixels forem 16
vezes maiores, a primeira camada aprende pesos 16 vezes menores e nada mais muda. **Os pesos chegariam
lá no fim, mas a escala decide como o treino chega lá, e pode impedir que ele chegue.** O gradiente de
um peso da primeira camada é a entrada vezes o gradiente que vem de cima, então entradas 16 vezes
maiores tornam cada passo nesses pesos 16 vezes maior, e cada um desses passos move as somas da camada
16 vezes mais longe ainda.

O `digits.py` da aula 1 divide os níveis de tinta por 16. O programa abaixo desfaz isso e testa
também uma terceira versão, padronizada, em que cada pixel tem média 0 e desvio-padrão 1 no conjunto
de treino. Ele usa o `tinynet.py` da aula 3 e o `optim.py` e o `fit.py` da aula 5, que devem estar
ao lado dele em `~/dl`. Salve como `~/dl/scale.py`:

```schooling-example
{
  "language": "python",
  "file": "scale.py",
  "parts": [
    {
      "code": "\"\"\"scale: the same network and the same rates, on the digits at three scales.\"\"\"\nimport numpy as np\n\nimport digits\nfrom fit import fit\nfrom optim import SGD\nfrom tinynet import Linear, Net, ReLU, softmax_cross_entropy\n\n(x, y), (xv, yv), _ = digits.load()\nmean, std = x.mean(axis=0), x.std(axis=0)\nstd[std == 0] = 1\nscales = {\"0 to 16\": (x * 16, xv * 16),\n          \"0 to 1\": (x, xv),\n          \"standardised\": ((x - mean) / std, (xv - mean) / std)}",
      "note": "Três versões das mesmas imagens. O `digits.py` divide por 16, então multiplicar por 16 devolve os níveis de tinta brutos. Padronizar leva cada pixel a média 0 e desvio-padrão 1, com estatísticas só do conjunto de treino. Alguns pixels estão em branco em toda imagem de treino e têm desvio 0, então são divididos por 1."
    },
    {
      "code": "def make():\n    rng = np.random.default_rng(0)\n    return Net(Linear(64, 64, rng), ReLU(), Linear(64, 10, rng))",
      "note": "A mesma semente toda vez, então as três execuções partem de pesos idênticos. Só as entradas mudam."
    },
    {
      "code": "for name, (a, _) in scales.items():\n    net = make()\n    loss, _ = softmax_cross_entropy(net.forward(a), y)\n    print(f\"{name:13s} first-layer sums: std {net.layers[0].forward(a).std():6.2f}\"\n          f\"   loss before training {loss:.2f}\")",
      "note": "Antes de qualquer treino: quão espalhadas estão as somas da primeira camada, e a perda que a rede sem treino marca."
    },
    {
      "code": "print(\"\\nval accuracy after 20 epochs of SGD\")\nprint(\"rate   \" + \"\".join(f\"{name:>14s}\" for name in scales))\nfor lr in (0.01, 0.1, 0.3, 1.0):\n    row = []\n    for a, b in scales.values():\n        net = make()\n        with np.errstate(all=\"ignore\"):\n            history = fit(net, SGD(net.params(), lr), (a, y), (b, yv), epochs=20, every=1000)\n        row.append(history[-1][3])\n    print(f\"{lr:<7}\" + \"\".join(f\"{acc:14.3f}\" for acc in row))",
      "note": "Doze execuções do `fit` da aula 5, quatro taxas por três escalas. `every=1000` evita que ele imprima cada época, e o `errstate` cala os avisos do NumPy quando uma execução estoura. A tabela guarda a acurácia de validação da última época."
    }
  ]
}
```

```
ana@vm:~/dl$ python scale.py
0 to 16       first-layer sums: std  11.09   loss before training 15.42
0 to 1        first-layer sums: std   0.69   loss before training 2.45
standardised  first-layer sums: std   1.39   loss before training 2.77

val accuracy after 20 epochs of SGD
rate          0 to 16        0 to 1  standardised
0.01            0.947         0.897         0.900
0.1             0.942         0.956         0.958
0.3             0.089         0.969         0.969
1.0             0.111         0.978         0.978
```

**Os pixels brutos fazem estrago antes do primeiro passo.** As somas da primeira camada se espalham
com desvio-padrão de 11,09 em vez de 0,69, e a rede sem treino marca uma perda de 15,42. Uma rede que
chutasse por igual entre dez classes marcaria ln 10, cerca de 2,30, então esta começa confiante e
errada. O `Linear` do tinynet sorteia os pesos iniciais pensando em entradas de tamanho perto de 1, e
entradas de 16 quebram essa suposição de cara.

A tabela pede leitura cuidadosa. Na taxa 0,01 os pixels brutos chegam a 0,947 contra 0,897 dos pixels
entre 0 e 1, o que parece uma vitória de quem não fez nada. São os passos maiores: numa taxa pequena,
a execução com passos 16 vezes maiores anda mais em 20 épocas. Em 0,3 e 1,0 a execução bruta termina
em 0,089 e 0,111, mais ou menos uma resposta certa em dez, enquanto a escalada sobe até 0,969 e 0,978.
**A escala das entradas faz parte da taxa de aprendizado.** Uma taxa ajustada para uma escala está
errada para outra, e a faixa de taxas que funcionam é mais estreita para a escala maior.

A coluna padronizada fica perto da coluna de 0 a 1 em todas as taxas, porque todo pixel aqui é medido
na mesma unidade e dividir por 16 já bastava. Padronizar vale a pena quando os atributos vêm em
unidades diferentes, um valor em reais ao lado de uma idade em anos, em que nenhuma taxa única serve
para os dois. Duas regras de `machine-learning` continuam valendo. A média e o desvio saem do conjunto
de treino e são aplicados como estão à validação e ao teste, e são guardados com o modelo, porque uma
previsão feita um mês depois precisa da mesma transformação.

**Escalar as entradas conserta a primeira camada e nada depois dela.** As entradas da segunda camada
são as saídas da primeira, a escala delas é a que os pesos fizerem, e muda a cada passo. A próxima
seção aplica o mesmo conserto a todas as camadas, durante o treino.
