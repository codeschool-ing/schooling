---
title: Agrupando por várias chaves, e o índice que isso cria
version: 1
---

**Agrupe por uma lista de colunas e cada combinação dos valores delas vira um grupo.** O resultado é
indexado por todas as chaves de uma vez, um **MultiIndex**, e ler ou remodelar isso é a segunda
metade desta seção.

```python
per = trips.groupby(["weekday", "plan"]).size()
per.head(4)
```

```
weekday  plan  
Friday   annual    4087
         day       1266
Monday   annual    4050
         day       1344
dtype: int64
```

Um número por dia da semana e plano. O índice tem dois níveis, `weekday` e `plan`, e uma linha é
nomeada pelos dois. Peça um dia da semana e você recebe os planos dele:

```python
per.loc["Sunday"]
```

```
plan
annual    1767
day       1708
dtype: int64
```

Aos domingos os passes diários quase igualam as assinaturas, enquanto nos dias úteis os assinantes
dominam: quem vai ao trabalho é assinante, e quem passeia compra um dia.

## De um resultado longo para uma tabela

Um resultado com duas chaves fica mais fácil de ler como tabela, uma chave descendo pela lateral e
outra atravessando o topo. O `unstack` move o nível mais interno do índice para as colunas:

```python
order = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
table = per.unstack("plan").loc[order]
table
```

```
plan       annual   day
weekday                
Monday       4050  1344
Tuesday      3954  1364
Wednesday    4157  1316
Thursday     3880  1329
Friday       4087  1266
Saturday     1543  1572
Sunday       1767  1708
```

`.loc[order]` põe os dias na ordem do calendário, porque um groupby ordena as chaves alfabeticamente,
e Friday antes de Monday é a ordem do alfabeto, não da semana. A aula 15 trata dessa remodelagem por
inteiro, `unstack`, `pivot_table` e os opostos deles.

## Chaves como colunas em vez de índice

`as_index=False`, ou `reset_index()` depois, mantém as chaves como colunas comuns, que é o formato
que um gráfico ou uma junção quer:

```python
trips.groupby(["weekday", "plan"], as_index=False).size().head(3)
```

```
  weekday    plan  size
0  Friday  annual  4087
1  Friday     day  1266
2  Monday  annual  4050
```
