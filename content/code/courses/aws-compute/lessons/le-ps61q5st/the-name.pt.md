---
title: Lendo o nome de um tipo
version: 1
---

Um nome como `c7gd.xlarge` parece um código de estoque, daqueles copiados de um post de blog e
nunca questionados. **É uma frase curta numa gramática pequena**, e cada pedaço dela muda algo que
você pode medir. Um pedaço fixa a proporção entre memória e processador, outro o conjunto de
instruções que a máquina roda, outro se o host tem disco próprio, e outro o tamanho da fatia que
você recebe. Leia a gramática uma vez
e um tipo que você nunca viu diz o que é antes de você procurá-lo.

```schooling-figure
{"svg": "<svg id=\"fig-type-name\" viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"O nome c7gd.xlarge dividido em cinco partes. c é a família, otimizada para computação, com 2 GiB por vCPU. 7 é a geração. g é o processador Graviton, Arm. d acrescenta um disco NVMe de 237 GB no host. xlarge é o tamanho: 4 vCPU e 8 GiB, o dobro de um large.\"><defs><marker id=\"type-name-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"24\" y=\"20\" width=\"120\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"84.0\" y=\"43\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"20\" fill=\"var(--phosphor)\" font-weight=\"600\">c</text><line x1=\"84.0\" y1=\"66\" x2=\"84.0\" y2=\"100\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#type-name-ah)\"></line><rect x=\"24\" y=\"104\" width=\"120\" height=\"112\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"84.0\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\" font-weight=\"600\">família</text><text x=\"84.0\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">otimizada para</text><text x=\"84.0\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">computação</text><text x=\"84.0\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">2 GiB por vCPU</text><rect x=\"162\" y=\"20\" width=\"120\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"222.0\" y=\"43\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"20\" fill=\"var(--phosphor)\" font-weight=\"600\">7</text><line x1=\"222.0\" y1=\"66\" x2=\"222.0\" y2=\"100\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#type-name-ah)\"></line><rect x=\"162\" y=\"104\" width=\"120\" height=\"112\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"222.0\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\" font-weight=\"600\">geração</text><text x=\"222.0\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">a sétima</text><text x=\"222.0\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">da família</text><text x=\"222.0\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">a 8 é mais nova</text><rect x=\"300\" y=\"20\" width=\"120\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"360.0\" y=\"43\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"20\" fill=\"var(--phosphor)\" font-weight=\"600\">g</text><line x1=\"360.0\" y1=\"66\" x2=\"360.0\" y2=\"100\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#type-name-ah)\"></line><rect x=\"300\" y=\"104\" width=\"120\" height=\"112\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\" font-weight=\"600\">processador</text><text x=\"360.0\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Graviton,</text><text x=\"360.0\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">o Arm que</text><text x=\"360.0\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">a AWS projeta</text><rect x=\"438\" y=\"20\" width=\"120\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"498.0\" y=\"43\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"20\" fill=\"var(--phosphor)\" font-weight=\"600\">d</text><line x1=\"498.0\" y1=\"66\" x2=\"498.0\" y2=\"100\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#type-name-ah)\"></line><rect x=\"438\" y=\"104\" width=\"120\" height=\"112\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"498.0\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\" font-weight=\"600\">extra</text><text x=\"498.0\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">disco NVMe</text><text x=\"498.0\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">no host</text><text x=\"498.0\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">237 GB aqui</text><rect x=\"576\" y=\"20\" width=\"120\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"636.0\" y=\"43\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"20\" fill=\"var(--phosphor)\" font-weight=\"600\">xlarge</text><line x1=\"636.0\" y1=\"66\" x2=\"636.0\" y2=\"100\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#type-name-ah)\"></line><rect x=\"576\" y=\"104\" width=\"120\" height=\"112\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"636.0\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\" font-weight=\"600\">tamanho</text><text x=\"636.0\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">4 vCPU, 8 GiB</text><text x=\"636.0\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">o dobro de large</text><text x=\"636.0\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">metade de 2xlarge</text><text x=\"360\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">o ponto separa o tamanho do resto</text></svg>", "caption": "Cinco partes, cinco fatos. Troque uma letra e muda exatamente uma propriedade da máquina.", "same": ["extra", "Graviton,", "4 vCPU, 8 GiB"]}
```

## Antes do ponto: família, geração, atributos

A primeira letra é a **família**, e a família fixa a proporção entre memória e processador: `m` é de
uso geral, `c` é otimizada para computação e `r` é otimizada para memória. A próxima seção percorre
as cinco categorias em que a AWS separa as famílias, com as letras de cada uma.

O número é a **geração**. Um número maior é hardware mais novo na mesma família, mais rápido por vCPU
e muitas vezes mais barato por hora. A tabela de preços traz tipos de sétima geração porque são os
que este curso compara, mas eles não são os mais novos: o catálogo abaixo já oferece `c8g`, `m8i` e
`r8g` em São Paulo. Uma geração não é retirada quando chega a seguinte, então um template escrito há
três anos continua lançando `m5` muito depois de a `m7` ter virado a melhor compra, e nada avisa.

O que vem depois do número são os **atributos**, uma letra cada, e o processador vem primeiro:

| letra | o que diz | exemplo |
|---|---|---|
| `i` | um processador Intel | `m7i.large` |
| `a` | um processador AMD | `m7a.large` |
| `g` | Graviton, o processador Arm que a AWS projeta | `m7g.large` |
| `d` | discos NVMe locais no host, o instance store | `c7gd.xlarge` |
| `n` | mais banda de rede | `c7gn.xlarge` |
| `e` | memória extra ou armazenamento extra para a família | `x2iedn.xlarge`, `i7ie.large` |
| `z` | uma frequência sustentada mais alta | `r7iz.large` |
| `-flex` | uma variante mais barata que não promete velocidade total o tempo todo | `m7i-flex.large` |

