---
title: VPN Site-to-Site, dois túneis pela internet
version: 1
---

**Uma VPN Site-to-Site liga uma rede que você mantém a uma VPC por túneis cifrados atravessando a
internet pública.** Três objetos a formam. Um **customer gateway** é o registro que a AWS tem do seu
roteador. Um **virtual private gateway** (ou um Transit Gateway) é a ponta da AWS, presa à VPC. A **conexão
VPN** entre eles são sempre **dois túneis IPsec**. A imagem errada é um túnel só, como costuma ser a
VPN de um escritório até uma filial. A AWS põe as suas duas pontas dos túneis em equipamentos
diferentes e faz manutenção nelas uma de cada vez. Um projeto com um túnel só de pé cai no
calendário de manutenção da AWS.

## O escritório, e uma AWS vazia

O escritório da loja é a rede `192.168.0.0/16` atrás de um roteador, cujo endereço público é
`203.0.113.12`. O roteador fala **BGP**, o protocolo de roteamento com que as redes contam umas às
outras quais endereços alcançam, como o número de AS privado `65000`. Reinicie o moto no primeiro
terminal (Ctrl+C, depois `moto_server -p 4567`) para que esta lição comece de uma AWS vazia. Depois
crie a parte da VPC da loja de que esta lição precisa, uma sub-rede e a tabela de rotas dela:

```sh
vpc=$(aws ec2 create-vpc --cidr-block 10.20.0.0/16 --query Vpc.VpcId --output text)
subnet=$(aws ec2 create-subnet --vpc-id "$vpc" --cidr-block 10.20.10.0/24 \
  --availability-zone sa-east-1a --query Subnet.SubnetId --output text)
rt=$(aws ec2 create-route-table --vpc-id "$vpc" --query RouteTable.RouteTableId --output text)
aws ec2 associate-route-table --route-table-id "$rt" --subnet-id "$subnet" > /dev/null
```

**Nada do lado do escritório foi rodado.** Não há roteador neste laboratório, então tudo o que o
roteador faz, negociar os túneis, falar BGP, mandar pacotes, é descrito pela documentação da AWS.

## O customer gateway

```
ana@laptop:~/aws$ aws ec2 create-customer-gateway --type ipsec.1 --public-ip 203.0.113.12 --bgp-asn 65000 --device-name office-router
{
    "CustomerGateway": {
        "Tags": [],
        "CustomerGatewayId": "cgw-d87f294afcc3f525a",
        "State": "available",
        "Type": "ipsec.1",
        "IpAddress": "203.0.113.12",
        "BgpAsn": "65000"
    }
}
```

**Um customer gateway é uma descrição, não um equipamento.** Ele diz à AWS onde vai estar a outra
ponta dos túneis e com que número de AS ela vai falar BGP. Criá-lo não alcança nada, e é por isso que
ele fica `available` na hora, na AWS tanto quanto no moto.

```
ana@laptop:~/aws$ cgw=$(aws ec2 describe-customer-gateways --query "CustomerGateways[0].CustomerGatewayId" --output text)
```

## A ponta da AWS: um virtual private gateway

O **virtual private gateway** é a porta da VPC para VPN e para Direct Connect. Ele tem um número de
AS próprio do lado da AWS, `64512` aqui, a menos que você escolha outro:

```
ana@laptop:~/aws$ aws ec2 create-vpn-gateway --type ipsec.1 --amazon-side-asn 64512 --query "VpnGateway.[VpnGatewayId,AmazonSideAsn,State]" --output text
vgw-20474c8c293a43205	64512	available
```

Depois ele é preso à VPC, que é o que o faz ser da VPC:

```
ana@laptop:~/aws$ vgw=$(aws ec2 describe-vpn-gateways --query "VpnGateways[0].VpnGatewayId" --output text)
ana@laptop:~/aws$ aws ec2 attach-vpn-gateway --vpn-gateway-id $vgw --vpc-id $vpc
{
    "VpcAttachment": {
        "VpcId": "vpc-e1a208744d0ad63a7",
        "State": "attached"
    }
}
```

Na AWS a associação passa por `attaching` antes de ficar `attached`. O moto pula direto para o fim.
Uma VPC aceita um virtual private gateway por vez. **Um Transit Gateway é a ponta alternativa**, que
a lição 20 constrói. A VPN se prende ao Transit Gateway, e toda VPC presa a ele alcança o escritório
pela mesma conexão. Essa é a ponta certa quando há mais que um par de VPCs. A seção depois da
próxima precifica as duas.

## A conexão, e o que o moto diz dos túneis dela

```
ana@laptop:~/aws$ aws ec2 create-vpn-connection --type ipsec.1 --customer-gateway-id $cgw --vpn-gateway-id $vgw --query "VpnConnection.[VpnConnectionId,State,Type]" --output text
vpn-d6e93da7bd7bbbfd9	available	ipsec.1
```

