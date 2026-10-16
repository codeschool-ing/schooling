---
title: A saída, com preço
version: 1
---

A função está em subnets privadas, alcança o banco de dados dela, e não alcança mais nada. **A
primeira chamada que ela faz ao S3, ao Secrets Manager ou a uma API de pagamento espera até o
timeout e falha**, sem nenhum erro que fale da rede, porque os pacotes não foram a lugar nenhum. Há
duas saídas, e elas custam muito diferente.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"Uma função numa subnet privada de uma VPC chega diretamente ao banco de dados ao lado dela. Para ir além ela tem três saídas: um NAT gateway, cobrado por hora e por gigabyte, para a internet inteira; um gateway endpoint, sem custo, para o S3 e o DynamoDB; e um interface endpoint, uma interface de rede na subnet, para um serviço da AWS cada, como o Secrets Manager ou o SQS.\"><defs><marker id=\"wy-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"16\" y=\"16\" width=\"440\" height=\"248\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"28\" y=\"34\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\" font-weight=\"600\">VPC</text><rect x=\"32\" y=\"52\" width=\"180\" height=\"196\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"44\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">subnet privada</text><rect x=\"48\" y=\"90\" width=\"148\" height=\"40\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"122\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">função</text><rect x=\"48\" y=\"180\" width=\"148\" height=\"40\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"122\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">banco de dados</text><path d=\"M122 132 L122 176\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#wy-ah)\"></path><rect x=\"260\" y=\"52\" width=\"180\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"350\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\" font-weight=\"600\">NAT gateway</text><text x=\"350\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">0,093/h + 0,093/GB</text><rect x=\"260\" y=\"122\" width=\"180\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"350\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">gateway endpoint</text><text x=\"350\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">sem custo, só rotas</text><rect x=\"260\" y=\"192\" width=\"180\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"350\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">interface endpoint</text><text x=\"350\" y=\"228\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">uma ENI por subnet, um serviço</text><path d=\"M198 104 L256 80\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#wy-ah)\"></path><path d=\"M198 112 L256 146\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#wy-ah)\"></path><path d=\"M198 120 L256 214\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#wy-ah)\"></path><rect x=\"500\" y=\"40\" width=\"204\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"602\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\" font-weight=\"600\">a internet</text><text x=\"602\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">e todo endpoint público</text><rect x=\"500\" y=\"122\" width=\"204\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"602\" y=\"147\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">S3, DynamoDB</text><rect x=\"500\" y=\"192\" width=\"204\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"602\" y=\"217\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">Secrets Manager, SQS, ...</text><path d=\"M442 77 L496 70\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#wy-ah)\"></path><path d=\"M442 147 L496 147\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#wy-ah)\"></path><path d=\"M442 217 L496 217\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#wy-ah)\"></path></svg>", "caption": "Uma subnet privada não tem rota para a internet, e isso inclui os endpoints públicos dos próprios serviços da AWS. Um NAT gateway abre tudo, por hora e por gigabyte; os endpoints abrem um serviço cada, e o tipo gateway não custa nada.", "same": ["VPC", "NAT gateway", "gateway endpoint", "interface endpoint"]}
```

## Um NAT gateway: tudo, por hora e por gigabyte

Um NAT gateway fica numa subnet pública com um endereço público, e uma rota na tabela das subnets
privadas manda o tráfego de internet delas para ele. A lição 17 de `aws-foundations` constrói um.
Ele abre a internet inteira para a função, e a tabela de preços de 16 de outubro de 2026 tem os dois
medidores dele:

```
ana@laptop:~/aws$ python3 prices.py ec2 | grep -A2 '^Network'
Network
  NAT gateway                                      0.093  per hour
  NAT gateway, data processed                      0.093  per GB
