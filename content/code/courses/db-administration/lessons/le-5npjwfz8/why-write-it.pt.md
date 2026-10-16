---
title: Por que escrever
version: 1
---

Um **runbook** é o procedimento para um sintoma: o que olhar, o que fazer com cada coisa que você
pode encontrar, como saber que funcionou e quem chamar quando não funcionou. Ele é escrito de dia,
por alguém com tempo, para alguém sem tempo — muitas vezes a mesma pessoa, acordada às três da
manhã por um alerta, lendo um terminal com um olho só.

A objeção comum é que a pessoa que conhece o servidor não precisa de um. **É exatamente para essa
pessoa que o runbook existe.** É ela quem recebe o chamado, é ela quem está de férias quando o
chamado vai para outra pessoa, e às três da manhã ela não é a engenheira que é às três da tarde.
Gente cansada pula passos, confia na lembrança da última vez e digita o comando que resolveu um
problema diferente. Uma página de passos escrita pela versão descansada da mesma pessoa é a defesa
mais barata que existe contra as três coisas.

## O que um runbook não é

Ele é mais estreito que os documentos ao lado dele, e mantê-lo estreito é o que o torna usável.

- Ele **não é uma descrição do sistema**. Onde o servidor está, como é feito o backup e como ele
  seria reconstruído é documentação para recuperação, e a lição 24 de db-reliability trata de
  escrever isso.
- Ele **não é o relato de um incidente**. Conduzir um incidente, os papéis que as pessoas assumem e
  a revisão depois são da lição 22 de db-reliability.
- Ele **não é um texto de estudo**. Este curso explicou por que um slot de replicação pode encher um
  disco (lição 7) e o que um disco cheio faz com o servidor (lição 9). O runbook não carrega nada da
  explicação. Ele carrega os três comandos em que esse entendimento se transforma, e os números a
  partir dos quais cada um importa.

## O que ele compra

**Os mesmos passos, na mesma ordem, toda vez**, então duas noites podem ser comparadas e um passo
pulado fica visível. **Uma segunda pessoa consegue fazer**, o que transforma "só a Ana sabe
resolver isso" numa página que qualquer pessoa de plantão segue. E **ele é o primeiro rascunho da
automação**: um passo que nunca precisa de julgamento — rode esta consulta, compare com aquele
número — é um passo que pode virar uma checagem no monitoramento ou uma linha num script como o da
lição 23, e o runbook é onde esses passos são encontrados.

O resto desta lição escreve um runbook para um único sintoma, o disco sob o PostgreSQL enchendo,
roda cada passo dele no seu servidor e mantém um registro enquanto faz isso.
