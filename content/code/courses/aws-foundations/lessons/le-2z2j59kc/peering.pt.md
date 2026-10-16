---
title: VPC peering, um par de cada vez
version: 1
---

**Uma conexão de peering liga exatamente duas VPCs, para que cada uma possa rotear para o intervalo
da outra como se fosse vizinha.** Nada fica no meio: não há gateway para dimensionar, nem cobrança
por hora, nem um ponto único de falha. O preço dessa simplicidade são três regras, e cada uma delas
pega alguém. **Os dois intervalos não podem se sobrepor, os dois lados precisam de rotas, e nada
passa através.**

A imagem errada é uma conexão de peering como um cabo entre duas redes que então viram uma só. Elas
não viram uma só. Um peering é um par, e **ele não é transitivo**. Se a produção tem peering com o
staging e com a cópia de recuperação de desastre, o staging continua sem alcançar a cópia através da
produção. Cada par que precisa conversar precisa do seu próprio peering.

## Partindo da lição 17

Reinicie o moto no primeiro terminal (Ctrl+C, depois `moto_server -p 4567`) para que esta lição
comece de uma AWS vazia, e reconstrua as lições 16 e 17. Os filtros da lição 18 e os endpoints da
lição 19 não entram no roteamento, então ficam de fora:

```
ana@laptop:~/aws$ bash net/16-vpc.sh > /dev/null && bash net/17-routes.sh > /dev/null
ana@laptop:~/aws$ vpc=$(aws ec2 describe-vpcs --filters Name=tag:Name,Values=shop-prod --query "Vpcs[0].VpcId" --output text)
ana@laptop:~/aws$ rts=$(aws ec2 describe-route-tables --filters Name=tag:Name,Values=private-a,private-b,private-c --query "RouteTables[].RouteTableId" --output text)
ana@laptop:~/aws$ svpc=$(aws ec2 create-vpc --cidr-block 10.30.0.0/16 --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=shop-staging},{Key=env,Value=staging}]' --query Vpc.VpcId --output text)
ana@laptop:~/aws$ ssub=$(aws ec2 create-subnet --vpc-id $svpc --cidr-block 10.30.48.0/20 --availability-zone sa-east-1a --query Subnet.SubnetId --output text)
ana@laptop:~/aws$ echo $vpc $svpc
vpc-4d9b138dab1e13c0a vpc-17bcf95982f6b62d7
```

O outro lado é a VPC do staging, `10.30.0.0/16`. **Na AWS ela mora na conta `shop-staging`**. O
laboratório põe as duas VPCs na conta padrão do moto, o que muda os comandos em uma opção e o
raciocínio em nada. Um peering entre contas nomeia a outra conta com `--peer-owner-id`, e a outra
conta o aceita com as próprias credenciais. Essa variante não foi executada aqui.

## Intervalos sobrepostos

A lição 16 prometeu isto. Uma cópia do intervalo da produção, feita do jeito que alguém faria uma
VPC de teste rápida copiando um comando, pede peering com a produção:

```
ana@laptop:~/aws$ copy=$(aws ec2 create-vpc --cidr-block 10.20.0.0/16 --query Vpc.VpcId --output text)
ana@laptop:~/aws$ bad=$(aws ec2 create-vpc-peering-connection --vpc-id $vpc --peer-vpc-id $copy --query VpcPeeringConnection.VpcPeeringConnectionId --output text)
ana@laptop:~/aws$ aws ec2 describe-vpc-peering-connections --vpc-peering-connection-ids $bad --query "VpcPeeringConnections[0].[Status.Code,RequesterVpcInfo.CidrBlock,AccepterVpcInfo.CidrBlock]" --output text
pending-acceptance	10.20.0.0/16	10.20.0.0/16
ana@laptop:~/aws$ aws ec2 delete-vpc-peering-connection --vpc-peering-connection-id $bad --query Return && aws ec2 delete-vpc --vpc-id $copy
true
```

**O moto aceitou o pedido**, e o estado dele diz que está a caminho. A AWS recusa um peering entre
VPCs cujos intervalos se sobrepõem, e nenhuma outra resposta faria sentido. Um endereço em
`10.20.0.0/16` estaria nas duas, e nenhuma tabela de rotas saberia dizer para qual delas um pacote
vai. Essa recusa não foi executada aqui, e a cópia é apagada. É por isso que a lição 16 escolheu
cada intervalo contra toda outra rede que a loja tem. É também por isso que seis VPCs padrão, todas
`172.31.0.0/16`, nunca podem ter peering entre si.

## Pedido, aceite, e as rotas dos dois lados

```
ana@laptop:~/aws$ pcx=$(aws ec2 create-vpc-peering-connection --vpc-id $vpc --peer-vpc-id $svpc --tag-specifications 'ResourceType=vpc-peering-connection,Tags=[{Key=Name,Value=prod-staging}]' --query VpcPeeringConnection.VpcPeeringConnectionId --output text)
ana@laptop:~/aws$ aws ec2 describe-vpc-peering-connections --vpc-peering-connection-ids $pcx --query "VpcPeeringConnections[0].Status.Code" --output text
pending-acceptance
ana@laptop:~/aws$ aws ec2 accept-vpc-peering-connection --vpc-peering-connection-id $pcx --query VpcPeeringConnection.Status.Code --output text
active
ana@laptop:~/aws$ for r in $rts; do aws ec2 create-route --route-table-id $r --destination-cidr-block 10.30.0.0/16 --vpc-peering-connection-id $pcx --query Return --output text; done
True
True
True
ana@laptop:~/aws$ srt=$(aws ec2 describe-route-tables --filters Name=vpc-id,Values=$svpc --query "RouteTables[0].RouteTableId" --output text)
ana@laptop:~/aws$ aws ec2 create-route --route-table-id $srt --destination-cidr-block 10.20.0.0/16 --vpc-peering-connection-id $pcx --query Return --output text
True
ana@laptop:~/aws$ aws ec2 describe-route-tables --filters Name=tag:Name,Values=private-a --query "RouteTables[0].Routes[].[DestinationCidrBlock,GatewayId || NatGatewayId || VpcPeeringConnectionId]" --output text
10.20.0.0/16	local
0.0.0.0/0	nat-99abbf31f5912eafc
10.30.0.0/16	pcx-d070c3104627acba3
```

