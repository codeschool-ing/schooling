---
title: O postmortem sem culpa
version: 1
---

Um postmortem é um documento escrito depois do incidente, e o propósito dele é o próximo incidente: **o
que no sistema permitiu que isto acontecesse, e o que o tornará menos provável ou menos caro**. Ele é
**sem culpa** por regra, e a regra não é educação. Uma revisão que conclui "a Carla implantou uma
mudança ruim" achou o último passo, e o sistema que deixou uma mudança ruim chegar a todos os clientes
continua lá para a próxima pessoa. Quem espera culpa para de contar a história inteira, e a revisão perde
exatamente os detalhes que explicariam o incidente.

## As perguntas, em ordem

1. **Impacto**: quem foi afetado, como, por quanto tempo, e quanto do orçamento de erro isso gastou
   (lição 12).
2. **Linha do tempo**: a da seção anterior, com as decisões das pessoas acrescentadas.
3. **Detecção**: como foi percebido, e quanto isso levou? Um alerta poderia ter percebido antes?
4. **Resposta**: o que funcionou, o que atrasou a equipe: um runbook que faltava, uma permissão que
   ninguém tinha, um painel que mentiu.
5. **Fatores contribuintes**: no plural. Incidentes raramente têm uma causa só, e "causa raiz" convida a
   busca a parar na primeira encontrada.
6. **Ações**: cada uma com dono e data, cada uma mudando o sistema em vez de pedir às pessoas mais
   cuidado.

## Ações que mudam o sistema

"Ter mais cuidado ao implantar" não é uma ação: ninguém pode ficar com ela e ninguém sabe quando está
feita. As ações que valem a pena mudam algo que permanece:

| fator contribuinte | uma ação fraca | uma ação que muda o sistema |
|---|---|---|
| um release ruim chegou a todos os clientes | testar com mais cuidado | canário com alarme só na versão nova (lição 3) |
| o alarme ficou quieto quando o serviço morreu | olhar o painel | tratar dado ausente como ruim (lição 10) |
| o arquivo de estado foi apagado à mão | ter cuidado no console | uma política de bucket recusando a exclusão (lição 7) |
| um cliente percebeu primeiro | monitorar melhor | um alerta de taxa de queima no checkout (lição 12) |

Cada célula da direita é uma mudança que alguém pode fazer, revisar e terminar, e cada uma veio de uma
lição anterior deste curso, o que não é coincidência: **operação é, em grande parte, as ações acumuladas
de postmortems anteriores**.

## A reunião e o documento

A reunião de revisão percorre a linha do tempo com todos que participaram, em poucos dias, enquanto a
memória está fresca, e quem a conduz é alguém que não esteve envolvido. O documento é compartilhado
amplamente, porque os fatores contribuintes do incidente de uma equipe costumam estar presentes no
serviço de outra. E a lista de ações é acompanhada até o fim: **um postmortem cujas ações nunca são
feitas é a descrição do próximo incidente**.