As gerações mais antigas não têm letra de processador quando ele é Intel: `m5.large` é Intel e
`m5a.large` é AMD, porque a letra chegou junto com as alternativas. Da sexta geração em diante, a
Intel leva o seu `i` como todo mundo.

O moto traz a descrição da própria AWS para cada tipo, então dá para conferir as letras com ela. Três
tipos que diferem por uma letra cada:

```
ana@laptop:~/aws$ aws ec2 describe-instance-types --instance-types c7g.xlarge c7gd.xlarge c7gn.xlarge --query "InstanceTypes[].[InstanceType,ProcessorInfo.SupportedArchitectures[0],InstanceStorageInfo.TotalSizeInGB,NetworkInfo.NetworkPerformance]" --output table
--------------------------------------------------------
|                 DescribeInstanceTypes                |
+--------------+--------+-------+----------------------+
|  c7g.xlarge  |  arm64 |  None |  Up to 12.5 Gigabit  |
|  c7gd.xlarge |  arm64 |  237  |  Up to 12.5 Gigabit  |
|  c7gn.xlarge |  arm64 |  None |  Up to 40 Gigabit    |
+--------------+--------+-------+----------------------+
```

Os três são Graviton, então os três são `arm64`. O `d` acrescenta um disco de 237 GB dentro do host,
e o `n` sobe o teto de rede de 12,5 para 40 gigabits por segundo. Todo o resto das três máquinas é
igual.

## A letra do processador decide o que vai rodar

**`g` é a letra com consequências.** Um processador Arm roda programas compilados para Arm, e uma
imagem feita para `x86_64` não dá boot nele. Os runtimes de linguagem, as principais distribuições
Linux e a maioria das imagens de contêiner publicam as duas builds, então um serviço em Python ou
Java em geral passa para o outro lado sem mudar nada. A mudança para no binário fechado de um
fornecedor, ou numa biblioteca nativa que ninguém compilou para `arm64`.

A letra também muda o que é uma vCPU:

```
ana@laptop:~/aws$ aws ec2 describe-instance-types --instance-types m7i.large m7a.large m7g.large --query "InstanceTypes[].[InstanceType,ProcessorInfo.Manufacturer,ProcessorInfo.SupportedArchitectures[0],VCpuInfo.DefaultCores,VCpuInfo.DefaultThreadsPerCore]" --output table
--------------------------------------------
|           DescribeInstanceTypes          |
+------------+--------+---------+----+-----+
|  m7a.large |  AMD   |  x86_64 |  2 |  1  |
|  m7g.large |  AWS   |  arm64  |  2 |  1  |
|  m7i.large |  Intel |  x86_64 |  1 |  2  |
+------------+--------+---------+----+-----+
```

Na `m7i.large` as duas vCPU são **um núcleo rodando duas threads**, o simultaneous multithreading da
Intel. Na `m7a.large` e na `m7g.large` são dois núcleos inteiros com uma thread cada: a sétima geração
da AMD na AWS roda sem a segunda thread, e o Graviton nunca teve uma. Então "2 vCPU" na tabela de
preços não é a mesma quantidade de processador nas três, e um programa limitado por CPU pode
terminar bem antes no tipo com dois núcleos de verdade. O único jeito de saber quanto antes é rodar o
seu próprio programa em cada um.

## O que o moto deixa passar, e a AWS não

Aqui o moto é mais tolerante que a AWS, e vale ver a diferença uma vez. As duas chamadas foram
aceitas:

```
ana@laptop:~/aws$ aws ec2 run-instances --image-id ami-0b44997419d0b0d38 --instance-type m7g.large --query "Instances[0].[InstanceType,Architecture]" --output text
m7g.large	x86_64
ana@laptop:~/aws$ aws ec2 run-instances --image-id ami-0b44997419d0b0d38 --instance-type m7i.huge --query "Instances[0].[InstanceType,State.Name]" --output text
m7i.huge	pending
```

A primeira lançou um tipo Arm a partir de uma imagem `x86_64`, a imagem Amazon Linux 2023 de onde a
lição 2 parte, e o moto ainda informa a instância como `x86_64`. A segunda lançou `m7i.huge`, um
tamanho que não existe. **Na AWS as duas chamadas são recusadas antes de qualquer coisa começar ou
ser cobrada**: o EC2 confere se a arquitetura da imagem bate com a do tipo, e se o tipo existe e é
oferecido onde você pediu. O moto guarda um registro de tudo o que recebeu.

O hábito a levar daqui é conferir o par você mesmo, porque um erro que o moto nunca levanta é um que
você vai encontrar pela primeira vez na AWS. `aws ec2 describe-images --image-ids … --query
'Images[0].Architecture'` mostra a arquitetura da imagem, e a do tipo está na tabela acima.

## Depois do ponto: o tamanho

Tudo depois do ponto é o **tamanho**: `nano`, `micro`, `small`, `medium`, `large`, `xlarge`, depois
`2xlarge` para cima, e `metal` para o host físico inteiro, sem hipervisor entre você e ele. Dentro de
uma família, cada degrau dobra as vCPU e a memória e mantém a proporção. A última seção de leitura
desta lição põe preços nessa duplicação, e na família cujos tamanhos não se comportam como os
outros.
