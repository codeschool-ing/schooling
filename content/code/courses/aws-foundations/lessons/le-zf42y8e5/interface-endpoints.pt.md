---
title: Interface endpoints, um endereço para um serviço dentro das suas sub-redes
version: 1
---

**Um interface endpoint põe uma interface de rede com endereço privado em cada sub-rede que você
escolhe, e o serviço responde nela.** Todos os outros serviços da AWS que podem ser alcançados de
forma privada são alcançados assim: STS, Systems Manager, o registro de contêineres, CloudWatch Logs
e uns duzentos mais. A tecnologia por baixo é o **AWS PrivateLink**. A última seção desta lição a
usa para um serviço da própria loja.

Onde um gateway endpoint é uma rota, um interface endpoint é um lugar: **uma interface numa sub-rede,
com um security group nela**, como uma pequena máquina que só encaminha. Ele é cobrado por hora para
cada zona em que fica e por gigabyte que carrega, o que um gateway endpoint não é.

## DNS privado, que o torna invisível para a aplicação

A aplicação continua chamando `sts.sa-east-1.amazonaws.com`, o nome que todo SDK usa. **Com o DNS
privado ligado, esse nome resolve dentro da VPC para os endereços privados do endpoint**, e fora da
VPC para os públicos, como antes. Nada no código nem na configuração da aplicação muda. O resolvedor
da VPC dá outra resposta à mesma pergunta. Para isso funcionar **a VPC precisa de dois atributos
ligados**, `enableDnsSupport` e `enableDnsHostnames`. Uma VPC que você cria tem o primeiro e não o
segundo, como os dois primeiros comandos mostram. O terceiro liga o segundo:

```
ana@laptop:~/aws$ aws ec2 describe-vpc-attribute --vpc-id $vpc --attribute enableDnsSupport --query EnableDnsSupport.Value
true
ana@laptop:~/aws$ aws ec2 describe-vpc-attribute --vpc-id $vpc --attribute enableDnsHostnames --query EnableDnsHostnames.Value
false
ana@laptop:~/aws$ aws ec2 modify-vpc-attribute --vpc-id $vpc --enable-dns-hostnames '{"Value":true}'
```

A AWS oferece o STS por endpoint nas três zonas. O `PrivateDnsName` dele é o nome que o endpoint vai
assumir:

```
ana@laptop:~/aws$ aws ec2 describe-vpc-endpoint-services --service-names com.amazonaws.sa-east-1.sts --query "ServiceDetails[0].[ServiceType[0].ServiceType,PrivateDnsName,AvailabilityZones]"
[
    "Interface",
    "sts.sa-east-1.amazonaws.com",
    [
        "sa-east-1a",
        "sa-east-1b",
        "sa-east-1c"
    ]
]
```

## Criando um para o STS

As interfaces do endpoint precisam de um security group próprio, que deixa entrar HTTPS das máquinas
da aplicação e nada mais. É a corrente da lição 18 de novo, com um elo a mais:

```
ana@laptop:~/aws$ ep=$(aws ec2 create-security-group --vpc-id $vpc --group-name endpoints-sg --description "interface endpoints" --query GroupId --output text)
ana@laptop:~/aws$ app=$(aws ec2 describe-security-groups --filters Name=group-name,Values=app-sg --query "SecurityGroups[0].GroupId" --output text)
ana@laptop:~/aws$ aws ec2 authorize-security-group-ingress --group-id $ep --protocol tcp --port 443 --source-group $app --query "SecurityGroupRules[0].[FromPort,ReferencedGroupInfo.GroupId]" --output text
443	sg-19bff292e592ad5d8
ana@laptop:~/aws$ apps=$(aws ec2 describe-subnets --filters Name=tag:tier,Values=app --query "Subnets[].SubnetId" --output text)
ana@laptop:~/aws$ sts=$(aws ec2 create-vpc-endpoint --vpc-id $vpc --vpc-endpoint-type Interface --service-name com.amazonaws.sa-east-1.sts --subnet-ids $apps --security-group-ids $ep --private-dns-enabled --query VpcEndpoint.VpcEndpointId --output text)
ana@laptop:~/aws$ aws ec2 describe-vpc-endpoints --vpc-endpoint-ids $sts --query "VpcEndpoints[0].[State,PrivateDnsEnabled,length(NetworkInterfaceIds),DnsEntries[0].DnsName]" --output text
available	True	3	vpce-76049ed7aeedc4428-0307bbc6.com.amazonaws.sa-east-1.sts
ana@laptop:~/aws$ aws ec2 describe-network-interfaces --network-interface-ids $(aws ec2 describe-vpc-endpoints --vpc-endpoint-ids $sts --query "VpcEndpoints[0].NetworkInterfaceIds" --output text) --query "NetworkInterfaces[].AvailabilityZone" --output text
sa-east-1a	sa-east-1b	sa-east-1c
```

