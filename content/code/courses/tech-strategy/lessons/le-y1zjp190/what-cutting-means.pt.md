---
title: O que "cortar 10%" quer dizer
version: 1
---

Enquanto o orçamento do ano que vem está sendo montado, Otávio pede a mesma coisa a todos os
departamentos: 10% a menos que este ano. Helena repassa o pedido ao Davi com uma linha — "de onde
sairia?" — e a primeira resposta na sala é a que a maioria das organizações de engenharia dá.
**Enxugar a nuvem, revisar as licenças, achar alguma eficiência.** Soa responsável, e a planilha da
seção anterior mostra que a conta não fecha.

## O tamanho do pedido

Na mesma aba, três fórmulas em células vazias. O corte em si:

```localised
=SOMA(B2:B5)*10%      1738400
```

O corte em engenheiros, dividindo pelos R$ 264.000 que um engenheiro custa por ano:

```localised
=ARRED(SOMA(B2:B5)*10%/264000;1)      6,6
```

E o corte como parcela da linha de nuvem, B3:

```localised
=ARRED(SOMA(B2:B5)*10%/B3*100;0)      68
```

**Um corte de 10% são R$ 1.738.400, o que dá 6,6 engenheiros, ou 68% da fatura da nuvem.** Ninguém
vai tirar dois terços da nuvem da Coreto em um ano com a venda de ingressos crescendo; a maior
economia isolada que a aula 12 encontra, ambientes de homologação ligados a noite toda, é de
R$ 117.600 por ano. Leve a comparação um passo adiante: tudo o que não é gente soma R$ 3.656.000 (o
total menos a linha de pessoas), então um corte tirado inteiro dessas três linhas levaria 47,5%
delas. Zerar só o ferramental, R$ 380.000, cobre 21,9% do pedido.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 170\" role=\"img\" data-fig=\"l11-cut\" aria-label=\"Duas barras na mesma escala. A de cima é tudo no orçamento da Coreto que não é gente, R$ 3.656.000: nuvem R$ 2.544.000, licenças e SaaS R$ 732.000, ferramental R$ 380.000. A de baixo é o corte de 10%, R$ 1.738.400, quase metade do comprimento da barra de cima.\"><text x=\"20.0\" y=\"22.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">Tudo o que não é gente: R$ 3.656.000</text><rect x=\"20.0\" y=\"32.0\" width=\"473.2\" height=\"44.0\" rx=\"2\" fill=\"var(--amber)\"></rect><rect x=\"493.2\" y=\"32.0\" width=\"136.1\" height=\"44.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"629.3\" y=\"32.0\" width=\"70.7\" height=\"44.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"256.6\" y=\"51.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--ink)\">Nuvem</text><text x=\"256.6\" y=\"67.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--ink)\">R$ 2.544.000</text><text x=\"561.2\" y=\"51.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Licenças</text><text x=\"561.2\" y=\"67.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">R$ 732.000</text><text x=\"664.7\" y=\"51.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Ferramental</text><text x=\"664.7\" y=\"67.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">R$ 380.000</text><text x=\"20.0\" y=\"106.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">O corte de 10%: R$ 1.738.400</text><rect x=\"20.0\" y=\"116.0\" width=\"323.3\" height=\"44.0\" rx=\"2\" fill=\"var(--phosphor)\"></rect><text x=\"181.7\" y=\"143.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--ink)\">47,5% da barra de cima</text></svg>", "caption": "Um corte de 10% do orçamento inteiro, medido contra as três linhas que não são gente. Tirado só delas, levaria quase metade de tudo o que a Coreto gasta fora da folha de pagamento."}
```

## Um corte é uma decisão sobre pessoas

Com pessoas em 79,0% do orçamento, **a maior parte de qualquer corte de verdade cai na linha de
pessoas**, diga o que disser a primeira reunião. Ele cai de um destes três jeitos: vagas abertas que
não são preenchidas, gente que sai e não é reposta, ou demissões. Cada um é uma decisão sobre quem
faz o trabalho no ano que vem, e chamar isso de "eficiência" não muda qual deles é.

Dizer isso com todas as letras importa por dois motivos. Otávio precisa saber o que está comprando:
um corte de 10% que na verdade são seis ou sete engenheiros a menos é uma decisão diferente de um
corte de 10% em desperdício, e ele deve tomá-la sabendo disso. E o time precisa ouvir isso do Davi
antes de deduzir sozinho a partir de uma mesa vazia.

**Os cortes que parecem de graça voltam como horas.** Cancelar uma licença leva o custo dela para a
linha de pessoas, como a seção anterior mostrou. Adiar uma atualização a empurra para o ano que vem,
com juros do tipo que a aula 5 mediu. Um corte que aparece como uma fatura menor e um time mais
ocupado economizou menos do que a fatura diz, e às vezes nada.

## O calendário corta pela metade

Um orçamento vale por um ano, e um corte decidido no meio dele só economiza os meses que restam. Um
congelamento de contratações que começa em julho economiza meio ano de cada vaga que deixa vazia,
então chegar a 6,6 anos de engenheiro desse jeito exige 13,2 vagas congeladas por seis meses
(6,6 × 2). A conta é simples e é esquecida com frequência, e é assim que um "corte de 10%" acertado
numa reunião vira um corte de 5% nos livros e uma segunda rodada de cortes no ano novo.

## Transformar o número em opções

Davi não responde "de onde sairia?" com um plano único, e também não se recusa. Ele escreve a
resposta como opções, cada uma com o que para e quem perceberia:

| opção | de onde saem os R$ 1.738.400 | o que para | quem percebe |
|---|---|---|---|
| A | 6,6 anos de engenheiro, de vagas não preenchidas | o trabalho que a estratégia já tinha adiado: a migração para microsserviços e o framework de front-end passam de "ano que vem" para "fora do plano" | os times que esperavam por eles |
| B | economias em nuvem e licenças primeiro, o resto de pessoas | o mesmo que A, menor; mais um engenheiro em trabalho de custo por um trimestre | a Plataforma, e o financeiro quando a economia chega atrasada |
| C | um corte menor, com o risco do corte inteiro escrito ao lado | nada no caminho da abertura de vendas | o Otávio, que precisa achar a diferença em outro lugar |

**É a estratégia que torna essa tabela possível.** A política orientadora da aula 1, "proteger a
abertura de vendas primeiro", diz onde o corte não pode cair: o time de Reservas e o teste de carga
ficam. A lista da aula 3 do que a Coreto não vai fazer diz onde ele pode cair com menos estrago,
porque aquele trabalho já estava esperando. Um time sem estratégia enfrenta um corte de orçamento
cortando um pouco de tudo, o que espalha o estrago por todas as prioridades de uma vez.

As opções vão para Helena e Otávio como uma escolha com consequências, que é uma conversa diferente
de uma negociação em torno de um percentual. A aula 13 de architect-communication trata dessa
negociação; a aula 19 deste curso trata da forma de uma recusa, para o dia em que a resposta certa
for não. O sentido contrário vem antes: a próxima seção é como o Davi pede dinheiro.
