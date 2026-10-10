---
title: A conta da reescrita
version: 1
---

Discussões sobre reescritas ficam nas palavras enquanto as pessoas deixarem: limpo contra bagunçado,
moderno contra legado. O Davi respondeu ao Mateus com os números da própria proposta numa planilha.
**Com esses números, a reescrita se paga 5,5 anos depois de entregue — se tudo sair como planejado.**
Considere um estouro e o retorno passa de oito anos. A conta é curta o bastante para fazer na sua
planilha, preparada na aula 1.

## Os números da proposta

Digite isto numa aba nova:

| | A | B |
|---|---|---|
| 1 | Engenheiros | 6 |
| 2 | Meses | 18 |
| 3 | Horas por mês por engenheiro | 160 |
| 4 | Horas economizadas por sprint depois da entrega | 120 |
| 5 | Taxa (R$ por hora) | 150 |

A economia é a afirmação da própria proposta: quando o código novo substituir o módulo antigo, os
times param de pagar 120 horas por sprint de juros no antigo. É generoso. É mais do que o dobro das
55 horas por sprint que a aula 5 mediu nas quatro dívidas com nome, e ninguém mediu o resto. O Davi
usou mesmo assim, porque **um argumento que se sustenta com o melhor número do outro lado é difícil
de contestar**.

## A conta, como proposta

O custo é o tempo das pessoas. Multiplique as três primeiras células: 6 engenheiros × 18 meses × 160
horas dá 17.280 horas. A R$ 150 a hora, são R$ 2.592.000.

A economia é de 120 horas por sprint, que a R$ 150 dão R$ 18.000 por sprint. Divida o custo pela
economia: R$ 2.592.000 ÷ R$ 18.000 dá 144 sprints. Com 26 sprints por ano, 144 sprints são 5,5 anos.

**Esses 5,5 anos começam quando o sistema novo é entregue, e não quando o trabalho começa.** Durante os
dezoito meses da reescrita, os juros do sistema antigo continuam sendo pagos por inteiro, então a
primeira economia de verdade chega com um ano e meio, e o dinheiro volta cerca de sete anos depois do
primeiro commit. O próprio `coreto-core` tem nove anos.

## Com um estouro

Dezoito meses para seis pessoas é uma estimativa, e a seção sobre por que as reescritas falham listou
os motivos pelos quais a estimativa de uma reescrita anda numa direção só. O Davi não citou um número
do mercado sobre quanto as reescritas estouram, porque não tinha nenhum em que confiasse. Ele fez uma
pergunta mais simples: e se levar metade do tempo a mais? Multiplique as horas por 1,5 e faça as
mesmas divisões.

| | como proposto | com estouro de 1,5× |
|---|---|---|
| horas | 17.280 | 25.920 |
| custo | R$ 2.592.000 | R$ 3.888.000 |
| tempo até a entrega | 18 meses | 27 meses |
| economia por sprint | R$ 18.000 | R$ 18.000 |
| retorno depois da entrega | 144 sprints, 5,5 anos | 216 sprints, 8,3 anos |

