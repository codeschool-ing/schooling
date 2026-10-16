---
title: melt, do largo de volta ao longo
version: 1
---

**O `melt` transforma colunas em linhas: cada valor de uma tabela larga vira uma linha própria, com
uma coluna dizendo de que coluna ele veio.** É o contrário do `pivot`, e é a ferramenta para quando
uma tabela chega larga e o próximo passo a quer longa.

O `wide` da primeira seção, derretido de volta:

```python
back = wide.reset_index().melt(id_vars="month", var_name="plan", value_name="trips")
back.head(3)
```

```
   month    plan  trips
0      1  annual   2016
1      2  annual   1902
2      3  annual   1983
```

```python
back.shape
```

```
(24, 3)
```

`id_vars` nomeia as colunas que ficam como estão e se repetem em toda linha; todas as outras são
derretidas. `var_name` e `value_name` dão nome às duas colunas novas; sem eles elas se chamam
`variable` e `value`, o que não diz nada. O `reset_index` veio antes porque o `melt` trabalha com
colunas, e no `wide` o mês era o índice.

As linhas saem agrupadas pela coluna antiga, todos os meses de annual e depois todos os de day, onde
o `long` as tinha por mês. O conteúdo é o mesmo; ordene se a ordem importar.

## Medidas guardadas lado a lado

Muitos arquivos chegam largos porque é assim que as pessoas os digitam. O `weather.csv` tem uma linha
por dia e uma coluna por medida:

```python
weather = pd.read_csv("weather.csv")
weather["date"] = pd.to_datetime(weather["date"], format="%Y-%m-%d")
measured = weather.melt(id_vars="date", var_name="measure", value_name="value")
measured.shape, measured["measure"].unique().tolist()
```

```
((730, 3), ['rain_mm', 'temp_max'])
```

Duas medidas de 365 dias são 730 linhas. Esse formato fica pior para uma pessoa e é exatamente o que
o seaborn da aula 19 quer para "uma linha por medida": a medida é uma coluna, então pode ser a cor de
uma linha, onde no formato largo ela fazia parte dos nomes das colunas, fora de alcance.

**Derreter mistura unidades.** Chuva em milímetros e temperatura em graus agora dividem a coluna
`value`, e uma `mean` dessa coluna seria um número sobre nada. O longo é o formato certo para agrupar
e desenhar por `measure`; é o errado para fazer contas entre medidas, que é para o que serve o largo.
