---
title: Que desenho para que pergunta
version: 1
---

**Fluxo, estado e mapa parecem iguais à primeira vista (caixas e setas) e respondem a três perguntas
diferentes.** Confundi-los é o motivo mais comum de um diagrama desta família parecer errado sem que
ninguém consiga dizer por quê.

| a pergunta | o desenho | as caixas são | as setas são |
| --- | --- | --- | --- |
| *o que acontece, passo a passo, e quem faz?* | diagrama de atividade, fluxograma, BPMN | passos, coisas sendo feitas | a ordem dos passos |
| *em que estados esta coisa pode estar, e o que a muda?* | máquina de estados | condições que duram | eventos que mudam a condição |
| *quais modelos dependem de quais, e quem se adapta?* | mapa de contextos | contextos delimitados, com seus times | relações upstream e downstream |
| *quem manda o quê para quem, em que ordem?* | diagrama de sequência, aula 2 | participantes | mensagens |

## Distinguir pelos nomes

Os nomes das caixas entregam o diagrama:

- **verbos** (*conferir o horário de partida*, *estornar*) são passos, então o desenho é um fluxo;
- **adjetivos e particípios** (*Reservada*, *Paga*, *Expirada*) são estados;
- **substantivos para áreas do negócio** (*Vendas*, *Frota*, *Preços*) são contextos;
- **substantivos para coisas que rodam** (*API de passagens*, *banco de reservas*) são contêineres,
  que é a aula 3.

Um diagrama cujas caixas misturam verbos e adjetivos são dois diagramas. *Reservada → Validando
pagamento → Paga* põe um passo entre dois estados; ou *validando* é um estado em que a passagem
realmente fica, e então deveria se chamar *Aguardando confirmação* e ter as próprias transições, ou
é um passo dentro da transição e não pertence à máquina de estados.

## O mesmo evento em três desenhos

O pagamento atrasado da seção da tabela de estados aparece nos três, de jeitos diferentes:

- no **fluxo**, é uma decisão depois de *receber o webhook*: `[reserva expirada]` leva a *estornar
  automaticamente*;
- na **máquina de estados**, é a transição `pagamento aprovado / estorno` de *Expirada* de volta para
  *Expirada*;
- no **mapa de contextos**, é a linha do gateway de pagamento até Pagamentos: o modelo de *aprovado*
  do gateway não sabe nada da expiração da Carcará, e traduzir entre os dois é trabalho da ACL.

Cada desenho mostra uma parte da mesma correção. Raramente é preciso desenhar os três; a habilidade
é saber qual deles a pergunta pede.