**Um peering é pedido por um lado e aceito pelo outro**, o que importa entre contas: o dono de cada
VPC concorda. Depois que ele fica `active`, nada mudou ainda para pacote nenhum, porque nenhuma
tabela o nomeia. Os últimos comandos da transcrição dão às três tabelas privadas da produção uma rota
para o intervalo do staging, e à tabela principal do staging uma para o da produção.

A regra do prefixo mais longo da lição 17 faz o resto. Um pacote de `app-a` para `10.30.48.10` casa
com `10.30.0.0/16` e com `0.0.0.0/0`, e o `/16` o manda para o peering. **Esquecer um dos lados é o
defeito clássico**: o pacote chega, e a resposta não tem rota de volta. Os security groups dos dois
lados continuam valendo. Os grupos da lição 18 nomeavam uns aos outros, e um grupo também pode se
referir a um grupo de uma VPC com peering na mesma região.

## Entre regiões

A loja mantém uma cópia de recuperação de desastre na Virgínia, `10.40.0.0/16` em `us-east-1`. Um
peering pode atravessar regiões. O pedido nomeia a outra região, e o aceite é feito lá:

```
ana@laptop:~/aws$ dr=$(aws ec2 create-vpc --region us-east-1 --cidr-block 10.40.0.0/16 --query Vpc.VpcId --output text)
ana@laptop:~/aws$ xpcx=$(aws ec2 create-vpc-peering-connection --vpc-id $vpc --peer-vpc-id $dr --peer-region us-east-1 --query VpcPeeringConnection.VpcPeeringConnectionId --output text)
ana@laptop:~/aws$ aws ec2 describe-vpc-peering-connections --region us-east-1 --vpc-peering-connection-ids $xpcx --query "VpcPeeringConnections[0].[Status.Code,RequesterVpcInfo.Region,AccepterVpcInfo.Region]" --output text
pending-acceptance	sa-east-1	us-east-1
ana@laptop:~/aws$ aws ec2 accept-vpc-peering-connection --region us-east-1 --vpc-peering-connection-id $xpcx --query VpcPeeringConnection.Status.Code --output text
active
```

O tráfego entre as duas é cobrado como **tráfego entre regiões**, os 0,138 por gigabyte saindo de São
Paulo que a lição 1 leu, e 0,02 no outro sentido.

## Não transitivo

A produção agora tem peering com o staging e com a Virgínia. A tabela do staging poderia receber uma
rota para `10.40.0.0/16` apontando para o peering da produção, e o pacote ainda seria descartado. **Um
peering só carrega tráfego entre as suas duas VPCs**, nunca tráfego a caminho de uma terceira. A
figura é a regra inteira.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"l20-not-transitive\" aria-label=\"Três VPCs. Em cima, shop-prod, 10.20.0.0/16 em sa-east-1. Embaixo à esquerda, shop-staging, 10.30.0.0/16 em sa-east-1; embaixo à direita, a cópia de recuperação de desastre, 10.40.0.0/16 em us-east-1. A produção tem peering com o staging e, entre regiões, com a cópia. Entre o staging e a cópia não há peering, e um pacote de um para o outro não passa pela produção: um peering só carrega tráfego entre as suas duas VPCs.\"><rect x=\"260.0\" y=\"30.0\" width=\"200.0\" height=\"64.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"48.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">shop-prod</text><text x=\"360.0\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">10.20.0.0/16</text><text x=\"360.0\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">sa-east-1</text><rect x=\"40.0\" y=\"210.0\" width=\"200.0\" height=\"64.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.4\"></rect><text x=\"140.0\" y=\"228.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">shop-staging</text><text x=\"140.0\" y=\"246.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">10.30.0.0/16</text><text x=\"140.0\" y=\"262.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">sa-east-1</text><rect x=\"480.0\" y=\"210.0\" width=\"200.0\" height=\"64.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.4\"></rect><text x=\"580.0\" y=\"228.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">cópia dr</text><text x=\"580.0\" y=\"246.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">10.40.0.0/16</text><text x=\"580.0\" y=\"262.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">us-east-1</text><path d=\"M280.0 96.0 L160.0 208.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.8\" fill=\"none\"></path><text x=\"168.0\" y=\"140.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">peering</text><path d=\"M440.0 96.0 L560.0 208.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.8\" fill=\"none\"></path><text x=\"552.0\" y=\"140.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">peering, entre regiões</text><path d=\"M242.0 242.0 L478.0 242.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"6 5\"></path><text x=\"360.0\" y=\"230.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">sem caminho</text><text x=\"360.0\" y=\"258.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">nem passando pela produção</text><text x=\"360.0\" y=\"312.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">cada par que precisa conversar precisa de um peering próprio</text></svg>", "caption": "Um peering é um par. Dois deles que dividem uma VPC não fazem um caminho entre as outras duas.", "same": ["peering"]}
```

O moto não transporta pacote nenhum, então isto, como todo caminho destas lições, é lido da
configuração e do comportamento documentado da AWS, e não visto.
