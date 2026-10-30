---
title: Alta disponibilidade, réplicas de leitura e a restauração
version: 1
---

**Um banco de dados pode falhar de dois jeitos: a máquina pode ir embora, ou alguém pode cometer um
erro.** Um flexible server tem uma cópia diferente para cada um, e uma terceira para leitura, e
confundi-las é o jeito mais comum de descobrir num incidente que a cópia pela qual você pagou era a
errada.

**Esta seção é ensinada a partir da documentação da Microsoft, e nada nela foi rodado**: replicação e
failover entre máquinas são exatamente o que um contêiner num laptop não consegue mostrar.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"Uma escrita, no tempo da esquerda para a direita, em quatro raias: a aplicação, o primário na zona 1, o standby de alta disponibilidade na zona 2 e uma réplica de leitura. A aplicação manda COMMIT; o primário a escreve no standby, o standby confirma, e só então o primário responde OK. Depois do OK, o primário envia a mudança para a réplica de leitura, que a aplica mais tarde. O intervalo entre o OK e a réplica aplicá-la é o atraso da réplica.\" data-fig=\"l10-ha\"><defs><marker id=\"arr-l10-ha-amber\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M 0 0 L 10 5 L 0 10 z\" fill=\"var(--amber)\"></path></marker><marker id=\"arr-l10-ha-phosphor\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M 0 0 L 10 5 L 0 10 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"20\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">aplicação</text><line x1=\"170\" y1=\"50\" x2=\"700\" y2=\"50\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line><text x=\"20\" y=\"105\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">primário, zona 1</text><line x1=\"170\" y1=\"105\" x2=\"700\" y2=\"105\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line><text x=\"20\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">standby, zona 2</text><line x1=\"170\" y1=\"160\" x2=\"700\" y2=\"160\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line><text x=\"20\" y=\"215\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">réplica de leitura</text><line x1=\"170\" y1=\"215\" x2=\"700\" y2=\"215\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line><line x1=\"190\" y1=\"50\" x2=\"228\" y2=\"101\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" marker-end=\"url(#arr-l10-ha-phosphor)\"></line><text x=\"200\" y=\"32\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">COMMIT</text><line x1=\"240\" y1=\"105\" x2=\"278\" y2=\"156\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" marker-end=\"url(#arr-l10-ha-phosphor)\"></line><line x1=\"290\" y1=\"160\" x2=\"328\" y2=\"109\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" marker-end=\"url(#arr-l10-ha-phosphor)\"></line><line x1=\"340\" y1=\"105\" x2=\"378\" y2=\"54\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" marker-end=\"url(#arr-l10-ha-phosphor)\"></line><text x=\"392\" y=\"32\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">OK</text><text x=\"285\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">síncrono: o OK espera</text><line x1=\"420\" y1=\"105\" x2=\"588\" y2=\"211\" stroke=\"var(--amber)\" stroke-width=\"1.6\" marker-end=\"url(#arr-l10-ha-amber)\"></line><text x=\"505\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">assíncrono: enviado depois do OK</text><circle cx=\"596\" cy=\"215\" r=\"5\" fill=\"var(--amber)\" stroke=\"none\"></circle><text x=\"610\" y=\"200\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">aplicada</text><line x1=\"384\" y1=\"240\" x2=\"384\" y2=\"252\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"596\" y1=\"240\" x2=\"596\" y2=\"252\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"384\" y1=\"246\" x2=\"596\" y2=\"246\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><text x=\"490\" y=\"264\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">atraso da réplica</text><line x1=\"384\" y1=\"54\" x2=\"384\" y2=\"240\" stroke=\"var(--paper-dim)\" stroke-width=\"0.8\" stroke-dasharray=\"2 2\"></line><text x=\"690\" y=\"270\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">tempo</text></svg>", "caption": "O standby da alta disponibilidade fica sabendo de toda escrita antes do OK; uma réplica de leitura só depois, e é por isso que ela pode ser lida e pode estar atrasada."}
```

## Alta disponibilidade, para a máquina

**A alta disponibilidade mantém um servidor standby que recebe toda escrita antes de o commit
voltar.** Quando o primário falha, o Azure promove o standby e o nome do servidor passa para
ele, e a aplicação se reconecta a um banco que não perdeu nada confirmado. Há dois modos, e o provider
os lista quando recebe um terceiro:

```
ana@laptop:~/azure/tf/flex$ sed -i.bak 's/"ZoneRedundant"/"ZoneRedundant2"/' main.tf && terraform validate -no-color 2>&1 | grep Error; mv main.tf.bak main.tf
Error: expected high_availability.0.mode to be one of ["SameZone" "ZoneRedundant"], got ZoneRedundant2
```

| modo | onde fica o standby | o que ele aguenta |
|---|---|---|
| `ZoneRedundant` | outra zona de disponibilidade da região | a perda de um servidor, ou de uma zona inteira |
| `SameZone` | a mesma zona do primário | a perda de um servidor, com menos latência em cada commit |

**O standby não responde a consultas**; ele existe para ser promovido. Ele dobra a computação e o
armazenamento do servidor na conta, e não é oferecido no Burstable, o que a próxima parte mostra que o
`validate` não sabe.

```
ana@laptop:~/azure/tf/flex$ sed -i.bak 's/"GP_Standard_D2ds_v5"/"B_Standard_B1ms"/' main.tf && terraform validate -no-color; mv main.tf.bak main.tf
Success! The configuration is valid.

```

**Isso passa, e o Azure recusaria**: a documentação diz que alta disponibilidade não é suportada no
nível Burstable. Como no pool da lição 8, a regra mora entre dois valores, o nível e o bloco, e só o
Azure confere o par.

## Réplicas de leitura, para ler

**Uma réplica de leitura é um servidor separado que reaplica as mudanças do primário depois que elas
são confirmadas.** Ela tem nome próprio, responde a consultas e está sempre um pouco atrás, que é o
atraso da réplica que a figura desenha. Os relatórios das nove da manhã dos analistas da Quitanda
pertencem a uma, longe dos checkouts. Uma réplica pode ficar em outra região e pode ser promovida a
servidor independente, o que faz dela a cópia que uma empresa usa para mudar um banco de região ou
sobreviver à perda de uma. O que ela não faz é proteger contra um erro: um `DELETE` sem `WHERE` chega
a ela um momento depois.

## A restauração, para o erro

**Os backups são automáticos, e uma restauração é a qualquer ponto dentro do período de retenção**, de
7 a 35 dias, como diz a faixa do provider para `backup_retention_days`:

```
ana@laptop:~/azure/tf/flex$ sed -i.bak 's/backup_retention_days         = 7/backup_retention_days         = 40/' main.tf && terraform validate -no-color 2>&1 | grep Error; mv main.tf.bak main.tf
Error: expected backup_retention_days to be in the range (7 - 35), got 40
```

Como nos bancos da lição 8, uma
restauração cria um servidor novo e deixa o antigo como está, então o trabalho depois de um erro é
restaurar para um minuto antes dele e copiar as linhas de volta. **O backup geo-redundante** guarda os
backups também na região par, para que um servidor possa ser restaurado lá se a região inteira for perdida. Ele é escolhido quando o servidor é criado e não pode ser ligado depois, e é por isso que o
`main.tf` escreve `false` em vez de deixar de fora.
