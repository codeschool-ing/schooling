---
title: A coluna que é a resposta
version: 1
---

O `churn.csv` tem uma coluna chamada `cancel_reason`. É o tipo de coluna que um cientista de dados
fica feliz de achar: o motivo que o assinante deu para sair, *price*, *quality*, *delivery*,
*moving* ou *other*. Certamente é útil. Salve isto como `obvious.py`:

```python
# obvious.py
import pandas as pd

churn = pd.read_csv("data/churn.csv")
reason = churn["cancel_reason"].fillna("(empty)")
print(pd.crosstab(reason, churn["churned"]))
```

```
ana@lab:~/ml$ python obvious.py
churned            0     1
cancel_reason             
(empty)        59200     0
delivery           0   725
moving             0   546
other              0   559
price              0  1092
quality            0   763
```

**Toda linha com motivo é de quem saiu, e todo mundo que saiu tem motivo.** A coluna não é uma
preditora do alvo; ela é o alvo, escrito em palavras. Ela é preenchida quando o assinante cancela, o
que vem depois do retrato, e no dia 1º, quando o crédito é enviado, está vazia para todo mundo. Um
modelo que a recebesse tiraria nota perfeita e, em uso, veria uma coluna vazia em toda linha e não
preveria nada.

Ninguém poria esta em produção, e é por isso que começamos por ela: ela mostra a forma de todo
vazamento em tamanho natural. **Uma coluna escrita por causa do resultado carrega o resultado.** A
mesma forma, menor, está por trás da maioria dos que chegam à produção:

- uma marca de *reembolso feito*, num modelo de quem vai reclamar;
- uma data de *enviado à cobrança*, num modelo de quem vai ficar inadimplente;
- uma *internação na UTI*, num modelo de quais pacientes estão em estado grave;
- o *número de ligações de acompanhamento*, num modelo de quais contatos de venda vão fechar.

Cada uma é registrada por alguém reagindo ao resultado, e cada uma está, no momento da previsão,
vazia ou em zero.

## O que fazer com ela

Deixe-a fora do modelo, e guarde-a. A `cancel_reason` é inútil para prever quem vai sair e valiosa
para entender por que as pessoas saíram, que é outro projeto com outra entrega: um gráfico para
quem decide o preço, em vez de uma lista para a equipe de retenção. Uma coluna que vaza é uma coluna
na pergunta errada.
