---
title: O postmortem sem culpados
version: 1
---

**Um postmortem é escrito para tornar o próximo incidente menos provável, e culpar uma pessoa faz o contrário.** O activity
log diz que Bruno reduziu o banco. Um postmortem que para aí, *Bruno errou*, produz uma ação, *Bruno deve tomar mais
cuidado*, que não conserta nada e ensina todo mundo a esconder a próxima mudança. As perguntas que produzem ações são sobre o
sistema: **por que isso era possível, por que parecia razoável, e por que levou 23 minutos depois da chamada para achar?**

Bruno estava cortando custo, o que a lição 23 pede que as pessoas façam, num banco que parecia superdimensionado o mês todo.
Ele foi recusado uma vez às 13:58 por falta de um papel e depois o recebeu, o que fez a mudança parecer autorizada. Nada
ligava o tamanho do banco à carga da tarde de quinta. Cada uma dessas é uma condição que qualquer outra pessoa poderia ter
encontrado, e cada uma vira uma ação.

O postmortem da loja tem uma página:

```
Checkout failures, 15 October 2026                               SEV2, blameless

Summary      42 minutes in which about two in three checkouts failed.
Impact       103 failed checkouts; 87% of the week's error budget.
Detection    burn-rate page at 14:15, 10 minutes after the first failure.
Trigger      sql-shop/shop scaled from S3 to S1 at 14:02, by hand, to cut cost.
Resolution   scaled back to S3 at 14:44.

Contributing factors
  - a production database could be resized from the portal with no review
  - nothing tied a database's size to the load it was carrying
  - the runbook did not start with "what changed?"

Actions                                                      owner     due
  - database size in Bicep; changes through the pipeline     platform  22 Oct
  - DTU-percentage alert on sql-shop, severity 2             carla     20 Oct
  - runbook step 1: the activity-log timeline query          carla     16 Oct
  - rightsizing reviewed in lesson 23's way, not by hand     bruno     30 Oct
```

Quatro regras o fazem funcionar:

- **ele nomeia o gatilho e não um culpado**: a mudança, a hora e o propósito, na voz passiva se for preciso;
- **fatores contribuintes são plural**: raramente há uma causa raiz só, e um modelo com uma caixa para ela produz uma resposta
  só;
- **toda ação tem dono e data**, ou é um desejo;
- **ele é lido**, numa reunião curta, pelas pessoas envolvidas e pelos donos das ações.

Os horários nele vêm das consultas desta lição, e esse é o outro motivo de a linha do tempo ser montada a partir de
registros: um postmortem cujos números vieram da memória começa uma discussão sobre os números.

O modelo acima está em inglês, como todo bloco de código deste curso; um postmortem da sua equipe é escrito na língua dela.
