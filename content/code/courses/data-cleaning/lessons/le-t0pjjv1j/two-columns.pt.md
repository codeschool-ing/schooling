---
title: Duas colunas de cada vez
version: 1
---

Pedidos com mais itens custam mais? A resposta óbvia é sim, e uma correlação deveria mostrar isso.
Dois tipos de correlação, e o primeiro de novo sem as empresas:

```
ana@lab:~/clean$ python -c "from explore import delivered as d; print(round(d['items'].corr(d['total']), 3), round(d['items'].rank().corr(d['total'].rank()), 3)); h = d[~d['corporate']]; print(round(h['items'].corr(h['total']), 3))"
0.224 0.644
0.427
```

**A correlação de Pearson é 0,224**, o que se lê como uma relação fraca. **A de Spearman é 0,644**,
o que se lê como uma relação forte, e aqui ela é calculada do jeito que é definida: a fórmula de
Pearson aplicada aos postos em vez dos valores. As duas discordam porque medem coisas diferentes. A
de Pearson mede quão bem uma reta se ajusta aos valores, e dezesseis pedidos corporativos de
milhares de reais cada ficam longe de qualquer reta que passe pelas cestas das famílias. A de
Spearman só pergunta se mais itens tendem a vir com um total maior, e para a maioria dos pedidos
vêm.

O terceiro número confirma o diagnóstico: **sem os pedidos corporativos, a de Pearson sobe para
0,427**. Um punhado de linhas extremas a tinha cortado quase pela metade. Quando os dois
coeficientes discordam tanto, a diferença já é uma descoberta: alguma coisa nos dados está longe do
resto, e vale achá-la antes de citar qualquer um dos números.

Nem todo par de colunas tem relação, e isso também é descoberta:

```
ana@lab:~/clean$ python -c "import pandas as pd; from explore import delivered as d; print(pd.crosstab(d['channel'], d['payment'], normalize='index').round(3).to_string())"
payment  boleto   card    pix
channel                      
app       0.048  0.553  0.398
site      0.052  0.549  0.399
```

Cada linha soma 1. Cartão, Pix e boleto são usados quase exatamente nas mesmas proporções no
aplicativo e no site, dentro de um ponto percentual. **Ausência de relação é um resultado**: diz que
uma campanha de Pix no aplicativo partiria do mesmo lugar que uma no site.

Dois cuidados acompanham toda relação encontrada desse jeito:

- **Correlação não é causa.** Pedidos com mais itens custam mais porque cada item custa alguma
  coisa, o que é uma causa; mas a maior parte das correlações num conjunto de dados de negócio não
  tem um mecanismo tão óbvio, e uma terceira coluna, o mês ou o cliente, muitas vezes move as duas.
- **Uma relação sobre todas as linhas pode esconder grupos** que se comportam diferente, como os
  pedidos corporativos aqui. Vale a regra da aula 9: olhe quem está longe do resto antes de resumir
  todo mundo.
