---
title: Valor do cliente ao longo da vida
version: 1
---

A Ipê gasta dinheiro para ganhar cada cliente do cartão: um anúncio, uma comissão a um parceiro, uma
tarifa a um site comparador. Se esse dinheiro foi bem gasto depende do que o cliente traz em todos os
anos em que fica, não no primeiro mês. **O valor do cliente ao longo da vida, o CLV, é essa soma**, e,
posto contra o custo de adquirir o cliente, diz quais canais valem o que custam.

## A versão simples

Um modelo completo de CLV desconta o dinheiro futuro, deixa a retenção mudar com a idade do cliente e
subtrai as perdas esperadas cliente a cliente. Esta aula usa a versão simples, e diz o que ela deixa de
fora:

**CLV = margem anual por cliente × anos esperados como cliente**

A margem anual é o que um cliente rende à Ipê num ano depois de captação, perdas e atendimento: margem,
não receita, porque receita que custa o mesmo para atender não vale nada. Os anos esperados vêm da
retenção, a parte dos clientes ainda ativos um ano depois. **Se 75% ficam a cada ano, um cliente fica em
média 1 ÷ (1 − 0,75) = 4 anos.** A fórmula vem de perder a mesma parte todo ano; com 90% de retenção dá
10 anos, e com 50%, dois.

Esta versão não é descontada: um real ganho em 2030 conta o mesmo que um ganho hoje, o que exagera vidas
longas. Todo CLV desta seção é, por isso, um teto, e a comparação entre canais é mais justa que qualquer
número isolado.

## Por canal de aquisição, na sua planilha

Os clientes do cartão da Ipê pelo canal que os trouxe, com o custo de adquirir cada um (CAC), a margem
anual por cliente e a retenção, tudo em reais e porcentagem. Digite a partir de A1:

| | A | B | C | D |
|---|---|---|---|---|
| 1 | Canal | CAC | Margem | Retenção % |
| 2 | Lojas parceiras | 180 | 260 | 70 |
| 3 | Anúncios de busca | 420 | 380 | 80 |
| 4 | Sites comparadores | 650 | 340 | 60 |
| 5 | Indicação | 120 | 300 | 75 |

Em E1 digite `Anos`, e em E2:

```localised
=ARRED(1/(1-D2/100);2)      3,33
```

Em F1 `CLV`, e em F2 a margem vezes os anos:

```localised
=ARRED(C2*E2;0)      866
```

E em G1 `CLV/CAC`, quantos reais de valor ao longo da vida cada real de aquisição compra:

```localised
=ARRED(F2/B2;1)      4,8
```

Copie E2:G2 até a linha 5:

| canal | CAC | anos | CLV | CLV/CAC |
|---|---|---|---|---|
| Lojas parceiras | R$ 180 | 3,33 | R$ 866 | 4,8 |
| Anúncios de busca | R$ 420 | 5 | R$ 1.900 | 4,5 |
| Sites comparadores | R$ 650 | 2,5 | R$ 850 | 1,3 |
| Indicação | R$ 120 | 4 | R$ 1.200 | 10 |

## O que a tabela diz

**Os clientes mais valiosos não são os mais baratos, e os mais baratos não são os mais valiosos.** Os
anúncios de busca trazem os clientes que valem mais, R$ 1.900 cada, e custam mais que o dobro das lojas
parceiras. Os sites comparadores parecem um canal como outro qualquer num relatório de clientes
ganhos, e mal se pagam: R$ 650 gastos para R$ 850 de margem, antes de descontar, com clientes que saem
mais rápido.

As indicações devolvem dez reais por real gasto. A tentação é mover toda a verba para lá, e a tabela não
diz se isso funciona: um canal de indicação é limitado por quantos clientes têm um amigo para indicar, e
as próximas mil indicações não vão custar R$ 120 cada. É o ponto da média contra o custo do próximo, da
busca paga da aula 15, de novo.

## Onde ele engana

A retenção medida nos clientes adquiridos no ano passado é um palpite sobre os adquiridos neste ano, por
um canal que pode ter mudado. E numa financeira, um cliente de margem alta pode ser um cliente de risco
alto: quem paga juros todo mês rende mais à Ipê do que quem paga a fatura inteira, até o mês em que para
de pagar. **Um CLV calculado sem as perdas da seção de risco de crédito é um número para os clientes que
a Ipê gostaria de ter.** Por isso a coluna de margem vem com as perdas descontadas, e por isso a equipe
da Fernanda o recalcula por safra, conforme as safras envelhecem.
