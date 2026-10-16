---
title: Um NAT gateway, e a leitura de para onde vai um pacote
version: 1
---

**Um NAT gateway deixa máquinas com endereços só privados abrirem conexões com a internet, e não
deixa nada da internet abrir uma conexão com elas.** Ele fica numa sub-rede pública, com um endereço
público próprio. O pacote de uma máquina privada vai até ele e sai com o endereço público do gateway
no lugar do seu. A resposta volta pelo mesmo caminho. As máquinas da aplicação da loja precisam
exatamente disso. Elas chamam um provedor de pagamentos e baixam atualizações, e ninguém de fora
deveria conseguir chamá-las.

A imagem errada é um NAT gateway como firewall. **Ele é um tradutor com uma porta de mão única.**
Ele bloqueia conexões abertas de fora porque não tem como saber para qual máquina privada elas são,
não porque inspeciona alguma coisa. Os filtros são a lição 18.

## Um endereço público, e o gateway

O endereço público de um NAT gateway é um **Elastic IP**, um endereço IPv4 alocado à conta e
mantido até ser liberado. Alocar um é um comando à parte, e o NAT gateway é criado em `public-a` com
ele:

```
ana@laptop:~/aws$ eip=$(aws ec2 allocate-address --domain vpc --tag-specifications 'ResourceType=elastic-ip,Tags=[{Key=Name,Value=nat-a}]' --query AllocationId --output text)
ana@laptop:~/aws$ nat=$(aws ec2 create-nat-gateway --subnet-id $pa --allocation-id $eip --tag-specifications 'ResourceType=natgateway,Tags=[{Key=Name,Value=nat-a}]' --query NatGateway.NatGatewayId --output text)
ana@laptop:~/aws$ aws ec2 describe-nat-gateways --nat-gateway-ids $nat --query "NatGateways[0].[NatGatewayId,State,VpcId]" --output text
nat-e507e5fbc7de6b4a9	available	vpc-4d9b138dab1e13c0a
```

**Um NAT gateway mora numa sub-rede, então numa zona.** A AWS o opera com redundância dentro dessa
zona e não além dela, e essa é toda a pergunta da próxima seção. Pô-lo numa sub-rede pública não é
enfeite. A tabela de `public-a` roteia os próprios pacotes dele para a internet, e só essa tabela
tem saída.

## A tabela de rotas privada

As sub-redes privadas da zona a ganham uma tabela cuja saída é o NAT gateway:

```
ana@laptop:~/aws$ priv=$(aws ec2 create-route-table --vpc-id $vpc --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=private-a}]' --query RouteTable.RouteTableId --output text)
ana@laptop:~/aws$ aws ec2 create-route --route-table-id $priv --destination-cidr-block 0.0.0.0/0 --nat-gateway-id $nat
{
    "Return": true
}
ana@laptop:~/aws$ for s in app-a data-a; do aws ec2 associate-route-table --route-table-id $priv --subnet-id $(aws ec2 describe-subnets --filters Name=tag:Name,Values=$s --query "Subnets[0].SubnetId" --output text) --query AssociationState.State --output text; done
associated
associated
ana@laptop:~/aws$ aws ec2 create-route --route-table-id $priv --destination-cidr-block 0.0.0.0/0 --gateway-id $igw

aws: [ERROR]: An error occurred (RouteAlreadyExists) when calling the CreateRoute operation: The route identified by 0.0.0.0/0 already exists
```

`app-a` e `data-a` ficam associadas a ela, então um pacote de qualquer uma delas para um endereço
fora da VPC vai para `nat-a`. Uma segunda rota para o mesmo destino é recusada, como mostra o último
comando: **um destino, uma rota**, no moto como na AWS.

## Vence o prefixo mais longo

O endereço de um pacote pode casar com várias rotas ao mesmo tempo. `10.20.97.10` está dentro de
`10.20.0.0/16` e dentro de `0.0.0.0/0`, porque tudo está dentro de `0.0.0.0/0`. **O roteador fica
com a rota de prefixo mais longo, a mais específica**, e a ordem em que as rotas foram escritas não
conta. Para ver isso com três rotas, a tabela ganha mais uma: o `192.168.0.0/16` do escritório,
mandado para um virtual private gateway. É a ponta da VPC numa VPN, que a lição 24 constrói direito.
Aqui ele é só um alvo.

