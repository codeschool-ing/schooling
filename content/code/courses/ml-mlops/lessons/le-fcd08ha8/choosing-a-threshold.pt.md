---
title: Escolhendo um limiar pelo que as coisas custam
version: 1
---

O limiar de 0,5 é do scikit-learn, escolhido para ninguém. **Um limiar que vale a pena usar vem de
dois números que o negócio já tem**: quanto custa uma ação, e quanto ela vale quando funciona.

Para esta seção, o marketing os fornece. Um voucher custa **R$ 10,00** para ser mandado. Um membro
que ia se afastar, recebe um e fica vale **R$ 60,00**, mais ou menos o que um membro gasta num mês e
pouco. Esses dois números são do exemplo, escritos no programa para serem fáceis de mudar; os do seu
time de marketing vão ser outros, e o método não. Salve isto como `thresholds.py`:

```python
"""thresholds.py: the same probabilities, cut at different places."""
import features
from model import COLUMNS, trained

VOUCHER = 10.00          # reais: what marketing pays for each voucher sent
SAVED = 60.00            # reais: what a lapsing member who is won back is worth

lapse = trained("2025-09-30")
test = features.build("2025-11-30")
p = lapse.predict_proba(test[COLUMNS])[:, 1]
lapsed = test["lapsed"].to_numpy() == 1

print("threshold  flagged  precision  recall  net value")
for threshold in (0.1, 0.15, 0.2, 0.3, 0.4, 0.5, 0.6):
    flagged = p >= threshold
    caught = (flagged & lapsed).sum()
    value = caught * SAVED - flagged.sum() * VOUCHER
    print(f"{threshold:9.2f}  {flagged.sum():7}  {caught / flagged.sum():9.3f}  "
          f"{caught / lapsed.sum():6.3f}  R$ {value:8.2f}")
```

Para cada limiar o programa conta os membros apontados, os que se afastaram entre eles, e o **valor
líquido**: cada afastamento pego vale R$ 60,00, cada voucher mandado custa R$ 10,00. Ele supõe, com
generosidade, que todo voucher mandado a um membro que ia se afastar o segura; a forma da resposta
sobrevive a uma taxa menor, e os números dela encolhem.

```
ana@dev:~/ml$ python thresholds.py
threshold  flagged  precision  recall  net value
     0.10     1688      0.262   0.834  R$  9640.00
     0.15     1049      0.355   0.702  R$ 11830.00
     0.20      742      0.434   0.608  R$ 11900.00
     0.30      488      0.514   0.474  R$ 10180.00
     0.40      352      0.614   0.408  R$  9440.00
     0.50      248      0.685   0.321  R$  7720.00
     0.60      180      0.750   0.255  R$  6300.00
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" data-fig=\"l04-thresholds\" aria-label=\"Valor líquido de agir com o modelo em cada limiar, a R$ 10,00 por voucher e R$ 60,00 por membro mantido: R$ 9.640 em 0,1, R$ 11.830 em 0,15, R$ 11.900 em 0,2, R$ 10.180 em 0,3, R$ 9.440 em 0,4, R$ 7.720 em 0,5 e R$ 6.300 em 0,6.\"><path d=\"M90.0 40.0 L90.0 220.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M86.0 220.0 L90.0 220.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"82.0\" y=\"220.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><path d=\"M90.0 168.6 L690.0 168.6\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M86.0 168.6 L90.0 168.6\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"82.0\" y=\"168.6\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">4.000</text><path d=\"M90.0 117.1 L690.0 117.1\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M86.0 117.1 L90.0 117.1\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"82.0\" y=\"117.1\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">8.000</text><path d=\"M90.0 65.7 L690.0 65.7\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M86.0 65.7 L90.0 65.7\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"82.0\" y=\"65.7\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">12.000</text><text x=\"90.0\" y=\"26.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">valor líquido, reais</text><path d=\"M90.0 220.0 L690.0 220.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M114.0 220.0 L114.0 96.1 L166.0 96.1 L166.0 220.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><text x=\"140.0\" y=\"233.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0,10</text><path d=\"M197.3 220.0 L197.3 67.9 L249.3 67.9 L249.3 220.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><text x=\"223.3\" y=\"233.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0,15</text><path d=\"M280.7 220.0 L280.7 67.0 L332.7 67.0 L332.7 220.0 Z\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"var(--amber)\"></path><text x=\"306.7\" y=\"233.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0,20</text><path d=\"M364.0 220.0 L364.0 89.1 L416.0 89.1 L416.0 220.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><text x=\"390.0\" y=\"233.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0,30</text><path d=\"M447.3 220.0 L447.3 98.6 L499.3 98.6 L499.3 220.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><text x=\"473.3\" y=\"233.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0,40</text><path d=\"M530.7 220.0 L530.7 120.7 L582.7 120.7 L582.7 220.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><text x=\"556.7\" y=\"233.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0,50</text><path d=\"M614.0 220.0 L614.0 139.0 L666.0 139.0 L666.0 220.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><text x=\"640.0\" y=\"233.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0,60</text><text x=\"390.0\" y=\"251.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">limiar</text><text x=\"306.7\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">melhor: 0,2</text><text x=\"556.7\" y=\"108.7\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">scikit-learn: 0,5</text></svg>", "caption": "O valor tem pico perto de 0,2, perto do custo de um voucher sobre o valor de um membro mantido, e o padrão de 0,5 deixa cerca de um terço para trás."}
```

**O melhor limiar aqui é cerca de 0,2, não 0,5.** Em 0,5 o modelo manda 248 vouchers e vale
R$ 7.720,00; em 0,2 ele manda 742, pega 322 membros que se afastariam em vez de 170, e vale
R$ 11.900,00. Mais abaixo, os vouchers para membros que iam ficar passam a custar mais do que trazem
os acertos a mais.

Há uma regra prática por trás de onde cai o pico. Um voucher se paga quando a chance de o seu membro
se afastar está acima do custo sobre o valor: 10 / 60, cerca de 0,17. **Para um modelo cujas
probabilidades merecem crédito, o melhor limiar fica perto dessa razão**, e é por isso que as duas
próximas seções verificam se estas merecem.

## Um orçamento em vez de um preço

Às vezes o negócio não tem preço, só um limite: *o marketing pode mandar trezentos vouchers este
mês.* Aí não há limiar nenhum a escolher; há uma lista a ordenar. Mande para os trezentos membros com
as maiores probabilidades, e a nota que importa é quantos desses trezentos se afastam. Essa é uma nota
da ordenação, que é a próxima seção.