Guarde o id dela, como de todo o resto aqui:

```
ana@laptop:~/aws$ vpn=$(aws ec2 describe-vpn-connections --query "VpnConnections[0].VpnConnectionId" --output text)
```

**A configuração para o roteador volta junto com a conexão**, como um documento XML em
`CustomerGatewayConfiguration`: os endereços das duas pontas de cada túnel, os números de BGP, a
cifragem e uma chave pré-compartilhada por túnel. A chave é um segredo, então este comando a deixa
fora da tela e imprime só as linhas que situam os túneis:

```
ana@laptop:~/aws$ aws ec2 describe-vpn-connections --vpn-connection-ids $vpn --query "VpnConnections[0].CustomerGatewayConfiguration" --output text | grep -E "ipsec_tunnel>|<ip_address>|<asn>"
          <ipsec_tunnel>
              <ip_address>12.1.2.3</ip_address>
              <ip_address>169.254.44.42</ip_address>
              <asn>65000</asn>
              <ip_address>52.2.144.13</ip_address>
              <ip_address>169.254.44.41</ip_address>
              <asn>7224</asn>
          </ipsec_tunnel>
          <ipsec_tunnel>
              <ip_address>12.1.2.3</ip_address>
              <ip_address>169.254.44.42</ip_address>
              <asn>65000</asn>
              <ip_address>52.2.144.13</ip_address>
              <ip_address>169.254.44.41</ip_address>
              <asn>7224</asn>
          </ipsec_tunnel>
```

**Leia isso como documento do moto, não como configuração.** Ele tem o formato que a AWS documenta:
dois blocos `<ipsec_tunnel>`. Cada um tem um endereço externo para as duas pontas, um par de
endereços dentro do túnel em `169.254.0.0/16`, e os números de BGP. Os valores não se sustentam:

- o endereço externo do cliente é `12.1.2.3`, e não o `203.0.113.12` que o customer gateway recebeu;
- o número de AS do lado da AWS é `7224`, e não o `64512` com que este gateway foi criado;
- os dois túneis são idênticos, endereço externo, endereços internos e tudo, enquanto a AWS dá a cada
  túnel **o seu próprio endereço externo, no seu próprio equipamento**, e o seu próprio `/30` interno.

Na AWS esse documento é o que um engenheiro de rede carrega no roteador, muitas vezes por um arquivo
que a AWS gera para a marca do roteador. Vindo do moto, é um modelo para ler e nada para carregar. O
estado que a AWS guarda sobre os túneis também falta:

```
ana@laptop:~/aws$ aws ec2 describe-vpn-connections --vpn-connection-ids $vpn --query "VpnConnections[0].[Options.StaticRoutesOnly,VgwTelemetry]"
[
    null,
    null
]
```

**`VgwTelemetry` é onde a AWS informa cada túnel**, uma entrada cada, `UP` ou `DOWN`, com o número
de rotas que aprendeu. É a primeira coisa a olhar quando o escritório não alcança a VPC. O moto não
devolve nada ali, porque não há túneis por trás da resposta dele.

## Rotas estáticas ou BGP

A VPC e o escritório precisam aprender os endereços um do outro, e há dois jeitos.

O **roteamento estático** os escreve: a conexão VPN fica sabendo que `192.168.0.0/16` está atrás dela,
e a tabela de rotas fica sabendo o mesmo. Funciona com qualquer roteador, e toda mudança é feita à mão
nas duas pontas. Ele também faz failover pior: sem BGP, o roteador precisa perceber um túnel morto com
verificações próprias antes de passar para o outro.

O **BGP** deixa as duas pontas contarem uma à outra: o roteador do escritório anuncia
`192.168.0.0/16` por cada túnel, e a AWS anuncia `10.20.0.0/16`. Quando um túnel cai, as rotas
aprendidas por ele são retiradas e o outro túnel carrega o tráfego. **Use BGP quando o roteador
souber falá-lo**, e é por isso que o customer gateway carrega um número de AS.

A **propagação de rotas** é a metade que toca a VPC. Uma tabela de rotas com a propagação ligada a
partir do virtual private gateway recebe as rotas que o gateway aprendeu, e as mantém atualizadas
sozinha. O moto 5.2.3 não consegue fazer isso:

```
ana@laptop:~/aws$ aws ec2 enable-vgw-route-propagation --route-table-id $rt --gateway-id $vgw

aws: [ERROR]: Unable to parse response (syntax error: line 1, column 0), invalid XML received. Further retries may succeed:
b'<!doctype html>\n<html lang=en>\n<title>500 Internal Server Error</title>\n<h1>Internal Server Error</h1>\n<p>The server encountered an internal error and was unable to complete your request. Either the server is overloaded or there is an error in the application.</p>\n'
```

