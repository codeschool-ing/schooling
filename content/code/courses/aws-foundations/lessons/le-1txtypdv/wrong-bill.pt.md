---
title: Uma fatura que chegou errada
version: 1
---

**Uma fatura que chega maior que o esperado quase nunca tem um preço errado; ela tem uma linha que
ninguém esperava que existisse.** As máquinas estão na lista de todo mundo, e alguém já fez a conta
na seção sobre pagar por uma máquina. O que chega sem aviso é o custo de coisas que não são máquinas:
algo deixado ligado, tráfego atravessando uma fronteira, um endereço que ninguém está usando. Cada
uma é pequena por hora, e um mês são 730 horas.

## O caso

A conta de staging da loja, `shop-staging`, roda um `m7i.large` sob demanda, e o time esperava que a
fatura de setembro fosse essa instância, 117,27 dólares, pela tabela da seção sobre pagar por uma
máquina. A fatura chegou com mais que o dobro. Este é um caso trabalhado: as quatro linhas abaixo são
um conjunto de erros que as lições de rede deste curso ensinam a evitar, com preços da
lista, não uma fatura que alguém recebeu. Os preços vêm de três ofertas:

```
ana@laptop:~/aws$ python3 price.py AmazonEC2 20260925174521 sa-east-1 SAE1-NatGateway-Hours SAE1-NatGateway-Bytes
AmazonEC2 20260925174521, published 2026-09-25, USD
SAE1-NatGateway-Hours
          0 to       Inf Hrs  0.0930
SAE1-NatGateway-Bytes
          0 to       Inf GB   0.0930
```

O NAT gateway fica na oferta do EC2, que o `terms.py` já baixou para o mesmo cache, então o
`price.py` a lê sem baixar de novo. Um **NAT gateway** é o que deixa máquinas numa sub-rede privada
alcançarem a internet, e a lição 17 constrói um; ele custa 0,093 dólar por hora em que existe e 0,093
por gigabyte que passa por ele, na lista de 25 de setembro de 2026.

```
ana@laptop:~/aws$ python3 price.py AmazonVPC 20260917190528 sa-east-1 SAE1-PublicIPv4:InUseAddress SAE1-PublicIPv4:IdleAddress
AmazonVPC 20260917190528, published 2026-09-17, USD
SAE1-PublicIPv4:InUseAddress
          0 to       Inf Hrs  0.0050
SAE1-PublicIPv4:IdleAddress
          0 to       Inf Hrs  0.0050
```

**Todo endereço IPv4 público custa 0,005 dólar por hora, preso a algo ou não**, na lista de 17 de
setembro de 2026. As duas linhas têm o mesmo preço; o que o nome da segunda diz é que um endereço
guardado e preso a nada continua sendo pago.

```
ana@laptop:~/aws$ python3 price.py AWSDataTransfer 20260916132208 sa-east-1 SAE1-DataTransfer-Regional-Bytes
AWSDataTransfer 20260916132208, published 2026-09-16, USD
SAE1-DataTransfer-Regional-Bytes
          0 to       Inf GB   0.0100
```

A travessia entre zonas é a linha da lição 1, 0,01 por gigabyte, cobrada dos dois lados.

## As quatro linhas que ninguém esperava

| tipo de uso na fatura | o que aconteceu | quantidade | dólares |
|---|---|---|---|
| `SAE1-NatGateway-Hours` | um NAT gateway criado para um teste em agosto e nunca apagado | 730 horas × 0,093 | 67,89 |
| `SAE1-NatGateway-Bytes` | as atualizações de software e os logs da instância, mandados para fora por ele | 200 GB × 0,093 | 18,60 |
| `SAE1-PublicIPv4:IdleAddress` | dois endereços guardados depois que as máquinas a que pertenciam foram apagadas | 2 × 730 horas × 0,005 | 7,30 |
| `SAE1-DataTransfer-Regional-Bytes` | a instância em `sa-east-1a` conversando com um banco de dados em `sa-east-1b` | 800 GB × 0,02 | 16,00 |

Juntas elas dão **109,79 dólares**, e a fatura é 117,27 + 109,79 = 227,06, antes de impostos. Nenhuma
das quatro é uma máquina, e a maior é um gateway que quase não carregou nada: as horas de um NAT
gateway custam mais que o tráfego dele até ele passar de 730 GB por mês.

## Achando-as

**Agrupe o mês por tipo de uso, filtrado pela conta.** No Cost Explorer é a consulta da lição 13 com
`--group-by Type=DIMENSION,Key=USAGE_TYPE` e um filtro em `LINKED_ACCOUNT`; no Cost and Usage Report é
um `GROUP BY` na coluna do tipo de uso, que a lição 15 escreve. Um tipo de uso nomeia a coisa com
exatidão, `NatGateway-Hours` em vez de "EC2", e o prefixo de região diz onde. Cada linha tem então um
dono a quem perguntar e uma correção:

- o NAT gateway é apagado, ou o staging deixa de ter um: a lição 19 alcança serviços da AWS por VPC
  endpoints sem ele;
- os dois endereços são liberados; um endereço só vale a pena guardar quando algo está preso a ele;
- a instância e o banco de dados vão para uma zona só, o que para staging é uma troca justa, já que
  staging não precisa sobreviver à perda de uma zona (a regra da lição 1 para pares que conversam
  muito).

**A fatura que chegou errada é o motivo das tags da lição 13.** Agrupadas por `team`, essas quatro
linhas teriam chegado com o nome de alguém. Sem tag, elas ficam em `team$`, e a pergunta "de quem é
isto" vira uma tarde lendo tipos de uso, que é a tarde que esta seção acabou de passar.
