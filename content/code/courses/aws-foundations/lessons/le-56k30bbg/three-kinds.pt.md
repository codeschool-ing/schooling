---
title: Três balanceadores, três camadas
version: 1
---

**O Elastic Load Balancing são três produtos sob uma API**, e a diferença entre eles é quanto do
tráfego cada um lê. O balanceador **application** lê cada requisição HTTP. O **network** lê só
endereços e portas. O **gateway** quase não lê nada e repassa pacotes inteiros a uma fileira de
appliances. A imagem errada é um único balanceador com algumas opções, em que você escolhe a mais
barata. Eles respondem a perguntas diferentes, e a pergunta vem primeiro: o que a coisa na frente
das máquinas precisa saber?

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 380\" role=\"img\" data-fig=\"l22-three-kinds\" aria-label=\"Os três balanceadores lado a lado. À esquerda, o application load balancer, camada 7: ele lê o host, o caminho e os cabeçalhos de cada requisição, e manda /api/* para o grupo de alvos shop-api e todo o resto para shop-web-app. No meio, o network load balancer, camada 4: ele repassa conexões TCP, UDP e TLS a partir de um endereço fixo por zona para um grupo de alvos, e o alvo vê o endereço do próprio chamador. À direita, o gateway load balancer, camada 3: o tráfego que entra na VPC vai para um endpoint de GWLB, o gateway load balancer manda cada pacote embrulhado em GENEVE na porta 6081 para um appliance de firewall, e o recebe de volta para seguir ao destino.\"><defs><marker id=\"l22-three-kinds-af-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l22-three-kinds-af-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l22-three-kinds-af-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20.0\" y=\"20.0\" width=\"200.0\" height=\"34.0\" rx=\"17\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"120.0\" y=\"37.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">um cliente, por HTTPS</text><rect x=\"20.0\" y=\"92.0\" width=\"200.0\" height=\"66.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"120.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">application</text><text x=\"120.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">camada 7</text><text x=\"120.0\" y=\"145.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">lê host, caminho, cabeçalhos</text><rect x=\"260.0\" y=\"20.0\" width=\"200.0\" height=\"34.0\" rx=\"17\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"37.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o terminal de um parceiro, TCP puro</text><rect x=\"260.0\" y=\"92.0\" width=\"200.0\" height=\"66.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">network</text><text x=\"360.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">camada 4</text><text x=\"360.0\" y=\"145.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">lê endereços e portas</text><rect x=\"500.0\" y=\"20.0\" width=\"200.0\" height=\"34.0\" rx=\"17\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"37.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o tráfego que entra na VPC</text><rect x=\"500.0\" y=\"92.0\" width=\"200.0\" height=\"66.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"600.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">gateway</text><text x=\"600.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">camada 3</text><text x=\"600.0\" y=\"145.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">não lê nada, todas as portas</text><path d=\"M120.0 56.0 L120.0 88.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l22-three-kinds-af-ah-paper-dim)\"></path><rect x=\"25.0\" y=\"230.0\" width=\"90.0\" height=\"56.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"70.0\" y=\"250.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">shop-api</text><text x=\"70.0\" y=\"268.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">grupo de alvos</text><rect x=\"125.0\" y=\"230.0\" width=\"110.0\" height=\"56.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"180.0\" y=\"250.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">shop-web-app</text><text x=\"180.0\" y=\"268.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">grupo de alvos</text><path d=\"M95.0 160.0 L72.0 226.0\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l22-three-kinds-af-ah-amber)\"></path><path d=\"M145.0 160.0 L176.0 226.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l22-three-kinds-af-ah-phosphor)\"></path><text x=\"60.0\" y=\"190.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">/api/*</text><text x=\"170.0\" y=\"190.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">padrão</text><text x=\"120.0\" y=\"312.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">regras escolhem o grupo</text><path d=\"M360.0 56.0 L360.0 88.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l22-three-kinds-af-ah-paper-dim)\"></path><text x=\"372.0\" y=\"74.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">um IP fixo por zona</text><rect x=\"300.0\" y=\"230.0\" width=\"120.0\" height=\"56.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"250.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">shop-tcp</text><text x=\"360.0\" y=\"268.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">grupo de alvos</text><path d=\"M360.0 160.0 L360.0 226.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l22-three-kinds-af-ah-phosphor)\"></path><text x=\"360.0\" y=\"312.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">o alvo vê o IP de quem chamou</text><rect x=\"520.0\" y=\"64.0\" width=\"160.0\" height=\"22.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"600.0\" y=\"75.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">endpoint de GWLB</text><path d=\"M600.0 56.0 L600.0 62.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M600.0 87.0 L600.0 89.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l22-three-kinds-af-ah-paper-dim)\"></path><rect x=\"540.0\" y=\"230.0\" width=\"120.0\" height=\"56.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"250.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">firewall</text><text x=\"600.0\" y=\"268.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">appliances</text><path d=\"M580.0 160.0 L580.0 226.0\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l22-three-kinds-af-ah-amber)\"></path><path d=\"M620.0 226.0 L620.0 160.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l22-three-kinds-af-ah-phosphor)\"></path><text x=\"574.0\" y=\"194.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--amber)\">GENEVE</text><text x=\"574.0\" y=\"207.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--amber)\">6081</text><text x=\"628.0\" y=\"194.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">volta</text><text x=\"600.0\" y=\"312.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">depois segue ao destino</text><text x=\"360.0\" y=\"340.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">quanto mais um balanceador lê, mais ele pode decidir</text><text x=\"360.0\" y=\"362.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">e mais da requisição ele tem de entender</text></svg>", "caption": "Três produtos sob uma API. A pergunta é quanto do tráfego a coisa na frente das máquinas precisa ler.", "same": ["appliances", "application", "firewall", "gateway", "network"]}
```

| | application (ALB) | network (NLB) | gateway (GWLB) |
|---|---|---|---|
| lê | HTTP e HTTPS: host, caminho, cabeçalhos, método | conexões TCP, UDP e TLS | pacotes IP, todas as portas |
| manda para | grupos de alvos escolhidos por regras | um grupo de alvos por listener | uma frota de appliances, e de volta |
| o endereço dele | um nome, cujos endereços mudam | um endereço fixo por zona, um Elastic IP se você quiser | um endpoint em cada VPC que ele atende |
| o alvo vê | o endereço do balanceador, com o de quem chamou em `X-Forwarded-For` | o endereço do próprio chamador | o pacote original, embrulhado em GENEVE |
| para a loja | a loja web e a API | um terminal de pagamento falando TCP puro | um firewall inspecionando tudo o que entra |

Um quarto, o balanceador **Classic**, ainda existe e ainda responde pela própria API, `elb`. Ele é a
geração anterior, a AWS pede que projetos novos não o usem, e este curso não usa.

## Começando de uma AWS vazia

Reinicie o moto no primeiro terminal (Ctrl+C, depois `moto_server -p 4567`) para que esta lição
comece de uma AWS vazia. A lição 16 constrói a VPC da loja com sub-redes públicas e privadas em três
zonas. Esta lição precisa de duas sub-redes em duas zonas, um grupo de segurança para o balanceador
e duas máquinas para onde mandar tráfego. A imagem das máquinas é buscada do jeito que a AWS
documenta, num parâmetro público que sempre nomeia o Amazon Linux mais recente:

```sh
vpc=$(aws ec2 create-vpc --cidr-block 10.20.0.0/16 --query Vpc.VpcId --output text)
a=$(aws ec2 create-subnet --vpc-id "$vpc" --cidr-block 10.20.0.0/24 \
  --availability-zone sa-east-1a --query Subnet.SubnetId --output text)
b=$(aws ec2 create-subnet --vpc-id "$vpc" --cidr-block 10.20.1.0/24 \
  --availability-zone sa-east-1b --query Subnet.SubnetId --output text)
sg=$(aws ec2 create-security-group --group-name shop-web-lb --vpc-id "$vpc" \
  --description "the web load balancer" --query GroupId --output text)
ami=$(aws ssm get-parameter --query Parameter.Value --output text \
  --name /aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64)
web1=$(aws ec2 run-instances --image-id "$ami" --instance-type t3.micro \
  --subnet-id "$a" --query "Instances[0].InstanceId" --output text)
web2=$(aws ec2 run-instances --image-id "$ami" --instance-type t3.micro \
  --subnet-id "$b" --query "Instances[0].InstanceId" --output text)
```

Não imprime nada, e deixa sete variáveis do shell neste terminal, que os comandos abaixo leem.

## O application load balancer

```
ana@laptop:~/aws$ aws elbv2 create-load-balancer --name shop-web --type application --scheme internet-facing --subnets $a $b --security-groups $sg --query "LoadBalancers[0].[Type,Scheme,DNSName,State.Code]" --output text
application	internet-facing	shop-web-1.sa-east-1.elb.amazonaws.com	provisioning
```

**A resposta é um nome, não um endereço.** `shop-web-1.sa-east-1.elb.amazonaws.com` é o que os
clientes recebem, e a lição 21 apontou o ápice da loja exatamente para esse nome com um alias. Na
AWS, os endereços por trás do nome mudam conforme o balanceador cresce e encolhe, e é por isso que
nada deve ser configurado com um deles. **`internet-facing`** dá a ele endereços públicos.
`internal` daria só privados, para um balanceador entre duas camadas das máquinas da própria loja.
Ele começa `provisioning`, e na AWS vira `active` alguns minutos depois. O moto fica onde começou,
já que nada está sendo construído.

Um ALB tem de ficar em **pelo menos duas zonas**, para que perder uma zona o deixe respondendo. A AWS
recusa uma sub-rede só. O moto 5.2.3 aceitou uma quando isso foi tentado, que é o padrão deste curso:
o moto guarda o que recebe e verifica menos que a AWS.

## O network load balancer

Um NLB é escolhido quando o protocolo não é HTTP, quando cada milissegundo conta, ou quando quem
chama precisa de **um endereço que nunca muda**. Um parceiro cujo firewall libera o tráfego da loja
pelo endereço é um desses casos. Cada zona ganha um endereço fixo, e num NLB voltado para a internet
ele pode ser um Elastic IP que a loja já tem. Aloque dois, um por zona:

```
ana@laptop:~/aws$ e1=$(aws ec2 allocate-address --domain vpc --query AllocationId --output text)
ana@laptop:~/aws$ e2=$(aws ec2 allocate-address --domain vpc --query AllocationId --output text)
```

```
ana@laptop:~/aws$ aws elbv2 create-load-balancer --name shop-tcp --type network --scheme internet-facing --subnet-mappings SubnetId=$a,AllocationId=$e1 SubnetId=$b,AllocationId=$e2 --query "LoadBalancers[0].AvailabilityZones"
[
    {
        "ZoneName": "sa-east-1a",
        "SubnetId": "subnet-dda1142fe1dec00ef"
    },
    {
        "ZoneName": "sa-east-1b",
        "SubnetId": "subnet-5ed24e25fb9c898bb"
    }
]
```

**Leia o que falta.** Na AWS, cada zona dessa resposta traz `LoadBalancerAddresses` com o Elastic IP
que recebeu. Esse endereço é o que o parceiro escreve no firewall dele. O moto guardou as zonas e
descartou os endereços, então esta transcrição mostra o pedido e não o resultado. A outra coisa que
um NLB faz e o moto não consegue mostrar é **manter o endereço de quem chama**. Um alvo atrás de um
NLB vê a conexão chegar do IP do próprio cliente. Um alvo atrás de um ALB vê o do ALB, e precisa ler
o cabeçalho para saber quem chamou.

## O gateway load balancer

Um GWLB serve para tráfego que tem de passar **através** de algo: um firewall, um detector de
intrusão, um equipamento que inspeciona cada pacote que entra na rede da loja. Ele escuta em todas
as portas ao mesmo tempo e manda cada pacote a um appliance embrulhado em **GENEVE**, um protocolo
de túnel na porta UDP 6081. Depois recebe o pacote de volta do appliance para seguir caminho. O
embrulho é o ponto: o pacote chega ao appliance exatamente como foi enviado, endereços e tudo, e sai
dele do mesmo jeito.

```
ana@laptop:~/aws$ aws elbv2 create-load-balancer --name shop-inspect --type gateway --subnets $a $b --query "LoadBalancers[0].[Type,DNSName]" --output text
gateway	shop-inspect-1.sa-east-1.elb.amazonaws.com
```

Os alvos dele são os appliances, num grupo de alvos que fala GENEVE:

```
ana@laptop:~/aws$ aws elbv2 create-target-group --name shop-firewalls --protocol GENEVE --port 6081 --vpc-id $vpc --query "TargetGroups[0].[Protocol,Port,HealthCheckProtocol,HealthCheckPort]" --output text
GENEVE	6081	TCP	80
```

Os appliances respondem às verificações de saúde numa porta comum, TCP 80 se nada for dito, enquanto
o tráfego em si chega na 6081. Um listener junta os dois, e ele não tem protocolo nem porta, porque
aceita tudo. Os ARNs são longos, então vão para variáveis primeiro:

```
ana@laptop:~/aws$ gwlb=$(aws elbv2 describe-load-balancers --names shop-inspect --query "LoadBalancers[0].LoadBalancerArn" --output text)
ana@laptop:~/aws$ fw=$(aws elbv2 describe-target-groups --names shop-firewalls --query "TargetGroups[0].TargetGroupArn" --output text)
ana@laptop:~/aws$ aws elbv2 create-listener --load-balancer-arn $gwlb --default-actions Type=forward,TargetGroupArn=$fw --query "Listeners[0].[Protocol,Port]" --output text
	None
```

**O tráfego chega a um GWLB por um endpoint**, não pelo nome dele. O GWLB é publicado como um
serviço de endpoint, e cada VPC cujo tráfego deve ser inspecionado ganha um **endpoint de GWLB**
próprio. Uma entrada na tabela de rotas então manda o tráfego para esse endpoint, como a lição 17
manda tráfego para um NAT gateway. O PrivateLink da lição 19 é a mesma maquinaria: um endpoint de
GWLB é mais um tipo de endpoint de VPC.

```
ana@laptop:~/aws$ aws ec2 create-vpc-endpoint-service-configuration --gateway-load-balancer-arns $gwlb --no-acceptance-required --query "ServiceConfiguration.ServiceName" --output text
com.amazonaws.vpce.sa-east-1.vpce-svc-da520fa0
```

```
ana@laptop:~/aws$ svc=$(aws ec2 describe-vpc-endpoint-service-configurations --query "ServiceConfigurations[0].ServiceName" --output text)
```

```
ana@laptop:~/aws$ aws ec2 create-vpc-endpoint --vpc-endpoint-type GatewayLoadBalancer --vpc-id $vpc --service-name $svc --subnet-ids $a --query "VpcEndpoint.[VpcEndpointId,VpcEndpointType,State]" --output text
vpce-78599abbf31f5912e	GatewayLoadBalancer	available
```

**O moto guardou tudo e não carregou pacote nenhum**, como não carrega em lugar nenhum. A rota que
manda o tráfego para o endpoint, o embrulho em GENEVE e a volta são comportamento documentado da AWS,
e não foram rodados aqui. Na prática os appliances muitas vezes moram numa conta de segurança
separada, que a lição 2 defendeu, e os endpoints de cada conta de carga de trabalho apontam para
eles.
