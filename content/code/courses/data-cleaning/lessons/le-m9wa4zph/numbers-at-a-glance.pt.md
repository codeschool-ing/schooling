---
title: Números num relance: as pontas e o meio
version: 1
---

**Para uma coluna numérica, o perfil acrescenta o resumo que o `statistics` ensinou: o centro, a
dispersão e, sobretudo, as duas pontas.** A maioria dos defeitos de uma coluna numérica mora nas
pontas, porque um erro de digitação ou um marcador é quase sempre muito maior ou muito menor que os
valores honestos em volta.

Os totais dos pedidos, lidos como números desta vez:

```
ana@lab:~/clean$ python -c "import pandas as pd; o = pd.read_csv('raw/orders.csv'); print(o['total'].describe())"
count    28551.000000
mean        94.112222
std        242.545325
min        -17.050000
25%         32.700000
50%         57.600000
75%        106.500000
max      26928.500000
Name: total, dtype: float64
```

Três coisas em oito linhas.

**O mínimo é negativo.** Um total de −R$ 17,05 não é reembolso — reembolsos têm status próprio — e
nada neste negócio paga um cliente por comprar verdura. É a primeira coisa a olhar:

```
ana@lab:~/clean$ python -c "import pandas as pd; o = pd.read_csv('raw/orders.csv'); print(o.loc[o['total'] < 0, ['order_id', 'total', 'discount', 'delivery_fee', 'fulfilment']])"
       order_id  total  discount  delivery_fee fulfilment
144      100145  -2.20      20.0           9.9   delivery
328      100329  -1.85      15.0           9.9   delivery
351      100352  -0.20      10.0           0.0     pickup
800      100801  -4.20      20.0           9.9   delivery
838      100839  -4.20      20.0           9.9   delivery
...         ...    ...       ...           ...        ...
27060    127036  -2.15      20.0           0.0     pickup
27125    127101  -2.10      20.0           0.0     pickup
27914    127890  -6.20      20.0           9.9   delivery
27961    127937  -2.65      20.0           9.9   delivery
28096    128072 -12.10      20.0           0.0     pickup

[137 rows x 5 columns]
```

137 pedidos, todos com um cupom que vale mais que a cesta mais o frete. O pedido de R$ 7,90 com um
cupom de R$ 20,00 foi registrado como −R$ 12,10. O site aceitou um cupom maior que o pedido e o
subtraiu assim mesmo; quanto o cliente realmente pagou é uma pergunta para quem cuida dos
pagamentos, e quase certamente foi zero. **Uma regra que ninguém escreveu — um total não pode ser
negativo — é o tipo de checagem de validade que um perfil sugere**, e a aula 9 decide o que fazer com
essas linhas.

**O desvio padrão, 242,55, é mais de duas vezes e meia a média, 94,11.** Para valores de pedido, que
não descem muito abaixo de zero, isso só acontece quando uns poucos valores ficam muito acima do
resto. A aula 7 do `statistics` chamou isso de cauda longa à direita.

**O máximo é R$ 26.928,50**, contra uma mediana de R$ 57,60. Os percentis mostram onde a cauda
começa:

```
ana@lab:~/clean$ python -c "import pandas as pd; o = pd.read_csv('raw/orders.csv'); print(o['total'].quantile([0.5, 0.9, 0.99, 0.999, 1]))"
0.500       57.6000
0.900      204.4000
0.990      481.2750
0.999      764.3925
1.000    26928.5000
Name: total, dtype: float64
```

Noventa e nove pedidos em cem ficam abaixo de R$ 481,28, e 999 em mil abaixo de R$ 764,39. O maior
é trinta e cinco vezes isso. **O salto do percentil 99,9 para o máximo é o retrato de um valor
atípico numa linha**, e ainda não diz nada sobre se o pedido é real. A aula 9 separa os pedidos
corporativos de Natal, que são reais, dos totais digitados com um zero a mais, que não são.

## Por que não olhar só a média?

Porque a média é puxada exatamente pelos valores que um perfil está procurando. 137 totais negativos
e alguns totais na casa das dezenas de milhares puxam a média em sentidos opostos, e uma média de
R$ 94 parece um número comum. **O mínimo, o máximo e um punhado de percentis não custam nada para
imprimir e são onde o problema aparece.** Os quartis dizem como é um pedido normal, de R$ 32,70 a
R$ 106,50, e essa é a régua para todo o resto.
