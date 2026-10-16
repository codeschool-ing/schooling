---
title: Categorias, e as barras que são médias
version: 1
---

**O `sns.barplot` não desenha contagens. Ele desenha a média de uma coluna para cada categoria, com uma
barra de erro, e a barra de erro vem de reamostragem aleatória.** Os dois fatos surpreendem quem
esperava o gráfico que teria desenhado à mão, e o segundo muda o gráfico toda vez que ele roda.

A duração média de viagem por plano:

```python
fig, ax = plt.subplots(figsize=(6, 3.5), layout="constrained")
sns.barplot(data=trips, x="plan", y="minutes", ax=ax)
[round(bar.get_height(), 2) for bar in ax.patches]
```

```
[np.float64(22.64), np.float64(14.12)]
```

As barras são as médias, 22,64 minutos para os passes diários e 14,12 para os assinantes, na ordem em
que os planos aparecem primeiro na tabela. A linha preta em cada barra é um **intervalo de confiança de
95%** para aquela média: um intervalo construído de modo que, se as viagens fossem coletadas de novo
muitas vezes, 95 intervalos assim em 100 conteriam a média verdadeira.

O seaborn o estima por **bootstrap**: tira mil amostras aleatórias de cada grupo, com reposição, calcula
a média de cada uma, e informa o intervalo dos 95% do meio. Amostras aleatórias querem dizer que as
pontas da linha se mexem um pouco a cada execução:

```python
ends = []
for _ in range(2):
    fig, ax = plt.subplots()
    sns.barplot(data=trips, x="plan", y="minutes", ax=ax)
    ends.append([round(line.get_ydata()[0], 3) for line in ax.lines])
    plt.close(fig)
ends[0] == ends[1]
```

```
False
```

Duas execuções do mesmo código desenharam barras de erro diferentes. A diferença é pequena, um
centésimo de minuto ou por aí, e é exatamente o tipo de diferença de que a aula 8 tratou: um notebook
que dá uma imagem diferente a cada execução não pode ser conferido contra si mesmo. O `seed=` resolve:

```python
ends = []
for _ in range(2):
    fig, ax = plt.subplots()
    sns.barplot(data=trips, x="plan", y="minutes", seed=8, ax=ax)
    ends.append([round(line.get_ydata()[0], 3) for line in ax.lines])
    plt.close(fig)
ends[0] == ends[1], ends[0]
```

```
(True, [np.float64(22.419), np.float64(14.024)])
```

## Quando você queria contagens

Para desenhar quantas viagens cada plano teve, o `countplot` conta as linhas:

```python
fig, ax = plt.subplots(figsize=(6, 3.5), layout="constrained")
sns.countplot(data=trips, x="plan", ax=ax)
[int(bar.get_height()) for bar in ax.patches]
```

```
[9899, 23438]
```

9.899 e 23.438, as contagens da aula 13. **Um gráfico de barras responde "quantos" ou "quanto em
média", e os dois parecem iguais**; o rótulo do eixo é a única coisa que diz ao leitor qual, então
defina-o. E quando a barra de erro não faz parte do ponto, `errorbar=None` a deixa de fora em vez de
deixar o leitor adivinhando o que ela quer dizer.
