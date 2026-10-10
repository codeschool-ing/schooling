---
title: Como ler uma curva de treinamento
version: 1
---

Uma curva de treinamento costuma ser lida num olhar: descendo é bom, o último número é o resultado.
**Quase tudo o que uma curva diz está nos detalhes que esse olhar pula**: qual linha é medida quando,
quanto do movimento é ruído, e onde a melhora deixou de valer o tempo. Esta seção lê uma execução
linha por linha.

Salve isto como `~/dl/curve.py`. Ele treina a rede de sempre por quarenta épocas com o `fit`
imprimindo cada uma, e depois resume a execução:

```schooling-example
{
  "language": "python",
  "file": "curve.py",
  "parts": [
    {
      "code": "\"\"\"curve: one training run, every epoch printed, and the numbers that say where to stop.\"\"\"\nimport numpy as np\n\nimport digits\nfrom fit import fit\nfrom optim import SGD\nfrom tinynet import Linear, Net, ReLU\n\ntrain, val, _ = digits.load()\nrng = np.random.default_rng(0)\nnet = Net(Linear(64, 64, rng), ReLU(), Linear(64, 10, rng))\nhistory = fit(net, SGD(net.params(), 0.3), train, val, epochs=40)",
      "note": "Quarenta épocas a uma taxa de 0,3, com o `fit` imprimindo cada uma delas. A taxa é mais alta que a do resto da aula para que a execução chegue ao seu platô dentro das quarenta épocas."
    },
    {
      "code": "epoch, train_loss, val_loss, val_acc = (np.array(column) for column in zip(*history))\nprint(f\"lowest val loss  {val_loss.min():.4f} at epoch {epoch[val_loss.argmin()]}\")\nprint(f\"highest val acc  {val_acc.max():.3f} at epoch {epoch[val_acc.argmax()]}\")\nfor first in range(1, 41, 10):\n    window = slice(first - 1, first + 9)\n    print(f\"epochs {first:2d}-{first + 9:2d}  mean val loss {val_loss[window].mean():.4f}  \"\n          f\"mean val acc {val_acc[window].mean():.3f}\")",
      "note": "O `history` guarda uma tupla por época, e `zip(*history)` a transforma em quatro colunas. A melhor época isolada é impressa, e também a média de cada bloco de dez, que lê por cima do ruído de uma época só."
    }
  ]
}
```

```
PENDING curve
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 330\" role=\"img\" aria-label=\"Perdas de treino e de validação nas 40 épocas do curve.py, em escala logarítmica. A perda de treino começa em 1,29, acima da perda de validação de 0,60, e cai sem parar até cerca de 0,02. A perda de validação cai depressa até cerca de 0,11 na época 12, depois se achata e oscila entre cerca de 0,08 e 0,11 de uma época para outra, com o ponto mais baixo, 0,0774, na época 38.\"><path d=\"M80 270 L600 270\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M80 270 L80 30\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M76 270.0 L600 270.0\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72\" y=\"270.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">0.01</text><path d=\"M76 238.60223504452495 L600 238.60223504452495\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72\" y=\"238.60223504452495\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">0.02</text><path d=\"M76 197.0966474332126 L600 197.0966474332126\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72\" y=\"197.0966474332126\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">0.05</text><path d=\"M76 165.69888247773753 L600 165.69888247773753\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72\" y=\"165.69888247773753\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">0.1</text><path d=\"M76 134.30111752226247 L600 134.30111752226247\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72\" y=\"134.30111752226247\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">0.2</text><path d=\"M76 92.79552991095014 L600 92.79552991095014\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72\" y=\"92.79552991095014\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">0.5</text><path d=\"M76 61.39776495547508 L600 61.39776495547508\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72\" y=\"61.39776495547508\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">1</text><path d=\"M76 30.0 L600 30.0\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72\" y=\"30.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">2</text><text x=\"80.0\" y=\"286\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">1</text><text x=\"200.0\" y=\"286\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">10</text><text x=\"333.33333333333337\" y=\"286\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">20</text><text x=\"466.6666666666667\" y=\"286\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">30</text><text x=\"600.0\" y=\"286\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">40</text><text x=\"340.0\" y=\"308\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">época</text><text x=\"88\" y=\"14\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">perda (escala log)</text><path d=\"M612 40 L636 40\" stroke=\"var(--amber)\" stroke-width=\"2.2\" fill=\"none\"></path><text x=\"612\" y=\"56\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">perda de treino</text><path d=\"M612 86 L636 86\" stroke=\"var(--phosphor)\" stroke-width=\"2.2\" fill=\"none\"></path><text x=\"612\" y=\"102\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">perda de validação</text></svg>", "caption": "As 40 épocas do `curve.py`, desenhadas a partir das linhas que ele imprimiu. A perda de treino continua caindo; a de validação deixa de acompanhá-la por volta da época 20 e oscila dentro de uma faixa."}
```

