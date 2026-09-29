---
title: Uma região é um lugar
version: 1
---

A imagem com que a maioria chega é a de uma região como uma configuração: um menu no alto do console,
como o fuso horário de um laptop, que muda um rótulo e mais nada. **Uma região é um lugar.** É uma
área geográfica, como São Paulo, o norte da Virgínia ou Frankfurt, onde um provedor mantém vários
datacenters agrupados em zonas isoladas, que são o assunto da próxima seção. Quando você cria uma
máquina virtual, um bucket ou um banco de dados, ele é criado numa região e fica fisicamente ali.

Cada provedor dá nomes do seu jeito. A AWS chama São Paulo de `sa-east-1`, a Azure chama de
`brazilsouth` e o Google Cloud, de `southamerica-east1`. Os nomes mudam e a ideia não, então esta aula
usa os nomes da AWS porque a planilha de preços do curso usa.

A região se escolhe por recurso, não por conta. Uma conta pode ter uma instância em São Paulo, um
bucket na Virgínia e um banco em Frankfurt, e nada impede você de montar exatamente isso sem querer.
Três consequências vêm da escolha, e cada uma já pegou alguém.

## Os dados ficam onde você os pôs

**Um recurso vive na sua região até você movê-lo.** Um bucket criado em `sa-east-1` guarda os
objetos em São Paulo. O provedor não os copia para outra região por conta própria: copiar entre
regiões é algo que você configura, e paga, como mostra a seção desta aula sobre várias regiões.
Então a região é onde a promessa de residência de dados da aula 2 é cumprida, e uma réplica que você
monta em outro país é onde ela é quebrada.

## Os serviços mudam de região para região

**Uma região não é cópia de todas as outras.** Serviços novos e tipos novos de instância chegam a
algumas regiões antes das outras, e um serviço pode faltar numa região por anos. Um projeto que
depende de um serviço gerenciado precisa conferir se esse serviço existe na região onde vai rodar,
antes de qualquer coisa ser construída. Essa conferência é uma tabela no site do próprio provedor, e
os cursos de cada fornecedor, `aws-foundations`, `azure-foundations` e `gcp-foundations`, mostram onde
cada um a mantém.

## Os preços mudam de região para região

**A mesma instância tem um preço diferente em cada região.** Mesmo tamanho, mesmo sistema
operacional, mesma hora. A planilha de preços do curso é a lista pública da AWS para `sa-east-1` e
`us-east-1`, em dólares americanos, sem impostos, nas versões de oferta que ela imprime:

```
ana@laptop:~/cloud$ python3 prices.py ec2 | sed -n '1,17p'
AWS public price list, USD, excluding tax
  offer AmazonEC2        version 20260925174521
  offer AWSLambda        version 20260919002359
  offer AmazonS3         version 20260926015512
  offer AWSDataTransfer  version 20260916132208
  offer AmazonEFS        version 20260911124425
  offer AmazonVPC        version 20260917190528
                                        sa-east-1    us-east-1

EC2, Linux, on demand, USD per hour
  t3.micro    2 vCPU   1 GiB              0.01680      0.01040
  t4g.small   2 vCPU   2 GiB              0.02680      0.01680
  t3.medium   2 vCPU   4 GiB              0.06720      0.04160
  m7i.large   2 vCPU   8 GiB              0.16065      0.10080
  m7g.large   2 vCPU   8 GiB              0.13010      0.08160
  c7i.large   2 vCPU   4 GiB              0.13755      0.08925
  m7i.xlarge  4 vCPU  16 GiB              0.32130      0.20160
```

Leia duas linhas. Uma `t3.micro` custa 0,01680 por hora em São Paulo e 0,01040 na Virgínia, e
0,01680 / 0,01040 = 1,615: a mesma máquina custa uns 62% a mais na `sa-east-1`. Uma `m7i.large` custa
0,16065 contra 0,10080, e 0,16065 / 0,10080 = 1,594, uns 59% a mais. **A razão não é um número
fixo**, mas toda linha sob demanda desse bloco fica entre 1,54 (a `c7i.large`) e 1,62.

Num mês de 30 dias, 720 horas, uma `m7i.large` sai por 0,16065 × 720 = 115,67 dólares em São Paulo e
0,10080 × 720 = 72,58 na Virgínia. A diferença, 43,09 dólares por mês para uma máquina, é o preço da
região e de mais nada.

A planilha diz quais são os preços, não por que diferem. Sejam quais forem os motivos, eles são do
provedor, e o que você pode usar é o número. Ele é uma das cinco perguntas do checklist desta aula
para escolher uma região, e raramente é a primeira: uma região mais barata que desrespeita a lei a que
você está sujeito, ou que põe seus usuários a cem milissegundos de distância, não é mais barata.
