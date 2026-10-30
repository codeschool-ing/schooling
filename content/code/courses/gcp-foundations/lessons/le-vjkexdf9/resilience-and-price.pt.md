---
title: Resiliência, e quanto custa
version: 1
---

**Disponibilidade se compra aos pares.** Todo desenho para o qual o Google oferece 99,99% é dois de alguma coisa
onde um funcionaria: dois túneis HA VPN onde um levaria o tráfego, duas conexões Interconnect em cada uma de
duas cidades onde uma bastaria. A pergunta para o planner não é qual desenho é o melhor, mas que número o enlace
do escritório tem de cumprir, e a aritmética que responde cabe numa dúzia de linhas.

Os documentos do Google dão os desenhos, lidos em 30 de outubro de 2026:

| desenho | o que exige | disponibilidade oferecida |
|---|---|---|
| um túnel VPN | Classic VPN | 99,9% |
| HA VPN | dois túneis, um de cada interface do gateway | 99,99% |
| Interconnect, uma cidade | duas conexões numa área metropolitana, em domínios de disponibilidade de borda diferentes | 99,9% |
| Interconnect, duas cidades | dois desses pares, em duas áreas metropolitanas | 99,99% |

E os preços, das páginas de preço do Cloud VPN e do Cloud Interconnect no mesmo dia: **0,05 USD por hora para
cada túnel VPN**, para Iowa, a região padrão da página; **2,328 USD por hora para uma conexão Dedicated de 10
Gbps** e **0,10 USD por hora para cada attachment de VLAN** de até 10 Gbps. Dados saindo por um Interconnect da
América do Sul para a América do Sul custam **0,11 USD por GiB**; dados por uma VPN são cobrados como saída
comum para a internet.

## Quatro desenhos, lado a lado

Salve isto como `~/gcp/sla.py`:

```schooling-example
{"language": "python", "file": "sla.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"What an availability figure allows, in minutes down and in dollars a month.\n\n    python3 sla.py PERCENT HOURLY_USD [PERCENT HOURLY_USD ...]\n\nEach pair is a design: the availability it is offered at, and what its\nparts cost an hour together.\n\"\"\"\nimport sys\n\n", "note": "Como é chamado: pares de números, um par por desenho, a disponibilidade e o preço por hora de tudo de que o desenho precisa."}, {"code": "HOURS = 730            # the hours Google's pricing uses for a month\nMINUTES = 30 * 24 * 60 # a 30-day month, the way availability is usually counted\n\n", "note": "Dois meses, de propósito. Os preços são por hora, e as páginas de preço do Google transformam horas num mês com 730; disponibilidade é uma fração do tempo, e um mês de 30 dias é o número redondo contra o qual as pessoas a citam."}, {"code": "args = sys.argv[1:]\nfor percent, hourly in zip(args[0::2], args[1::2]):\n    down = MINUTES * (1 - float(percent) / 100)\n    print(f'{percent:>6}%  up to {down:6.1f} min down a month  {float(hourly) * HOURS:9.2f} USD a month')\n", "note": "Para cada desenho, os minutos por mês que a disponibilidade dele ainda permite perder, e quanto as partes dele custam num mês. Nada nele sabe o que é VPN ou Interconnect: os dois números são o desenho inteiro, no que diz respeito a esta pergunta."}]}
```

Os quatro desenhos: um túnel; dois; duas conexões de 10 Gbps com um attachment cada; quatro delas:

```
ana@laptop:~/gcp$ python3 sla.py 99.9 0.05 99.99 0.10 99.9 4.856 99.99 9.712
  99.9%  up to   43.2 min down a month      36.50 USD a month
 99.99%  up to    4.3 min down a month      73.00 USD a month
  99.9%  up to   43.2 min down a month    3544.88 USD a month
 99.99%  up to    4.3 min down a month    7089.76 USD a month
```

**O segundo túnel custa 36,50 dólares por mês e devolve uns 39 minutos por mês**, e é por isso que o planner tem
dois e ninguém discute. O salto para o Interconnect é outra decisão por completo: o custo dele é dominado pelos
circuitos, não pela disponibilidade, e ele se justifica pela banda e pelo preço de transferência, nunca pelo
nove a mais, que o HA VPN já dá. Estes são só os preços por hora do Google; a instalação de colocation, o
cross-connect e a própria linha de internet do escritório são contas à parte.

## O que o planner escolheu

**HA VPN, dois túneis, para dois endereços no roteador do escritório**, com o BGP da primeira seção. Ele atende
à necessidade do escritório, algumas centenas de megabits para a equipe e os backups noturnos, a 73 dólares por
mês mais a saída. O ponto em que isso muda está escrito com antecedência em vez de descoberto num incidente:
quando os túneis passarem de metade da capacidade por um mês, ou quando a transferência noturna for grande o
bastante para os 0,11 por GiB do Interconnect, com os circuitos dele, custarem menos que a saída para a internet
da VPN.
