---
title: Mais espaço, IPv6, e o que torna uma sub-rede pública
version: 1
---

**Uma VPC pode crescer depois de criada, e o nome de uma sub-rede não decide nada.** Esta seção
acrescenta um segundo intervalo à VPC da loja, dá IPv6 a ela, e depois pergunta quais das nove
sub-redes alcançam a internet. A resposta é nenhuma, incluindo as três chamadas `public`, e o motivo
é a lição 17 inteira.

## Um segundo intervalo

Um `/16` é o maior intervalo primário, e uma VPC que o enche não fica presa: **até cinco intervalos
IPv4 podem ser associados a uma VPC**, uma cota que a AWS aumenta sob pedido. O motivo comum é uma
plataforma que dá muitos endereços a cada máquina, como o Kubernetes dando um a cada pod. O lugar
de costume para achar espaço é `100.64.0.0/10`, o bloco reservado para redes de
operadoras, que o resto do plano da loja nunca usa.

```
ana@laptop:~/aws$ aws ec2 associate-vpc-cidr-block --vpc-id $vpc --cidr-block 100.64.0.0/16 --query "CidrBlockAssociation.[CidrBlock,CidrBlockState.State]" --output text
100.64.0.0/16	associating
ana@laptop:~/aws$ aws ec2 describe-route-tables --filters Name=vpc-id,Values=$vpc --query "RouteTables[].Routes[].[DestinationCidrBlock,GatewayId]" --output text
10.20.0.0/16	local
100.64.0.0/16	local
ana@laptop:~/aws$ overlap=$(aws ec2 associate-vpc-cidr-block --vpc-id $vpc --cidr-block 10.20.128.0/17 --query CidrBlockAssociation.AssociationId --output text)
ana@laptop:~/aws$ aws ec2 disassociate-vpc-cidr-block --association-id $overlap --query "CidrBlockAssociation.[CidrBlock,CidrBlockState.State]" --output text
10.20.128.0/17	disassociating
```

**Cada intervalo ganha uma rota `local` própria** na tabela de rotas, e é assim que um pacote entre
`10.20.x.x` e `100.64.x.x` fica dentro da VPC. A AWS recusa um segundo intervalo que se sobreponha
ao primeiro, ou a uma rota já presente numa das tabelas de rotas da VPC. Ela também restringe
intervalos por família. Uma VPC cujo intervalo primário está em `10.0.0.0/8` não pode acrescentar um
de `172.16.0.0/12` ou `192.168.0.0/16`. **O moto verifica menos**, e os dois últimos comandos
mostram isso. Ele aceitou `10.20.128.0/17`, metade do próprio intervalo primário da VPC, que a AWS
recusaria. Essa recusa não foi executada aqui. O intervalo sobreposto foi retirado de novo com
`disassociate-vpc-cidr-block`, para que o laboratório bata com o que a AWS guardaria.

## IPv6, em poucas palavras

**Um intervalo IPv6 na AWS é público por natureza.** A AWS dá a uma VPC um `/56` de endereços únicos
no mundo, do pool dela, e cada sub-rede fica com um `/64` dele. São 2⁶⁴ endereços por sub-rede,
então ninguém planeja sub-redes IPv6 por tamanho. Não existe um intervalo IPv6 privado no sentido de
`10.0.0.0/8`. Uma máquina com endereço IPv6 tem um que a internet inteira poderia rotear. **O que a
mantém privada é um gateway que deixa conexões saírem e nenhuma entrar**, o egress-only internet
gateway da lição 17.

```
ana@laptop:~/aws$ aws ec2 associate-vpc-cidr-block --vpc-id $vpc --amazon-provided-ipv6-cidr-block --query "Ipv6CidrBlockAssociation.Ipv6Pool" --output text
Amazon
ana@laptop:~/aws$ six=$(aws ec2 describe-vpcs --vpc-ids $vpc --query "Vpcs[0].Ipv6CidrBlockAssociationSet[0].Ipv6CidrBlock" --output text); echo $six
2400:6500:a393:7400::/56
ana@laptop:~/aws$ first=$(python3 -c "import ipaddress, sys; print(next(ipaddress.ip_network(sys.argv[1]).subnets(new_prefix=64)))" $six); echo $first
2400:6500:a393:7400::/64
ana@laptop:~/aws$ pa=$(aws ec2 describe-subnets --filters Name=tag:Name,Values=public-a --query "Subnets[0].SubnetId" --output text)
ana@laptop:~/aws$ aws ec2 associate-subnet-cidr-block --subnet-id $pa --ipv6-cidr-block $first --query "Ipv6CidrBlockAssociation.Ipv6CidrBlockState.State" --output text
associated
```