```
ana@laptop:~/aws$ vgw=$(aws ec2 create-vpn-gateway --type ipsec.1 --query VpnGateway.VpnGatewayId --output text)
ana@laptop:~/aws$ aws ec2 attach-vpn-gateway --vpn-gateway-id $vgw --vpc-id $vpc --query VpcAttachment.State --output text
attached
ana@laptop:~/aws$ aws ec2 create-route --route-table-id $priv --destination-cidr-block 192.168.0.0/16 --gateway-id $vgw
{
    "Return": true
}
ana@laptop:~/aws$ aws ec2 describe-route-tables --route-table-ids $priv --query "RouteTables[0].Routes[].[DestinationCidrBlock,GatewayId || NatGatewayId]" --output text
10.20.0.0/16	local
0.0.0.0/0	nat-e507e5fbc7de6b4a9
192.168.0.0/16	vgw-b9be566075fd466e2
```

Lendo essa tabela para três pacotes mandados por uma máquina em `app-a`:

| pacote para | rotas que o contêm | mais longa | vai para |
|---|---|---|---|
| `10.20.97.10`, o banco de dados em `data-a` | `10.20.0.0/16`, `0.0.0.0/0` | `/16` | `local` |
| `192.168.4.20`, uma impressora no escritório | `192.168.0.0/16`, `0.0.0.0/0` | `/16` | o virtual private gateway |
| `198.51.100.7`, o provedor de pagamentos | `0.0.0.0/0` | `/0` | `nat-a` |

