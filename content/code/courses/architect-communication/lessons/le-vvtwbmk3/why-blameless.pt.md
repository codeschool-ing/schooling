---
title: Por que sem culpados, e o que isso não quer dizer
version: 1
---

**Um postmortem que procura um culpado encontra um, e não aprende mais nada, porque todo o resto das
pessoas para de dizer a verdade.** Um postmortem sem culpados parte do princípio de que as pessoas
envolvidas fizeram o que fazia sentido para elas com o que sabiam naquele momento, e pergunta por que
fazia sentido. As respostas mostram onde o sistema é fraco.

## O primeiro rascunho

As primeiras notas sobre o incidente de 6 de março, escritas por um engenheiro tarde da noite na
sexta, diziam: "Causa raiz: a logística rodou um backfill no horário de pico sem verificar." Até onde
ia, estava correto. Também transformava Paulo, que tinha iniciado a tarefa, na causa; e a aula 9
mostrou o que essa frase fez com a relação entre dois times por meses.

Paulo tinha seguido o runbook. O runbook mandava rodar o backfill "quando as zonas de entrega mudarem".
As zonas tinham mudado naquela tarde. Nada no runbook, na tarefa, no banco ou no calendário dizia que
sexta às 19:05 era uma hora ruim, e nada impedia a tarefa de abrir quantas conexões quisesse.
**Qualquer engenheiro da Marola, com aquele runbook naquela tarde, poderia ter feito o mesmo.** É essa a
frase que uma revisão sem culpados procura.

## De onde vem a ideia

John Allspaw, que então chefiava as operações da Etsy, escreveu em 2012 o post que popularizou a
prática, *Blameless PostMortems and a Just Culture*. O argumento dele, apoiado em pesquisas de segurança
na aviação e na saúde, é prático, não gentil: um engenheiro que espera ser punido por um erro dá um
relato que o protege, e a organização perde o detalhe de que precisa. Um engenheiro que espera ouvir
"o que você via, e por que aquilo fazia sentido?" dá o detalhe.

Sidney Dekker, cujo trabalho sobre erro humano sustenta boa parte disso, chama o princípio de
racionalidade local (*local rationality*): as ações das pessoas fazem sentido de onde elas estavam, com
o que conseguiam ver. **O trabalho da revisão é reconstruir onde elas estavam.**

## O que sem culpados não quer dizer

- **Não quer dizer que ninguém responde por nada.** A responsabilidade sai de "quem fez" e vai para
  "quem vai mudar o quê, até quando", e as ações no final têm nomes.
- **Não quer dizer que vale tudo.** Sabotagem deliberada, ou ignorar uma regra por desprezo, não é
  problema de sistema. Esses casos são raros e são tratados como conduta, fora do postmortem.
- **Não quer dizer evitar nomes por completo.** A linha do tempo diz que Paulo iniciou a tarefa às
  19:05, porque ele iniciou. O que ela não faz é parar aí, como se isso explicasse alguma coisa.

::: track tech-lead
A aula 15 de `delivery-metrics` tratou de postmortems sem culpados do lado do tech lead: as ações de
acompanhamento e como fazer com que sejam cumpridas. Esta aula se concentra na escrita e na reunião,
que é onde a culpa entra ou é mantida do lado de fora.
:::

::: track *
O resto desta aula trata da escrita e da reunião, que é onde a culpa entra ou é mantida do lado de
fora.
:::
