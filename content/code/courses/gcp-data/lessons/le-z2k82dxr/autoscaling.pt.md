---
title: Autoscaling, e o minuto que ele cobra
version: 1
---

**Uma reserva com autoscaling é cobrada pelos slots a que ela escalou, não pelos slots que uma consulta
usou.** Entre a baseline e o máximo, o autoscaler do BigQuery acrescenta slots quando há consultas
esperando por eles e os tira quando não há. A documentação do autoscaler do Google diz que ele os
acrescenta em passos de 50, e a página de preços diz que cada slot acrescentado é cobrado por segundo
com mínimo de um minuto. Essas duas regras decidem quanto custa uma consulta pequena em slots, e são o
motivo de uma carga que parece barata em slot-horas poder sair cara numa conta.

**Esta seção é um modelo, e diz isso.** Nada aqui roda o autoscaler do BigQuery, e o de verdade decide
sozinho quando escalar e quanto esperar antes de reduzir, o que a documentação descreve sem pôr números.
O que o modelo aplica são as duas regras documentadas e nada mais: uma consulta que pede 4 slots escala
a reserva em 50, e esses 50 são cobrados por pelo menos 60 segundos. Ele também supõe o pior caso para
essas regras, uma consulta que chega sozinha, sem nada mais rodando para dividir os slots que ela
provocou.

## O modelo

Salve isto como `~/gcp/autoscale.py`. Ele recebe de quantos slots uma consulta precisa, por quantos
segundos, quantas consultas assim chegam num mês e, opcionalmente, a palavra `fluid`, que tira o
minuto:

`autoscale.py`:

```python
import math
import sys

STEP, MINIMUM_S = 50, 60  # slots are added in steps of 50, and billed for at least a minute
SLOT_HOUR = 0.093         # USD, Enterprise, pay as you go, southamerica-east1, read 2026-10-30

slots, seconds, count = int(sys.argv[1]), float(sys.argv[2]), int(sys.argv[3])
minimum = 0 if sys.argv[4:] == ['fluid'] else MINIMUM_S
used = slots * seconds * count / 3600
billed = math.ceil(slots / STEP) * STEP * max(seconds, minimum) * count / 3600
print(f'{count:,} queries of {slots} slots for {seconds:g} s')
print(f'  slot-hours used   {used:10,.2f}   {used * SLOT_HOUR:9,.2f} USD')
print(f'  slot-hours billed {billed:10,.2f}   {billed * SLOT_HOUR:9,.2f} USD')
```

Duas cargas. O painel das lojas da Quitanda, 100.000 consultas pequenas por mês, cada uma precisando de
4 slots por 3 segundos, precificado com o minuto e depois com fluid scaling; e uma transformação
noturna, 300 consultas grandes por mês, cada uma precisando de 400 slots por dois minutos. Depois,
quanto as consultas do painel custam sob demanda, cada uma cobrada pelo mínimo de 10 MB da seção
anterior:

```
ana@laptop:~/gcp$ python3 autoscale.py 4 3 100000
100,000 queries of 4 slots for 3 s
  slot-hours used       333.33       31.00 USD
  slot-hours billed  83,333.33    7,750.00 USD
ana@laptop:~/gcp$ python3 autoscale.py 4 3 100000 fluid
100,000 queries of 4 slots for 3 s
  slot-hours used       333.33       31.00 USD
  slot-hours billed   4,166.67      387.50 USD
ana@laptop:~/gcp$ python3 autoscale.py 400 120 300
300 queries of 400 slots for 120 s
  slot-hours used     4,000.00      372.00 USD
  slot-hours billed   4,000.00      372.00 USD
ana@laptop:~/gcp$ python3 -c "print(100000 * 10 * 2**20 / 2**40)"
0.95367431640625
```

**O painel usou 333 slot-horas e foi cobrado por 83.333, duzentas e cinquenta vezes mais.** Cada
consulta pediu 4 slots e provocou 50, e os usou por 3 segundos dos 60 cobrados: 50 ÷ 4 × 60 ÷ 3 dá 250.
No preço do Enterprise isso são 7.750 USD por mês por 31 USD de trabalho. **O fluid scaling tira o
minuto** e deixa os passos de 50, e a conta cai para 387,50 USD, ainda doze vezes e meia o trabalho.
**Sob demanda, as mesmas 100.000 consultas são 0,95 TiB**, cada uma cobrada pelo mínimo de 10 MB, o que
cabe no TiB gratuito e não custa nada.

**A transformação noturna é o caso oposto.** Quatrocentos slots são um número inteiro de passos e dois
minutos passam do mínimo, então o que ela usou e o que foi cobrado são iguais: 4.000 slot-horas e 372
USD. Uma carga feita de consultas longas e largas paga pelo que usa; uma feita de consultas curtas e
estreitas paga pelo arredondamento.

## O que o modelo deixa de fora

**Consultas reais se sobrepõem**, e é isso que salva o painel numa reserva de verdade. Quando os blocos
atualizam juntos, as consultas deles dividem os 50 slots que a primeira provocou, e o minuto é pago uma
vez por todas em vez de uma vez por cada. O 250 do modelo é o teto do efeito, para consultas tão
espaçadas que nenhuma encontra outra, e o que um painel real paga fica em algum ponto abaixo disso.
Onde fica está em `INFORMATION_SCHEMA.JOBS` e nas views de uso da própria reserva, que um projeto
real lê antes de decidir.

**Uma baseline também muda a conta.** Slots da baseline são pagos toda hora, usados ou não, e as
consultas os pegam primeiro; o autoscaler só acrescenta slots acima dela. Uma reserva com baseline de
100 e máximo de 300 paga por 100 slots o mês inteiro e pelos slots escalados acima de 100 só enquanto
eles estão lá. Uma baseline do tamanho da carga que nunca para, com autoscaling acima dela para a carga
que vem e vai, é como a documentação do Google sugere combinar os dois, e é a mesma forma da escolha
que todo modelo de preço deste curso teve: pagar pelo piso e alugar os picos.

**Slots ociosos também podem ser emprestados.** No Enterprise e no Enterprise Plus, slots que a baseline
de uma reserva tem e não está usando podem ser tomados emprestados por outras reservas do mesmo projeto
de administração, para que as transformações da noite rodem em capacidade que as analistas pagaram e
deixaram parada. Se uma reserva empresta e toma emprestado é uma configuração da reserva, e nada disso
pode ser mostrado aqui.
