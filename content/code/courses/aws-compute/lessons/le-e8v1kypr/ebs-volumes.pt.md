---
title: Volumes EBS, e os três números que você escolhe
version: 1
---

Um disco costuma ser comprado pelo tamanho, e um disco mais rápido é um modelo mais caro do mesmo
tamanho. **Um volume EBS são três números, e no `gp3` você os define separadamente**: os gigabytes
que ele guarda, as operações de entrada e saída por segundo que ele pode fazer (IOPS) e os megabytes
por segundo que ele pode mover (throughput). É um dispositivo de bloco servido pela rede a partir de
um armazenamento numa Availability Zone, anexado a uma instância como se fosse um disco local, e
cobrado pelo que você provisionou, usado ou não.

## Os tipos de volume

| tipo | feito de | desempenho | para |
|---|---|---|---|
| `gp3` | SSD | 3.000 IOPS e 125 MiB/s incluídos em qualquer tamanho; o que passar disso é comprado à parte | quase tudo: discos raiz, a maioria dos bancos |
| `gp2` | SSD | 3 IOPS por GiB, então o desempenho só cresce com o tamanho | volumes criados antes de o `gp3` existir |
| `io2` | SSD | os IOPS que você provisiona, até 1.000 por GiB | bancos que precisam de uma taxa garantida e de durabilidade maior |
| `st1` | disco rígido | throughput que cresce com o tamanho; fraco em IOPS aleatórios | leituras sequenciais grandes: logs, pipelines de dados |
| `sc1` | disco rígido | o menor throughput | dados lidos raramente, pelo menor preço |

**O `gp3` é a resposta padrão**, e o motivo está na primeira coluna de números. No `gp2` um volume de
100 GiB recebe 300 IOPS, e o único jeito de chegar a 3.000 é comprar 1.000 GiB de que ninguém
precisa. No `gp3` todo volume começa em 3.000 e 125 MiB/s, e o extra é uma linha separada na conta. O
`io2` soma durabilidade à taxa: a AWS declara 99,999% para ele, contra 99,8% a 99,9% para os outros.
Os dois tipos de disco rígido não podem ser volume de boot, e a AWS os vende a partir de 125 GiB.

Cada tipo, criado no moto:

```
ana@laptop:~/aws$ aws ec2 create-volume --availability-zone sa-east-1a --size 100 --volume-type gp3
{
    "Iops": 3000,
    "VolumeType": "gp3",
    "VolumeId": "vol-63a9f0f2cdbd8b807",
    "Size": 100,
    "AvailabilityZone": "sa-east-1a",
    "State": "available",
    "CreateTime": "2026-10-16T16:38:15+00:00",
    "Attachments": [],
    "Encrypted": false
}
ana@laptop:~/aws$ aws ec2 create-volume --availability-zone sa-east-1a --size 100 --volume-type gp3 --iops 6000 --throughput 250 --query "[VolumeType,Size,Iops,Throughput]" --output text
gp3	100	6000	250
ana@laptop:~/aws$ aws ec2 create-volume --availability-zone sa-east-1a --size 100 --volume-type gp2 --query "[VolumeType,Size,Iops]" --output text
gp2	100	None
ana@laptop:~/aws$ aws ec2 create-volume --availability-zone sa-east-1a --size 100 --volume-type io2 --iops 10000 --query "[VolumeType,Size,Iops]" --output text
io2	100	10000
ana@laptop:~/aws$ aws ec2 create-volume --availability-zone sa-east-1a --size 500 --volume-type st1 --query "[VolumeType,Size,Iops]" --output text
st1	500	None
```

As formas são da AWS, e dois dos números são do moto. **Na AWS a primeira resposta traz um
`Throughput` de 125**, a linha de base incluída, que o moto deixa de fora; e o volume `gp2` tem 300
IOPS, três por GiB, onde o moto não informa nenhum. O moto guarda os números que você dá e calcula
poucos por conta própria.

Ele também guarda números que a AWS recusaria:

