---
title: Uma carga de trabalho, precificada em três armazenamentos
version: 1
---

**A tela "meus pedidos" do aplicativo da Quitanda é uma carga de trabalho com forma clara**: um
cliente a abre, e o aplicativo mostra os pedidos recentes dele, os mais novos primeiro. Ela é lida
por uma chave, o cliente, e por um intervalo sob ela, as datas dos pedidos. Ponha números nela antes
de escolher:

| | |
|---|---|
| consultas | 100.000 por dia, 3.000.000 por mês |
| cada consulta devolve | até dez pedidos, menos de 4 KB ao todo |
| pedidos novos | 20.000 por dia, 600.000 por mês, cada um com menos de 1 KB |
| dados guardados | 50 GiB |
| latência | a tela abre em bem menos de um segundo |

Três armazenamentos deste curso poderiam guardá-la: o Firestore, um documento por pedido sob o
cliente; o Cloud SQL, uma tabela com índice no cliente e na data; e o BigQuery, o warehouse aonde os
pedidos já chegam. O programa abaixo precifica os três com os preços de São Paulo que as aulas
anteriores leram:

```schooling-example
{"language": "python", "file": "my_orders.py", "parts": [{"code": "# Quitanda's \"my orders\" screen, priced in three stores.\n# Prices: southamerica-east1, USD, read 2026-10-30 from cloud.google.com.\nLOOKUPS = 3_000_000          # a month\nORDERS_PER_LOOKUP = 10\nNEW_ORDERS = 600_000         # a month\nGIB = 50                     # data kept\nHOURS = 730                  # a month\n\n", "note": "A carga de trabalho, escrita antes de nomear qualquer armazenamento. Cada número abaixo é um destes multiplicado por um preço, que é a ordem das seis perguntas."}, {"code": "def firestore():\n    reads = LOOKUPS * ORDERS_PER_LOOKUP * 0.045 / 100_000\n    writes = NEW_ORDERS * 0.135 / 100_000\n    stored = GIB * 0.135\n    return {'document reads': reads, 'document writes': writes, 'storage': stored}\n\n", "note": "**O Firestore cobra cada documento que uma consulta devolve**, então uma consulta de dez pedidos são dez leituras, a US$ 0,045 por 100.000. As escritas custam US$ 0,135 por 100.000 e o armazenamento US$ 0,135 por GiB-mês, de cloud.google.com/firestore/pricing. A cota gratuita diária fica de fora: ela é de um banco por projeto, e um negócio a ultrapassa."}, {"code": "def cloud_sql():\n    machine = (2 * 0.1239 + 8 * 0.021) * HOURS\n    disk = GIB * 0.51\n    return {'2 vCPU, 8 GiB, regional HA': machine, 'SSD, HA': disk}\n\n", "note": "**O Cloud SQL cobra a máquina por hora, faça ela o que fizer.** Edição Enterprise com alta disponibilidade, US$ 0,1239 por hora de vCPU e US$ 0,021 por GiB-hora de memória, e SSD a US$ 0,51 por GiB-mês com HA, os preços da aula 6. O número de consultas nem aparece."}, {"code": "def bigquery():\n    mib = LOOKUPS * 10                      # each query billed at least 10 MB\n    tib = mib / 1024 / 1024\n    return {f'{tib:.2f} TiB scanned, first TiB free': (tib - 1) * 11.25}\n\n", "note": "**O BigQuery sob demanda cobra cada consulta por no mínimo 10 MB por tabela referenciada**, por menos linhas que devolva, a US$ 11,25 por TiB em São Paulo depois de um TiB gratuito por mês, de cloud.google.com/bigquery/pricing. Três milhões de consultas minúsculas são muitos mínimos."}, {"code": "for name, lines in (('Firestore', firestore()), ('Cloud SQL', cloud_sql()), ('BigQuery', bigquery())):\n    print(name)\n    for what, usd in lines.items():\n        print(f'  {what:34} {usd:9.2f}')\n    print(f'  {\"total a month\":34} {sum(lines.values()):9.2f}')\n", "note": "Um bloco por armazenamento, cada linha com rótulo, e o total. A saída é a fonte da tabela seguinte."}]}
```

```
ana@laptop:~/gcp$ python3 my_orders.py
Firestore
  document reads                         13.50
  document writes                         0.81
  storage                                 6.75
  total a month                          21.06
Cloud SQL
  2 vCPU, 8 GiB, regional HA            303.53
  SSD, HA                                25.50
  total a month                         329.03
BigQuery
  28.61 TiB scanned, first TiB free     310.62
  total a month                         310.62
```

## Firestore

**Treze dólares e meio dos vinte e um são leituras**, porque o Firestore conta documentos, não
consultas: uma tela de dez pedidos são dez leituras. É o padrão de acesso para o qual ele é
precificado, e isso diz algo útil sobre o desenho. Uma tela que mostrasse só o último pedido custaria
um décimo disso em leituras, e um documento por cliente guardando os últimos dez pedidos faria de
cada consulta uma leitura só, ao preço de reescrever esse documento a cada pedido novo. No Firestore
a forma do documento é uma linha da fatura.

## Cloud SQL

**Cerca de quinze vezes a fatura do Firestore, para uma carga que usa uma fatia da máquina.** A
instância é o preço, com um standby numa segunda zona porque a aula 7 não aceitaria menos para dados
de que o negócio depende, e o preço não se mexe se a tela for aberta três milhões de vezes ou três.
Mas a comparação tem uma segunda metade. **Se os pedidos da Quitanda já moram no Cloud SQL**, como a
seção anterior decidiu, a tela "meus pedidos" é mais uma consulta indexada numa máquina que já está
paga de qualquer jeito, e o custo marginal dela é quase zero. O armazenamento mais barato para uma
carga muitas vezes é o que já roda para a carga ao lado.

## BigQuery

**O BigQuery é o armazenamento que não deveria estar nesta comparação**, e precificá-lo mostra por
quê. Cada consulta da tela seria uma consulta do BigQuery, e toda consulta é cobrada por no mínimo
10 MB por tabela que referencia, por menos linhas que leia. Três milhões de mínimos são quase vinte e
nove tebibytes por mês de bytes que ninguém leu. E cada consulta leva um segundo ou mais, porque uma
consulta é um job que é planejado, recebe slots e roda antes de responder. Um cliente não espera tudo
isso por uma tela. O preço sozinho teria posto o BigQuery no nível do Cloud SQL; a segunda pergunta,
latência, o descarta antes de o preço ser lido, que é a ordem em que a primeira seção desta aula
insistiu.

## O que os três números dizem

| armazenamento | por mês | o que diz |
|---|---|---|
| Firestore | cerca de 21 | o padrão de acesso é aquele para o qual ele é precificado |
| Cloud SQL | cerca de 329 sozinho, quase zero ao lado dos pedidos | a instância é o preço, e ela pode já estar paga |
| BigQuery | cerca de 311, e lento demais | um warehouse sendo usado como banco |

**Nem o Firestore nem o Cloud SQL é "a resposta" a partir só desses números.** Um time começando do
zero poria "meus pedidos" no Firestore; um time cujos pedidos já estão no Cloud SQL acrescentaria um
índice e não pagaria nada a mais. Os dois estão certos para a situação deles, e os dois leem os
mesmos três números.
