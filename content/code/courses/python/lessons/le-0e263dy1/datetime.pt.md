---
title: Três tipos, e o que não tem fuso
version: 2
---

```python
from datetime import date, datetime, timedelta

date.today()                      # 2026-09-21
datetime.now()                    # 2026-09-21 14:03:11.482000
date(2026, 9, 21) + timedelta(days=30)
```

`date` é um dia. `datetime` é um dia e uma hora. `timedelta` é uma DURAÇÃO, e é ela que faz a
aritmética funcionar: uma data mais uma duração é uma data, e uma data menos uma data é uma
duração.

```python
(date(2026, 12, 25) - date.today()).days
```

**Essa é a razão inteira de não fazer isto à mão.** Trinta dias a partir de 15 de fevereiro é uma
pergunta cuja resposta certa depende do ano, e ninguém erra a regra do bissexto duas vezes — erra
uma, em produção, em fevereiro.

## Analisar e formatar

```python
datetime.strptime("2026-09-21", "%Y-%m-%d")      # string  → datetime
datetime.now().strftime("%d/%m/%Y")              # datetime → string
date.fromisoformat("2026-09-21")                 # the ISO case, shorter
```

O `strptime` ANALISA e o `strftime` FORMATA, e todo mundo consulta as letras toda vez. O hábito
útil é outro: **quando a string é ISO — ano, mês, dia, com traços — use `fromisoformat`**, que é
mais curto, mais rápido e não tem como ter o formato escrito errado.

E guarde datas em ISO. `21/09/2026` e `09/21/2026` são a mesma string para um computador e dias
diferentes para duas pessoas.

## O datetime ingênuo

```python
datetime.now()                    # naive — no time zone attached
datetime.now(timezone.utc)        # aware
```

Um `datetime` sem fuso se chama INGÊNUO, e é o padrão. Ele quer dizer "esta hora, em algum lugar" —
e comparar um ingênuo com um consciente levanta erro, que é o Python se recusando a chutar.

**A regra que sobrevive ao contato com a realidade: guarde e calcule em UTC, converta na borda.** O
carimbo de tempo no banco é UTC; a tela mostra a hora de quem lê. Qualquer outra coisa é um defeito
que aparece duas vezes por ano e não dá para reproduzir.

`zoneinfo.ZoneInfo("America/Sao_Paulo")` são os fusos da biblioteca padrão, e um fuso com NOME em
vez de um deslocamento — porque o deslocamento mudou, historicamente, e o nome sabe quando.

## O que este curso não precisa

Conversão de fuso em toda direção, calendários, dias úteis. Quando você chegar lá, o `dateutil` é a
dependência que todo mundo usa e ela vale a instalação.
