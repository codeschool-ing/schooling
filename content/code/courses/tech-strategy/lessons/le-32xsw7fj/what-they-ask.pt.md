---
title: O que executivos perguntam
version: 1
---

Um executivo que revisa uma estratégia técnica pergunta quatro coisas: **o que pode dar errado,
quanto custa, quando se paga, e o que você quer dele hoje.** Risco, dinheiro, tempo e a decisão.
Uma apresentação que responde a outras perguntas — como o sistema funciona, por que o desenho
antigo foi escolhido, como é o novo — responde a perguntas que ninguém na sala fez. E gasta o tempo
em que as quatro teriam sido respondidas.

Duas semanas antes da revisão de estratégia da Coreto, Davi mostrou a Helena Prates o rascunho da
apresentação. Ele abria com a arquitetura do `coreto-core`, percorria o módulo de reservas e chegava
às travas de linha com um diagrama da fila que elas formam sob carga. Estava correto, e Davi tinha
orgulho do diagrama. Helena deixou que ele chegasse ao fim e disse: "O Otávio vai te parar no
segundo slide e perguntar quanto custa. Comece por aí."

## As quatro perguntas

Otávio Lins é o CFO da Coreto. Ele não precisa entender uma trava de linha para aprovar um time que
as remove, assim como não precisa entender uma impressora de ingressos para aprovar a compra de uma.
**Do que ele precisa é o bastante para comparar esta decisão com as outras na mesa dele**, e toda
decisão na mesa dele chega nas mesmas quatro perguntas.

| o que Otávio pergunta | a resposta técnica | a resposta que ele consegue usar |
|---|---|---|
| O que acontece se não fizermos nada? | "o módulo de reservas é frágil sob carga" | "esperamos perder R$ 364.800 por ano em aberturas que falham" |
| Quanto custa, e comparado com quê? | "quatro engenheiros por dois trimestres" | "a correção custa R$ 48.000 em horas de engenharia, e ninguém novo é contratado" |
| Quando vemos o resultado? | "depois da refatoração" | "antes da temporada de aberturas deste ano, medido por um teste de carga" |
| O que você precisa de mim? | (nenhuma resposta) | "aprovar o time de Reservas a partir de 1º de março, e os dois projetos que esperam um ano" |

A coluna do meio não está errada. Ela está na unidade errada para este leitor, e deixa a tradução
para ele, que não consegue fazê-la sem o conhecimento que não tem. A coluna da direita faz a
tradução por ele, e cada número nela vem de um trabalho que este curso já fez: a aula 5 precificou a
dívida, e a próxima seção precifica o risco.

A quarta linha é a que as apresentações mais deixam vazia. **Uma revisão que termina sem decisão
não aconteceu**, seja o que for que se apresentou nela, porque nada está diferente na manhã
seguinte. Escreva a decisão que você quer antes de escrever qualquer outra coisa, e, se não
conseguir escrevê-la, você ainda não está pronto para pedir a reunião.

## Responda na unidade deles

Cada pergunta tem uma unidade em que quem pergunta pensa, e uma revisão de estratégia é onde a
tradução tem de chegar pronta, e não começar.

**Risco é dinheiro por ano, ou uma consequência com nome.** "Frágil" é um adjetivo; uma perda
esperada é um número que se pode pôr ao lado de um preço. A aula 4 de `architect-communication`
mostra como um risco técnico vira um risco de negócio — probabilidade e impacto, e as consequências
que o dinheiro não cobre —, e a próxima seção aplica isso ao maior risco da Coreto.

Dinheiro é real e uma fração de algo que o leitor já conhece. A aula 11 pôs o orçamento de
engenharia da Coreto em R$ 17.384.000, 79,0% dele em pessoas. Medida contra isso, uma correção de
R$ 48.000 é pequena, e dizer isso faz parte da resposta.

Tempo é uma data no calendário do negócio. "Dois trimestres" não significa nada para um CFO até
estar preso a algo com que ele já conta — aqui, a temporada de aberturas, cuja receita ele projeta
todo ano.

A decisão é um verbo, um dono e uma data: aprovar, financiar, parar, esperar. A aula 3 de
`architect-communication` trata de adaptar uma mensagem a um conselho ou a um executivo em geral; a
aula 24 de `people-leadership` trata da relação com a pessoa a quem você se reporta. As duas se
aplicam aqui, e nenhuma precisa ser repetida.

## Não fazer nada é uma opção, e tem preço

Executivos escolhem entre opções, e uma apresentação com uma proposta só oferece a eles uma escolha
entre o sim e uma discussão. **A opção que eles sempre têm é não fazer nada**, então precifique-a
primeiro. Na Coreto, não fazer nada são os R$ 364.800 por ano de perda esperada, mais as 31 horas de
juros que a dívida da reserva de assentos cobra a cada sprint (aula 5). Tudo o que Davi propõe é
medido contra essa linha, e essa linha é o motivo de a reunião existir.

## No que eles vão testar você

Um CFO testa uma estratégia pelo que ela deixa de lado, porque é para lá que vai o dinheiro que não
está sendo gasto. Espere a pergunta "o que vocês não vão fazer?", e responda a partir da página: a
aula 3 pôs a lista lá. Na Coreto ela é curta — a migração para microsserviços e o novo framework de
front-end esperam um ano —, e **dizer isso antes que ele pergunte é o sinal mais forte de que a
estratégia escolheu alguma coisa.**

Espere também a pergunta sobre o quanto você tem certeza. Soar confiante não a responde. Mostrar o
quanto a sua estimativa pode estar errada antes que a decisão mude responde, e essa é a última parte
da próxima seção.
