---
title: Ações que acontecem de verdade
version: 1
---

**Um postmortem vale as ações que saem dele e são cumpridas, e nada mais.** A falha mais comum não é
uma análise ruim; é uma boa análise cujas ações são vagas, sem dono e esquecidas até o próximo
incidente, que então tem os mesmos fatores contribuintes e o mesmo relato.

## Três tipos de ação

Todo fator contribuinte pode ser respondido de uma de três maneiras, e uma boa lista tem um pouco de
cada:

| tipo | o que faz | em 6 de março |
|---|---|---|
| **prevenir** | elimina o furo, para que não aconteça mais desse jeito | uma cota de conexões por serviço no banco de pedidos |
| **detectar** | descobre mais cedo, se acontecer mesmo assim | um alerta para conexões do banco acima de 90%, não só para erros do checkout |
| **mitigar** | diminui o estrago, ou acelera a recuperação | um botão de "parar todas as tarefas em lote" no runbook de incidentes |

Uma lista só de *prevenir* supõe que o time encontrou todos os caminhos de entrada. Uma lista só de
*detectar* aceita a falha e apenas a encurta. **Defesa em profundidade quer dizer pelo menos uma de
cada, para os fatores que mais importam.**

## Cada ação tem um dono, uma data e um ticket

A revisão de 6 de março produziu seis ações. Foi assim que elas foram escritas:

| ação | dono | prazo | situação em maio |
|---|---|---|---|
| runbook: nenhum backfill entre 17:00 e 22:00 | Henrique | 7 de março | feita |
| alerta para conexões do banco acima de 90% | Lucas | 20 de março | feita |
| cota de conexões por serviço (uma RFC, aula 2) | Lívia | 1º de maio | feita |
| a tarefa de backfill abre no máximo 10 conexões | Paulo | 27 de março | feita |
| botão de "parar todas as tarefas em lote" no runbook de incidentes | Lucas | 3 de abril | feita |
| réplica de leitura para o planejador de rotas | time de plataforma | abril | feita |

**"Ter mais cuidado" não é uma ação.** Nem "melhorar o monitoramento" ou "aumentar a conscientização".
Uma ação nomeia uma mudança, uma pessoa responsável por ela, uma data e um ticket onde se pode ver em
que pé ela está. Se não dá para escrevê-la assim, ela ainda não está pronta para ser uma ação; é uma
pergunta que alguém precisa responder antes.

Repare em quem é o dono da quarta ação. Paulo, cuja tarefa deu início ao incidente, escolheu ficar com
a correção da própria tarefa. **Numa revisão sem culpados, a pessoa mais próxima do evento costuma ser a
melhor para consertar o sistema em volta dele**, e pedir isso a ela é sinal de confiança, não penitência.

## Acompanhe onde não dá para esquecer

As ações de postmortem da Marola entram no backlog normal do time responsável, marcadas com o
incidente, e o relato do incidente tem link para cada ticket. Uma vez por mês, a reunião de engenharia
gasta cinco minutos com um número: **a fração das ações de postmortem cumpridas dentro do prazo.** No
ano anterior era 40%; depois que a revisão de 6 de março tornou esse número visível, passou de 80%.

## Pequeno e agora, em vez de grande e depois

Uma lista de ações com um projeto enorme ("reescrever o sistema de pedidos") e nada pequeno é uma
lista em que nada acontece por seis meses. A lista de 6 de março teve quatro ações feitas em um mês,
e cada uma, sozinha, fechou um furo. A réplica, a grande, era a que mais importava e já estava
aprovada; ela não precisou carregar a resposta inteira nas costas.
