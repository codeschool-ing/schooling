---
title: Quando o apply é a ferramenta certa
version: 1
---

**O `apply` é certo quando o cálculo precisa mesmo de Python, e o número de chamadas é pequeno.** As
duas metades importam. Um laço sobre doze meses não custa nada; um laço sobre um milhão de linhas custa
minutos, calcule o que calcular.

A maior sequência de dias secos em cada mês é um cálculo do primeiro tipo. Cada dia depende dos dias
anteriores, então não há uma expressão de coluna única para ele, e um laço simples o diz com clareza:

```python
weather = pd.read_csv("weather.csv")
weather["date"] = pd.to_datetime(weather["date"], format="%Y-%m-%d")

def longest_dry(rain):
    best = run = 0
    for r in rain:
        run = run + 1 if r == 0 else 0
        best = max(best, run)
    return best

dry = weather.groupby(weather["date"].dt.month)["rain_mm"].agg(longest_dry)
dry.tolist()
```

```
[8, 10, 7, 2, 2, 1, 3, 5, 9, 9, 7, 12]
```

Dezembro teve uma sequência de 12 dias secos, junho só de 1. Doze chamadas, uma por mês, cada uma
sobre uns trinta valores:

```python
t_dry = %timeit -o -q weather.groupby(weather["date"].dt.month)["rain_mm"].agg(longest_dry)
round(t_dry.average * 1000, 1)
```

```
1.2
```

Cerca de um milissegundo. Ninguém deveria reescrever isso para ganhar tempo. **Meça antes de
otimizar**: um caminho lento que roda doze vezes não é lento.

A função também deixa visível uma decisão, o que vale tanto quanto a velocidade dela. `r == 0` é
`False` para uma leitura faltante, então um dia sem leitura **interrompe** uma sequência seca em vez de
estendê-la. Essa é uma escolha honesta; contar dias desconhecidos como secos é outra. No `weather.csv`
as duas dão os mesmos doze números, porque nenhum dos seis dias sem leitura está num lugar em que
alongaria a maior sequência de um mês, e em outros dados elas podem discordar. Numa função a escolha é
uma linha que você lê e muda; escondida numa expressão vetorizada esperta ela seria bem mais difícil de
ver.

## Formatar é o outro caso

O `DataFrame.map` aplica uma função a cada célula, o que combina mais com apresentação que com cálculo,
numa tabela já pequena o bastante para ler:

```python
summary = trips.groupby("plan")[["minutes"]].median()
summary.map(lambda v: f"{v:.1f} min")
```

```
         minutes
plan            
annual  12.4 min
day     19.9 min
```

O resultado é texto, pronto para imprimir ou colar, e não mais números. Guarde a tabela numérica para
tudo o que calcula, e formate no fim.

**A regra que esta aula deixa**: escreva a expressão de colunas quando ela existe, o que é quase
sempre; use `map` com um dicionário para consultas; e guarde o `apply` para lógica que precisa de
Python, aplicada a pedaços poucos o bastante para o laço não importar.
