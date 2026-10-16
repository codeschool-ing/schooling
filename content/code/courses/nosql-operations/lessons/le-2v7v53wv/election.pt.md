---
title: Perder o primário, e a eleição que vem depois
version: 1
---

Um primário sai de cena de dois jeitos, e por dentro eles não se parecem em nada. **Alguém o para**,
para uma atualização ou um reinício, e ele tem tempo de passar o cargo. **Ou ele morre**, uma queda
de energia ou um processo morto, e os outros precisam perceber o silêncio. O MongoDB leva
milissegundos no primeiro caso e uns dez segundos no segundo, e o laboratório mostra os dois.

## Uma parada planejada

```sh
docker stop -t 30 mongo1
```

`-t 30` dá ao servidor trinta segundos para parar de forma limpa antes de o Docker matá-lo. O padrão
do Docker é dez, e um membro de replica set leva mais que isso: ele renuncia ao cargo e então passa
até quinze segundos avisando os clientes de que está saindo antes de terminar.

```
ana@vm:~$ docker stop -t 30 mongo1
mongo1
ana@vm:~$ docker exec mongo2 mongosh --quiet --eval 'rs.status().members.map(m => ({ name: m.name, state: m.stateStr, health: m.health }))'
[
  { name: 'mongo1:27017', state: '(not reachable/healthy)', health: 0 },
  { name: 'mongo2:27017', state: 'PRIMARY', health: 1 },
  { name: 'mongo3:27017', state: 'SECONDARY', health: 1 }
]
ana@vm:~$ docker inspect --format '{{.State.FinishedAt}}' mongo1
2026-10-10T07:55:05.943247343Z
ana@vm:~$ docker exec mongo2 mongosh --quiet --eval 'const m = rs.status().electionCandidateMetrics; ({ reason: m.lastElectionReason, electedAt: m.lastElectionDate, writableAt: m.wMajorityWriteAvailabilityDate })'
{
  reason: 'stepUpRequestSkipDryRun',
  electedAt: ISODate('2026-10-10T07:54:50.897Z'),
  writableAt: ISODate('2026-10-10T07:54:50.915Z')
}
```

Leia os dois horários um contra o outro. O `mongo2` foi eleito às 07:54:50.897 e pôde aceitar
escritas majority 18 ms depois; o `mongo1` terminou de parar às 07:55:05.943, quinze segundos
depois de o sucessor já estar trabalhando. O motivo, `stepUpRequestSkipDryRun`, dá nome ao
mecanismo: um primário que renuncia **pede a um secundário atualizado que assuma na hora**, e a
eleição pula o ensaio de costume porque o primário antigo já abriu mão do cargo.

## Uma queda

O `docker kill` manda `SIGKILL`, que encerra o processo sem chance de dizer nada, o mais perto que
um contêiner chega de puxar o cabo da tomada. Traga o `mongo1` de volta primeiro, para que o
conjunto tenha três membros de novo, e mate quem for o primário agora, o `mongo2` nesta execução:

```
ana@vm:~$ docker start mongo1
mongo1
ana@vm:~$ docker exec mongo1 mongosh --quiet --eval 'rs.status().members.map(m => ({ name: m.name, state: m.stateStr, health: m.health }))'
[
  { name: 'mongo1:27017', state: 'SECONDARY', health: 1 },
  { name: 'mongo2:27017', state: 'PRIMARY', health: 1 },
  { name: 'mongo3:27017', state: 'SECONDARY', health: 1 }
]
ana@vm:~$ docker kill mongo2
mongo2
ana@vm:~$ docker inspect --format '{{.State.FinishedAt}}' mongo2
2026-10-10T07:55:23.100639701Z
ana@vm:~$ docker exec mongo3 mongosh --quiet --eval 'const m = rs.status().electionCandidateMetrics; ({ reason: m.lastElectionReason, electedAt: m.lastElectionDate, writableAt: m.wMajorityWriteAvailabilityDate })'
{
  reason: 'electionTimeout',
  electedAt: ISODate('2026-10-10T07:55:31.752Z'),
  writableAt: ISODate('2026-10-10T07:55:31.860Z')
}
```

