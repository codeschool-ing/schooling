---
title: Uma camada de armazenamento para o cluster inteiro
version: 1
---

**O AlloyDB é PostgreSQL rodando sobre um sistema de armazenamento que o Google construiu para ele, e
o armazenamento é toda a diferença.** O motor que analisa o seu SQL, planeja a consulta e mantém as
suas transações separadas é PostgreSQL, com os mesmos drivers, o mesmo `psql` e a maior parte das
mesmas extensões. Por baixo dele, onde o Cloud SQL dá a cada instância um disco próprio, o AlloyDB dá
ao cluster inteiro um serviço de armazenamento regional, compartilhado por toda máquina que roda o
motor. Quase todo o resto do AlloyDB, como ele faz failover, como as réplicas acompanham e como é
cobrado, decorre dessa mudança.

**A ideia errada é que o AlloyDB é o Cloud SQL numa máquina maior.** A instância do Cloud SQL da aula
6 é PostgreSQL numa máquina virtual com um persistent disk ligado a ela; o standby da aula 7 tem um
disco mantido em sincronia com ele, e cada réplica de leitura guarda uma cópia inteira só dela. As
máquinas do AlloyDB não são donas de disco nenhum. **Nada nesta seção pode ser executado**: o Google
não publica emulador para o AlloyDB, e o que vem a seguir é ensinado a partir da documentação dele, a
página "AlloyDB overview" em cloud.google.com/alloydb/docs/overview, e da página de preços, lida em
2026-10-30. Não há transcrição aqui, e a aula diz o mesmo sempre que o próprio AlloyDB for o assunto.

## O log desce, as páginas sobem

**Um servidor PostgreSQL que você conhece escreve duas vezes.** De `sql-databases`: uma mudança vai
primeiro para o write-ahead log, que é o que torna um commit durável, e as páginas de dados alteradas
são escritas depois, por um checkpoint. As duas escritas caem no disco que o servidor tem. Esse é o
projeto do Cloud SQL, e as réplicas da aula 7 copiam o log desse disco para os delas.