**Uma interface por sub-rede nomeada, então três**, uma em cada zona, para que perder uma zona perca
só a interface daquela zona. O moto escreve o nome DNS do endpoint do jeito dele. O da AWS tem a
forma `vpce-…-….sts.sa-east-1.vpce.amazonaws.com`, e com o DNS privado ligado ninguém precisa
usá-lo.

## Quanto custa

```
ana@laptop:~/aws$ python3 price.py AmazonVPC 20260917190528 sa-east-1 SAE1-VpcEndpoint-Hours SAE1-VpcEndpoint-Bytes
AmazonVPC 20260917190528, published 2026-09-17, USD
SAE1-VpcEndpoint-Hours
          0 to       Inf Hrs  0.0210
SAE1-VpcEndpoint-Bytes
          0 to 1,048,576 GB   0.0100
  1,048,576 to 5,242,880 GB   0.0060
  5,242,880 to       Inf GB   0.0040
```

Estes são os preços de 17 de setembro de 2026. **0,021 dólar por hora para cada zona em que o
endpoint fica**, e 0,01 por gigabyte no primeiro petabyte do mês. Para o endpoint do STS em três
zonas:

| | por mês |
|---|---|
| 3 zonas × 730 horas × 0,021 | 45,99 |
| cada gigabyte por ele | 0,01 |
| o mesmo gigabyte por um NAT gateway (lição 17) | 0,093 |

