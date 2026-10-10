---
title: Quem decide, escrito antes que alguém precise saber
version: 1
---

Autonomia costuma ser discutida como um sentimento: o time se sente confiável ou não. **Ela é mais
útil como uma lista de decisões, cada uma com um dono.** Um time tem tanta autonomia quanto as
decisões que consegue tomar sem perguntar, e só sabe quanto tem se a lista existir. A aula 2 escreveu
uma lista dessas entre duas lideranças. Esta seção a escreve entre um time e todo mundo acima e em
volta dele.

## Portas que abrem para os dois lados

A carta de 2015 da Amazon aos acionistas traz uma distinção que se espalhou pelas empresas de
software porque é muito fácil de aplicar. Algumas decisões são **portas de mão única**: têm
consequências e são difíceis ou impossíveis de reverter, então merecem cuidado e o julgamento de mais
gente. A maioria é **porta de mão dupla**: se a decisão se mostrar errada, você volta pela porta e
tenta outra coisa. O alerta da carta é que as organizações tendem a tratar toda decisão como porta de
mão única, o que deixa tudo lento.

A distinção dá uma primeira resposta para "quem decide". **Portas de mão dupla pertencem o mais perto
possível do trabalho**, porque o custo de uma decisão errada é pequeno e o custo de esperar não é.
Portas de mão única sobem, ou saem para os lados, até quem vai ter de viver com as consequências.

| decisão no Agenda | que porta | quem decide |
|---|---|---|
| a ordem do trabalho dentro do objetivo do trimestre | mão dupla | o time, com a Helena |
| o texto de um lembrete | mão dupla, dentro do texto que o jurídico aprovou | o time |
| uma API pública nova que os sistemas das clínicas vão chamar | mão única: as clínicas constroem em cima | o Diego, depois de uma revisão de design com o time de plataforma |
| abandonar uma funcionalidade que uma clínica pagou | mão única: uma promessa comercial | o Otávio, com vendas |
| trocar o motor de banco de dados | mão única, e cara | uma revisão de design entre times |
| quem do time trabalha em quê | mão dupla | a Renata, consultando o Diego |

Duas ressalvas mantêm a ideia honesta. Muitas decisões parecem portas de mão dupla e não são, porque
alguma outra coisa é construída em cima delas antes que alguém perceba: o nome de um campo numa API é
fácil de mudar no dia em que vai ao ar e muito difícil seis meses depois. E uma porta de mão dupla
atravessada repetidamente na direção errada sai cara no total, mesmo que cada volta seja barata.

## Decisões que caem entre as cadeiras

A lista pega um tipo de problema que de outra forma é invisível: decisões que todo mundo supõe
pertencerem a outra pessoa. No Agenda, ninguém tinha decidido quem podia desligar uma feature flag em
produção de madrugada. A engenheira de plantão supunha que precisava do Diego; o Diego supunha que o
plantão podia. A pergunta apareceu às três da manhã, durante um incidente, e foi respondida com vinte
minutos de espera até o Diego acordar.

**As decisões que mais importa escrever são as que vão ser necessárias com pressa.** Um time consegue
descobrir o dono de uma questão de design em uma semana. Não consegue descobrir o dono de um rollback
enquanto clientes não conseguem marcar consultas.

## A página de decisões, ampliada

A aula 1 começou uma página de decisões no seu caderno com quatro colunas: a data, o que foi
decidido, por quê, e o que você espera ver se tiver acertado. Acrescente duas:

- **Quem decidiu.** Um nome, ou um grupo com uma regra ("o time, por acordo no planejamento").
- **Que porta.** Mão única ou mão dupla, conforme julgado na hora.

A primeira permite ver, meses depois, se as decisões estão sendo tomadas no nível certo. Se toda
linha da página da Renata diz "Renata", o time tem menos autonomia do que ela acha que tem. A segunda
permite conferir o julgamento depois: uma decisão registrada como mão dupla que se mostrou difícil de
reverter vale uma frase sobre por quê.

## A sua tarefa

Para um time que você conhece, liste dez decisões que ele toma num mês típico. Para cada uma,
escreva que porta é e quem a decide hoje. Depois confira:

- Pelo menos metade das portas de mão dupla é decidida por quem faz o trabalho.
- Toda porta de mão única tem um dono com nome, não "a gestão".
- Pelo menos uma decisão seria necessária com pressa, durante um incidente ou fora do horário, e o
  dono dela é alguém que estaria acordado.
- Se um nome aparece na maioria das linhas, você encontrou para onde a autonomia do time está indo.
