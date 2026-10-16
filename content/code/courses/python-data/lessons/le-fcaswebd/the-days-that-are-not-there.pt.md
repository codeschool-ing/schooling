---
title: Os dias que não estão lá
version: 1
---

**Uma janela de sete linhas só é de sete dias quando todo dia tem uma linha.** Uma contagem feita com
`groupby` só tem linha para os dias em que algo aconteceu, e uma série calma tem lacunas. Numa série
assim, uma janela móvel, um `shift` e uma média são todos calculados sobre os dias errados, e nenhum
deles avisa.

A `S12`, a estação mais calma, contada por dia com `groupby`:

```python
s12 = trips[trips["start_station"] == "S12"]
per_day = s12.groupby(s12["started_at"].dt.normalize()).size()
len(per_day), per_day.index.freq
```

```
(326, None)
```

326 linhas para um ano de 365 dias, e sem frequência: o pandas não consegue prometer que as linhas
estão a um dia de distância, porque não estão. Os primeiros dias mostram onde:

```python
per_day.head(8)
```

```
started_at
2025-01-01    1
2025-01-02    1
2025-01-03    2
2025-01-04    1
2025-01-06    2
2025-01-08    2
2025-01-09    1
2025-01-10    4
dtype: int64
```

Faltam 5 e 7 de janeiro. Ninguém começou viagem na `S12` nesses dias, então o `groupby` não teve o que
contar e não criou linha. O número certo para esses dias é 0, e a série não o contém.

## Duas janelas, as duas erradas

Uma janela de 7 linhas, e uma janela de 7 dias escrita como tempo, `"7D"`:

```python
pd.DataFrame({"rows": per_day.rolling(7).mean(), "days": per_day.rolling("7D").mean()}).head(10).round(2)
```

```
            rows  days
started_at            
2025-01-01   NaN  1.00
2025-01-02   NaN  1.00
2025-01-03   NaN  1.33
2025-01-04   NaN  1.25
2025-01-06   NaN  1.40
2025-01-08   NaN  1.60
2025-01-09  1.43  1.60
2025-01-10  1.86  2.00
2025-01-11  2.00  2.20
2025-01-12  2.71  3.00
```

A janela de linhas em 9 de janeiro cobre sete linhas que voltam até 1º de janeiro, nove dias. A
janela de tempo cobre os dias certos, de 3 a 9 de janeiro, mas faz a média só das linhas que existem
neles, então os dois dias vazios ficam de fora em vez de contarem como 0. **Uma janela de tempo
acerta o intervalo e não os zeros que faltam.** Ela também responde desde o primeiro dia, porque uma
janela de tempo precisa de um valor só por padrão, enquanto uma janela de linhas precisa de todos.

## A correção está nos dados

O `resample` monta a série a partir do calendário, então todo dia está lá e um dia vazio conta 0:

```python
full = s12.set_index("started_at").resample("D").size()
len(full), int((full == 0).sum())
```

```
(365, 39)
```

```python
full.rolling(7).mean().loc["2025-01-07":"2025-01-10"].round(2)
```

```
started_at
2025-01-07    1.00
2025-01-08    1.14
2025-01-09    1.14
2025-01-10    1.43
Freq: D, dtype: float64
```

Em 9 de janeiro a média honesta é 1,14 viagem por dia, onde a janela de linhas dizia 1,43 e a janela
de tempo 1,60. No ano a diferença tem o mesmo formato:

```python
round(per_day.mean(), 2), round(full.mean(), 2)
```

```
(np.float64(2.6), np.float64(2.32))
```

A média dos dias que tiveram viagens não é a média dos dias. **Antes de uma janela, garanta que a
série tem uma linha para cada passo**, e decida o que é um passo vazio.

Essa decisão depende do que a série mede. Uma contagem sem eventos é 0, então o 0 do `resample` está
certo. Uma **leitura** que não foi feita é desconhecida, não 0: os seis dias sem leitura do
pluviômetro no `weather.csv` são `NaN`, e um total móvel de chuva ou vira `NaN` em volta deles ou, com
janela de tempo ou `min_periods`, os trata como secos em silêncio. O tempo tem uma linha para cada dia;
o que lhe falta são seis valores, e a pergunta da aula 12 volta: o que você quer que os faltantes
signifiquem.
