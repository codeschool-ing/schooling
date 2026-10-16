---
title: Tabelas de rotas, e o gateway que torna uma sub-rede pública
version: 1
---

**Uma tabela de rotas é uma lista de destinos, cada um com um alvo, e toda sub-rede usa exatamente
uma.** Quando uma máquina manda um pacote, o roteador da VPC lê a tabela da sub-rede da máquina,
acha a rota cujo destino contém o endereço do pacote e entrega o pacote ao alvo dessa rota. A lição
16 terminou com nove sub-redes e uma tabela que só conhecia a própria VPC. Esta lição dá à loja três
tipos de saída, e cada uma delas é uma linha numa tabela.

A imagem errada é um roteador que se configura uma vez para a VPC inteira. **Há tantas decisões de
roteamento quanto tabelas de rotas**, e duas máquinas em duas sub-redes da mesma VPC podem mandar o
mesmo pacote para dois lugares diferentes, porque as sub-redes delas usam tabelas diferentes.

## Partindo da lição 16

Reinicie o moto no primeiro terminal (Ctrl+C, depois `moto_server -p 4567`) para que esta lição
comece de uma AWS vazia, e reconstrua a VPC da lição 16 com o script que ela deixou em `~/aws/net`.
Os ids que o moto inventa vão ser diferentes dos impressos aqui.

```
ana@laptop:~/aws$ bash net/16-vpc.sh
public-a	10.20.0.0/20	sae1-az1	4091
public-b	10.20.16.0/20	sae1-az2	4091
public-c	10.20.32.0/20	sae1-az3	4091
app-a	10.20.48.0/20	sae1-az1	4091
app-b	10.20.64.0/20	sae1-az2	4091
app-c	10.20.80.0/20	sae1-az3	4091
data-a	10.20.96.0/20	sae1-az1	4091
data-b	10.20.112.0/20	sae1-az2	4091
data-c	10.20.128.0/20	sae1-az3	4091
ana@laptop:~/aws$ vpc=$(aws ec2 describe-vpcs --filters Name=tag:Name,Values=shop-prod --query "Vpcs[0].VpcId" --output text)
ana@laptop:~/aws$ aws ec2 describe-route-tables --filters Name=vpc-id,Values=$vpc --query "RouteTables[].Routes[]"
[
    {
        "DestinationCidrBlock": "10.20.0.0/16",
        "GatewayId": "local",
        "Origin": "CreateRouteTable",
        "State": "active"
    }
]
```

O segundo comando guarda o id da VPC em `vpc`, como a lição 16 fez, e o terceiro imprime a única
tabela que a VPC tem. **A rota `local` é o próprio intervalo da VPC**: qualquer pacote para um
endereço dentro de `10.20.0.0/16` fica dentro da VPC, seja qual for a sub-rede de destino. A AWS a
põe em toda tabela, e ela não pode ser apagada. É por isso que duas máquinas na VPC sempre se
alcançam, no que depende do roteamento; se o pacote é então aceito é a pergunta da lição 18.

## A tabela principal, e as que você cria

**A tabela de rotas principal é a que uma sub-rede usa quando ninguém lhe deu outra.** A lição 16
encontrou as nove sub-redes usando-a implicitamente. Isso faz dela a tabela de toda sub-rede criada
às pressas, então o hábito seguro é **deixar a tabela principal privada, e dar a cada sub-rede que
precisa de mais uma tabela explícita própria**. Uma sub-rede acrescentada no ano que vem sem pensar
cai então num lugar fechado.

Uma tabela pertence a uma VPC e pode servir muitas sub-redes; uma sub-rede fica associada a uma
tabela de cada vez. Mudar uma sub-rede de tabela é `replace-route-table-association`, e vale a
partir do pacote seguinte, e é também por isso que uma associação errada é uma queda que começa na
hora.

## Um internet gateway

**Um internet gateway é a porta da VPC para a internet**: um alvo que uma rota pode nomear, anexado
a uma VPC, operado pela AWS em todas as zonas da região, de modo que ele não tem zona própria a
perder. Ele também traduz entre o endereço privado de uma máquina e o endereço público que a
internet vê, e é por isso que uma máquina atrás dele precisa de um endereço público próprio. Ele não
custa nada por hora; o que ele carrega é cobrado como transferência de dados, pelos preços que a
lição 1 leu.