```

**Os dois medidores correm cada um por si.** A cobrança por hora é paga em toda hora em que o
gateway existe, usado ou não: 0,093 × 730 = 67,89 USD por mês em sa-east-1. Um NAT gateway vive numa
zona, e uma função em duas zonas cujo único gateway está na zona a perde a internet quando a zona a
cai, então o arranjo que a AWS recomenda é um gateway por zona: dois deles para as duas subnets desta
lição, 135,78 USD por mês antes de um único byte. A cobrança de dados é 0,093 USD por gigabyte que o
gateway processa, nos dois sentidos. Uma função que baixa 200 GB por mês do S3 através dele soma
200 × 0,093 = 18,60 USD, por um tráfego que nunca precisou sair da AWS.

Esse último número é o que vale olhar duas vezes. **O tráfego para o S3 através de um NAT gateway
paga a cobrança de dados do gateway por algo que tem um caminho gratuito**, e os próximos parágrafos
são esse caminho.

## Endpoints: um serviço de cada vez

Um VPC endpoint dá às subnets um caminho privado para um serviço da AWS, sem a internet e sem um NAT
gateway. A lição 19 de `aws-foundations` apresenta os dois tipos; o que importa aqui é de qual a
função precisa.

Um **gateway endpoint** existe só para o S3 e o DynamoDB. Ele é uma entrada na tabela de rotas que
manda o tráfego para as faixas de endereço do serviço até o endpoint, e não custa nada, nem por hora
nem por gigabyte. Para uma função que lê e grava no S3, ele tira de uma vez a maior parte da conta
de dados de um NAT gateway.

Um **interface endpoint** existe para a maioria dos outros serviços: Secrets Manager, SQS, SNS, Step
Functions, CloudWatch Logs, ECR. Ele é uma interface de rede em cada subnet que você escolher, com um
endereço privado para o qual o nome de sempre do serviço resolve dentro da VPC, então o SDK não
precisa de mudança. Ele é cobrado por hora por zona e por gigabyte; **esses preços não estão na
tabela de preços deste curso**, então esta lição não cita valor para eles, e a página de preços do
PrivateLink da AWS é onde eles são publicados.

Os dois rodam contra o moto. A tabela de rotas é a que a VPC ganhou ao ser criada. O interface
endpoint ganha um security group próprio, que admite HTTPS, a porta 443, a partir do grupo da
função: o SDK fala com o endpoint por HTTPS, e na AWS um endpoint cujo grupo não admite nada não
responde nada.

```
ana@laptop:~/aws$ RT=$(aws ec2 describe-route-tables --filters Name=vpc-id,Values=$VPC --query "RouteTables[0].RouteTableId" --output text)
ana@laptop:~/aws$ aws ec2 create-vpc-endpoint --vpc-id $VPC --vpc-endpoint-type Gateway --service-name com.amazonaws.sa-east-1.s3 --route-table-ids $RT --query "VpcEndpoint.{Id: VpcEndpointId, Type: VpcEndpointType, State: State}"
{
    "Id": "vpce-1020c426d8afd2870",
    "Type": "Gateway",
    "State": "available"
}
ana@laptop:~/aws$ EP=$(aws ec2 create-security-group --vpc-id $VPC --group-name orders-endpoints --description "the endpoints" --query GroupId --output text)
ana@laptop:~/aws$ aws ec2 authorize-security-group-ingress --group-id $EP --protocol tcp --port 443 --source-group $FN --query "SecurityGroupRules[].{Port: FromPort, From: ReferencedGroupInfo.GroupId}"
[
    {
        "Port": 443,
        "From": "sg-3e0f3ea4cf6cf0f8a"
    }
]
ana@laptop:~/aws$ aws ec2 create-vpc-endpoint --vpc-id $VPC --vpc-endpoint-type Interface --service-name com.amazonaws.sa-east-1.secretsmanager --subnet-ids $A $B --security-group-ids $EP --query "VpcEndpoint.{Id: VpcEndpointId, Type: VpcEndpointType, Interfaces: NetworkInterfaceIds}"
{
    "Id": "vpce-c1d15a50458422a04",
    "Type": "Interface",
    "Interfaces": [
        "eni-d8d8e16d0c205af12",
        "eni-3b1b17dee817d5abd"
    ]
}
ana@laptop:~/aws$ aws ec2 describe-route-tables --route-table-ids $RT --query "RouteTables[0].Routes[].[DestinationCidrBlock || DestinationPrefixListId, GatewayId]" --output text
10.0.0.0/16	local
pl-fe6f0c1379a3c5867	vpce-1020c426d8afd2870
ana@laptop:~/aws$ aws ec2 describe-network-interfaces --query "NetworkInterfaces[].[NetworkInterfaceId, SubnetId]" --output text
eni-d8d8e16d0c205af12	subnet-dfadb89736d4aa1a9
eni-3b1b17dee817d5abd	subnet-2703629957a6494c1
```

O gateway endpoint aparece na tabela de rotas como uma rota para uma prefix list, `pl-` e um id, que
é o conjunto de endereços do S3 na região, apontando para o endpoint. O interface endpoint fez duas
interfaces de rede, uma em cada subnet, e elas são as duas linhas da última listagem. **Essas são as
únicas interfaces da conta**: a função, cujas interfaces Hyperplane a AWS teria posto nas mesmas
subnets, não tem nenhuma no moto, como a seção anterior mostrou.

## Escolhendo entre elas

A conta decide a maioria dos casos, e o formato dela é curto:

- uma função que só fala com o banco de dados não precisa de **nenhuma das duas**: nenhuma rota para
  fora é o arranjo mais barato e mais privado que existe;
- uma função que também usa o S3 ou o DynamoDB precisa de **um gateway endpoint**, que é gratuito;
- uma função que também usa dois ou três outros serviços da AWS precisa de **interface endpoints**
  para eles, cobrados por serviço e por zona;
- uma função que chama algo na internet pública, um provedor de pagamento ou um webhook, precisa de
  **um NAT gateway**, e então do gateway endpoint também, para que o tráfego do S3 não pague a
  cobrança de dados do gateway no caminho.

Um NAT gateway é compartilhado por tudo o que está na VPC, então os 135,78 USD por mês muitas vezes
já estão sendo pagos por outros motivos, e uma função que entra nessa VPC soma só os dados dela. O
erro é criar o gateway para uma função, e depois pagar a cobrança de dados dele num tráfego para o S3
que um endpoint teria levado de graça.