O `mongo1` voltou como secundário e continuou secundário. O `mongo2` morreu às 07:55:23.101 e o
`mongo3` foi eleito às 07:55:31.752, **8,65 segundos sem primário nenhum**. O motivo agora é
`electionTimeout`: os membros trocam um heartbeat a cada dois segundos, e um secundário que não tem
notícia de um primário há `electionTimeoutMillis`, dez segundos por padrão, convoca uma eleição. Os
dez segundos contam a partir do último heartbeat que o secundário recebeu, e não do instante da
queda, e é por isso que o intervalo aqui fica um pouco abaixo de dez.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 250\" role=\"img\" aria-label=\"Uma linha do tempo da queda capturada nesta aula. Três faixas, uma por membro. mongo2 é primário até ser morto no segundo 0; os heartbeats que os outros lhe mandam a cada dois segundos ficam sem resposta. Por 8,65 segundos não há primário. Então mongo3 se candidata, mongo1 vota nele, e mongo3 vira primário; ele aceita escritas majority 0,11 segundo depois.\"><defs><marker id=\"el9-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"el9-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><text x=\"24\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">mongo2</text><line x1=\"100\" y1=\"60\" x2=\"632\" y2=\"60\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"2 4\"></line><text x=\"24\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">mongo3</text><line x1=\"100\" y1=\"120\" x2=\"632\" y2=\"120\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"2 4\"></line><text x=\"24\" y=\"180\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">mongo1</text><line x1=\"100\" y1=\"180\" x2=\"632\" y2=\"180\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"2 4\"></line><line x1=\"176\" y1=\"35\" x2=\"176\" y2=\"200\" stroke=\"var(--amber)\" stroke-width=\"1\" stroke-dasharray=\"4 3\"></line><line x1=\"504.7\" y1=\"35\" x2=\"504.7\" y2=\"200\" stroke=\"var(--amber)\" stroke-width=\"1\" stroke-dasharray=\"4 3\"></line><line x1=\"178\" y1=\"205\" x2=\"502.7\" y2=\"205\" stroke=\"var(--amber)\" stroke-width=\"1\" marker-end=\"url(#el9-ah-amber)\" marker-start=\"url(#el9-ah-amber)\"></line><text x=\"340.35\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">sem primário por 8,65 s</text><rect x=\"100\" y=\"51\" width=\"76\" height=\"18\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"138.0\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">primário</text><text x=\"172\" y=\"42\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">morto</text><text x=\"252\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--amber)\">×</text><text x=\"328\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--amber)\">×</text><text x=\"404\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--amber)\">×</text><text x=\"480\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--amber)\">×</text><text x=\"366\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">heartbeats sem resposta</text><rect x=\"100\" y=\"111\" width=\"404.7\" height=\"18\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"138.0\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">secundário</text><rect x=\"504.7\" y=\"111\" width=\"127.30000000000001\" height=\"18\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"568.35\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">primário</text><rect x=\"100\" y=\"171\" width=\"532\" height=\"18\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"138.0\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">secundário</text><line x1=\"504.7\" y1=\"170\" x2=\"504.7\" y2=\"132\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#el9-ah-phosphor)\"></line><text x=\"482.7\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">voto</text><text x=\"508.7\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">eleito 8,65 s</text><text x=\"512.7\" y=\"142\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">escritas majority 8,76 s</text><line x1=\"176\" y1=\"222\" x2=\"176\" y2=\"226\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><text x=\"176\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">0</text><line x1=\"252\" y1=\"222\" x2=\"252\" y2=\"226\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><text x=\"252\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">2</text><line x1=\"328\" y1=\"222\" x2=\"328\" y2=\"226\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><text x=\"328\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">4</text><line x1=\"404\" y1=\"222\" x2=\"404\" y2=\"226\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><text x=\"404\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">6</text><line x1=\"480\" y1=\"222\" x2=\"480\" y2=\"226\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><text x=\"480\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">8</text><line x1=\"556\" y1=\"222\" x2=\"556\" y2=\"226\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><text x=\"556\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">10</text><line x1=\"632\" y1=\"222\" x2=\"632\" y2=\"226\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><text x=\"632\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">12</text><text x=\"632\" y=\"218\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">segundos depois do kill</text></svg>", "caption": "A queda, tirada da captura. Ninguém decide que o primário morreu: os secundários deixam de ouvi-lo, e o timeout de eleição de dez segundos, contado a partir do último heartbeat recebido, faz o resto."}
```

Durante esses nove segundos uma escrita não tem para onde ir. Um driver a segura e tenta de novo
quando aparece um novo primário, e por isso uma aplicação bem configurada vê uma requisição lenta em
vez de um erro; uma escrita que dura mais que a paciência do driver falha. **Dez segundos são uma
troca, não uma constante.** Diminua o valor e uma queda custa menos, e uma rede que trava por alguns
segundos passa a provocar eleições de que ninguém precisava.

## O primário antigo volta

```
ana@vm:~$ docker start mongo2
mongo2
ana@vm:~$ docker exec mongo2 mongosh --quiet --eval 'rs.status().members.map(m => ({ name: m.name, state: m.stateStr, health: m.health }))'
[
  { name: 'mongo1:27017', state: 'SECONDARY', health: 1 },
  { name: 'mongo2:27017', state: 'SECONDARY', health: 1 },
  { name: 'mongo3:27017', state: 'PRIMARY', health: 1 }
]
```

O `mongo2` voltou como secundário. Ele não retoma o cargo: o conjunto tem um primário, e nada na
configuração prefere o `mongo2`. Ele buscou no oplog do `mongo3` o que tinha perdido e seguiu
copiando.

**Quem vence é decisão dos servidores, não sua.** Nesta execução foi o `mongo2` e depois o `mongo3`;
na sua pode ser outro, e todo comando daqui em diante usa os nomes que o seu próprio `rs.status()`
imprimiu. Uma aplicação nunca precisa saber: a próxima seção se conecta do jeito que uma aplicação se
conecta, e encontra o primário sozinha.
