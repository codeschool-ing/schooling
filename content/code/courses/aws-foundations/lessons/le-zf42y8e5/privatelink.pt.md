---
title: PrivateLink para um serviço seu
version: 1
---

**O PrivateLink deixa uma VPC oferecer um serviço a outras do jeito que a AWS oferece o STS.** O
provedor põe um Network Load Balancer na frente do serviço e o publica como um **endpoint service**,
e cada consumidor cria um interface endpoint para ele na própria VPC. O tráfego vai num sentido só,
do consumidor para o provedor, e nada mais de uma VPC é visível para a outra.

A imagem errada é que duas VPCs precisam ser ligadas para dividir um serviço. Ligá-las, com o peering
ou o Transit Gateway da lição 20, abre rotas entre intervalos inteiros nos dois sentidos, e **falha
quando os dois intervalos se sobrepõem**. O PrivateLink não liga nada: o consumidor vê uma interface
com endereço do próprio intervalo, e o provedor vê conexões chegando ao load balancer dele. Duas VPCs
que usam `10.20.0.0/16` ainda podem usar os serviços uma da outra assim.

## O serviço de estoque da loja

A aplicação da loja tem uma API interna que responde "quantos ainda restam deste item". O ambiente de
staging, na conta `shop-staging` da lição 2, precisa ler os números de estoque da produção para
testar contra dados reais, e nada mais da produção. A API roda nas máquinas da aplicação, então o load
balancer na frente dela é um Network Load Balancer **interno** nas três sub-redes app:

```
ana@laptop:~/aws$ nlb=$(aws elbv2 create-load-balancer --name stock-api --type network --scheme internal --subnets $apps --query "LoadBalancers[0].LoadBalancerArn" --output text)
ana@laptop:~/aws$ aws elbv2 describe-load-balancers --names stock-api --query "LoadBalancers[0].[Type,Scheme,length(AvailabilityZones)]" --output text
network	internal	3
```

A lição 22 trata de load balancers; aqui a única coisa que importa é que um endpoint service precisa
de um Network Load Balancer (ou de um Gateway Load Balancer, que serve a outro propósito) por trás.

## Publicando-o como endpoint service

```
ana@laptop:~/aws$ svc=$(aws ec2 create-vpc-endpoint-service-configuration --network-load-balancer-arns $nlb --acceptance-required --query ServiceConfiguration.ServiceId --output text)
ana@laptop:~/aws$ aws ec2 describe-vpc-endpoint-service-configurations --service-ids $svc --query "ServiceConfigurations[0].[ServiceName,AcceptanceRequired,length(AvailabilityZones)]" --output text
com.amazonaws.vpce.sa-east-1.vpce-svc-4fbe58fe	True	3
```

**O nome do serviço é o endereço que os consumidores pedem**, `com.amazonaws.vpce.sa-east-1.vpce-svc-…`,
da mesma família que `com.amazonaws.sa-east-1.sts`. `--acceptance-required` quer dizer que o endpoint
de cada consumidor espera até o provedor aceitá-lo, então a loja decide cada conexão, e não cada
conta.

Quem pode pedir, para começo de conversa, é o segundo controle. **Um endpoint service fica invisível
para todo mundo até um principal ser permitido**, e a loja permite exatamente um, a conta
`shop-staging`. Essa conta é criada aqui na organização do moto, como a lição 3 fez:

```
ana@laptop:~/aws$ aws organizations create-organization --feature-set ALL --query Organization.FeatureSet --output text
ALL
ana@laptop:~/aws$ staging=$(aws organizations create-account --email aws+shop-staging@example.com --account-name shop-staging --query CreateAccountStatus.AccountId --output text); echo $staging
321532293571
ana@laptop:~/aws$ aws ec2 modify-vpc-endpoint-service-permissions --service-id $svc --add-allowed-principals arn:aws:iam::$staging:root
{
    "ReturnValue": true
}
ana@laptop:~/aws$ aws ec2 describe-vpc-endpoint-service-permissions --service-id $svc --query "AllowedPrincipals[].Principal" --output text
arn:aws:iam::321532293571:root
```

## O consumidor, na outra conta

O lado do staging trabalha por um profile que assume o role de administrador da conta, como a lição 2
montou um; o profile nomeia o número de conta desta execução, então depois de reiniciar o moto ele é
definido de novo. A VPC do staging é `10.30.0.0/16`, com uma sub-rede para o teste:

```
ana@laptop:~/aws$ aws configure set profile.shop-staging.role_arn arn:aws:iam::$staging:role/OrganizationAccountAccessRole
ana@laptop:~/aws$ aws configure set profile.shop-staging.credential_source Environment
ana@laptop:~/aws$ aws configure set profile.shop-staging.role_session_name ana
ana@laptop:~/aws$ aws --profile shop-staging sts get-caller-identity --query Account --output text
321532293571
ana@laptop:~/aws$ svpc=$(aws --profile shop-staging ec2 create-vpc --cidr-block 10.30.0.0/16 --query Vpc.VpcId --output text)
ana@laptop:~/aws$ ssub=$(aws --profile shop-staging ec2 create-subnet --vpc-id $svpc --cidr-block 10.30.48.0/20 --availability-zone sa-east-1a --query Subnet.SubnetId --output text)
ana@laptop:~/aws$ aws --profile shop-staging ec2 create-vpc-endpoint --vpc-id $svpc --vpc-endpoint-type Interface --service-name com.amazonaws.vpce.sa-east-1.$svc --subnet-ids $ssub --query "VpcEndpoint.[VpcEndpointId,State,OwnerId]" --output text
vpce-d2da24b6a04de105b	available	321532293571
```