O moto respondeu `500`, e o `create-vpn-connection-route` dele também, a rota estática do lado da
conexão. Na AWS, o `enable-vgw-route-propagation` dá certo e não imprime nada, e o `PropagatingVgws`
da tabela de rotas passa a nomear o gateway. O que o moto guarda é uma rota estática na tabela de
rotas, a mesma rota que um projeto estático escreveria à mão:

```
ana@laptop:~/aws$ aws ec2 create-route --route-table-id $rt --destination-cidr-block 192.168.0.0/16 --gateway-id $vgw --query Return --output text
True
```

```
ana@laptop:~/aws$ aws ec2 describe-route-tables --route-table-ids $rt --query "RouteTables[0].Routes[].[DestinationCidrBlock,GatewayId,Origin]" --output text
10.20.0.0/16	local	CreateRouteTable
192.168.0.0/16	vgw-20474c8c293a43205	CreateRoute
```

A lição 17 lê uma tabela de rotas linha a linha. **`CreateRoute` na última coluna é como uma rota
estática diz quem a escreveu**. Uma propagada diz `EnableVgwRoutePropagation`. A rota local,
`10.20.0.0/16`, é o que a VPC sabe de si mesma.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"l24-tunnels\" aria-label=\"Uma VPN Site-to-Site. À esquerda, o escritório, 192.168.0.0/16, com o roteador no endereço público 203.0.113.12, AS BGP 65000. No meio, a internet. À direita, a região sa-east-1, onde a AWS roda duas pontas de túnel em equipamentos separados, e atrás delas o virtual private gateway, AS 64512, preso à VPC 10.20.0.0/16. Dois túneis ligam o roteador às duas pontas, cada um com a sua sessão BGP. Quando a AWS faz manutenção numa ponta, as rotas aprendidas por aquele túnel são retiradas e o outro túnel carrega o tráfego.\"><rect x=\"20.0\" y=\"50.0\" width=\"170.0\" height=\"220.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"105.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">o escritório</text><text x=\"105.0\" y=\"88.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">192.168.0.0/16</text><rect x=\"45.0\" y=\"130.0\" width=\"120.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"105.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">roteador</text><text x=\"105.0\" y=\"168.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">203.0.113.12</text><text x=\"105.0\" y=\"216.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">AS 65000</text><rect x=\"240.0\" y=\"120.0\" width=\"120.0\" height=\"80.0\" rx=\"36\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"300.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">a internet</text><rect x=\"410.0\" y=\"30.0\" width=\"290.0\" height=\"260.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"6 4\"></rect><text x=\"424.0\" y=\"48.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">sa-east-1</text><rect x=\"430.0\" y=\"73.0\" width=\"120.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"490.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">ponta do túnel 1</text><text x=\"490.0\" y=\"106.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">equipamento separado</text><rect x=\"430.0\" y=\"203.0\" width=\"120.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"490.0\" y=\"220.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">ponta do túnel 2</text><text x=\"490.0\" y=\"236.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">equipamento separado</text><rect x=\"580.0\" y=\"100.0\" width=\"110.0\" height=\"120.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"635.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">virtual</text><text x=\"635.0\" y=\"142.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">private gateway</text><text x=\"635.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">AS 64512</text><text x=\"635.0\" y=\"186.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">presa à</text><text x=\"635.0\" y=\"202.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">10.20.0.0/16</text><path d=\"M552.0 95.0 L578.0 130.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M552.0 225.0 L578.0 190.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M167.0 150.0 L260.0 138.0\" stroke=\"var(--amber)\" stroke-width=\"2.0\" fill=\"none\"></path><path d=\"M340.0 132.0 L428.0 100.0\" stroke=\"var(--amber)\" stroke-width=\"2.0\" fill=\"none\"></path><path d=\"M167.0 170.0 L260.0 182.0\" stroke=\"var(--amber)\" stroke-width=\"2.0\" fill=\"none\" stroke-dasharray=\"6 4\"></path><path d=\"M340.0 188.0 L428.0 222.0\" stroke=\"var(--amber)\" stroke-width=\"2.0\" fill=\"none\" stroke-dasharray=\"6 4\"></path><text x=\"212.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--amber)\">túnel 1</text><text x=\"212.0\" y=\"194.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--amber)\">túnel 2</text><text x=\"360.0\" y=\"312.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">dois túneis, duas sessões BGP: manutenção numa ponta move as rotas para a outra</text></svg>", "caption": "Uma conexão VPN são sempre dois túneis. Um projeto que deixa um deles desligado perde o escritório durante a manutenção da AWS.", "same": ["private gateway", "virtual"]}
```