O terceiro pacote dá um **segundo salto**. `nat-a` fica em `public-a`, então a tabela de `public-a`
roteia o pacote que sai do gateway, e o `0.0.0.0/0` dela aponta para o internet gateway. Duas
tabelas, lidas uma depois da outra, são o caminho inteiro.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 430\" role=\"img\" data-fig=\"l17-packet-walk\" aria-label=\"Três pacotes de uma máquina em app-a, lidos contra a tabela de rotas private-a. A tabela tem quatro rotas: 10.20.0.0/16 para local, 192.168.0.0/16 para o virtual private gateway, 0.0.0.0/0 para nat-a, e ::/0 para o egress-only internet gateway. O pacote para 10.20.97.10 casa com o /16 e com o /0; o /16 é mais longo, então ele fica local e chega a data-a. O pacote para 192.168.4.20 casa com 192.168.0.0/16 e com o /0; o /16 vence e ele vai para o virtual private gateway, rumo ao escritório. O pacote para 198.51.100.7 só casa com o /0, então vai para nat-a em public-a, e ali a tabela pública manda 0.0.0.0/0 para o internet gateway e para fora, à internet.\"><defs><marker id=\"l17-packet-walk-af-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l17-packet-walk-af-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l17-packet-walk-af-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20.0\" y=\"46.0\" width=\"160.0\" height=\"56.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"100.0\" y=\"64.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">uma máquina em app-a</text><text x=\"100.0\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10.20.48.10</text><path d=\"M182.0 74.0 L236.0 74.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l17-packet-walk-af-ah-paper-dim)\"></path><rect x=\"240.0\" y=\"16.0\" width=\"300.0\" height=\"138.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"390.0\" y=\"34.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">tabela de rotas private-a</text><text x=\"262.0\" y=\"60.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">10.20.0.0/16</text><text x=\"420.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">→</text><text x=\"446.0\" y=\"60.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">local</text><text x=\"262.0\" y=\"83.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">192.168.0.0/16</text><text x=\"420.0\" y=\"83.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">→</text><text x=\"446.0\" y=\"83.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">vgw</text><text x=\"262.0\" y=\"106.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">0.0.0.0/0</text><text x=\"420.0\" y=\"106.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">→</text><text x=\"446.0\" y=\"106.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">nat-a</text><text x=\"262.0\" y=\"129.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">::/0</text><text x=\"420.0\" y=\"129.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">→</text><text x=\"446.0\" y=\"129.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">eigw</text><text x=\"630.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">lida três vezes,</text><text x=\"630.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">uma por pacote</text><text x=\"85.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper-dim)\">pacote para</text><rect x=\"20.0\" y=\"212.0\" width=\"130.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"85.0\" y=\"230.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">10.20.97.10</text><path d=\"M152.0 230.0 L241.0 230.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l17-packet-walk-af-ah-phosphor)\"></path><text x=\"197.0\" y=\"218.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">/16 vence /0</text><rect x=\"20.0\" y=\"292.0\" width=\"130.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"85.0\" y=\"310.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">192.168.4.20</text><path d=\"M152.0 310.0 L241.0 310.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l17-packet-walk-af-ah-paper-dim)\"></path><text x=\"197.0\" y=\"298.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">/16 vence /0</text><rect x=\"20.0\" y=\"372.0\" width=\"130.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"85.0\" y=\"390.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">198.51.100.7</text><path d=\"M152.0 390.0 L241.0 390.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l17-packet-walk-af-ah-amber)\"></path><text x=\"197.0\" y=\"378.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">só /0 casa</text><rect x=\"245.0\" y=\"212.0\" width=\"150.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"320.0\" y=\"230.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">local: data-a</text><rect x=\"245.0\" y=\"292.0\" width=\"150.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"320.0\" y=\"310.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">virtual private gw</text><path d=\"M397.0 310.0 L496.0 310.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l17-packet-walk-af-ah-paper-dim)\"></path><rect x=\"500.0\" y=\"292.0\" width=\"200.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"600.0\" y=\"310.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o escritório (lição 24)</text><rect x=\"245.0\" y=\"372.0\" width=\"150.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"320.0\" y=\"390.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">nat-a em public-a</text><path d=\"M397.0 390.0 L496.0 390.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l17-packet-walk-af-ah-amber)\"></path><text x=\"446.0\" y=\"378.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">public: /0 → igw</text><rect x=\"500.0\" y=\"372.0\" width=\"70.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"535.0\" y=\"390.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">igw</text><path d=\"M572.0 390.0 L606.0 390.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l17-packet-walk-af-ah-amber)\"></path><rect x=\"610.0\" y=\"372.0\" width=\"90.0\" height=\"36.0\" rx=\"16\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"655.0\" y=\"390.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">internet</text></svg>", "caption": "Vence o prefixo mais longo que contém o endereço. O terceiro pacote é roteado duas vezes: pela private-a até o NAT gateway, depois pela public-a até o internet gateway.", "same": ["internet", "local: data-a", "public: /0 → igw", "virtual private gw"]}
```

## IPv6: o egress-only internet gateway

IPv6 não precisa de tradução, já que os endereços da lição 16 já são públicos, então um NAT gateway
não tem nada a fazer por ele. O que uma sub-rede privada precisa é só da porta de mão única. **Um
egress-only internet gateway deixa conexões saírem por IPv6 e nenhuma entrar**, e não custa nada por
hora. A rota que o usa nomeia `::/0`, o todo-endereço do IPv6:

```
ana@laptop:~/aws$ eigw=$(aws ec2 create-egress-only-internet-gateway --vpc-id $vpc --query EgressOnlyInternetGateway.EgressOnlyInternetGatewayId --output text)
ana@laptop:~/aws$ aws ec2 create-route --route-table-id $priv --destination-ipv6-cidr-block ::/0 --egress-only-internet-gateway-id $eigw
{
    "Return": true
}
ana@laptop:~/aws$ aws ec2 describe-route-tables --route-table-ids $priv --query "RouteTables[0].Routes[].[DestinationCidrBlock || DestinationIpv6CidrBlock,GatewayId || NatGatewayId || EgressOnlyInternetGatewayId]" --output text
10.20.0.0/16	local
0.0.0.0/0	nat-e507e5fbc7de6b4a9
192.168.0.0/16	vgw-b9be566075fd466e2
::/0	eigw-6cc5c52ce541a0121
```

As sub-redes privadas da loja não têm endereços IPv6, então essa rota não vai carregar nada por
enquanto. Ela está aqui para que a tabela se leia como uma de pilha dupla.

## Nada se moveu

**Cada linha daquela tabela foi lida, não testada.** O moto guarda as rotas e não move pacote
nenhum, então os três percursos acima são raciocínio a partir das tabelas. A AWS os seguiria do
mesmo jeito só porque a regra é a mesma: das rotas que contêm o endereço, a de prefixo mais longo.
Na AWS, o VPC Reachability Analyzer responde "esta máquina alcança aquela, e por onde" a partir da
mesma configuração. Os VPC Flow Logs registram o que de fato se moveu. A lição 18 fala mais dos
dois, e nenhum foi executado aqui.
