---
title: A conta de um data warehouse
version: 1
---

**Um cluster provisionado custa os seus nós por toda hora em que existe, e o Serverless custa as suas
RPUs por toda hora em que trabalha.** Qual sai mais barato depende de uma quantidade, as horas de
trabalho por dia, e os dois preços da tabela bastam para achar onde a linha cai:

```
ana@laptop:~/aws$ python3 prices.py redshift
AWS public price list, sa-east-1, USD, excluding tax

Redshift, USD
  ra3.large, per node-hour                              0.86600  hour
  ra3.xlplus, per node-hour                             1.73100  hour
  ra3.4xlarge, per node-hour                            5.19500  hour
  managed storage                                       0.04300  GB-month
  Serverless, per RPU-hour                              0.59760  RPU-hour
  Spectrum, per TB scanned                              5.00000  TB
```

## Dois nós, o mês inteiro

O cluster desta lição são dois nós `ra3.xlplus`. Um mês de 30 dias tem 720 horas:

| | conta | USD por mês |
|---|---|---|
| computação | 2 nós × 1,731 × 720 h | 2.492,64 |
| armazenamento gerenciado, 500 GB | 500 × 0,043 | 21,50 |
| **total** | | **2.514,14** |

**A computação é 99% disso.** Os 500 GB que os pedidos da Quitanda ocupam depois de comprimidos custam
menos do que o cluster gasta em sete horas. Essa é a aritmética por trás do desenho do RA3: o
armazenamento é barato e cresce sozinho, e as horas de nó são a decisão.

**Um cluster pausado para a linha da computação.** O `pause-cluster` mantém os dados e o endpoint e
para de cobrar os nós até o `resume-cluster`, e a AWS cobra só o armazenamento enquanto isso:

```
ana@laptop:~/aws$ aws redshift pause-cluster --cluster-identifier quitanda-dw --query Cluster.ClusterStatus --output text
paused
ana@laptop:~/aws$ aws redshift describe-clusters --cluster-identifier quitanda-dw --query "Clusters[0].[ClusterStatus,NumberOfNodes]" --output text
paused	2
ana@laptop:~/aws$ aws redshift resume-cluster --cluster-identifier quitanda-dw --query Cluster.ClusterStatus --output text
available
```

O moto mudou o status e não parou nada, porque nada estava rodando. Na AWS, um cluster pausado nas
doze horas de toda noite em que ninguém consulta economiza metade da linha de computação, 1.246,32 USD
por mês. O preço são alguns minutos de espera toda manhã enquanto ele volta, e alguém ou alguma
coisa lembrar de pausá-lo.

## Serverless, algumas horas por dia

O Serverless cobra 0,5976 USD por RPU-hora, só enquanto há consultas rodando. Duas cargas, cada uma
num mês de 30 dias:

| carga | conta | USD por mês |
|---|---|---|
| analistas, 4 horas por dia a 32 RPUs | 32 × 0,5976 × 4 × 30 | 2.294,78 |
| um dashboard, 1 hora por dia a 8 RPUs | 8 × 0,5976 × 1 × 30 | 143,42 |

**A 32 RPUs, a linha cai em cerca de quatro horas e um terço por dia.** Uma hora a 32 RPUs custa 32 ×
0,5976 = 19,1232 USD, e 2.492,64 ÷ (19,1232 × 30) dá 4,34: abaixo dessas horas ocupadas por dia, o
Serverless custa menos que os dois nós; acima, o cluster custa menos. A 8 RPUs uma hora custa 4,7808
USD e a linha vai para 17,38 horas por dia, então um workgroup Serverless pequeno continua mais barato
a menos que fique ocupado quase o tempo todo. O armazenamento custa os mesmos 0,043 por GB-mês nos
dois, então não move a linha. **O número a acompanhar são as horas ocupadas, não o tamanho dos
dados.**

Esses são preços de tabela. Nós reservados, pagos com um ou três anos de antecedência, custam menos
por hora; a tabela não os imprime e o curso não os cita.

## Consultando o lake a partir do Redshift

**O Redshift Spectrum lê arquivos no S3 de dentro de uma consulta do Redshift**, por meio de uma
tabela externa, para que um relatório junte os pedidos do mês passado no warehouse com três anos de
histórico que nunca saíram do lake. Ele é cobrado como o Athena, pelos dados lidos: 5,00 USD por TB na
tabela. Uma consulta que lê 0,2 TB de CSV custa 0,2 × 5,00 = 1,00 USD, e as mesmas linhas em Parquet,
lidas em duas das vinte colunas, leem uma fração disso. A lição 15 mede os bytes que uma consulta lê,
e a lição 19 são as duas decisões que os definem.
