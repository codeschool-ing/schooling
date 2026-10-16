---
title: Quando os números do negócio se movem
version: 1
---

O corte de equilíbrio é 40 / (0,3 × 480), e desses três números só um é um preço. R$ 40 é o que o
crédito custa, e o financeiro sabe isso ao centavo. R$ 480 é uma média sobre assinantes passados, uma
estimativa, mas estável. **Os 30% são um palpite**: a parte de quem sai que um crédito segura foi medida
uma vez, num teste pequeno, e ninguém se surpreenderia se a verdade fosse 20% ou 40%.

Então, antes de defender um corte, descubra quanto a resposta depende do palpite. Salve isto como
`sensitivity.py`; ele dá preço a todo corte sob cinco valores da parte segurada:

```python
# sensitivity.py
import numpy as np
import pandas as pd

from feira import CREDIT, KEPT

scores = pd.read_csv("scores.csv")
left = scores["churned"] == 1
cuts = np.round(np.arange(0.05, 0.51, 0.01), 2)

def value(saved, cut):
    send = scores["chance"] >= cut
    return saved * KEPT * (left & send).sum() - CREDIT * send.sum()

print("kept by a credit   break-even   best cut   net there   net at 0.278")
for saved in [0.2, 0.25, 0.3, 0.35, 0.4]:
    values = [value(saved, cut) for cut in cuts]
    print(f"{saved:16.0%}   {CREDIT / (saved * KEPT):10.3f}   {cuts[np.argmax(values)]:8.2f}"
          f"   R$ {max(values):6,.0f}   R$ {value(saved, CREDIT / (0.3 * KEPT)):7,.0f}")
```

O `net_value` do `feira.py` usa os 30% que recebeu, então este programa escreve a mesma conta com a
parte como argumento.

```
ana@lab:~/ml$ python sensitivity.py
kept by a credit   break-even   best cut   net there   net at 0.278
             20%        0.417       0.39   R$  5,968   R$   4,968
             25%        0.333       0.24   R$ 13,680   R$  13,320
             30%        0.278       0.23   R$ 23,832   R$  21,672
             35%        0.238       0.19   R$ 35,272   R$  30,024
             40%        0.208       0.19   R$ 47,488   R$  38,376
```

Leia em duas direções.

**Descendo pelas colunas de dinheiro, o palpite importa enormemente.** Com 20%, o programa todo faz
cerca de R$ 6.000 em seis meses; com 40%, umas oito vezes isso. Se o crédito de retenção vale a pena
rodar depende muito mais desse número do que de qualquer escolha deste curso. Vale dizer isso a quem é
dono dele, com todas as letras, antes que alguém gaste um mês ajustando o modelo: **um teste melhor do
crédito vale mais que um modelo melhor.**

**Atravessando as colunas de corte, o palpite importa bem menos.** O melhor corte vai de 0,39 a 0,19
conforme a parte sobe. Manter 0,278 seja qual for a verdade custa pouco se o crédito funcionar pior que
o esperado: cerca de R$ 1.000 com 20% e R$ 360 com 25%. Custa mais se funcionar melhor, R$ 5.248 com
35% e R$ 9.112 com 40%, porque ali um corte alto demais e o problema de setembro empurram para o mesmo
lado. Um corte só é tão bom quanto os números de onde foi calculado, e o jeito mais barato de
protegê-lo é recalculá-lo sempre que um deles mudar.

**É por isso que o corte pertence ao negócio.** Quem faz ciência de dados é dono da curva: das chances,
da calibração delas e da tabela acima. Quem é dono do crédito, da margem e do teste é dono dos três
números de onde o corte é calculado, e deve conseguir ler o que acontece quando muda um deles. A Ana
põe a tabela na frente dessas pessoas em vez de um número só, com a linha de equilíbrio calculada com o
que elas combinaram por último.
