---
title: Planning poker
version: 1
---

O **planning poker** é um jeito de um time combinar um tamanho junto sem que a primeira pessoa a falar decida por todo mundo. James Grenning o descreveu em 2002, e o livro *Agile Estimating and Planning* (2005), de Mike Cohn, o tornou o padrão.

## Uma rodada

Cada pessoa segura um baralho com a escala nas cartas: 0, ½, 1, 2, 3, 5, 8, 13, 20, 40, 100, e em geral um **?** para *não faço ideia* e uma xícara de café para *preciso de uma pausa*.

1. O Product Owner lê a história e responde às perguntas sobre ela.
2. Cada pessoa escolhe uma carta **em segredo**.
3. Todo mundo vira a carta **no mesmo instante**.
4. Se as cartas concordam, esse é o tamanho. Se diferem, quem mostrou a **maior e a menor** explica por quê.
5. O time discute brevemente e vota de novo, em geral convergindo em duas ou três rodadas.

## Por que as cartas ficam escondidas

A regra que mais importa é a revelação simultânea. Amos Tversky e Daniel Kahneman mostraram em 1974 que os julgamentos numéricos das pessoas são puxados para qualquer número que elas ouvem primeiro, mesmo um claramente irrelevante; eles chamaram isso de **ancoragem**. Numa reunião em que o desenvolvedor mais sênior diz "isso é 3" antes de qualquer outra pessoa pensar no assunto, a estimativa do time é a estimativa daquele desenvolvedor com passos a mais. Cartas escondidas dão ao julgamento de cada pessoa uma chance de ser ouvido.

## A discordância é o valor

Quando um desenvolvedor mostra 3 e outro mostra 13, a parte útil da reunião está para acontecer. Em geral um deles sabe algo que o outro não sabe: o 13 sabe que o provedor de pagamento exige uma aprovação separada para cada clínica nova; o 3 sabe que já existe uma biblioteca que trata disso. **A conversa revela a suposição, e o segundo voto é mais bem informado que qualquer uma das primeiras cartas.** Um time que pula a explicação e tira a média jogou isso fora.

## O antepassado dele

O planning poker é uma forma leve do **Wideband Delphi**, um método que Barry Boehm descreveu nos anos 1970, adaptando a técnica Delphi de previsão da RAND Corporation: especialistas estimam independentemente, a dispersão é discutida, e eles estimam de novo. A ideia é antiga porque funciona: julgamento independente primeiro, depois discussão, depois revisão.