**Uma primária do AlloyDB escreve só o log, e escreve na camada de armazenamento.** Um commit é
durável assim que os registros de log estão no armazenamento de log regional, que os guarda em mais
de uma zona da região. Depois, um componente que o Google chama de **serviço de processamento de log**
(*log processing service*) lê esse log e o aplica aos blocos de dados, em segundo plano e espalhado
por muitos servidores, de modo que as páginas existem na camada de armazenamento sem que a primária
jamais escreva uma. Quando uma instância precisa de uma página que não tem em memória, pede esse bloco
à camada de armazenamento, e ela devolve a versão que o log diz ser a atual.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"Um cluster do AlloyDB em southamerica-east1. Em cima, quatro nós: a instância primária como um nó ativo e um nó de standby, e um read pool de dois nós; cada nó mantém um cache. Embaixo, uma camada de armazenamento regional em três zonas, com o log e os blocos que o serviço de processamento de log constrói a partir dele. A primária ativa manda para baixo só registros de log; os nós do read pool leem blocos do mesmo armazenamento; a primária também manda seu fluxo de log aos outros nós para que os caches fiquem corretos.\" data-fig=\"l08-alloydb-storage\"><defs><marker id=\"ah-l08-alloydb-storage\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M 0 0 L 10 5 L 0 10 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"310\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"24\" y=\"26\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">cluster quitanda-orders, uma região</text><rect x=\"40\" y=\"50\" width=\"140\" height=\"62\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"110\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">ativo</text><text x=\"110\" y=\"87\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">instância primária</text><text x=\"110\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">memória + cache local</text><rect x=\"190\" y=\"50\" width=\"140\" height=\"62\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"260\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">standby</text><text x=\"260\" y=\"87\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">instância primária</text><text x=\"260\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">memória + cache local</text><rect x=\"380\" y=\"50\" width=\"140\" height=\"62\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"450\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">nó 1</text><text x=\"450\" y=\"87\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">read pool</text><text x=\"450\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">memória + cache local</text><rect x=\"530\" y=\"50\" width=\"140\" height=\"62\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"600\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">nó 2</text><text x=\"600\" y=\"87\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">read pool</text><text x=\"600\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">memória + cache local</text><rect x=\"30\" y=\"190\" width=\"660\" height=\"110\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">camada de armazenamento regional, de todos os nós</text><rect x=\"45\" y=\"220\" width=\"200\" height=\"68\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"145\" y=\"234\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">southamerica-east1-a</text><text x=\"145\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">armazenamento do log</text><text x=\"145\" y=\"272\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">blocos, feitos a partir do log</text><rect x=\"260\" y=\"220\" width=\"200\" height=\"68\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"234\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">southamerica-east1-b</text><text x=\"360\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">armazenamento do log</text><text x=\"360\" y=\"272\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">blocos, feitos a partir do log</text><rect x=\"475\" y=\"220\" width=\"200\" height=\"68\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"575\" y=\"234\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">southamerica-east1-c</text><text x=\"575\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">armazenamento do log</text><text x=\"575\" y=\"272\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">blocos, feitos a partir do log</text><line x1=\"110\" y1=\"112\" x2=\"110\" y2=\"218\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" marker-end=\"url(#ah-l08-alloydb-storage)\"></line><text x=\"118\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">só registros de log</text><line x1=\"450\" y1=\"218\" x2=\"450\" y2=\"114\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" marker-end=\"url(#ah-l08-alloydb-storage)\"></line><line x1=\"600\" y1=\"218\" x2=\"600\" y2=\"114\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" marker-end=\"url(#ah-l08-alloydb-storage)\"></line><text x=\"458\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">blocos, quando o cache falha</text><line x1=\"180\" y1=\"81\" x2=\"380\" y2=\"81\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\" marker-end=\"url(#ah-l08-alloydb-storage)\"></line><text x=\"285\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">fluxo de log, para os caches</text><line x1=\"250\" y1=\"112\" x2=\"250\" y2=\"140\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></line></svg>", "caption": "Um cluster, uma camada de armazenamento: a primária escreve o log, o armazenamento constrói as páginas, e todo nó as lê.", "same": ["standby", "read pool"]}
```

**Cada máquina ainda mantém um cache, e mantém dois.** O primeiro é o buffer cache do próprio
PostgreSQL, em memória, o `shared_buffers` que você pode ver com `SHOW` em qualquer PostgreSQL. O
segundo é o que a documentação do Google chama de **ultra-fast cache**, uma camada maior no
armazenamento local do nó, para que uma página expulsa da memória continue por perto. Uma leitura só
chega ao serviço de armazenamento quando os dois falham, e é isso que impede uma camada de
armazenamento remota de deixar toda consulta mais lenta.

## O que a camada compartilhada muda

**O armazenamento é uma propriedade do cluster, e é cobrado pelo que guarda.** Não há tamanho de disco
para escolher nem para aumentar: a página de preços diz que o armazenamento regional "automatically
scales up and down" e que "you only pay for the storage you use". Diz também que o custo do
armazenamento não muda quando se acrescentam instâncias ou nós de read pool, porque toda instância lê
o mesmo armazenamento. Um disco do Cloud SQL é um tamanho que alguém escolheu, pago inteiro desde o
primeiro dia e mais uma vez para cada réplica; um cluster do AlloyDB com 37 GiB paga 37, uma vez.

**Uma réplica é uma leitora dos mesmos dados, não uma cópia deles.** Um nó de leitura do AlloyDB não
reaplica o log em páginas próprias. Ele lê blocos da camada de armazenamento como a primária, e recebe
o fluxo de log da primária só para manter os seus caches corretos. É por isso que as réplicas do
AlloyDB são documentadas como acompanhando com um atraso curto, que não cresce com o tamanho do
banco, e por isso não há nada a ressincronizar quando uma é acrescentada.

**Um failover não move dados**, e aqui a diferença para o Cloud SQL é menor do que parece. O standby de
uma primária do AlloyDB de alta disponibilidade lê o mesmo armazenamento, então quando o nó ativo
falha, o standby só precisa assumir as escritas. O standby do Cloud SQL da aula 7 está na mesma
posição por outro motivo, um disco replicado de forma síncrona entre duas zonas. Onde os dois projetos
se separam é nas réplicas de leitura: as do Cloud SQL guardam cada uma uma cópia que precisa ser
construída e mantida em dia, e as do AlloyDB não guardam nenhuma. A próxima seção mostra os comandos
que montam os dois formatos.

## O que ela não muda

**Continua havendo exatamente um escritor.** Toda escrita de um cluster passa pela instância primária,
e uma primária é uma máquina de cada vez. A página de preços põe o teto em 288 vCPUs e 2.232 GiB de
memória por nó, que é uma máquina muito grande e ainda assim uma só. Um cluster com mais tráfego de
leitura do que uma máquina atende acrescenta nós de leitura; um cluster com mais tráfego de
**escrita** do que a maior máquina absorve não tem próximo passo dentro do AlloyDB, e é nessa linha
que começa o Spanner da aula 9.

**E o motor continua sendo PostgreSQL**, que é a razão de comprá-lo. Uma consulta lenta porque falta
um índice é igualmente lenta no AlloyDB, e criar o índice continua sendo a cura. O que a camada de
armazenamento compra é tudo o que fica abaixo do motor: durabilidade entre zonas, armazenamento que
cresce sozinho, réplicas sem cópia e failover sem nada para alcançar. A terceira seção desta aula
mostra a única mudança que o AlloyDB faz acima do armazenamento, dentro do próprio motor.
