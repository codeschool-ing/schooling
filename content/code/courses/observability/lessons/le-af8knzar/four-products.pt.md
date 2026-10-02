---
title: Quatro produtos, quatro histórias
version: 1
---

Os quatro do título desta aula não são quatro versões da mesma coisa. **Cada um começou com um problema
e cresceu na direção dos outros**, e onde ele começou ainda aparece no que faz melhor e no que cobra.

| | começou como | coleta com | cobra principalmente por |
|---|---|---|---|
| Datadog | métricas de infraestrutura para servidores na nuvem, 2010 | o Datadog Agent em cada host, mais uma biblioteca de rastreamento por linguagem | hosts, mais o volume de logs, spans indexados e métricas customizadas |
| New Relic | desempenho de aplicações para Ruby on Rails, 2008 | um agente por linguagem | dados ingeridos, em gigabytes, mais o número de usuários completos |
| Dynatrace | monitoramento profundo de aplicações Java e .NET corporativas | o OneAgent, instalado uma vez por host, que instrumenta todo processo que acha | consumo: memória de host por hora, dados ingeridos e consultas |
| Sentry | um registrador de erros de código aberto para Django, 2008 | um SDK por linguagem, dentro da aplicação | eventos: erros, spans, replays |

Leia a última coluna como um conjunto de unidades, e não de preços. Os preços mudam todo ano e variam
por contrato, e a página de preços de cada produto é a única fonte que vale citar. **A unidade é o que
dura**, e é ela que decide qual dos seus hábitos fica caro.

Três diferenças importam na prática:

- **O Dynatrace instrumenta sem que peçam.** O OneAgent acha os processos de um host e injeta a
  instrumentação em cada um, então os rastros aparecem antes de alguém escrever código. É o mais longe
  que qualquer um deles vai dos spans escritos à mão da aula 2, e a análise causal dele, que o produto
  chama de Davis, se apoia nesse quadro completo.
- **O Datadog é o mais amplo.** Ele começou pelo host e pela conta de nuvem, e as integrações dele,
  centenas, são o motivo de a maioria das equipes adotá-lo; APM e logs vieram depois e são cobrados à
  parte.
- **O Sentry é sobre o erro.** Ele agrupa exceções em issues, acompanha-as entre versões e avisa quando
  uma corrigida volta. Acrescentou rastreamento depois, e é o único dos quatro cujo servidor você
  mesmo pode rodar.

Elastic, Grafana Cloud e Honeycomb vendem o mesmo tipo de coisa e aparecem nas mesmas avaliações; os
dois primeiros são as formas hospedadas de armazenamentos que este curso rodou.
