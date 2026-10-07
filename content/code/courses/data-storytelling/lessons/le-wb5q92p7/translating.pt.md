---
title: Transformando um achado em dinheiro
version: 1
---

Os R$ 790 mil do slide do conselho na aula 4 vieram de quatro passos. **Cada um é uma multiplicação, e cada um
carrega uma hipótese que deve ser dita em voz alta.**

## Os quatro passos

**Primeiro, os cancelamentos a mais.** 1.058 primeiras caixas atrasadas em seis meses, e clientes atrasados
cancelam 24,1 pontos a mais que os do prazo. Se os atrasados tivessem cancelado como os outros, quantos a
menos teriam saído?

```localised
=ARRED(1058*(439/1058-881/5055);0)
```

O Calc dá **255** em seis meses, então 510 por ano.

Segundo, a margem perdida por cancelamento a mais: R$ 1.554,14, da seção anterior, a margem ao longo da
vida de um sobrevivente menos o que um cliente que cancela cedo pagou. Terceiro, a margem perdida por ano:
510 vezes R$ 1.554,14 dá **R$ 792.611,40**, dito em toda página como "cerca de R$ 790 mil", pelos motivos da
aula 8.

Quarto, a aquisição gasta com eles: 510 clientes a R$ 152 cada dão **R$ 77.520** por ano, pagos para
conquistar clientes que saíram antes de devolver o investimento. Isso não é somado à margem. Responde a
outra pergunta, *quanto do orçamento de marketing é desperdiçado?*, e pertence a outro leitor.

## As hipóteses, ditas em voz alta

- **Que a distância é causada pelo atraso.** O passo 1 supõe que os clientes atrasados teriam se comportado
  como os do prazo. A aula 10 tirou a região como alternativa; o piloto testa a causa diretamente.
- **Que o cancelamento de 4% ao mês depois dos 90 dias se mantém.** É a taxa recente da Faro; pode mudar.
- **Que a margem de 31% se mantém.** Os custos de ração e frete mudam.

**Cada hipótese é um lugar onde um cético pode empurrar**, e nomeá-las primeiro leva a conversa de "não
acredito" para "de qual hipótese você duvida?", que é uma conversa que dá para ter com números.

## Os erros comuns

- **Usar receita em vez de margem.** 510 clientes vezes 28 meses vezes R$ 189,90 dá cerca de R$ 2,7 milhões,
  e está errado como custo: a Faro também teria gasto a maior parte disso em ração e frete.
- **Contar a mesma perda duas vezes.** Margem perdida e aquisição desperdiçada são as duas reais, e somá-las
  finge que o dinheiro da aquisição também teria produzido margem.
- **Anualizar sem cuidado.** Dobrar seis meses para um ano funciona aqui porque o padrão mensal é estável (a
  sparkline da aula 7). Num negócio sazonal, não funcionaria.