**Na AWS esse endpoint agora estaria `pendingAcceptance`**, e não carregaria tráfego nenhum até a
loja rodar `accept-vpc-endpoint-connections` para ele. O moto o cria `available` na hora, e responde
tanto ao `describe-vpc-endpoint-connections` quanto ao `accept-vpc-endpoint-connections` com um erro
interno, então o aceite não foi executado aqui. Depois de aceito, as máquinas do staging alcançariam
a API de estoque na interface do endpoint na própria sub-rede, com um endereço de `10.30.0.0/16`. A
produção veria as conexões chegarem dos endereços privados do próprio load balancer, nunca dos do
staging, e é por isso que os dois intervalos podem se sobrepor à vontade.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"l19-privatelink\" aria-label=\"PrivateLink entre duas contas. À esquerda, a conta shop-staging com a VPC 10.30.0.0/16, uma máquina de teste e um interface endpoint numa das sub-redes. À direita, a conta shop-prod com a VPC 10.20.0.0/16, o Network Load Balancer interno stock-api nas sub-redes app, e as máquinas da aplicação atrás dele. Uma seta vai do interface endpoint ao load balancer: PrivateLink, num sentido só, aceito pelo provedor. Entre as duas VPCs não há rota, então os intervalos poderiam até se sobrepor.\"><defs><marker id=\"l19-privatelink-af-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20.0\" y=\"30.0\" width=\"300.0\" height=\"250.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"36.0\" y=\"48.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">shop-staging</text><rect x=\"36.0\" y=\"62.0\" width=\"268.0\" height=\"202.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper)\" stroke-width=\"1.2\"></rect><text x=\"50.0\" y=\"80.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">VPC 10.30.0.0/16</text><rect x=\"50.0\" y=\"94.0\" width=\"240.0\" height=\"156.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"400.0\" y=\"30.0\" width=\"300.0\" height=\"250.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"416.0\" y=\"48.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">shop-prod</text><rect x=\"416.0\" y=\"62.0\" width=\"268.0\" height=\"202.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper)\" stroke-width=\"1.2\"></rect><text x=\"430.0\" y=\"80.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">VPC 10.20.0.0/16</text><rect x=\"430.0\" y=\"94.0\" width=\"240.0\" height=\"156.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"52.0\" y=\"112.0\" width=\"110.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"107.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">máquina de teste</text><rect x=\"170.0\" y=\"176.0\" width=\"110.0\" height=\"48.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"225.0\" y=\"193.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">interface</text><text x=\"225.0\" y=\"206.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">endpoint</text><path d=\"M140.0 154.0 L140.0 200.0 L166.0 200.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l19-privatelink-af-ah-phosphor)\"></path><rect x=\"444.0\" y=\"176.0\" width=\"110.0\" height=\"48.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"499.0\" y=\"193.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">stock-api</text><text x=\"499.0\" y=\"206.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">(NLB interno)</text><rect x=\"566.0\" y=\"112.0\" width=\"96.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"614.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">máquinas da app</text><path d=\"M556.0 192.0 L604.0 192.0 L604.0 156.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l19-privatelink-af-ah-phosphor)\"></path><path d=\"M282.0 200.0 L290.0 200.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M290.0 200.0 L304.0 200.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M304.0 200.0 L320.0 200.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M320.0 200.0 L400.0 200.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M400.0 200.0 L416.0 200.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M416.0 200.0 L430.0 200.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M430.0 200.0 L440.0 200.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#l19-privatelink-af-ah-phosphor)\"></path><text x=\"360.0\" y=\"186.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">PrivateLink</text><text x=\"360.0\" y=\"216.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">num sentido só</text><text x=\"360.0\" y=\"300.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">nenhuma rota entre 10.30.0.0/16 e 10.20.0.0/16: os intervalos poderiam se sobrepor</text><text x=\"360.0\" y=\"318.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">aceite obrigatório; principal permitido: shop-staging</text></svg>", "caption": "O consumidor vê uma interface na própria sub-rede; o provedor vê conexões no load balancer dele. Nada mais de uma VPC é visível para a outra.", "same": ["PrivateLink", "endpoint", "interface", "stock-api"]}
```

**Quem paga o quê segue as peças.** O consumidor paga pelo interface endpoint dele, os 0,021 por hora
por zona e 0,01 por gigabyte da seção anterior. O provedor paga pelo Network Load Balancer dele, que a
lição 22 precifica. Nenhum dos dois paga NAT gateway nem dados mandados para a internet, porque nada
foi para lá.

## Quando usar qual

| você quer | use |
|---|---|
| uma rota privada até o S3 ou o DynamoDB | um gateway endpoint: grátis, uma linha numa tabela de rotas |
| um caminho privado até outro serviço da AWS | um interface endpoint: uma interface por zona, por hora e por gigabyte |
| oferecer um serviço seu a outras VPCs ou contas, num sentido só | PrivateLink: um endpoint service atrás de um Network Load Balancer |
| duas VPCs cujas máquinas conversam livremente | peering ou Transit Gateway, lição 20 |

A última linha é a que esta lição não faz. Quando duas redes precisam alcançar muitas coisas uma na
outra, endpoint por endpoint é a ferramenta errada, e a lição 20 liga os próprios intervalos.
