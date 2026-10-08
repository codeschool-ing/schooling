---
title: Volume
version: 2
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
    print(f"{day}  {n:4}  {'#' * n}")
print()
for h in range(24):
    print(f"{h:02}h  {hours[h]:4}  {'#' * hours[h]}")
```

```
ana@dev:~/obs$ python volume.py
Mon 28    46  ##############################################
Tue 29    47  ###############################################
Wed 30    45  #############################################
Thu 01    55  #######################################################
Fri 02    48  ################################################
Sat 03    36  ####################################
Sun 04    34  ##################################

00h     0  
01h     2  ##
02h     2  ##
03h     2  ##
04h     4  ####
05h     4  ####
06h     7  #######
07h    13  #############
08h    20  ####################
09h    21  #####################
10h    19  ###################
11h    18  ##################
12h    17  #################
13h    20  ####################
14h    22  ######################
15h    20  ####################
16h    18  ##################
17h    15  ###############
18h    18  ##################
19h    20  ####################
20h    19  ###################
21h    19  ###################
22h     9  #########
23h     2  ##
```

Duas formas, as duas comuns. **Dias úteis são mais movimentados que o fim de semana**, em cerca de
um quarto. **O dia é movimentado das oito da manhã às dez da noite**, com um pouco mais no meio da
manhã e no meio da tarde, e quase nada entre meia-noite e seis. O tráfego foi gerado com essa forma
de propósito, porque é a forma de quase todo serviço que as pessoas usam do trabalho e de casa, e
vale conhecê-la por três motivos.

**Capacidade e limites de taxa se definem pelo pico, não pela média.** 22 pedidos na hora mais
movimentada da semana, somados os sete dias, contra nenhum à meia-noite: a hora de pico de um dia
útil roda a várias vezes a taxa da madrugada. Um limite de taxa de fornecedor que é folgado na média
pode ser atingido toda tarde às três, e um computador que responde uma pergunta de cada vez, como o
Ollama faz aqui, enfileira cada pedido que chega enquanto ele está ocupado.

**Uma taxa só se compara dentro das mesmas horas.** Uma taxa de recusa calculada entre meia-noite e
seis é uma taxa sobre um punhado de pedidos; a mesma taxa entre nove e cinco é sobre mais de cem. Um
painel que mostre taxas por hora sem o volume ao lado faz a madrugada parecer alarmante toda noite.

**Uma queda de volume é uma falha que não manda erro.** Se o site da loja parasse de carregar o widget
de ajuda, a taxa de erro do assistente seria perfeita: ninguém pergunta, nada falha. O volume
comparado com a mesma hora da semana passada é o alarme para isso, e é o único que consegue vê-lo. A
aula 16 o constrói.
