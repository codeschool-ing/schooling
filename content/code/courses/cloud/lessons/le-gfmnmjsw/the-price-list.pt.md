---
title: Lendo a lista pública de preços
version: 2
---

Todo preço desta aula, e deste curso, é uma linha de um só documento: **a lista pública de preços que
a AWS publica em JSON**, que qualquer pessoa lê sem conta. O curso a lê com `prices.py`, o programa que a
aula 1 imprime inteiro, e esta é a tabela inteira que ele imprime:

```
ana@laptop:~/cloud$ python3 prices.py
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

EC2, Linux, 1-year reserved, no upfront, USD per hour
  t3.micro                                0.00960      0.00650
  t4g.small                               0.01540      0.01050
  t3.medium                               0.03860      0.02610
  m7i.large                               0.09956      0.06668
  m7g.large                               0.08060      0.05400
  c7i.large                               0.09085      0.05904
  m7i.xlarge                              0.19911      0.13336

EBS, USD per GB-month
  gp3 SSD volume                           0.1520       0.0800
  st1 HDD volume                           0.0860       0.0450
  snapshot                                 0.0680       0.0500

Networking, USD
  NAT gateway, per hour                    0.0930       0.0450
  NAT gateway, per GB processed            0.0930       0.0450
  load balancer (ALB), per hour            0.0340       0.0225
  public IPv4 address, per hour            0.0050       0.0050

S3, USD per GB-month (first tier)
  Standard                                0.04050      0.02300
  Standard-Infrequent Access              0.02210      0.01250
  Glacier Instant Retrieval               0.00830      0.00400
  Glacier Flexible Retrieval              0.00765      0.00360

S3 requests, USD per 1,000
  PUT, COPY, POST, LIST                   0.00700      0.00500
  GET and the rest                        0.00056      0.00040

EFS, USD per GB-month
  Standard                                 0.5700       0.3000

Data transfer, USD per GB
  out to the internet, first 10 TB         0.1500       0.0900
  out to the internet, next 40 TB          0.1380       0.0850
  out to the internet, next 100 TB         0.1260       0.0700
  out to the internet, over 150 TB         0.1140       0.0500
  between zones, each direction            0.0100       0.0100
  to the other region                      0.1380       0.0200
  in from the internet                     0.0000       0.0000

Lambda, USD
  per 1 million requests                     0.20         0.20
  per GB-second, x86                 0.0000166667 0.0000166667
  per GB-second, Arm                 0.0000133334 0.0000133334
  free tier, requests                   1,000,000    1,000,000
  free tier, GB-seconds                   400,000      400,000
```

## Ofertas e versões

A lista é dividida em **ofertas**, uma por serviço: `AmazonEC2` guarda as máquinas e os discos delas,
`AmazonVPC` os endereços públicos, `AWSDataTransfer` o tráfego, e assim por diante. Cada oferta é
publicada como um arquivo JSON por região, e **cada oferta guarda todas as versões que já publicou**. Uma
versão leva o nome do momento em que foi publicada, então `20260919002359` é a lista de preços do Lambda
como estava às 00:23:59 UTC de 19 de setembro de 2026.

O `prices.py` nomeia uma versão de cada oferta e nunca pede "a mais recente". É por isso que a tabela
acima vai imprimir os mesmos números no ano que vem, quando a AWS já tiver publicado muitas versões
novas e alguns preços tiverem mudado. **Um número numa aula tem de ser reproduzível, e só uma versão
fixada é.** O preço disso é que a tabela é uma fotografia. Para uma decisão de verdade, você lê a versão
atual, ou usa a calculadora do próprio provedor, que lê a lista atual por você: o AWS Pricing Calculator,
o Google Cloud Pricing Calculator, a calculadora de preços do Azure.

O cabeçalho também diz o que os números não são. Estão em USD e sem impostos. São o preço público, antes
de qualquer desconto que uma empresa negocie, de qualquer crédito e de qualquer compromisso, assunto da
seção sobre compromissos.

## O que é uma linha

A tabela é aritmética sobre o JSON. Aqui está o preço por requisição do Lambda em
São Paulo, lido do arquivo bruto com `curl` e `jq`, em dois passos:

```
ana@laptop:~/cloud$ url=https://pricing.us-east-1.amazonaws.com/offers/v1.0/aws/AWSLambda/20260919002359/sa-east-1/index.json
ana@laptop:~/cloud$ curl -s "$url" | jq '.products[] | select(.attributes.usagetype == "SAE1-Request") | .sku'
"7TZ969MZND3Z6HD7"
ana@laptop:~/cloud$ curl -s "$url" | jq '.terms.OnDemand["7TZ969MZND3Z6HD7"][].priceDimensions[] | {description, unit, pricePerUnit}'
{
  "description": "AWS Lambda - Total Requests - South America (Sao Paulo)",
  "unit": "Request",
  "pricePerUnit": {
    "USD": "0.0000002000"
  }
}
```

O primeiro passo acha o **produto**. Todo produto tem um SKU, um código opaco, e um conjunto de
atributos; o que diz o que está sendo medido é o `usagetype`. `SAE1-Request` se lê em duas partes:
`SAE1` é o prefixo da região de São Paulo, e `Request` é a coisa contada. Um produto ainda não é um
preço. É a definição de um medidor.

O segundo passo lê o **termo** do produto. `OnDemand` é o termo sem compromisso; o arquivo do EC2 também
traz termos `Reserved`, que é de onde vem o segundo bloco de preços de máquinas da tabela. Dentro do
termo, cada **dimensão de preço** traz a unidade e o preço de uma unidade: 0,0000002 USD por requisição.
Multiplique por um milhão e você tem a linha da tabela, `per 1 million requests 0.20`.

**Uma linha da tabela, então, são três coisas juntas**: um produto que diz o que é medido e onde, um
termo que diz em que condições, e uma dimensão de preço que diz quanto por unidade. O texto de
`description` existe para pessoas, e o programa nunca o lê.

## Faixas

Uma dimensão de preço também tem `beginRange` e `endRange`, que ficaram fora da consulta acima porque,
nas requisições do Lambda, valem `0` e `Inf`: um preço só para toda requisição. Onde não é assim, o
produto é **em faixas**. O tráfego de saída para a internet é o caso mais claro da tabela: 0,1500 por GB
nos primeiros 10 TB do mês, depois 0,1380, 0,1260 e 0,1140 conforme o volume cresce. Cada faixa é uma
dimensão de preço do mesmo produto, com seu próprio intervalo. Uma faixa vale para os gigabytes dentro
do intervalo dela, não para o mês inteiro, então o 11º terabyte custa menos que os dez primeiros, e os
dez primeiros continuam custando 0,1500 por gigabyte.

As franquias gratuitas também são faixas, como a seção sobre camadas gratuitas mostra com a mesma
consulta: um preço de zero, até um limite.
