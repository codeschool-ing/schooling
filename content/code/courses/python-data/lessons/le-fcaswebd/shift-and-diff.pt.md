---
title: shift, e a comparação com ontem
version: 1
---

**O `shift(n)` move os valores de uma série `n` passos ao longo do índice, para que cada linha veja a
linha anterior.** Tudo o que compara um momento com outro anterior se apoia nele: a mudança desde
ontem, o crescimento desde a semana passada.

```python
daily.shift(1).head(3)
```

```
started_at
2025-01-01      NaN
2025-01-02    106.0
2025-01-03    108.0
Freq: D, dtype: float64
```

O índice ficou onde estava; os valores deslizaram uma posição para baixo. O primeiro dia não tem nada
antes dele, então recebe `NaN`, e os inteiros viraram floats para guardá-lo. **Um shift sempre deixa
`n` faltantes no começo**, e tudo o que for calculado a partir dele começa com eles também.

A mudança em relação ao dia anterior é a série menos o seu shift, e `diff` é a grafia mais curta:

```python
pd.DataFrame({"trips": daily, "yesterday": daily.shift(1), "change": daily.diff()}).head(4)
```

```
            trips  yesterday  change
started_at                          
2025-01-01    106        NaN     NaN
2025-01-02    108      106.0     2.0
2025-01-03    115      108.0     7.0
2025-01-04     47      115.0   -68.0
```

O `pct_change` divide a mudança pelo valor anterior, uma mudança relativa:

```python
daily.pct_change().round(3).head(3)
```

```
started_at
2025-01-01      NaN
2025-01-02    0.019
2025-01-03    0.065
Freq: D, dtype: float64
```

## Com o que comparar

Dia contra dia mistura a semana: um sábado é mais calmo que uma sexta porque é sábado, e a grade da
aula 15 mostrou quanto. Comparar cada dia com **o mesmo dia da semana uma semana antes** tira o padrão
semanal:

```python
week_change = daily - daily.shift(7)
week_change.head(9)
```

```
started_at
2025-01-01     NaN
2025-01-02     NaN
2025-01-03     NaN
2025-01-04     NaN
2025-01-05     NaN
2025-01-06     NaN
2025-01-07     NaN
2025-01-08    -6.0
2025-01-09   -47.0
Freq: D, dtype: float64
```

Agora são sete dias de `NaN`, porque a primeira semana não tem semana anterior. 8 de janeiro, uma
quarta, teve 6 viagens a menos que 1º de janeiro, a quarta anterior; 9 de janeiro teve 47 a menos que
2 de janeiro. Qual `shift` usar é uma pergunta sobre os dados, não sobre o pandas: dados diários com
ritmo semanal pedem 7, dados mensais com ritmo anual pedem 12.

**O `shift` anda por linhas, não por tempo.** No `daily`, uma linha é um dia, então `shift(7)` é uma
semana. Numa série com dias faltando, sete linhas para trás podem ser dez dias para trás, e a
comparação fica errada em silêncio. `shift(freq="7D")` desloca o índice no tempo em vez de deslocar os
valores por linhas, e a quarta seção é sobre por que uma série com dias faltando pede cuidado em todo
lugar, não só aqui.
