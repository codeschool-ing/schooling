---
title: A linha do tempo, a partir das marcas
version: 1
---

Quando o incidente acaba, o primeiro documento dele é uma **linha do tempo**: o que aconteceu, quando, em
ordem. Montada de memória, ela erra do jeito que a memória erra, com eventos misturados, horários
arredondados e duas ações trocadas de ordem. Montada a partir das marcas que as pessoas e as máquinas
deixaram, ela é exata.

O laboratório tem duas fontes: as anotações no Grafana, escritas pelo robô de deploy e por quem comanda,
e o log do pager, escrito pelo webhook do Alertmanager. Um comando junta as duas, ordenadas pelo
horário:

```
ana@obs:~/shop$ { curl -s -H "Authorization: Bearer $(cat .grafana-token)" 'localhost:3000/api/annotations?from='$(date -d '-30 min' +%s000) | jq -r '.[] | [(.time/1000 | strftime("%H:%M:%S")), "mark", .text] | @tsv'; docker compose logs --no-log-prefix pager | grep '"PAGE"' | jq -r '[.time[11:19], "pager", "\(.status) \(.alertname)"] | @tsv'; } | sort
20:46:49	mark	payments 1.4.2
20:49:58	pager	firing CheckoutBudgetBurningFast
20:50:00	mark	SEV-2 declared: checkouts failing, IC ana
20:51:01	mark	payments rolled back to 1.4.0
20:51:58	pager	resolved CheckoutBudgetBurningFast
20:55:55	mark	resolved: 5-minute burn rate below 1, checkouts normal
```

Leia como o postmortem vai ler, todos os horários em UTC:

| horário | o que aconteceu |
|---|---|
| 20:46:49 | a versão 1.4.2 do payments é lançada, e os checkouts começam a falhar |
| 20:49:58 | o alerta de queima rápida aciona quem está de plantão |
| 20:50:00 | um SEV-2 é declarado, com a ana no comando |
| 20:51:01 | o payments é revertido para a 1.4.0 |
| 20:51:58 | o page é resolvido |
| 20:55:55 | o incidente é encerrado, com a taxa de queima de cinco minutos abaixo de 1 |

Cada intervalo é uma pergunta para a revisão. O primeiro é o **tempo para detectar**: três minutos e
nove segundos da versão ao page. Reverter levou mais um minuto, a investigação da seção anterior, e o
incidente foi encerrado nove minutos depois de começar. A aula 18 transforma esses intervalos nos
números que as equipes acompanham, e escreve o postmortem que parte desta lista.

Dois hábitos deixam a linha do tempo fácil assim:

- **Toda ação humana é marcada quando é tomada**, pela pessoa ou pelo escriba. Uma marca custa um
  comando; reconstruí-la um dia depois custa uma discussão.
- **Toda máquina guarda horários num fuso só.** As anotações voltam em UTC pelo `strftime` do `jq`, e os
  serviços registram em UTC. Uma linha do tempo que junta um log no horário local com um em UTC põe a
  reversão três horas antes da versão.
