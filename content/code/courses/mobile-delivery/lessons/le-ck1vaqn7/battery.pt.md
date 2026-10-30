---
title: Bateria
version: 1
---

**Um app que drena a bateria é desinstalado, e a pessoa raramente diz por quê.** O uso de bateria é
o tipo de desempenho mais difícil de ver, porque acontece quando ninguém está olhando o app: em
segundo plano, com o celular no bolso. *Lido na documentação do Android sobre o Android vitals e
sobre wake locks, outubro de 2026; não rodado.*

## O que o Android conta

Um **wake lock** mantém o processador acordado com a tela apagada, para uma tarefa terminar. Segurado
por tempo demais, ele impede o celular de dormir. O Android vitals informa **wake locks parciais
excessivos**: uma sessão em que os wake locks parciais do app, somados, duram **duas horas ou mais em
24 horas**. O limite de mau comportamento, como nos crashes, é uma fração das sessões:

| | limite de mau comportamento |
|---|---|
| wake locks parciais excessivos | 5% das sessões |
| uso excessivo de bateria | 1% |

**Despertares excessivos**, alarmes que acordam o celular com frequência demais, e **rede e buscas de
Wi-Fi em segundo plano** também são informados.

## O que o planner faz em segundo plano

Ele sincroniza sessões com o servidor e agenda lembretes. Os dois têm versões caras e baratas:

| | cara | barata |
|---|---|---|
| sincronizar | um timer que acorda a cada cinco minutos, em qualquer rede | o agendador do sistema, o **WorkManager** no Android e o **BGTaskScheduler** no iOS, uma vez por hora, quando há rede |
| lembretes | um alarme exato por sessão, lição 5 | um alarme inexato, ou uma notificação local agendada que o sistema entrega |

As versões baratas deixam o **sistema** escolher quando rodar, juntando o trabalho de muitos apps
num único despertar. Essa é toda a ideia: um app que pede ao sistema sai mais barato que um app que
insiste.

## iOS e React Native

O iOS dá aos apps muito menos tempo em segundo plano, para começo de conversa, e informa o que eles
usam no Organizer do Xcode e nos logs de energia do MetricKit. Apps React Native usam os mesmos
agendadores nativos por bibliotecas como o módulo de tarefas em segundo plano do Expo, então a mesma
escolha é feita ali, e o custo aparece nos mesmos relatórios nativos.
