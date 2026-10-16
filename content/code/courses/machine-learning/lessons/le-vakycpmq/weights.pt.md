---
title: Lendo os pesos de um modelo linear
version: 1
---

Três grupos de pessoas pedem a um modelo que se explique, e fazem perguntas diferentes. A equipe de
retenção pergunta **por que este assinante** recebeu crédito. Os gestores perguntam **o que move o churn**
em geral. E quem responde pelo modelo pergunta **se ele está fazendo algo que não devia**, que é o assunto
da aula 20. Esta aula monta as ferramentas para as duas primeiras, começando pelo modelo que se explica mais
diretamente.

A previsão de uma regressão logística é uma soma, então os pesos dela são a explicação dela. O pipeline da
aula 15 guarda os nomes das 36 colunas, e os pesos saem na mesma ordem. Salve isto como `weights.py`:

```python
# weights.py
import pandas as pd

from churn_model import build
from feira import by_time, load_churn

train, _ = by_time(load_churn())
model = build().fit(train, train["churned"])
names = model.named_steps["prepare"].get_feature_names_out()
weights = pd.Series(model.named_steps["logistic"].coef_[0], index=names)

numbers = weights[weights.index.str.startswith("numbers__")]
print("numbers, per standard deviation:")
print(numbers.reindex(numbers.abs().sort_values(ascending=False).index[:8]).round(2).to_string())
print("one word column, payment:")
print(weights[weights.index.str.startswith("words__payment")].round(2).to_string())
```

```
ana@lab:~/ml$ python weights.py
numbers, per standard deviation:
numbers__rating_90d       -0.46
numbers__unhappy           0.31
numbers__late_and_new      0.27
numbers__complaints_90d    0.27
numbers__skips_90d         0.23
numbers__gone_quiet        0.18
numbers__tenure_capped    -0.14
numbers__skip_streak       0.14
one word column, payment:
words__payment_boleto   -0.08
words__payment_card     -0.56
words__payment_pix      -0.59
```

**Os números se leem como a aula 5 ensinou**: por desvio padrão, em log-odds. Uma nota mais alta é o que
mais baixa a chance, e cinco das sete colunas da aula 14 estão entre as oito primeiras, `unhappy` em
segundo. O modelo está usando as formas que recebeu.

**As palavras pedem mais cuidado.** Os três pesos de pagamento são negativos, o que parece dizer que todo
jeito de pagar baixa a chance de sair. Não diz. Com uma coluna por valor e nenhum valor descartado, os três
pesos dividem uma constante com o intercepto, e só as **diferenças** entre eles querem dizer algo: o −0,08
do boleto contra o −0,56 do cartão diz que pagar com boleto soma cerca de 0,48 aos log-odds, comparado a
pagar com cartão. Leia os pesos de uma categoria uns contra os outros, nunca um de cada vez.

Mais dois cuidados com pesos, ambos da aula 5 e ambos ainda verdadeiros. Um peso só é comparável a outro
quando as colunas estão na mesma escala, o que a escala do pipeline garante para os números. E **colunas
correlacionadas dividem o peso**: `rating_90d` e `unhappy` descrevem a mesma coisa de dois jeitos, então
nenhum dos dois pesos sozinho diz quanto as notas importam. Juntos dizem.

Um modelo de boosting não tem pesos para ler. O resto da aula é sobre explicar modelos que não se explicam
sozinhos.