## A primeira época: perda de treino acima da de validação

Na época 1 a perda de treino é **1,2885 e a de validação 0,6048**, menos da metade. A rede não
encontrou um conjunto mais fácil. Os dois números são medidos em momentos diferentes: o `fit` faz a
média da perda de treino nos 34 lotes da época, enquanto os pesos ainda mudavam, e mede a perda de
validação uma vez, no fim da época, com os pesos depois dos 34 passos. Os primeiros lotes da época 1
foram avaliados por uma rede que não sabia nada, e eles puxam a média para cima.

Então a perda de treino fica atrasada em cerca de meia época. Isso pesa enquanto a perda cai depressa e
deixa de pesar quando a curva se achata: na época 7 as duas estão em 0,1492 e 0,1508. **No começo, uma
perda de treino acima da de validação é contabilidade do laço, não um fato sobre os dados.**

## Quanto do movimento é ruído

A perda de validação foi de 0,1361 na época 9 para **0,1854 na época 10**, e voltou a 0,1248 na época
11. Nada aconteceu na época 10. Com taxa de 0,3 e lotes de 32, cada época termina num lugar um pouco
diferente, e 360 imagens de validação são uma amostra pequena para medir isso.

A acurácia é ainda mais grosseira. Uma imagem de validação é 1/360 do conjunto, 0,0028, então **0,969
e 0,972 diferem por uma imagem**. A maior acurácia da execução, 0,981 na época 29, é seguida por 0,967
na época 30: cinco imagens ganhas, depois cinco perdidas. Ler a melhor época como a melhor rede é ler
um sorteio de sorte como resultado.

O remédio é tirar médias. Os blocos de dez épocas no fim da saída dizem o que as épocas isoladas não
conseguem:

| épocas | perda de validação média | melhora sobre o bloco anterior |
| --- | --- | --- |
| 1–10 | 0,2497 | |
| 11–20 | 0,1133 | 0,1364 |
| 21–30 | 0,0975 | 0,0158 |
| 31–40 | 0,0868 | 0,0107 |

## Onde parar

**A perda de treino nunca para de cair**: 0,0198 na época 40, e continuaria. Ela mede o quanto a rede
se ajusta às imagens em que treina, e com épocas suficientes ela se ajusta a quase todas. A decisão de
parar vem da perda de validação, e aqui ela melhorou 0,0107 nas últimas dez épocas, enquanto uma única
época a moveu mais do que isso: de 0,0774 na época 38 para 0,0946 na época 39. **Quando a melhora de
um bloco é menor que a oscilação dentro dele, mais épocas compram pouco**, e esta execução chega a esse
ponto em algum lugar entre as épocas 30 e 40.

As duas medidas de validação também discordam sobre o melhor momento: a menor perda está na época 38 e
a maior acurácia na época 29. Isso é comum, e é por isso que a regra para escolher uma época precisa
ser decidida antes da execução, e não escolhida depois pela coluna que parecer melhor. Guardar os pesos
da melhor época, em vez da última, é o early stopping, e a aula 7 o escreve.

A distância entre as duas linhas, 0,0198 contra 0,0808 na época 40, é a rede indo melhor nas imagens
que já viu do que nas que não viu. **Uma distância, sozinha, é normal.** Uma perda de validação que
vira e sobe enquanto a de treino continua caindo é a forma que preocupa, e a próxima seção a produz.