A sua planilha deve dar os mesmos números. A economia não cresce com o estouro; só o custo cresce.
**Com 1,5×, o retorno depois da entrega é de 8,3 anos**, e com 27 meses de construção antes dele o
dinheiro volta cerca de dez anos e meio depois do início do trabalho — mais tempo do que o
`coreto-core` existe.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Duas barras horizontais numa escala de 0 a 11 anos. A proposta: construir leva o primeiro 1,5 ano, depois o retorno leva 5,5 anos, terminando em 7. Com um estouro de 1,5 vez: construir leva 2,25 anos, depois o retorno leva 8,3 anos, terminando depois de 10,5. Uma linha tracejada em 9 anos marca a idade do coreto-core hoje.\"><path d=\"M200.0 214 L200.0 222\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"200.0\" y=\"238\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">0</text><path d=\"M243.6 214 L243.6 222\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"243.6\" y=\"238\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">1</text><path d=\"M287.3 214 L287.3 222\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"287.3\" y=\"238\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">2</text><path d=\"M330.9 214 L330.9 222\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"330.9\" y=\"238\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">3</text><path d=\"M374.5 214 L374.5 222\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"374.5\" y=\"238\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">4</text><path d=\"M418.2 214 L418.2 222\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"418.2\" y=\"238\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">5</text><path d=\"M461.8 214 L461.8 222\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"461.8\" y=\"238\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">6</text><path d=\"M505.5 214 L505.5 222\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"505.5\" y=\"238\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">7</text><path d=\"M549.1 214 L549.1 222\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"549.1\" y=\"238\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">8</text><path d=\"M592.7 214 L592.7 222\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"592.7\" y=\"238\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">9</text><path d=\"M636.4 214 L636.4 222\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"636.4\" y=\"238\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">10</text><path d=\"M680.0 214 L680.0 222\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"680.0\" y=\"238\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">11</text><text x=\"440.0\" y=\"262\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">anos desde o primeiro dia da reescrita</text><text x=\"188\" y=\"97\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">como proposto</text><rect x=\"200.0\" y=\"75\" width=\"65.5\" height=\"34\" fill=\"var(--amber)\"></rect><rect x=\"265.5\" y=\"75\" width=\"240.0\" height=\"34\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"385.5\" y=\"97\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">retorno: 5,5 anos</text><text x=\"188\" y=\"172\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">com estouro de 1,5×</text><rect x=\"200.0\" y=\"150\" width=\"98.2\" height=\"34\" fill=\"var(--amber)\"></rect><rect x=\"298.2\" y=\"150\" width=\"362.2\" height=\"34\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"479.3\" y=\"172\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">retorno: 8,3 anos</text><rect x=\"70\" y=\"18\" width=\"14\" height=\"14\" fill=\"var(--amber)\"></rect><text x=\"90\" y=\"30\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">construindo, nada economizado ainda</text><rect x=\"340\" y=\"18\" width=\"14\" height=\"14\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"30\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">entregue, economiza R$ 18.000 por sprint</text><path d=\"M592.7 190 L592.7 222\" stroke=\"var(--paper)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\"></path><text x=\"586.7\" y=\"208\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">coreto-core hoje: 9 anos de idade</text></svg>", "caption": "A conta da reescrita como tempo. O retorno só começa quando o sistema novo é entregue, então o dinheiro volta cerca de sete anos depois do primeiro dia como proposto, e mais de dez com um estouro."}
```

## O que a conta deixa de fora

A planilha é generosa com a reescrita em alguns pontos e injusta com ela em outros, e o Davi escreveu
as duas listas.

Ela é generosa porque:

- supõe uma economia de 120 horas por sprint, mais do que o dobro de qualquer coisa medida;
- ignora o alvo móvel, as funcionalidades que serão construídas duas vezes, uma em cada sistema;
- ignora o custo de uma virada que falha, que na Coreto cai numa abertura de vendas.

Ela é injusta porque não dá ao sistema novo crédito por nada que ele faria e o antigo não faz. A
proposta não citou nada desse tipo que uma casa ou um comprador fosse notar, então não havia o que
creditar, mas outra proposta poderia ter citado.

## Contra as dívidas que ela deveria corrigir

A aula 5 precificou a parte do `coreto-core` que mais dói. A dívida das reservas de assento tem um
principal de 320 horas, R$ 48.000. **A reescrita custa 54 vezes isso** (R$ 2.592.000 ÷ R$ 48.000), e
começa a economizar um ano e meio depois. Pagar as dívidas que cobram mais juros, uma de cada vez,
compra uma parte grande da economia por uma parte pequena do preço, e cada pagamento começa a
economizar na sprint seguinte.

A resposta do Davi ao Mateus foi não à reescrita e sim à parte dela que importava: tirar o código das
reservas de assento do `coreto-core`, começando agora, sem parar as vendas. A aula 7 mostra como.
Como dar esse não a um colega e mantê-lo do seu lado é a aula 19.
