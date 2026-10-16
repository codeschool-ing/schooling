---
title: Instance store, o disco que pertence ao host
version: 1
---

O `d` num nome de tipo, e a família `i` inteira, prometem discos NVMe locais, e local soa como
seguro: o disco está ali, na máquina. **Um disco de instance store pertence ao host, não à sua
instância**, e a instância só o pega emprestado. Quando a instância sai do host, por uma parada, um
encerramento ou uma falha de hardware, o disco fica para trás e a AWS o apaga antes que outra pessoa
o receba. O que ele compra em troca é velocidade, e um preço já incluído no da instância.

## Que tipos têm um

O moto traz os tamanhos que a AWS publica:

```
ana@laptop:~/aws$ aws ec2 describe-instance-types --instance-types i4i.large i4i.xlarge c7gd.xlarge m7gd.large m7i.large --query "InstanceTypes[].[InstanceType,InstanceStorageSupported,InstanceStorageInfo.TotalSizeInGB,InstanceStorageInfo.Disks[0].Type]" --output table
------------------------------------------
|          DescribeInstanceTypes         |
+--------------+--------+-------+--------+
|  c7gd.xlarge |  True  |  237  |  ssd   |
|  i4i.large   |  True  |  468  |  ssd   |
|  i4i.xlarge  |  True  |  937  |  ssd   |
|  m7gd.large  |  True  |  118  |  ssd   |
|  m7i.large   |  False |  None |  None  |
+--------------+--------+-------+--------+
```

A `i4i.large` tem 468 GB e a `i4i.xlarge` o dobro, 937; a `m7gd.large` tem 118 e a `c7gd.xlarge` 237,
então o disco cresce com o tamanho como todo o resto. A `m7i.large`, sem `d`, não tem nenhum.

Lance uma, e o instance store não aparece onde aparecem os volumes EBS:

```
ana@laptop:~/aws$ ID3=$(aws ec2 run-instances --image-id ami-0b44997419d0b0d38 --instance-type i4i.large --query "Instances[0].InstanceId" --output text)
ana@laptop:~/aws$ aws ec2 describe-instances --instance-ids "$ID3" --query "Reservations[0].Instances[0].[InstanceType,RootDeviceType,BlockDeviceMappings[].DeviceName]" --output text
i4i.large	ebs
/dev/sda1
```

O único mapeamento é o raiz EBS, `/dev/sda1`, e `RootDeviceType` diz `ebs`. **É também assim que a
AWS mostra**: nos tipos Nitro o instance store NVMe é anexado automaticamente e não aparece no
mapeamento de dispositivos de bloco. Dentro da instância ele é um dispositivo próprio, como
`/dev/nvme1n1`, sem sistema de arquivos, que você formata e monta a cada boot, porque ele começa
vazio toda vez que a instância inicia num host novo. O moto não tem disco para dar, então nada disso
pôde ser executado aqui.

Como o disco começa vazio em todo host novo, prepará-lo faz parte de todo boot, e não é um passo
feito uma vez. O jeito comum são algumas linhas no user data da instância, ou uma unit do systemd
embutida na imagem, que formatam o dispositivo e o montam antes de a aplicação iniciar. A lição 7 é
sobre user data; o que importa aqui é que uma aplicação que espera o diretório existir não pode
iniciar antes de esse passo ter rodado.

## O que sobrevive a quê

| | instance store | volume EBS |
|---|---|---|
| reiniciar | mantido | mantido |
| parar e iniciar | **apagado** | mantido |
| encerrar | **apagado** | apagado ou mantido, pela opção dele |
| o host falha | **perdido** | mantido, na zona dele |
| um snapshot | impossível | sim |

A quarta linha é a que pega as pessoas. Ninguém escolhe uma falha de host, e a AWS também aposenta
hosts numa agenda própria, mandando um aviso de que a instância vai ser parada. Um instance store com
a única cópia de alguma coisa é uma perda esperando por um desses, e um auto scaling group trocando
uma instância doente, na lição 4, é o mesmo evento vindo de outra direção.

## Para que serve

**Dados que são temporários ou copiados em outro lugar.** Dentro desses dois tipos, é o melhor disco
que o EC2 tem:

- um **cache**: o cache de borda de uma CDN, um cache de build, uma cópia local de algo cujo original
  está no S3; perdê-lo custa um reabastecimento e mais nada;
- **espaço de rascunho**: os arquivos de shuffle de um job Spark, as tabelas temporárias de uma
  ordenação grande, quadros intermediários de uma codificação de vídeo;
- **bancos que se replicam sozinhos**, como Cassandra ou um cluster Kafka, onde os dados de cada nó
  também estão em outros dois e um nó que perde o disco é reconstruído pelos vizinhos. É em torno
  disso que a família `i` é projetada.

O que ele não serve para guardar é a única cópia de um banco, os uploads que os usuários enviaram ou
qualquer coisa que alguém viria pedir para restaurar.

## O preço dele

O disco não custa nada à parte, mas o tipo que o carrega custa mais. A tabela de preços de 16 de
outubro de 2026 deixa a comparação exata, porque a `i4i.large` e a `r7i.large` têm as mesmas 2 vCPU e
16 GiB:

| | por hora | por mês de 730 horas |
|---|---|---|
| `r7i.large` | 0,21105 | 154,07 USD |
| `i4i.large` | 0,274 | 200,02 USD |
| a diferença, 468 GB de NVMe | 0,06295 | 45,95 USD |
| um volume `gp3` de 468 GB, para comparar | | 71,14 USD |

O disco local custa cerca de dois terços de um volume `gp3` do mesmo tamanho, e os 3.000 IOPS
incluídos num `gp3` são uma pequena fração do que faz um disco NVMe local. **O que a diferença compra
é durabilidade**, que o instance store não tem de jeito nenhum. Para um cache é uma boa troca; para a
única cópia de qualquer coisa não é troca a preço nenhum.