```
ana@laptop:~/aws$ aws ec2 create-volume --availability-zone sa-east-1a --size 100 --volume-type gp3 --iops 90000 --query "[VolumeType,Size,Iops]" --output text
gp3	100	90000
ana@laptop:~/aws$ aws ec2 create-volume --availability-zone sa-east-1a --size 10 --volume-type st1 --query "[VolumeType,Size]" --output text
st1	10
```

Um volume `gp3` pode ter no máximo 500 IOPS por GiB, então 100 GiB param em 50.000, e a AWS rejeita
90.000. Um volume `st1` de 10 GiB está abaixo do mínimo de 125 GiB e também é rejeitado. **Nos dois
casos o moto criou o volume.** Como na verificação de arquitetura da lição 1, o hábito é conhecer os
limites você mesmo, porque o primeiro lugar em que você encontra a recusa não deveria ser um
deploy.

## Quanto custa um volume

A tabela de preços de 16 de outubro de 2026 tem todas as linhas necessárias, por mês em `sa-east-1`:

| volume | conta | por mês |
|---|---|---|
| `gp3`, 100 GB, os 3.000 IOPS e 125 MiB/s incluídos | 100 × 0,152 | 15,20 USD |
| o mesmo, subido para 6.000 IOPS | + 3.000 × 0,0095 | + 28,50 USD |
| e para 250 MiB/s | + 125 × 0,076 | + 9,50 USD |
| **o segundo `gp3` acima, no total** | | **53,20 USD** |
| `io2`, 100 GB, só o armazenamento | 100 × 0,238 | 23,80 USD |
| `st1`, 500 GB | 500 × 0,086 | 43,00 USD |

Dobrar o desempenho daquele volume `gp3` custou duas vezes e meia o que custaram os gigabytes, e é
por isso que desempenho é o número a medir antes de subir. A linha do `io2` é só armazenamento: os
IOPS provisionados dele também são cobrados por IOPS-mês, a um preço que a tabela não imprime, e
para um volume de 10.000 IOPS essa linha é a maior. O volume `st1` guarda cinco vezes o primeiro
`gp3` por menos de três vezes o preço, que é o argumento a favor dele, desde que as leituras sejam
grandes e em ordem.

## A instância também tem um limite

Os IOPS e o throughput de um volume são o que o volume consegue fazer. **O que chega à instância
também é limitado pelo tipo de instância**, porque o EBS viaja pela rede, e todo tipo tem uma banda
para ele:

```
ana@laptop:~/aws$ aws ec2 describe-instance-types --instance-types m7i.large m7i.2xlarge m7i.8xlarge --query "InstanceTypes[].[InstanceType,EbsInfo.EbsOptimizedInfo.BaselineThroughputInMBps,EbsInfo.EbsOptimizedInfo.BaselineIops,EbsInfo.EbsOptimizedInfo.MaximumThroughputInMBps]" --output table
----------------------------------------------
|            DescribeInstanceTypes           |
+--------------+---------+--------+----------+
|  m7i.2xlarge |  312.5  |  12000 |  1250.0  |
|  m7i.8xlarge |  1250.0 |  40000 |  1250.0  |
|  m7i.large   |  81.25  |  3600  |  1250.0  |
+--------------+---------+--------+----------+
```

A `m7i.large` tem garantidos 81,25 MB/s e 3.600 IOPS para o EBS, somando todos os volumes, e pode
subir a 1.250 MB/s por um tempo, como a rede dela na lição 1. Um volume provisionado a 250 MiB/s
nessa instância paga um throughput que a instância só sustenta em picos. A linha de base cresce com
o tamanho, então a `m7i.2xlarge` sustenta 312,5 MB/s e a `m7i.8xlarge` chega ao pico.
**Dimensione o volume e a instância juntos**; subir um sem o outro compra um número que nada
consegue usar.

## O que o moto não consegue mostrar

Nenhum desses volumes guarda um byte. O moto guarda o registro e não serve bloco nenhum, então nada
aqui foi formatado, montado ou medido, e os números de IOPS e throughput acima são promessas da
documentação da AWS, não leituras. O jeito de medir um volume real é um benchmark como o `fio` dentro
de uma instância na AWS, o que está fora do que este curso consegue executar.