Então **um interface endpoint economiza 0,083 por gigabyte contra o NAT e custa 45,99 por mês para
existir**. Os NAT gateways podem ficar de qualquer jeito, porque a aplicação chama um provedor de
pagamentos. Então o endpoint se paga acima de 45,99 / 0,083 ≈ **554 GB por mês** para aquele
serviço. As chamadas ao STS são pequenas, então para o STS ele não se pagaria só no dinheiro. Para
um registro de contêineres baixando imagens o dia inteiro, muitas vezes se paga.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 400\" role=\"img\" data-fig=\"l19-three-ways\" aria-label=\"Três maneiras de uma máquina da aplicação na sub-rede privada app-a alcançar algo fora da VPC shop-prod, 10.20.0.0/16. Para o S3, o pacote casa com a prefix list do S3 na tabela de rotas e vai para o gateway endpoint: uma rota, e de graça. Para o STS, vai para o interface endpoint, uma interface de rede dentro da própria app-a: 0,021 dólar por hora por zona e 0,01 por gigabyte. Para o provedor de pagamentos na internet, casa com 0.0.0.0/0 e vai para nat-a em public-a, depois pelo internet gateway: 0,093 dólar por gigabyte e 0,093 por hora.\"><defs><marker id=\"l19-three-ways-af-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l19-three-ways-af-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"10.0\" y=\"30.0\" width=\"480.0\" height=\"350.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"6 4\"></rect><text x=\"26.0\" y=\"46.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">sa-east-1</text><rect x=\"25.0\" y=\"58.0\" width=\"450.0\" height=\"310.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper)\" stroke-width=\"1.4\"></rect><text x=\"41.0\" y=\"76.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">shop-prod  10.20.0.0/16</text><rect x=\"45.0\" y=\"90.0\" width=\"230.0\" height=\"160.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"60.0\" y=\"106.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">app-a</text><rect x=\"60.0\" y=\"120.0\" width=\"100.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"110.0\" y=\"142.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">máquina da app</text><rect x=\"150.0\" y=\"190.0\" width=\"110.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"205.0\" y=\"205.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">interface</text><text x=\"205.0\" y=\"218.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">endpoint</text><rect x=\"45.0\" y=\"270.0\" width=\"230.0\" height=\"84.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"60.0\" y=\"286.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">public-a</text><rect x=\"150.0\" y=\"300.0\" width=\"110.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"205.0\" y=\"320.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">nat-a</text><rect x=\"560.0\" y=\"108.0\" width=\"140.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"630.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">S3</text><rect x=\"560.0\" y=\"192.0\" width=\"140.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"630.0\" y=\"212.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">STS</text><rect x=\"560.0\" y=\"300.0\" width=\"140.0\" height=\"40.0\" rx=\"16\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"630.0\" y=\"320.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">provedor de pagamentos</text><path d=\"M162.0 128.0 L275.0 128.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\"></path><path d=\"M275.0 128.0 L475.0 128.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\"></path><path d=\"M475.0 128.0 L490.0 128.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\"></path><path d=\"M490.0 128.0 L556.0 128.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#l19-three-ways-af-ah-phosphor)\"></path><text x=\"375.0\" y=\"116.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">gateway endpoint: uma rota, grátis</text><path d=\"M110.0 166.0 L110.0 212.0 L146.0 212.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l19-three-ways-af-ah-phosphor)\"></path><path d=\"M262.0 212.0 L275.0 212.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M275.0 212.0 L475.0 212.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M475.0 212.0 L490.0 212.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M490.0 212.0 L556.0 212.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l19-three-ways-af-ah-phosphor)\"></path><text x=\"375.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">0,021/h por zona + 0,01/GB</text><path d=\"M80.0 166.0 L80.0 250.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M80.0 250.0 L80.0 270.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M80.0 270.0 L80.0 320.0 L146.0 320.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l19-three-ways-af-ah-amber)\"></path><path d=\"M262.0 320.0 L275.0 320.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M275.0 320.0 L475.0 320.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M475.0 320.0 L490.0 320.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M490.0 320.0 L556.0 320.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l19-three-ways-af-ah-amber)\"></path><text x=\"375.0\" y=\"308.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">NAT: 0,093/GB + 0,093/h</text><text x=\"375.0\" y=\"338.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">depois o internet gateway</text><text x=\"600.0\" y=\"380.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">ofertas VPC e EC2, setembro de 2026</text></svg>", "caption": "A mesma máquina, três destinos, três preços. Só o gateway endpoint é grátis, e só o S3 e o DynamoDB têm um.", "same": ["S3", "STS", "endpoint", "interface"]}
```

## Dispensando o NAT gateway de vez

A economia de verdade vem quando uma sub-rede não precisa de nada da internet. O banco de dados da
loja conversa com a aplicação e grava os backups no S3, e nada mais. Com o gateway endpoint da seção
anterior, **as sub-redes de dados poderiam não ter rota `0.0.0.0/0` nenhuma**: a única saída delas
seria a rota grátis para o S3. Isso tira o último caminho do banco de dados até a internet, um ganho
de segurança além de economia. É por isso que muitas VPCs dão à camada de dados uma tabela de rotas
própria em vez de dividir a da camada de aplicação, como faz o script da lição 17.

Onde uma sub-rede precisa de um punhado de serviços da AWS e de nada mais, interface endpoints para
esses serviços e um gateway endpoint para o S3 substituem o NAT gateway dessa sub-rede. Com três NAT
gateways a 214,62 por mês e alguns interface endpoints a 45,99 cada, a conta depende de quantos
serviços são necessários. A tabela da lição 17 e esta são as ferramentas para fazê-la.
