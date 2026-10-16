---
title: Um gráfico por grupo, numa chamada
version: 1
---

**O seaborn tem dois tipos de função: as que desenham num axes, e as que fazem uma figura inteira
deles.** `histplot`, `boxplot`, `scatterplot` e `barplot` desenham num axes, o que você passar ou o
atual. `displot`, `catplot` e `relplot` montam uma figura nova com **um axes por grupo**, os pequenos
múltiplos da aula 18, a partir de um só argumento.

O histograma da primeira seção, um painel por plano em vez de duas cores num só:

```python
g = sns.displot(data=trips, x="minutes", col="plan", binwidth=2, height=3, aspect=1.3)
g.set(xlim=(0, 80))
type(g).__name__, g.axes.shape
```

```
('FacetGrid', (1, 2))
```

`col="plan"` criou uma coluna de painéis por valor de `plan`, com a mesma escala vertical nos dois, o
`sharey` da aula 18 por padrão. `height` é a altura de cada painel em polegadas e `aspect` a largura
como múltiplo dela. O que volta não é um `Axes` mas um **`FacetGrid`**, que guarda a figura e o array
de eixos, um por painel.

Essa diferença é a surpresa de sempre. Um `FacetGrid` não tem `set_title` nem `set_xlim`; tem `set`,
que vale para todos os painéis, e `set_titles`, que dá título a eles a partir dos valores dos grupos.
Para qualquer outra coisa, `g.axes` é o array de eixos do matplotlib, e `g.figure` a figura:

```python
g.set_titles("{col_name} plan")
g.set_axis_labels("minutes", "trips")
g.figure.suptitle("Trip lengths by plan", y=1.03)
g.savefig("lengths.png")
[ax.get_title() for ax in g.axes.flat]
```

```
['day plan', 'annual plan']
```

`{col_name}` é preenchido com o valor de `col` de cada painel. `g.savefig` salva a grade inteira, já
com `bbox_inches="tight"`, então os rótulos da aula 18 não são cortados. `row=` acrescenta uma segunda
dimensão de painéis, `col="plan", row="bike"` fazendo uma grade de quatro, e `relplot` e `catplot`
aceitam os mesmos argumentos para dispersões e categorias.

**Qual usar é uma pergunta sobre a comparação.** Cores num axes comparam os grupos no mesmo lugar, o
que funciona para dois ou três grupos que não se sobrepõem muito. Painéis comparam o formato de cada
grupo sozinho, o que funciona para mais grupos, ou para grupos que se esconderiam uns atrás dos outros
num axes só.
