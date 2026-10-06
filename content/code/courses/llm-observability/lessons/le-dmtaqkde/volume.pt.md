---
title: Volume
version: 1
---

A primeira pergunta sobre um sistema em produção é a mais sem graça e a mais pulada: **quanto ele está
sendo usado, e quando?** O volume é o denominador de todos os outros números desta aula, e uma mudança
nele muitas vezes é o primeiro sinal de outra coisa. O `volume.py` desenha a semana em barras:

```python
"""volume.py: requests per day, and per hour of the day across the week, as bars."""
from collections import Counter

import costs

rows = costs.requests()
days = Counter(r["at"].strftime("%a %d") for r in rows)
hours = Counter(r["at"].hour for r in rows)
for day, n in days.items():
    print(f"{day}  {n:4}  {'#' * (n // 5)}")
print()
for h in range(24):
    print(f"{h:02}h  {hours[h]:4}  {'#' * (hours[h] // 3)}")
```

```
ana@lab:~/obs$ python volume.py
Mon 28   200  ########################################
Tue 29   210  ##########################################
Wed 30   207  #########################################
Thu 01   208  #########################################
Fri 02   224  ############################################
Sat 03   153  ##############################
Sun 04   143  ############################

00h    11  ###
01h    11  ###
02h    10  ###
03h     9  ###
04h     7  ##
05h    17  #####
06h    25  ########
07h    52  #################
08h    79  ##########################
09h    98  ################################
10h    94  ###############################
11h    82  ###########################
12h    72  ########################
13h    89  #############################
14h    96  ################################
15h    99  #################################
16h    72  ########################
17h    65  #####################
18h    73  ########################
19h    82  ###########################
20h    79  ##########################
21h    64  #####################
22h    37  ############
23h    22  #######
```

Duas formas, as duas comuns. **Dias úteis são mais movimentados que o fim de semana**, em cerca de um
terço. **O dia tem duas corcovas**, meio da manhã e meio da tarde, com uma baixa no almoço e uma cauda
longa à noite, e quase nada entre meia-noite e seis. O tráfego foi gerado com essa forma de propósito,
porque é a forma de quase todo serviço que as pessoas usam do trabalho e de casa, e vale conhecê-la por
três motivos.

**Capacidade e limites de taxa se definem pelo pico, não pela média.** 99 pedidos na hora mais
movimentada da semana, somados ao longo de sete dias, significam que a hora de pico num dia útil roda a
várias vezes a taxa da madrugada. Um limite de taxa de fornecedor confortável na média pode ser atingido
toda tarde às três.

**Uma taxa só se compara dentro das mesmas horas.** Uma taxa de recusa calculada entre meia-noite e seis
é uma taxa sobre um punhado de pedidos; a mesma taxa entre nove e cinco é sobre centenas. Um painel que
mostre taxas por hora sem o volume ao lado faz a madrugada parecer alarmante toda noite.

**Uma queda de volume é uma falha que não manda erro.** Se o site da loja parasse de carregar o widget
de ajuda, a taxa de erro do assistente seria perfeita: ninguém pergunta, nada falha. O volume
comparado com a mesma hora da semana passada é o alarme para isso, e é o único que consegue vê-lo. A
aula 16 o constrói.
