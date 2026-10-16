---
title: O que você deixa de fazer
version: 1
---

A promessa de um banco gerenciado é que outra pessoa o opera, e a versão que as pessoas repetem é
que **você deixa de operá-lo**. Você deixa de fazer mais ou menos metade do que as dezenove últimas
aulas fizeram, e a metade que fica é a que decide se os dados estão certos. Esta aula não tem nada a
digitar: não existe conta de nuvem para este curso, então **nenhum comando foi rodado contra
provedor nenhum**, e cada produto aqui é citado pela documentação pública, não mostrado numa tela.

## Os provedores, por produto

Cada um dos três tem um serviço operado pela empresa que o faz, e vários operados por provedores de
nuvem:

| produto | operado por quem o faz | operado por um provedor de nuvem |
|---|---|---|
| MongoDB | MongoDB Atlas | Amazon DocumentDB e Azure Cosmos DB for MongoDB, que são outros motores falando o protocolo do MongoDB (próximas seções) |
| Redis | Redis Cloud | Amazon ElastiCache, Google Cloud Memorystore, Azure Cache for Redis |
| Cassandra | DataStax Astra DB, da empresa que há muito tempo é a principal patrocinadora comercial do Cassandra | Amazon Keyspaces e Azure Cosmos DB for Apache Cassandra, de novo outros motores |

## A linha entre vocês dois

Os provedores chamam isso de **modelo de responsabilidade compartilhada**, e todos desenham a linha
mais ou menos no mesmo lugar:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 330\" role=\"img\" aria-label=\"Uma pilha de responsabilidades de um banco gerenciado, dividida por uma linha. Acima dela, as suas: o modelo de dados e os índices, a shard key e as configurações de consistência, a política de expulsão, a capacidade e sua conta, os testes de restauração e o acesso. Abaixo dela, as do provedor: backups e seu armazenamento, o mecanismo de failover, os patches e as máquinas.\"><text x=\"110\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">seus</text><text x=\"110\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">decisões sobre os dados</text><rect x=\"200\" y=\"14\" width=\"155\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"277.5\" y=\"29.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">modelo de dados, índices</text><rect x=\"365\" y=\"14\" width=\"155\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"442.5\" y=\"29.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">shard key, consistência</text><rect x=\"530\" y=\"14\" width=\"155\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"607.5\" y=\"29.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">política de expulsão</text><rect x=\"200\" y=\"54\" width=\"155\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"277.5\" y=\"69.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">capacidade, e a conta</text><rect x=\"365\" y=\"54\" width=\"155\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"442.5\" y=\"69.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">testes de restauração</text><rect x=\"530\" y=\"54\" width=\"155\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"607.5\" y=\"69.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">quem tem acesso</text><line x1=\"30\" y1=\"112\" x2=\"670\" y2=\"112\" stroke=\"var(--amber)\" stroke-width=\"2\" stroke-dasharray=\"6 4\"></line><text x=\"350\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">a linha da responsabilidade compartilhada</text><text x=\"110\" y=\"175\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\" font-weight=\"600\">do provedor</text><text x=\"110\" y=\"193\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">operar o software</text><rect x=\"220\" y=\"150\" width=\"440\" height=\"32\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"440.0\" y=\"166.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">backups e seu armazenamento</text><rect x=\"220\" y=\"192\" width=\"440\" height=\"32\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"440.0\" y=\"208.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">replicação e mecanismo de failover</text><rect x=\"220\" y=\"234\" width=\"440\" height=\"32\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"440.0\" y=\"250.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">patches, versões menores</text><rect x=\"220\" y=\"276\" width=\"440\" height=\"32\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"440.0\" y=\"292.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">máquinas, discos, rede</text></svg>", "caption": "A linha fica onde começam as decisões sobre os seus dados. Tudo abaixo dela é operado para você; tudo acima é executado como você decidiu, certo ou errado."}
```

Abaixo da linha está tudo o que este curso fez com `docker run`, `rs.initiate()`, `--replicaof`,
`nodetool repair` e um cron. Mais exatamente:

- **As máquinas e suas falhas.** Um disco que morre é trocado e o nó é reconstruído a partir dos
  pares, sem chamado seu.
- **Patches.** Correções de segurança do sistema operacional e versões menores do banco são
  aplicadas numa janela de manutenção que você escolhe e o provedor executa. Versões maiores em
  geral ainda são iniciadas por você, porque podem mudar comportamentos de que a aplicação depende.
- **O mecanismo de failover.** O replica set, o Sentinel, o anel de nós são montados para você entre
  zonas de disponibilidade. A eleição da aula 9 continua acontecendo; você só não monta mais os
  membros entre os quais ela acontece.
- **Backups e seu armazenamento.** Snapshots numa agenda, guardados pela retenção que você escolhe,
  num armazenamento que o provedor paga para tornar durável, e muitas vezes uma restauração para um
  ponto no tempo por cima.
- **O monitoramento da aula 20**, coletado e desenhado no console do provedor, com alertas que você
  configura em vez de exporters que você roda.

## O que não vai embora com eles

**Um failover continua sendo um failover.** O provedor promove um novo primário em segundos, e
durante esses segundos as conexões que a aplicação mantinha caem e as escritas em andamento recebem
erros. Repetir essas escritas e reconectar ao novo primário cabem à aplicação, como cabiam nas aulas
9 e 15, e nenhum serviço escreve esse código por você.

**Gerenciado não é o mesmo que ilimitado.** Todo plano tem um tamanho: memória para um Redis,
armazenamento e operações por segundo para os outros. Chegar a ele se parece exatamente com as aulas
14 e 20, expulsões ou escritas recusadas, com a diferença de que a correção é um plano maior e uma
fatura maior, e não uma VM maior.

**E um backup que o provedor faz continua sendo só um backup até alguém restaurá-lo**, que é o
primeiro item da próxima seção.
