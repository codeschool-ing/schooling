---
title: Escalonamento: quando o page não é atendido
version: 1
---

Um page é uma pergunta a uma pessoa, e pessoas às vezes estão dormindo, no metrô ou no banho.
**Escalonamento é a regra do que acontece quando o page não é reconhecido**: depois de alguns minutos, a
próxima pessoa é acionada, e depois a próxima.

Um reconhecimento (acknowledgement) é a pessoa dizendo *estou com isto*; ele para o escalonamento e diz
a todos os outros que alguém está olhando. O Alertmanager não tem essa ideia. Ele manda, agrupa e
repete, mas não sabe se um humano leu a mensagem, e é por isso que o pager do laboratório é um log e que
equipes reais põem um serviço de acionamento entre o Alertmanager e o telefone: PagerDuty, Opsgenie,
Grafana OnCall, ou o recurso de acionamento da ferramenta de chat delas. Esses guardam a escala, recebem
o reconhecimento e rodam a política de escalonamento:

| passo | depois de | quem é acionado |
|---|---|---|
| 1 | imediatamente | o plantonista principal, por notificação e depois ligação |
| 2 | 10 minutos sem reconhecimento | o segundo plantonista |
| 3 | 20 minutos | a liderança da equipe |
| 4 | 30 minutos | a direção de engenharia |

Os tempos são escolhidos contra o objetivo: uma taxa de queima de 14,4 gasta 2% do orçamento do mês por
hora, então vinte minutos sem ninguém olhando custam uns 0,7%, o que uma equipe pode decidir que é
aceitável antes de acordar alguém da liderança.

O escalonamento também corre **para o lado**: quem está de plantão aciona outra equipe quando o problema
é dela. Isso só funciona se toda equipe tem a própria escala e um jeito documentado de ser alcançada, e
um serviço sem isso é um serviço cujos incidentes terminam às três da manhã na agenda pessoal do celular
de alguém.
