---
title: Quanto custa, contra o Cloud SQL
version: 1
---

**O AlloyDB cobra três coisas: as vCPUs e a memória de cada nó, o armazenamento que o cluster guarda e
os backups.** Não há cobrança por leitura nem por escrita, nem linha de I/O de espécie alguma. O Cloud
SQL, da aula 6, cobra as vCPUs e a memória de cada instância e o disco que cada uma recebeu. Então
comparar os dois é comparar uma tarifa mais alta de computação com um total menor de armazenamento, e
quem ganha depende do formato do banco, não do produto.

**As tarifas, das duas páginas de preço**, São Paulo, USD, preços de tabela sem compromisso, lidas em
2026-10-30 em cloud.google.com/alloydb/pricing e cloud.google.com/sql/pricing:

| | AlloyDB, N2 e C4A | Cloud SQL Enterprise |
|---|---|---|
| por vCPU-hora | 0,1051 | 0,062, ou 0,1239 em alta disponibilidade |
| por GiB de memória por hora | 0,01781 | 0,0105, ou 0,021 em alta disponibilidade |
| armazenamento, por GiB-mês | 0,476909, usado, uma vez por cluster | 0,255 SSD, ou 0,51 em alta disponibilidade, provisionado, por instância |
| backups, por GiB-mês | 0,158994 | 0,12 |

**A computação do AlloyDB custa cerca de 70% a mais por nó**, e o armazenamento por GiB fica perto do
SSD de alta disponibilidade do Cloud SQL. Os números que decidem saem de multiplicar essas tarifas por
um formato real, e um programa curto faz isso para que cada valor possa ser conferido.

## O banco de pedidos da Quitanda, dos dois jeitos

**O formato**: uma primária de 8 vCPUs e 64 GiB com alta disponibilidade, capacidade de leitura de
mais duas máquinas do mesmo tamanho e 500 GiB de dados. No AlloyDB isso é uma primária regional e um
read pool de dois nós; no Cloud SQL, uma instância de alta disponibilidade e duas réplicas de leitura.

```schooling-example
{"language": "python", "file": "compare.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"Quitanda's orders database, priced as AlloyDB and as Cloud SQL Enterprise.\n\nUSD a month, southamerica-east1, list prices read on 2026-10-30 from\ncloud.google.com/alloydb/pricing and cloud.google.com/sql/pricing.\n\"\"\"\nHOURS = 730\n\n", "note": "A docstring diz de onde vem cada número abaixo, e quando foi lido. **730 horas** é o mês que as duas páginas de preço usam nos próprios valores mensais."}, {"code": "ALLOYDB = {'vcpu': 0.1051, 'gib': 0.01781, 'storage': 0.476909}\nCLOUDSQL = {'vcpu': 0.062, 'gib': 0.0105, 'ha_vcpu': 0.1239, 'ha_gib': 0.021,\n            'ssd': 0.255, 'ha_ssd': 0.51}\n\n", "note": "**As tarifas, copiadas das páginas.** As do AlloyDB para N2 e C4A, por vCPU-hora e por GiB-hora, e o armazenamento regional por GiB-mês. As das máquinas de uso geral da edição Enterprise do Cloud SQL, com as tarifas separadas que a página lista para uma instância de alta disponibilidade, e o armazenamento SSD por GiB-mês, zonal e de alta disponibilidade."}, {"code": "VCPU, GIB, DATA, READERS = 8, 64, 500, 2\n\n\ndef node(rates, vcpu='vcpu', gib='gib'):\n    return (VCPU * rates[vcpu] + GIB * rates[gib]) * HOURS\n\n", "note": "**O formato para o qual os dois recebem preço**: máquinas de 8 vCPUs e 64 GiB, 500 GiB de dados e a capacidade de leitura de duas máquinas ao lado da primária. `node` é uma máquina por um mês num par de tarifas."}, {"code": "alloydb = {\n    'primary, regional, 2 nodes': 2 * node(ALLOYDB),\n    'read pool, 2 nodes': READERS * node(ALLOYDB),\n    'storage, 500 GiB, once': DATA * ALLOYDB['storage'],\n}\n", "note": "**O AlloyDB cobra a primária regional como dois nós**, o ativo e o standby, na mesma tarifa de qualquer nó, e o armazenamento uma vez para o cluster inteiro."}, {"code": "cloudsql = {\n    'primary, high availability': node(CLOUDSQL, 'ha_vcpu', 'ha_gib'),\n    'two read replicas': READERS * node(CLOUDSQL),\n    'SSD, 500 GiB, primary': DATA * CLOUDSQL['ha_ssd'],\n    'SSD, 500 GiB, each replica': READERS * DATA * CLOUDSQL['ssd'],\n}\n\n", "note": "**O Cloud SQL cobra a primária de alta disponibilidade nas tarifas próprias dela**, que já incluem o standby, e **o armazenamento por instância**: o disco da primária na tarifa de alta disponibilidade, e um disco inteiro para cada réplica."}, {"code": "for name, bill in (('AlloyDB', alloydb), ('Cloud SQL Enterprise', cloudsql)):\n    print(name)\n    for line, usd in bill.items():\n        print(f'  {line:<30}{usd:>10,.2f}')\n    print(f'  {\"a month\":<30}{sum(bill.values()):>10,.2f}')\n", "note": "Cada conta linha por linha, e depois o total. Nada é arredondado antes de ser impresso."}]}
```

