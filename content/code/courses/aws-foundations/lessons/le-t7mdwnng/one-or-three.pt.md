---
title: Um NAT gateway por zona, ou um para todas, e quanto custa cada um
version: 1
---

**Um NAT gateway pertence a uma zona, então a loja escolhe entre perder a saída de uma zona junto
com a zona, e pagar por três.** Com um gateway em `public-a`, as sub-redes privadas das zonas b e c
mandam o tráfego de internet delas atravessando uma fronteira de zona para chegar a ele, e quando a
zona a falha elas perdem a internet junto, embora as próprias zonas estejam bem. Com um gateway em
cada zona, a tabela privada de cada zona aponta para o seu, e uma falha fica onde aconteceu. O resto
desta seção põe preços nas duas opções.

## Os preços

Um NAT gateway é cobrado pela hora em que existe e pelo gigabyte que processa, e essas duas linhas
estão na **oferta do EC2**, não na da VPC. Essa oferta precifica todo tipo de máquina em toda
combinação, então é grande: o `price.py` a baixa uma vez, e o `ls` no fim mostra o que ele guarda.

```
ana@laptop:~/aws$ python3 price.py AmazonEC2 20260925174521 sa-east-1 SAE1-NatGateway-Hours SAE1-NatGateway-Bytes SAE1-RegionalNatGateway-Hours
AmazonEC2 20260925174521, published 2026-09-25, USD
SAE1-NatGateway-Hours
          0 to       Inf Hrs  0.0930
SAE1-NatGateway-Bytes
          0 to       Inf GB   0.0930
SAE1-RegionalNatGateway-Hours
          0 to       Inf Hrs  0.0930
ana@laptop:~/aws$ ls -sh ~/.cache/aws-prices | grep AmazonEC2
279M AmazonEC2-20260925174521-sa-east-1.json
```

Estes são os preços que a AWS publicou em **25 de setembro de 2026** para São Paulo, e o endereço
público vem da oferta da VPC de **17 de setembro de 2026**:

```
ana@laptop:~/aws$ python3 price.py AmazonVPC 20260917190528 sa-east-1 SAE1-PublicIPv4:InUseAddress
AmazonVPC 20260917190528, published 2026-09-17, USD
SAE1-PublicIPv4:InUseAddress
          0 to       Inf Hrs  0.0050
```

**0,093 dólar por hora, 0,093 dólar por gigabyte, e 0,005 por hora para o Elastic IP.** Um mês tem
umas 730 horas, que é o que os próprios exemplos da AWS usam, então um NAT gateway com seu endereço
custa:

| | por mês |
|---|---|
| o gateway, 730 × 0,093 | 67,89 |
| o Elastic IP dele, 730 × 0,005 | 3,65 |
| **um NAT gateway, antes de qualquer tráfego** | **71,54** |
| **três, um por zona** | **214,62** |

Os gigabytes custam o mesmo de qualquer jeito: 200 GB por mês pelo NAT são 200 × 0,093 = **18,60
dólares**, seja um gateway levando todos ou três dividindo. **O que muda com o número de gateways é a
parte por hora, e a travessia.**

A terceira linha, `SAE1-RegionalNatGateway-Hours`, é um tipo mais novo de NAT gateway que a própria
AWS espalha pelas zonas, ao mesmo preço por hora. O moto 5.2.3 só constrói o tipo zonal, então esta
lição também; leia as páginas da AWS sobre o regional antes de contar com ele, porque ele muda a
troca abaixo.

## O que o gateway compartilhado custa no lugar

Um gateway compartilhado economiza dois deles, **143,08 dólares por mês**. O que ele acrescenta é a
travessia: todo gigabyte das zonas b e c chega a `public-a` atravessando uma fronteira de zona, e a
lição 1 mediu isso a 0,01 por gigabyte **em cada sentido**, então 0,02 por gigabyte que atravessa. O
ponto de equilíbrio é 143,08 / 0,02 ≈ **7.154 GB por mês** atravessando até o gateway
compartilhado. Abaixo disso, um gateway sai mais barato em dinheiro; acima, três saem.

