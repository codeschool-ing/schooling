---
title: A taxa de aprendizado é o tamanho do passo
version: 1
---

A taxa de 1,0 do `descent.py` não foi escolhida por regra nenhuma. Ela simplesmente funcionou. **A
taxa de aprendizado define o tamanho de cada passo, e a inclinação não diz nada sobre qual tamanho
é seguro.** Aqui estão quatro taxas nos mesmos dez pontos, a partir do mesmo peso inicial. Salve
como `~/dl/rates.py`:

```python
# rates.py: the same descent at four learning rates, side by side
import numpy as np

from points import x, y

rates = [0.1, 1.0, 2.4, 2.8]
ws = np.zeros(len(rates))
print("step" + "".join(f"{'lr ' + str(lr):>10}" for lr in rates))
for step in range(16):
    print(f"{step:4d}" + "".join(f"{w:10.3f}" for w in ws))
    grads = np.array([np.mean(2 * x * (w * x - y)) for w in ws])
    ws = ws - np.array(rates) * grads

c = 2 * np.mean(x * x)
print(f"curvature {c:.2f}: a rate of {1 / c:.2f} lands in one step, above {2 / c:.2f} it diverges")
```

```
ana@vm:~/dl$ python rates.py
step    lr 0.1    lr 1.0    lr 2.4    lr 2.8
   0     0.000     0.000     0.000     0.000
   1     0.264     2.638     6.331     7.386
   2     0.507     3.244     0.962    -1.152
   3     0.732     3.384     5.515     8.718
   4     0.939     3.416     1.654    -2.692
   5     1.131     3.424     4.928    10.498
   6     1.308     3.425     2.152    -4.749
   7     1.471     3.426     4.506    12.876
   8     1.621     3.426     2.510    -7.499
   9     1.760     3.426     4.203    16.055
  10     1.888     3.426     2.767   -11.173
  11     2.007     3.426     3.984    20.302
  12     2.116     3.426     2.952   -16.084
  13     2.217     3.426     3.827    25.979
  14     2.310     3.426     3.085   -22.645
  15     2.396     3.426     3.715    33.564
curvature 0.77: a rate of 1.30 lands in one step, above 2.60 it diverges
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 660 340\" role=\"img\" aria-label=\"O peso contra o passo, por quinze passos com quatro taxas de aprendizado, com uma linha tracejada no fundo, 3,426. Com 0,1 o peso sobe devagar e chega a 2,396 no passo 15. Com 1,0 chega ao fundo em poucos passos e fica. Com 2,4 pula o fundo até 6,331, volta para 0,962 e ziguezagueia para dentro. Com 2,8 cada ziguezague é mais largo que o anterior e a linha sai do gráfico no passo 7.\"><path d=\"M60 290 L520 290\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M60 290 L60 30\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"60.0\" y=\"306\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">0</text><text x=\"213.33333333333334\" y=\"306\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">5</text><text x=\"366.6666666666667\" y=\"306\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">10</text><text x=\"520.0\" y=\"306\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">15</text><text x=\"46\" y=\"290.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">-6</text><text x=\"46\" y=\"246.66666666666666\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">-3</text><text x=\"46\" y=\"203.33333333333331\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">0</text><text x=\"46\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">3</text><text x=\"46\" y=\"116.66666666666666\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">6</text><text x=\"46\" y=\"73.33333333333334\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">9</text><text x=\"46\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">12</text><text x=\"290.0\" y=\"326\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">passo</text><text x=\"54\" y=\"14\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">o peso w</text><path d=\"M60 203.33333333333331 L520 203.33333333333331\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M60 153.84666666666666 L520 153.84666666666666\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 4\"></path><path d=\"M60.0 203.3 L90.7 199.5 L121.3 196.0 L152.0 192.8 L182.7 189.8 L213.3 187.0 L244.0 184.4 L274.7 182.1 L305.3 179.9 L336.0 177.9 L366.7 176.1 L397.3 174.3 L428.0 172.8 L458.7 171.3 L489.3 170.0 L520.0 168.7\" stroke=\"var(--phosphor-dim)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M60.0 203.3 L90.7 165.2 L121.3 156.5 L152.0 154.5 L182.7 154.0 L213.3 153.9 L244.0 153.9 L274.7 153.8 L305.3 153.8 L336.0 153.8 L366.7 153.8 L397.3 153.8 L428.0 153.8 L458.7 153.8 L489.3 153.8 L520.0 153.8\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M60.0 203.3 L90.7 111.9 L121.3 189.4 L152.0 123.7 L182.7 179.4 L213.3 132.2 L244.0 172.2 L274.7 138.2 L305.3 167.1 L336.0 142.6 L366.7 163.4 L397.3 145.8 L428.0 160.7 L458.7 148.1 L489.3 158.8 L520.0 149.7\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M60.0 203.3 L90.7 96.6 L121.3 220.0 L152.0 77.4 L182.7 242.2 L213.3 51.7 L244.0 271.9 L273.1 30.0\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\" stroke-dasharray=\"5 3\"></path><text x=\"532\" y=\"102.88888888888889\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">lr 2.4</text><text x=\"532\" y=\"118.88888888888889\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">oscila</text><text x=\"532\" y=\"146.22222222222223\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">lr 1.0</text><text x=\"532\" y=\"162.22222222222223\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">na medida</text><text x=\"532\" y=\"189.55555555555554\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor-dim)\">lr 0.1</text><text x=\"532\" y=\"205.55555555555554\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor-dim)\">pequena demais</text><text x=\"284.66666666666663\" y=\"36\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">lr 2.8</text><text x=\"284.66666666666663\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">diverge, sai do gráfico</text><path d=\"M370 268.3333333333333 L394 268.3333333333333\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 4\"></path><text x=\"400\" y=\"268.3333333333333\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">o fundo, 3,426</text></svg>", "caption": "A mesma descida com quatro taxas de aprendizado, desenhada com os números que o `rates.py` imprimiu."}
```

Quatro comportamentos, um por coluna:

- **0,1 se arrasta.** Depois de 15 passos chegou a 2,396 dos 3,426 para onde vai. Vai chegar, mas
  cada passo é uma fração do que o terreno permite.
- **1,0 chega.** Está em 3,424 no passo 5 e em 3,426 no passo 7, e fica ali.
- **2,4 passa do ponto.** O primeiro passo cai em 6,331, muito além do fundo, e o segundo em 0,962,
  do outro lado. Cada travessia cai um pouco mais perto, e ela assenta em ziguezague.
- **2,8 diverge.** Cada passo passa do ponto por mais do que o erro que queria corrigir, então as
  oscilações crescem: 33,564 no passo 15, e a perda junto.

**Para este modelo, onde cada comportamento começa é aritmética.** A inclinação da inclinação, a
**curvatura**, vale 0,77 em toda a parábola. Cada passo multiplica a distância até o fundo por
`1 - lr × 0,77`: com 0,1 isso guarda 92% da distância, com 1,0 guarda 23%, com 2,4 troca o sinal e
guarda 85%, e com 2,8 troca o sinal e aumenta a distância. A última linha imprimiu os dois limites:
1,30 cai no fundo num passo só, e qualquer taxa acima de 2,60 diverge.

Uma rede não tem uma curvatura só. Tem uma para cada direção entre os pesos dela, e elas mudam
conforme os pesos andam, então ninguém calcula a taxa segura de uma rede de verdade. Experimenta-se
algumas, observa-se a perda, e fica-se com a maior que não explode. **Uma perda que cresce passo
após passo é a assinatura de uma taxa alta demais**, e a aula 5 trata de escolhê-la bem.