O `/56` aqui é invenção do moto, de um bloco que no mundo real pertence à AWS, e o seu vai ser
diferente. O programa Python de uma linha pega o primeiro `/64` dele, do jeito que o `plan.py` pegou
o primeiro `/20`. A sub-rede `public-a` agora tem um endereço em cada família. O resto deste curso
fica no IPv4, que é onde estão os endereços da loja e as linhas da lista de preços.

## Público é uma rota, não uma configuração

Esta é a ideia para a qual a lição foi construída, e é a que mais aparece errada. **Uma sub-rede é
pública quando a tabela de rotas dela manda `0.0.0.0/0` para um internet gateway.** Nada mais a
torna pública: nem o nome, nem uma tag, nem a flag `MapPublicIpOnLaunch` que as sub-redes da VPC
padrão carregam. Essa flag dá a uma máquina um endereço público quando ela liga, e **um endereço sem
rota para a internet não vai a lugar nenhum**. É o remetente numa carta que ninguém põe no correio.

Então a pergunta "esta sub-rede é pública?" se responde lendo a tabela de rotas dela:

```
ana@laptop:~/aws$ aws ec2 describe-route-tables --filters Name=vpc-id,Values=$vpc --query "RouteTables[].[RouteTableId,Associations[0].Main]" --output text
rtb-8d2d42a15ed11e3a3	True
ana@laptop:~/aws$ aws ec2 describe-route-tables --filters Name=association.subnet-id,Values=$pa --query "RouteTables[].RouteTableId"
[]
ana@laptop:~/aws$ aws ec2 describe-route-tables --filters Name=vpc-id,Values=$vpc --query "RouteTables[0].Routes[].[DestinationCidrBlock || DestinationIpv6CidrBlock,GatewayId]" --output text
10.20.0.0/16	local
100.64.0.0/16	local
2400:6500:a393:7400::/56	local
```

A VPC tem **uma tabela de rotas, a principal**, e o segundo comando não acha tabela nenhuma associada
a `public-a`. As duas coisas são esperadas. Uma sub-rede sem associação própria usa a tabela
principal, **implicitamente**, então uma busca por associação explícita responde com uma lista vazia.
E as rotas da tabela principal são só as `local`, uma para cada intervalo, IPv4 e IPv6: tudo dentro
da VPC, nada fora dela.