A loja manda uns 200 GB por mês para a internet a partir das sub-redes privadas, dois terços delas
das zonas b e c. Compartilhar custaria 133 × 0,02 ≈ 2,67 dólares de travessia, para economizar
143,08 de gateways. **Só no dinheiro, o gateway compartilhado ganha com folga.** O que ele custa não
está na fatura:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 370\" role=\"img\" data-fig=\"l17-nat-choice\" aria-label=\"Duas maneiras de dar uma saída às sub-redes privadas da loja, desenhadas lado a lado nas três zonas de sa-east-1. À esquerda, um NAT gateway por zona: app-a usa nat-a em public-a, app-b usa nat-b, app-c usa nat-c, e nada atravessa uma zona. Custa 214,62 dólares por mês antes do tráfego, e perder a zona a custa só a saída da zona a. À direita, um NAT gateway compartilhado, nat-a em public-a: app-b e app-c chegam a ele atravessando as fronteiras de zona, a 0,01 dólar por gigabyte em cada sentido. Custa 71,54 dólares por mês mais a travessia, e perder a zona a corta as zonas b e c da internet também.\"><defs><marker id=\"l17-nat-choice-af-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l17-nat-choice-af-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"195.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">um por zona</text><text x=\"195.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">214,62 por mês</text><text x=\"535.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">um compartilhado</text><text x=\"535.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">71,54 por mês, mais 0,02 por GB que atravessa</text><rect x=\"30.0\" y=\"56.0\" width=\"330.0\" height=\"210.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"6 4\"></rect><rect x=\"42.0\" y=\"70.0\" width=\"92.0\" height=\"184.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"88.0\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">sa-east-1a</text><rect x=\"50.0\" y=\"96.0\" width=\"76.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"88.0\" y=\"116.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">app-a</text><rect x=\"50.0\" y=\"196.0\" width=\"76.0\" height=\"46.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"88.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">public-a</text><rect x=\"62.0\" y=\"218.0\" width=\"52.0\" height=\"18.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"88.0\" y=\"227.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">nat-a</text><path d=\"M88.0 138.0 L88.0 192.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l17-nat-choice-af-ah-phosphor)\"></path><rect x=\"150.0\" y=\"70.0\" width=\"92.0\" height=\"184.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"196.0\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">sa-east-1b</text><rect x=\"158.0\" y=\"96.0\" width=\"76.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"196.0\" y=\"116.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">app-b</text><rect x=\"158.0\" y=\"196.0\" width=\"76.0\" height=\"46.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"196.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">public-b</text><rect x=\"170.0\" y=\"218.0\" width=\"52.0\" height=\"18.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"196.0\" y=\"227.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">nat-b</text><path d=\"M196.0 138.0 L196.0 192.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l17-nat-choice-af-ah-phosphor)\"></path><rect x=\"258.0\" y=\"70.0\" width=\"92.0\" height=\"184.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"304.0\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">sa-east-1c</text><rect x=\"266.0\" y=\"96.0\" width=\"76.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"304.0\" y=\"116.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">app-c</text><rect x=\"266.0\" y=\"196.0\" width=\"76.0\" height=\"46.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"304.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">public-c</text><rect x=\"278.0\" y=\"218.0\" width=\"52.0\" height=\"18.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"304.0\" y=\"227.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">nat-c</text><path d=\"M304.0 138.0 L304.0 192.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l17-nat-choice-af-ah-phosphor)\"></path><rect x=\"370.0\" y=\"56.0\" width=\"330.0\" height=\"210.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"6 4\"></rect><rect x=\"382.0\" y=\"70.0\" width=\"92.0\" height=\"184.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"428.0\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">sa-east-1a</text><rect x=\"390.0\" y=\"96.0\" width=\"76.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"428.0\" y=\"116.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">app-a</text><rect x=\"390.0\" y=\"196.0\" width=\"76.0\" height=\"46.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"428.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">public-a</text><rect x=\"394.0\" y=\"218.0\" width=\"52.0\" height=\"18.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"420.0\" y=\"227.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">nat-a</text><path d=\"M420.0 138.0 L420.0 192.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l17-nat-choice-af-ah-phosphor)\"></path><rect x=\"490.0\" y=\"70.0\" width=\"92.0\" height=\"184.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"536.0\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">sa-east-1b</text><rect x=\"498.0\" y=\"96.0\" width=\"76.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"536.0\" y=\"116.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">app-b</text><rect x=\"498.0\" y=\"196.0\" width=\"76.0\" height=\"46.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"536.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">public-b</text><rect x=\"598.0\" y=\"70.0\" width=\"92.0\" height=\"184.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"644.0\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">sa-east-1c</text><rect x=\"606.0\" y=\"96.0\" width=\"76.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"644.0\" y=\"116.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">app-c</text><rect x=\"606.0\" y=\"196.0\" width=\"76.0\" height=\"46.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"644.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">public-c</text><path d=\"M536.0 138.0 L536.0 166.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M536.0 166.0 L490.0 166.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M644.0 138.0 L644.0 166.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M644.0 166.0 L598.0 166.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M598.0 166.0 L582.0 166.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M582.0 166.0 L536.0 166.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M490.0 166.0 L474.0 166.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M474.0 166.0 L460.0 166.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M460.0 166.0 L460.0 196.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M460.0 196.0 L460.0 227.0 L449.0 227.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l17-nat-choice-af-ah-amber)\"></path><text x=\"535.0\" y=\"280.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">cada travessia de zona: 0,01 por GB em cada sentido</text><text x=\"195.0\" y=\"300.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">zona a perdida: as máquinas da zona a</text><text x=\"195.0\" y=\"316.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">perdem a saída, e mais ninguém</text><text x=\"535.0\" y=\"300.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">zona a perdida: as zonas b e c perdem</text><text x=\"535.0\" y=\"316.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">a saída também</text><text x=\"360.0\" y=\"352.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">preços de NAT: oferta EC2 de 25 de setembro de 2026; 730 horas por mês, com um Elastic IP cada</text></svg>", "caption": "Três gateways custam 143,08 dólares por mês a mais que um. Um gateway só transforma a falha de uma zona na falha de todos."}
```

- **A falha de uma zona vira a de todas.** Com o gateway na zona a, perder a zona a para as chamadas
  de pagamento das máquinas em b e c também, que eram o motivo de a loja se espalhar por zonas.
- **Todo o tráfego de saída da VPC passa pela capacidade de uma zona.** Um gateway escala sozinho
  dentro de limites; um gateway só ainda carrega tudo.

Então a escolha da loja é **um por zona na produção e um compartilhado no staging**, onde uma zona
perdida custa uma tarde, não vendas. É uma decisão sobre quanto vale uma queda, e a tabela acima é
com o que ela se pesa. E se a maior parte dos 200 GB for tráfego para o S3, a lição 19 mostra um
jeito de mandá-lo para lá de graça, que ganha das duas opções.

## A lição como script

Este é o arranjo de produção, cada zona com seu gateway e sua tabela, como um script para as
próximas lições reconstruírem a partir dele. Ele procura as sub-redes pelos nomes que a lição 16
deu:

```sh
cat > ~/aws/net/17-routes.sh <<'EOF'
# Lesson 17: the shop's routes. An internet gateway and one public route table
# for the three public subnets; in each zone, a NAT gateway and a private route
# table for that zone's app and data subnets. Run it after 16-vpc.sh.
subnet() { aws ec2 describe-subnets --filters Name=tag:Name,Values="$1" \
  --query "Subnets[0].SubnetId" --output text; }
