---
title: Vinte perguntas, feitas pelos dados
version: 1
---

Uma árvore de decisão prevê fazendo perguntas, uma de cada vez, cada uma sobre uma coluna: *a
avaliação é no máximo 3,6?* Se sim, vá para a esquerda; se não, para a direita; e faça a próxima
pergunta ali. No fim do caminho fica uma **folha**, um grupo de linhas de treino que responderam a
todas as perguntas do mesmo jeito, e a previsão é o que essas linhas fizeram: a parte de quem saiu
entre elas, num classificador.

As perguntas não são escritas por ninguém. O ajuste as escolhe de cima para baixo: a cada passo,
tenta toda coluna e todo lugar onde cortá-la, e fica com o corte que melhor separa as classes. Depois
faz o mesmo dentro de cada uma das duas metades. A escolha é **gulosa**: cada corte é o melhor
disponível naquele momento, sem olhar adiante para ver se um corte pior agora permitiria cortes
melhores depois.

Uma árvore de duas perguntas de profundidade é pequena o bastante para ser impressa inteira. A
`DecisionTreeClassifier` do scikit-learn 1.9 aceita lacunas nas colunas numéricas e decide, a cada
corte, para que lado os valores vazios vão, então as colunas entram como estão. Salve isto como
`first_tree.py`:

```python
# first_tree.py
from sklearn.tree import DecisionTreeClassifier, export_text

from feira import NUMERIC, by_time, load_churn

train, test = by_time(load_churn())
tree = DecisionTreeClassifier(max_depth=2, random_state=0)
tree.fit(train[NUMERIC], train["churned"])
print(export_text(tree, feature_names=NUMERIC, show_weights=True))
```

```
ana@lab:~/ml$ python first_tree.py
|--- rating_90d <= 3.60
|   |--- complaints_90d <= 0.50
|   |   |--- weights: [1861.00, 525.00] class: 0
|   |--- complaints_90d >  0.50
|   |   |--- weights: [543.00, 353.00] class: 0
|--- rating_90d >  3.60
|   |--- skips_90d <= 2.50
|   |   |--- weights: [32333.00, 1091.00] class: 0
|   |--- skips_90d >  2.50
|   |   |--- weights: [1690.00, 232.00] class: 0
```

A primeira pergunta é a **avaliação**, e é o mesmo corte que a melhor regra isolada achou na aula 2:
até 3,6, de um lado. A segunda pergunta muda conforme o lado. Entre as pessoas de avaliação baixa, a
árvore pergunta das **reclamações**; entre as de avaliação boa, dos **pulos**. Isso é algo que nenhuma
regra isolada faria: uma pergunta seguinte diferente para cada tipo de assinante.

Os `weights` são as linhas de treino em cada folha, quem fica primeiro e quem sai depois. A folha de
avaliação baixa e pelo menos uma reclamação tem 543 que ficaram e 353 que saíram, então a chance de
sair ali, para a árvore, é 353 ÷ 896, uns **39%**. Toda folha diz `class: 0`, *fica*, porque em toda
folha quem fica é maioria. **A classe prevista de uma árvore esconde quase tudo; as probabilidades são
a parte útil**, e no ponto de equilíbrio de 28% da aula 2, a folha de 39% merece um crédito.
