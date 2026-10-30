---
title: Nós, processing units, edições, e pelo que ele cobra
version: 1
---

**O Spanner cobra três coisas: capacidade de computação por hora, armazenamento por GiB-mês e dados
movidos entre regiões.** A computação são os nós ou processing units da instância, cobrados esteja ela
ocupada ou não; o armazenamento é o que os bancos guardam, com os índices; a replicação entre regiões
só vale para configurações dual-region e multirregionais. Não há cobrança por consulta nem por linha
lida. Então a conta é definida por quanta capacidade a instância mantém ligada, e a pergunta é o que
decide esse número.

**A ideia errada é que o Spanner é caro demais para qualquer coisa pequena.** Ele começava em um nó.
Hoje começa em 100 processing units, um décimo de nó, e a página de preços diz que uma instância de 200
processing units por 6 horas é cobrada como 1,2 nó-hora. Toda mudança de capacidade é cobrada por pelo
menos uma hora.

## As tarifas

**Da página de preços, `southamerica-east1` regional, USD, preços de tabela, lida em 2026-10-30** em
cloud.google.com/spanner/pricing. A página põe preço na computação por nó-hora por **edição**, e um nó
numa configuração regional inclui as suas três réplicas:

| | por nó-hora, regional |
|---|---|
| Standard | 1,35 |
| Enterprise | 1,845 |
| Enterprise Plus | 2,565 |
| armazenamento, SSD, as três réplicas | 0,45 por GiB-mês |
| armazenamento, HDD, as três réplicas | 0,09 por GiB-mês |

**As edições diferem no que uma instância pode ser, não na velocidade.** A página de preços diz que as
configurações dual-region e multirregionais estão disponíveis na Enterprise Plus, e as réplicas
opcionais só de leitura na Enterprise e na Enterprise Plus; a Standard é uma instância regional com o
núcleo do Spanner. A visão geral das edições em cloud.google.com/spanner/docs/editions-overview lista o
resto, e a linha de comando conhece os três nomes:

```
ana@laptop:~/gcp$ gcloud spanner instances create --help | sed -n '/^     --edition/,/Standard edition/p'
     --edition=EDITION
        Spanner edition. EDITION must be one of:

         EDITION_UNSPECIFIED
            Spanner's legacy pricing model. For more information, see the
            Spanner editions overview
            (https://cloud.google.com/spanner/docs/editions-overview)
         ENTERPRISE
            Enterprise edition
         ENTERPRISE_PLUS
            Enterprise Plus edition
         STANDARD
            Standard edition
```

`price.py`:

```python
"""Spanner, regional southamerica-east1, USD a month at list prices read on
2026-10-30 from cloud.google.com/spanner/pricing."""
HOURS = 730
NODE_HOUR = {'Standard': 1.35, 'Enterprise': 1.845, 'Enterprise Plus': 2.565}
SSD_GIB_MONTH = 0.45

for edition, rate in NODE_HOUR.items():
    print(f'{edition:<16} 100 PU {0.1 * rate * HOURS:>8,.2f}'
          f'   1 node {rate * HOURS:>9,.2f}   3 nodes {3 * rate * HOURS:>9,.2f}')
print(f'500 GiB of SSD storage {500 * SSD_GIB_MONTH:,.2f}')
```

```
ana@laptop:~/gcp$ python3 price.py
Standard         100 PU    98.55   1 node    985.50   3 nodes  2,956.50
Enterprise       100 PU   134.69   1 node  1,346.85   3 nodes  4,040.55
Enterprise Plus  100 PU   187.25   1 node  1,872.45   3 nodes  5,617.35
500 GiB of SSD storage 225.00
```

**A menor instância custa 98,55 por mês na Standard**, 100 processing units por 730 horas, e um nó
custa 985,50, que bate com o valor mensal que a própria página de preços imprime. Os 500 GiB da
Quitanda somam 225,00 de armazenamento, réplicas incluídas. Para comparar com a aula 8, um nó do
AlloyDB de 8 vCPUs custava 1.445,87 por mês; mas um nó do Spanner não é uma máquina de um tamanho dado,
então os dois não se comparam nó a nó, só conta a conta, para a mesma carga.

## O que decide o número de nós

**A CPU, medida, e o armazenamento, dentro de um limite por nó.** A orientação do Google é manter a
utilização de CPU de alta prioridade de uma instância regional abaixo de 65%, para que uma zona possa
cair e as sobreviventes absorvam a carga dela, e cada nó ou processing unit guarda uma quantidade
limitada de dados, que a página de cotas documenta. Uma instância de 100 processing units com mais
dados do que a sua parte precisa crescer mesmo ociosa. O autoscaler gerenciado do Spanner, nas edições
Enterprise, move a capacidade entre limites que você define.