**As nove sub-redes, portanto, são privadas**, incluindo `public-a`, `public-b` e `public-c`. Os
nomes dizem para que elas servem. As rotas dizem o que elas são, e agora as rotas dizem a mesma
coisa para as nove.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 470\" role=\"img\" data-fig=\"l16-shop-vpc\" aria-label=\"A VPC de produção da loja, shop-prod, 10.20.0.0/16, dentro da região sa-east-1. Ela se estende por três Availability Zones, sa-east-1a, b e c, cujos ids de zona são sae1-az1, az2 e az3. Cada zona tem três sub-redes, uma por camada: public, app e data. A zona a tem public-a 10.20.0.0/20, app-a 10.20.48.0/20 e data-a 10.20.96.0/20; a zona b tem public-b 10.20.16.0/20, app-b 10.20.64.0/20 e data-b 10.20.112.0/20; a zona c tem public-c 10.20.32.0/20, app-c 10.20.80.0/20 e data-c 10.20.128.0/20. Abaixo delas, a tabela de rotas principal, que as nove usam por enquanto, com uma rota: 10.20.0.0/16 para local. A camada pública tem borda âmbar porque a lição 17 a torna pública; hoje a tabela de rotas dela é a mesma de todas as outras.\"><rect x=\"16.0\" y=\"16.0\" width=\"688.0\" height=\"404.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"6 4\"></rect><text x=\"32.0\" y=\"34.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">sa-east-1</text><rect x=\"36.0\" y=\"48.0\" width=\"648.0\" height=\"356.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper)\" stroke-width=\"1.4\"></rect><text x=\"52.0\" y=\"66.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">shop-prod  10.20.0.0/16</text><rect x=\"56.0\" y=\"82.0\" width=\"192.0\" height=\"222.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"152.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">sa-east-1a</text><text x=\"152.0\" y=\"113.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">sae1-az1</text><rect x=\"70.0\" y=\"126.0\" width=\"164.0\" height=\"48.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"152.0\" y=\"142.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">public-a</text><text x=\"152.0\" y=\"159.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.20.0.0/20</text><rect x=\"70.0\" y=\"184.0\" width=\"164.0\" height=\"48.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"152.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">app-a</text><text x=\"152.0\" y=\"217.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.20.48.0/20</text><rect x=\"70.0\" y=\"242.0\" width=\"164.0\" height=\"48.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"152.0\" y=\"258.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">data-a</text><text x=\"152.0\" y=\"275.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.20.96.0/20</text><rect x=\"262.0\" y=\"82.0\" width=\"192.0\" height=\"222.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"358.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">sa-east-1b</text><text x=\"358.0\" y=\"113.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">sae1-az2</text><rect x=\"276.0\" y=\"126.0\" width=\"164.0\" height=\"48.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"358.0\" y=\"142.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">public-b</text><text x=\"358.0\" y=\"159.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.20.16.0/20</text><rect x=\"276.0\" y=\"184.0\" width=\"164.0\" height=\"48.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"358.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">app-b</text><text x=\"358.0\" y=\"217.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.20.64.0/20</text><rect x=\"276.0\" y=\"242.0\" width=\"164.0\" height=\"48.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"358.0\" y=\"258.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">data-b</text><text x=\"358.0\" y=\"275.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.20.112.0/20</text><rect x=\"468.0\" y=\"82.0\" width=\"192.0\" height=\"222.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"564.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">sa-east-1c</text><text x=\"564.0\" y=\"113.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">sae1-az3</text><rect x=\"482.0\" y=\"126.0\" width=\"164.0\" height=\"48.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"564.0\" y=\"142.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">public-c</text><text x=\"564.0\" y=\"159.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.20.32.0/20</text><rect x=\"482.0\" y=\"184.0\" width=\"164.0\" height=\"48.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"564.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">app-c</text><text x=\"564.0\" y=\"217.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.20.80.0/20</text><rect x=\"482.0\" y=\"242.0\" width=\"164.0\" height=\"48.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"564.0\" y=\"258.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">data-c</text><text x=\"564.0\" y=\"275.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.20.128.0/20</text><rect x=\"56.0\" y=\"320.0\" width=\"604.0\" height=\"66.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"358.0\" y=\"340.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">tabela de rotas principal, usada pelas nove até a lição 17</text><text x=\"358.0\" y=\"364.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">10.20.0.0/16  →  local</text><rect x=\"140.0\" y=\"436.0\" width=\"22.0\" height=\"14.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"170.0\" y=\"443.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">camada pública, quando a lição 17 a rotear</text><rect x=\"430.0\" y=\"436.0\" width=\"22.0\" height=\"14.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"460.0\" y=\"443.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">camadas privadas</text></svg>", "caption": "Nove sub-redes, três por zona. Os nomes dizem para que servem; por enquanto uma tabela de rotas diz a mesma coisa para todas."}
```

A lição 17 torna três delas públicas. Ela anexa um internet gateway e dá a essas três uma tabela de
rotas própria que aponta `0.0.0.0/0` para ele. As outras seis continuam privadas, e alcançam a
internet, quando precisam, por um NAT gateway posto numa sub-rede pública. Duas tabelas de rotas
diferentes, nove sub-redes idênticas: **público e privado são uma propriedade da tabela de rotas.**
Uma sub-rede vira uma coisa ou outra ao ser associada a ela.

## Começando as próximas lições daqui

O moto esquece tudo quando para. As lições 17 a 20 começam de um moto vazio e reconstroem a VPC e as
sub-redes desta lição com `bash net/16-vpc.sh`. É por isso que o script cria a VPC quando não há
nenhuma. O segundo intervalo e os endereços IPv6 não estão nele, porque nenhuma das lições 17 a 20
precisa deles.