```
ana@laptop:~/aws$ igw=$(aws ec2 create-internet-gateway --tag-specifications 'ResourceType=internet-gateway,Tags=[{Key=Name,Value=shop-prod}]' --query InternetGateway.InternetGatewayId --output text)
ana@laptop:~/aws$ aws ec2 attach-internet-gateway --internet-gateway-id $igw --vpc-id $vpc
ana@laptop:~/aws$ aws ec2 describe-internet-gateways --internet-gateway-ids $igw --query "InternetGateways[0].Attachments[].[VpcId,State]" --output text
vpc-4d9b138dab1e13c0a	available
ana@laptop:~/aws$ aws ec2 attach-internet-gateway --internet-gateway-id $igw --vpc-id $(aws ec2 describe-vpcs --filters Name=is-default,Values=true --query "Vpcs[0].VpcId" --output text)

aws: [ERROR]: An error occurred (Resource.AlreadyAssociated) when calling the AttachInternetGateway operation: Resource igw-7678c2ce06f59ad39 is already associated.
```

**Um gateway se anexa a uma VPC de cada vez**: quando se pede para anexar este também à VPC padrão,
o moto recusa com `Resource.AlreadyAssociated`, como a AWS faz. A regra vale no outro sentido
também, um internet gateway por VPC, e a AWS recusa um segundo; essa recusa não foi executada aqui.

## A tabela de rotas pública

Anexar o gateway ainda não mudou nada, e é esse o ponto da lição 16: nenhuma tabela manda nada para
ele. **Uma sub-rede fica pública no momento em que a tabela dela tem uma rota para `0.0.0.0/0` até o
internet gateway**, então a loja cria uma tabela para isso e associa as três sub-redes públicas a
ela:

```
ana@laptop:~/aws$ pub=$(aws ec2 create-route-table --vpc-id $vpc --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=public}]' --query RouteTable.RouteTableId --output text)
ana@laptop:~/aws$ aws ec2 create-route --route-table-id $pub --destination-cidr-block 0.0.0.0/0 --gateway-id $igw
{
    "Return": true
}
ana@laptop:~/aws$ for z in a b c; do aws ec2 associate-route-table --route-table-id $pub --subnet-id $(aws ec2 describe-subnets --filters Name=tag:Name,Values=public-$z --query "Subnets[0].SubnetId" --output text) --query AssociationState.State --output text; done
associated
associated
associated
ana@laptop:~/aws$ aws ec2 describe-route-tables --route-table-ids $pub --query "RouteTables[0].Routes[].[DestinationCidrBlock,GatewayId]" --output text
10.20.0.0/16	local
0.0.0.0/0	igw-7678c2ce06f59ad39
ana@laptop:~/aws$ pa=$(aws ec2 describe-subnets --filters Name=tag:Name,Values=public-a --query "Subnets[0].SubnetId" --output text)
ana@laptop:~/aws$ aws ec2 describe-route-tables --filters Name=association.subnet-id,Values=$pa --query "RouteTables[].Tags[?Key==\`Name\`].Value[]" --output text
public
```

**`0.0.0.0/0` é todo endereço IPv4**, o prefixo mais curto que existe, então é a rota que um pacote
toma quando nada mais específico casa. Na tabela `public` isso quer dizer: dentro da VPC, `local`;
em qualquer outro lugar, para fora pelo gateway. `public-a`, `public-b` e `public-c` agora são
públicas, e o filtro que respondeu `[]` na lição 16 acha a tabela delas.

**As outras seis sub-redes continuam privadas**, e não podem simplesmente usar a mesma tabela. Uma
máquina em `app-a` não tem endereço público, então o internet gateway não teria em que traduzir o
endereço dela, e um banco de dados em `data-a` não deveria estar a uma rota da internet de qualquer
forma. A próxima seção dá a elas uma saída que funciona num sentido só.

## O que o moto não faz aqui

**O moto não roteia nada.** Ele guarda toda tabela, toda rota e toda associação exatamente como a
AWS as devolve, e nenhum pacote passa por nenhuma delas: não há máquinas para mandar um e não há
rede por trás dos registros. Tudo o que esta lição diz sobre para onde vai um pacote é lido das
tabelas, do jeito que se lê um mapa, e a figura da próxima seção leva três pacotes por elas à mão.
Na AWS, o lugar para verificar um caminho de verdade é o VPC Reachability Analyzer, que a lição 18
cita junto com as outras ferramentas que observam o tráfego.
