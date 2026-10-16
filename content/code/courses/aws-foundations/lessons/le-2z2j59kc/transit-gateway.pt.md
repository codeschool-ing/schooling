---
title: Transit Gateway, um hub com tabelas de rotas próprias
version: 1
---

**Um Transit Gateway é um roteador regional ao qual se ligam VPCs, VPNs e links de Direct Connect, e
ele roteia entre eles.** Onde o peering é um conjunto de pares, um Transit Gateway é um hub: cada
rede se liga uma vez, e as tabelas de rotas do próprio hub decidem qual attachment alcança qual. **Ele
é transitivo por desenho**, que é justamente o que o peering se recusa a ser. Ele é cobrado por hora
para cada attachment e por gigabyte que processa.

A imagem errada é um Transit Gateway como um peering maior. Ele é um roteador com estado próprio:
**attachments, tabelas de rotas, associações e propagações**, quatro palavras que são esta seção
inteira.

## O hub

```
ana@laptop:~/aws$ tgw=$(aws ec2 create-transit-gateway --description shop-hub --options AmazonSideAsn=64512,DefaultRouteTableAssociation=enable,DefaultRouteTablePropagation=enable --tag-specifications 'ResourceType=transit-gateway,Tags=[{Key=Name,Value=shop-hub}]' --query TransitGateway.TransitGatewayId --output text)
ana@laptop:~/aws$ aws ec2 describe-transit-gateways --transit-gateway-ids $tgw --query "TransitGateways[0].[State,Options.AmazonSideAsn,Options.DefaultRouteTableAssociation,Options.DefaultRouteTablePropagation]" --output text
available	64512	enable	enable
```

O hub foi criado com **uma tabela de rotas padrão**, e as duas opções pedem que todo attachment novo
seja associado a ela e propague para ela. `AmazonSideAsn` é o número do hub no BGP, o protocolo com
que uma VPN ou um link de Direct Connect troca rotas com ele. A lição 24 o usa.

## Attachments

**Um attachment de VPC põe uma interface do hub em uma sub-rede por zona da VPC**, a mesma ideia de
um interface endpoint na lição 19. A loja liga a produção pelas três sub-redes app e o staging por
uma sub-rede própria:

```
ana@laptop:~/aws$ apps=$(aws ec2 describe-subnets --filters Name=tag:tier,Values=app --query "Subnets[].SubnetId" --output text)
ana@laptop:~/aws$ aws ec2 create-transit-gateway-vpc-attachment --transit-gateway-id $tgw --vpc-id $vpc --subnet-ids $apps --query "TransitGatewayVpcAttachment.[State,length(SubnetIds)]" --output text
available	3
ana@laptop:~/aws$ aws ec2 create-transit-gateway-vpc-attachment --transit-gateway-id $tgw --vpc-id $svpc --subnet-ids $ssub --query "TransitGatewayVpcAttachment.[State,length(SubnetIds)]" --output text
available	1
ana@laptop:~/aws$ aws ec2 describe-transit-gateway-attachments --filters Name=transit-gateway-id,Values=$tgw --query "TransitGatewayAttachments[].[TransitGatewayAttachmentId,ResourceType,ResourceId]" --output text
tgw-attach-cb9da2b6611dc8fa7	vpc	vpc-4d9b138dab1e13c0a
tgw-attach-6d31e9a35a4c177e1	vpc	vpc-17bcf95982f6b62d7
```

## Associação e propagação

Duas palavras, e elas respondem a duas perguntas diferentes:

- **Associação** decide em que tabela de rotas do hub o tráfego de um attachment é procurado. Cada
  attachment fica associado a exatamente uma.
- **Propagação** decide que tabelas do hub aprendem o intervalo de um attachment como rota. Um
  attachment pode propagar para várias, ou para nenhuma.

Com os dois padrões ligados, todo attachment fica associado à tabela padrão e propaga o intervalo da
sua VPC para ela. Então **toda VPC alcança toda outra**: o hub é uma malha completa numa tabela só.