```
ana@laptop:~/gcp$ python3 compare.py
AlloyDB
  primary, regional, 2 nodes      2,891.73
  read pool, 2 nodes              2,891.73
  storage, 500 GiB, once            238.45
  a month                         6,021.92
Cloud SQL Enterprise
  primary, high availability      1,704.70
  two read replicas               1,705.28
  SSD, 500 GiB, primary             255.00
  SSD, 500 GiB, each replica        255.00
  a month                         3,919.98
```

**O AlloyDB custa 2.101,94 a mais por mês pelas mesmas máquinas**, 6.021,92 contra 3.919,98, e as
linhas dizem onde. A computação é 5.783,46 no AlloyDB e 3.409,98 no Cloud SQL; o armazenamento é
238,45 contra 510,00. A linha de armazenamento é a vantagem do AlloyDB, e a de computação é maior.

**Um nó por uma hora mostra a diferença na menor escala**:

```
ana@laptop:~/gcp$ python3 -c 'print(round(8 * 0.1051 + 64 * 0.01781, 5), round(8 * 0.062 + 64 * 0.0105, 5), round(8 * 0.1239 + 64 * 0.021, 5))'
1.98064 1.168 2.3352
```

**1,98064 contra 1,168 pelas mesmas 8 vCPUs e 64 GiB.** Esses são os 70%, e uma primária regional os
paga duas vezes, por dois nós, enquanto a tarifa de alta disponibilidade do Cloud SQL, 2,3352, também
é o dobro da sua tarifa simples.

## Onde fica a linha

**O armazenamento é a linha em que o AlloyDB ganha**, então a pergunta é quantos dados fecham a
diferença. Cada GiB nesse formato custa ao AlloyDB 0,476909, uma vez. No Cloud SQL o mesmo GiB está em
três discos, 0,51 na primária e 0,255 em cada réplica, 1,02 ao todo. A diferença de computação
dividida pela diferença de armazenamento por GiB é a quantidade de dados em que as duas contas se
encontram:

```
ana@laptop:~/gcp$ python3 -c 'print(round((2 * 2891.73 - 1704.70 - 1705.28) / (0.51 + 2 * 0.255 - 0.476909)))'
4370
```

**Cerca de 4.370 GiB**, um pouco mais de 4 TiB, até a economia de armazenamento do AlloyDB pagar a
computação dele, nessas máquinas e nesses preços. Os 500 GiB da Quitanda ficam muito abaixo. Três
coisas movem a linha, e cada uma é um motivo para fazer esta conta com os seus números em vez de
confiar nesta:

- **Cada réplica a empurra para baixo.** Cada réplica do Cloud SQL traz mais um disco inteiro, 0,255
  por GiB, e cada nó de leitura do AlloyDB não traz nenhum; quatro réplicas em vez de duas levam o
  armazenamento do Cloud SQL a 1,53 por GiB.
- **Provisionado não é usado.** Um disco do Cloud SQL é dimensionado acima dos dados que guarda, com
  folga para crescer, e é cobrado pelo tamanho. Um disco de 700 GiB com 500 cobra 700, na primária e
  em cada réplica; o programa acima deu ao Cloud SQL o benefício da dúvida dimensionando-o exato.
- **Nós menores, ou menos nós.** Se o columnar engine deixar os relatórios dos analistas rodarem num
  nó de leitura em vez de dois, ou num menor, a linha de computação encolhe um nó, 1.445,87 por mês
  nesse tamanho. Essa é uma aposta numa medida que ninguém consegue tirar sem um cluster, e é a medida
  a tirar no free trial abaixo antes de construir em cima dela.

**Três coisas não estão em nenhuma das contas.** Os backups têm preço na tabela acima e crescem com o
que se guarda. O tráfego de rede para fora da região é o assunto da aula 5, e é o mesmo para os dois.
E o Enterprise Plus, a outra edição do Cloud SQL, tem tarifas próprias na mesma página, um failover
mais rápido e um cache de dados; ele estreitaria a diferença pelo outro lado. Os descontos por uso
comprometido reduzem os dois, nas porcentagens de cada página, por um ou três anos de compromisso.

## O free trial, e para que ele serve

**O AlloyDB oferece um cluster de free trial por 30 dias**, que a página de preços descreve como até 1
TB de dados, uma primária de 8 vCPUs e um nó de read pool de 8 vCPUs, além do crédito que uma conta
nova do Google Cloud recebe. É o formato com preço acima, menos a alta disponibilidade e uma leitora,
e basta para responder à única pergunta que esta aula não conseguiu: quanto mais rápido o relatório
dos analistas roda no columnar engine, com os dados da própria Quitanda, e portanto quantos nós o
cluster real precisa. **Ele não foi usado neste curso**, que não tem conta, e nada nesta página foi
medido no AlloyDB.
