---
title: De controller a operator
version: 1
---

**Um operator é um controller que codifica como operar um software em particular**, escrito por
pessoas que o conhecem bem. O controller de Backups sabe uma coisa, um horário. Um operator de
PostgreSQL, como o CloudNativePG da lição 28, sabe criar um primário e réplicas, promover uma réplica
quando o primário morre, arquivar o write-ahead log num bucket, e atualizar entre versões principais na
ordem certa. Cada uma dessas coisas é um ciclo de reconciliação sobre objetos como `Cluster` e
`Backup`, e cada uma substitui uma página de manual de operação que alguém seguia às três da manhã.

| | um controller | um operator |
|---|---|---|
| observa | qualquer tipo, nativo ou customizado | os tipos customizados de uma aplicação |
| sabe | como fazer os objetos baterem | como operar aquela aplicação: failover, backup, atualização |
| exemplos | os controllers de Deployment, Job e de nós | CloudNativePG, Strimzi para Kafka, cert-manager |
| escrito por | o Kubernetes, ou você | quem é especialista na aplicação, normalmente |

Antes de escrever um, vale perguntar se já existe: para software muito usado, um operator que outra
pessoa mantém é quase sempre melhor que um novo, e as perguntas a fazer a ele são as desta lição. O que
ele reconcilia, o que faz quando não alcança a API, e o que apaga quando o objeto dele vai embora.

**Um operator roda com permissões amplas**, muitas vezes entre namespaces, então instalar um é uma
decisão de confiança tanto quanto de conveniência, do mesmo jeito que a lição 37 disse de um chart. Vale
ler o RBAC dele antes de ele rodar.