```
ana@laptop:~/aws$ rtb=$(aws ec2 describe-transit-gateways --transit-gateway-ids $tgw --query "TransitGateways[0].Options.AssociationDefaultRouteTableId" --output text)
ana@laptop:~/aws$ aws ec2 get-transit-gateway-route-table-associations --transit-gateway-route-table-id $rtb --query "Associations[].[ResourceId,State]" --output text
vpc-4d9b138dab1e13c0a	associated
vpc-17bcf95982f6b62d7	associated
ana@laptop:~/aws$ for a in $(aws ec2 describe-transit-gateway-attachments --filters Name=transit-gateway-id,Values=$tgw --query "TransitGatewayAttachments[].TransitGatewayAttachmentId" --output text); do aws ec2 enable-transit-gateway-route-table-propagation --transit-gateway-route-table-id $rtb --transit-gateway-attachment-id $a --query Propagation.State --output text; done
enabled
enabled
ana@laptop:~/aws$ aws ec2 search-transit-gateway-routes --transit-gateway-route-table-id $rtb --filters Name=type,Values=propagated --query Routes
[]
ana@laptop:~/aws$ for a in $(aws ec2 describe-transit-gateway-attachments --filters Name=transit-gateway-id,Values=$tgw --query "TransitGatewayAttachments[].[TransitGatewayAttachmentId,ResourceId]" --output text | tr "\t" ":"); do cidr=$(aws ec2 describe-vpcs --vpc-ids ${a#*:} --query "Vpcs[0].CidrBlock" --output text); aws ec2 create-transit-gateway-route --transit-gateway-route-table-id $rtb --destination-cidr-block $cidr --transit-gateway-attachment-id ${a%:*} --query "Route.[DestinationCidrBlock,Type,State]" --output text; done
10.20.0.0/16	static	active
10.30.0.0/16	static	active
```