tags() { echo "ResourceType=$1,Tags=[{Key=Name,Value=$2},{Key=project,Value=shop}]"; }
vpc=$(aws ec2 describe-vpcs --filters Name=tag:Name,Values=shop-prod \
  --query "Vpcs[0].VpcId" --output text)
igw=$(aws ec2 create-internet-gateway --tag-specifications "$(tags internet-gateway shop-prod)" \
  --query InternetGateway.InternetGatewayId --output text)
aws ec2 attach-internet-gateway --internet-gateway-id "$igw" --vpc-id "$vpc"
pub=$(aws ec2 create-route-table --vpc-id "$vpc" --tag-specifications "$(tags route-table public)" \
  --query RouteTable.RouteTableId --output text)
aws ec2 create-route --route-table-id "$pub" --destination-cidr-block 0.0.0.0/0 \
  --gateway-id "$igw" > /dev/null
for z in a b c; do
  aws ec2 associate-route-table --route-table-id "$pub" --subnet-id "$(subnet public-$z)" > /dev/null
  eip=$(aws ec2 allocate-address --domain vpc --tag-specifications "$(tags elastic-ip nat-$z)" \
    --query AllocationId --output text)
  nat=$(aws ec2 create-nat-gateway --subnet-id "$(subnet public-$z)" --allocation-id "$eip" \
    --tag-specifications "$(tags natgateway nat-$z)" --query NatGateway.NatGatewayId --output text)
  priv=$(aws ec2 create-route-table --vpc-id "$vpc" --tag-specifications "$(tags route-table private-$z)" \
    --query RouteTable.RouteTableId --output text)
  aws ec2 create-route --route-table-id "$priv" --destination-cidr-block 0.0.0.0/0 \
    --nat-gateway-id "$nat" > /dev/null
  for tier in app data; do
    aws ec2 associate-route-table --route-table-id "$priv" --subnet-id "$(subnet $tier-$z)" > /dev/null
  done
  echo "zone $z: $nat in public-$z, $priv for app-$z and data-$z"