**Nada disso dá para medir aqui**, e o emulador mostra o motivo do jeito mais simples. Ele aceita uma
instância de qualquer tamanho válido e não lhe dá capacidade nenhuma:

```
ana@laptop:~/gcp$ gcloud spanner instances create quitanda-big --config=emulator-config --description="Five nodes" --nodes=5
Creating instance...
.....done.
ana@laptop:~/gcp$ gcloud spanner instances describe quitanda-big --format='value(nodeCount,processingUnits)'
5	5000
```

**Cinco nós, criados em um segundo, num laptop.** E ele não muda uma instância depois:

```
ana@laptop:~/gcp$ gcloud spanner instances update quitanda --processing-units=200
ERROR: (gcloud.spanner.instances.update) HttpError accessing <http://localhost:9020/v1/projects/planner-dev/instances/quitanda?alt=json>: response: <{'content-type': 'application/json', 'date': 'Fri, 30 Oct 2026 18:47:49 GMT', 'content-length': '83', 'status': 501}>, content <{"code":12,"message":"Cloud Spanner Emulator does not support updating instances."}>
This may be due to network connectivity issues. Please check your network settings, and the status of the service you are trying to reach.
```

## Tudo o mais que o emulador não faz

```
ana@laptop:~/gcp$ gcloud spanner databases execute-sql shop --instance=quitanda --sql='SELECT * FROM Stock' --query-mode=PLAN
 None No query plan

ana@laptop:~/gcp$ gcloud spanner databases execute-sql shop --instance=quitanda --sql='SELECT * FROM Stock' --query-mode=PROFILE
┌────────────────────┬──────────┬───────────────┬──────────────┬───────────────────┐
│ TOTAL_ELAPSED_TIME │ CPU_TIME │ ROWS_RETURNED │ ROWS_SCANNED │ OPTIMIZER_VERSION │
├────────────────────┼──────────┼───────────────┼──────────────┼───────────────────┤
│ 2.126915ms         │ Unknown  │ 2             │ Unknown      │ Unknown           │
└────────────────────┴──────────┴───────────────┴──────────────┴───────────────────┘
 None No query plan

Product   Units
rice-5kg  31
banana    41
```

**`No query plan`.** Os planos do Spanner, que mostram onde uma consulta leu e se cruzou splits, não
são produzidos pelo emulador em modo de consulta nenhum; `PROFILE` devolve as linhas e uma tabela de
estatísticas cujo tempo de CPU e linhas lidas são `Unknown`. A lista completa, a partir do que esta
aula rodou:

| no Spanner | no emulador |
|---|---|
| splits, movidos por carga e tamanho | nenhum; um processo |
| réplicas, um líder por split, TrueTime | nenhuma; um relógio |
| planos de consulta em `PLAN` e `PROFILE` | `No query plan` |
| transações de leitura e escrita concorrentes | uma por vez; a outra é abortada |
| configurações de instância por região | só `emulator-config` listada, e outras aceitas sem conferir |
| mudar a capacidade de uma instância | recusado, `does not support updating instances` |
| edições | a flag aceita, e nada registrado |
| desempenho, latência, custo | nada para medir |

**Duas dessas linhas são armadilhas, não lacunas**, e são elas que valem lembrar:

```
ana@laptop:~/gcp$ gcloud spanner instances create quitanda-sp --config=regional-southamerica-east1 --description="São Paulo" --processing-units=100 --edition=ENTERPRISE
Creating instance...
.....done.
ana@laptop:~/gcp$ gcloud spanner instances describe quitanda-sp
config: projects/planner-dev/instanceConfigs/regional-southamerica-east1
createTime: '2026-10-30T18:47:52.108394845Z'
displayName: São Paulo
name: projects/planner-dev/instances/quitanda-sp
processingUnits: 100
state: READY
updateTime: '2026-10-30T18:47:52.108394845Z'
Terminated
```

**`regional-southamerica-east1` não estava na lista do próprio emulador, e foi aceita**; no Google
Cloud ela seria conferida contra as configurações que o seu projeto pode usar. E `--edition=ENTERPRISE`
foi aceita e depois não apareceu na descrição, então uma edição escolhida contra o emulador é escolhida
contra nada. O schema, o SQL, as chaves e as transações se comportaram como no Spanner; a capacidade e
a conta são ensinadas a partir da documentação, e a **instância de free trial** da página de preços, 90
dias e até 10 GiB, é onde uma primeira medida real não custa nada.