O moto associou os dois attachments sozinho, como a AWS faz. **A propagação é onde ele fica aquém**.
Ele não registra nada até a propagação ser ligada explicitamente. Mesmo então a busca por rotas
propagadas volta vazia, onde a AWS listaria `10.20.0.0/16` e `10.30.0.0/16` com o tipo `propagated`.
Essa resposta não foi executada aqui. A loja escreve as duas rotas como rotas **estáticas** no
lugar, que o moto guarda e que a AWS também aceita. Uma rota estática é o que se escreve quando um
intervalo precisa ser alcançado e nenhum attachment o propaga.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 360\" role=\"img\" data-fig=\"l20-hub\" aria-label=\"O Transit Gateway shop-hub no meio, com dois attachments de VPC: shop-prod, 10.20.0.0/16, pelas três sub-redes app, e shop-staging, 10.30.0.0/16, por uma sub-rede. Abaixo do hub, a tabela de rotas padrão dele, com uma rota para 10.20.0.0/16 até o attachment da produção e uma para 10.30.0.0/16 até o do staging. Associação diz em que tabela do hub o tráfego de um attachment é procurado; propagação diz que tabelas aprendem o intervalo do attachment. A tabela de rotas de cada VPC ainda precisa de uma rota apontando para o hub.\"><defs><marker id=\"l20-hub-af-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l20-hub-af-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20.0\" y=\"40.0\" width=\"200.0\" height=\"64.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.4\"></rect><text x=\"120.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">shop-prod</text><text x=\"120.0\" y=\"76.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">10.20.0.0/16</text><text x=\"120.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">3 sub-redes app</text><rect x=\"500.0\" y=\"40.0\" width=\"200.0\" height=\"64.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.4\"></rect><text x=\"600.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">shop-staging</text><text x=\"600.0\" y=\"76.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">10.30.0.0/16</text><text x=\"600.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1 sub-rede</text><rect x=\"290.0\" y=\"44.0\" width=\"140.0\" height=\"56.0\" rx=\"12\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"360.0\" y=\"64.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">shop-hub</text><text x=\"360.0\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Transit Gateway</text><path d=\"M222.0 72.0 L288.0 72.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#l20-hub-af-ah-phosphor)\" marker-start=\"url(#l20-hub-af-ah-phosphor)\"></path><path d=\"M432.0 72.0 L498.0 72.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#l20-hub-af-ah-phosphor)\" marker-start=\"url(#l20-hub-af-ah-phosphor)\"></path><text x=\"255.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">attachment</text><text x=\"465.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">attachment</text><path d=\"M360.0 102.0 L360.0 150.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l20-hub-af-ah-paper-dim)\"></path><rect x=\"200.0\" y=\"154.0\" width=\"320.0\" height=\"92.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"172.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">tabela de rotas do hub (padrão)</text><text x=\"360.0\" y=\"198.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">10.20.0.0/16  →  attach shop-prod</text><text x=\"360.0\" y=\"222.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">10.30.0.0/16  →  attach shop-staging</text><text x=\"120.0\" y=\"280.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">associação:</text><text x=\"120.0\" y=\"298.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">em que tabela o tráfego de</text><text x=\"120.0\" y=\"314.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">um attachment é procurado</text><text x=\"600.0\" y=\"280.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">propagação:</text><text x=\"600.0\" y=\"298.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">que tabelas aprendem</text><text x=\"600.0\" y=\"314.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o intervalo de um attachment</text><text x=\"360.0\" y=\"344.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--amber)\">a tabela de cada VPC ainda aponta o outro intervalo para o hub</text></svg>", "caption": "O hub roteia entre attachments, por tabelas próprias. As VPCs ainda precisam mandar os pacotes para ele.", "same": ["Transit Gateway", "attachment"]}
```

## As tabelas das próprias VPCs apontam para o hub

O hub roteia entre attachments, e as VPCs ainda precisam mandar os pacotes para ele. Isso é uma rota
na tabela de cada VPC com o hub como alvo. As tabelas privadas da produção tinham uma rota para o
intervalo do staging pelo peering. **Substituir o alvo** dela leva esse tráfego para o hub, e o
peering é então removido:

```
ana@laptop:~/aws$ for r in $rts; do aws ec2 replace-route --route-table-id $r --destination-cidr-block 10.30.0.0/16 --transit-gateway-id $tgw; done
ana@laptop:~/aws$ aws ec2 replace-route --route-table-id $srt --destination-cidr-block 10.20.0.0/16 --transit-gateway-id $tgw
ana@laptop:~/aws$ aws ec2 delete-vpc-peering-connection --vpc-peering-connection-id $pcx --query Return --output text
True
ana@laptop:~/aws$ aws ec2 describe-route-tables --filters Name=tag:Name,Values=private-a --query "RouteTables[0].Routes[].[DestinationCidrBlock,GatewayId || NatGatewayId || TransitGatewayId]" --output text
10.20.0.0/16	local
0.0.0.0/0	nat-99abbf31f5912eafc
10.30.0.0/16	tgw-7c18a17f112a84b50
```

## Mais de uma tabela: quem pode alcançar quem

A tabela padrão dá a todo mundo uma rota para todo mundo. A necessidade real da loja é mais
estreita: **o staging não pode alcançar a produção**, e os dois precisam alcançar uma VPC
compartilhada de ferramentas, um executor de CI e um coletor de logs. Isso são duas tabelas de rotas
no hub. Produção e staging ficam associados cada um a uma tabela que só tem a rota da VPC de
ferramentas. A VPC de ferramentas fica associada a uma tabela que tem as duas rotas deles. Cada um
vê o hub, e as tabelas do hub decidem que eles não se veem. **Isso é algo que o peering não consegue
expressar**, já que todo peering é tudo ou nada entre o seu par. A segunda tabela é um comando, e o
moto a cria como a AWS criaria:

```
ana@laptop:~/aws$ iso=$(aws ec2 create-transit-gateway-route-table --transit-gateway-id $tgw --tag-specifications 'ResourceType=transit-gateway-route-table,Tags=[{Key=Name,Value=isolated}]' --query TransitGatewayRouteTable.TransitGatewayRouteTableId --output text)
ana@laptop:~/aws$ aws ec2 describe-transit-gateway-route-tables --filters Name=transit-gateway-id,Values=$tgw --query "TransitGatewayRouteTables[].[TransitGatewayRouteTableId,DefaultAssociationRouteTable,Tags[?Key==\`Name\`]|[0].Value]" --output text
tgw-rtb-8d83589407cbbe367	True	None
tgw-rtb-4cf6ba861b4c25b4b	False	isolated
```

Mudar um attachment para ela é `disassociate-transit-gateway-route-table` e depois
`associate-transit-gateway-route-table`. Sem VPC de ferramentas no laboratório, a loja para na
tabela. O que ela impediria é, como sempre aqui, lido das tabelas e não visto.

## Compartilhando o hub com outra conta

Um Transit Gateway pertence a uma conta. **O AWS Resource Access Manager (RAM) o compartilha** com
outras contas da organização, que então ligam as próprias VPCs a ele:

```
ana@laptop:~/aws$ aws organizations create-organization --feature-set ALL --query Organization.FeatureSet --output text
ALL
ana@laptop:~/aws$ staging=$(aws organizations create-account --email aws+shop-staging@example.com --account-name shop-staging --query CreateAccountStatus.AccountId --output text); echo $staging
049133565432
ana@laptop:~/aws$ aws ram create-resource-share --name shop-hub --resource-arns $(aws ec2 describe-transit-gateways --transit-gateway-ids $tgw --query "TransitGateways[0].TransitGatewayArn" --output text) --principals $staging --query "resourceShare.[name,status,allowExternalPrincipals]" --output text
shop-hub	ACTIVE	True
ana@laptop:~/aws$ aws ram get-resource-share-associations --association-type PRINCIPAL --query "resourceShareAssociations[].[associatedEntity,status]" --output text
049133565432	ASSOCIATED
```

O moto registra o compartilhamento e a associação dele com a conta nova. Na AWS, a `shop-staging`
então veria o `shop-hub` no próprio `describe-transit-gateways` e criaria o attachment dela ali. O
dono do hub o aceitaria, a menos que o hub aceite attachments compartilhados sozinho
(`AutoAcceptSharedAttachments`, `disable` por padrão). Essa metade não foi executada aqui.