done
EOF
```

Ele deixa de fora a rota do escritório e o egress-only gateway, que estavam ali para serem lidos e
não usados. Para conferir, reinicie o moto mais uma vez e rode o script da lição 16 e este, um
depois do outro; o último comando lista as tabelas, quantas sub-redes cada uma serve, e para onde
cada uma manda `0.0.0.0/0`:

```
ana@laptop:~/aws$ bash net/16-vpc.sh > /dev/null && bash net/17-routes.sh
zone a: nat-99abbf31f5912eafc in public-a, rtb-2f5b255a96df86cac for app-a and data-a
zone b: nat-de872524ebf250fe5 in public-b, rtb-8a1f0f36b3db1cfbe for app-b and data-b
zone c: nat-c69478fa57a3113fe in public-c, rtb-2725b1ebad62ad346 for app-c and data-c
ana@laptop:~/aws$ vpc=$(aws ec2 describe-vpcs --filters Name=tag:Name,Values=shop-prod --query "Vpcs[0].VpcId" --output text)
ana@laptop:~/aws$ aws ec2 describe-route-tables --filters Name=vpc-id,Values=$vpc --query "RouteTables[].[Tags[?Key==\`Name\`]|[0].Value, length(Associations), Routes[?DestinationCidrBlock==\`0.0.0.0/0\`]|[0].[GatewayId || NatGatewayId]|[0]]" --output text
None	1	None
public	3	igw-9b4b06c5ca27dc488
private-a	2	nat-99abbf31f5912eafc
private-b	2	nat-de872524ebf250fe5
private-c	2	nat-c69478fa57a3113fe
```

**A tabela sem nome é a principal**: ela não serve sub-rede nenhuma agora, e a única associação dela
é o marcador que a faz principal. Toda sub-rede tem uma tabela explícita, três públicas e seis
privadas, e uma sub-rede acrescentada depois sem tabela cai naquela que não tem saída.
