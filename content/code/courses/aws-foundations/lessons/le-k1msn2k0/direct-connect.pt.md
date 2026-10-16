---
title: Direct Connect, um cabo até a AWS
version: 1
---

**O Direct Connect é um enlace físico entre a sua rede e a da AWS**, feito num prédio onde as duas têm
equipamentos, para que o tráfego entre o escritório e a VPC nunca atravesse a internet pública. A
imagem errada é uma VPN mais rápida. Uma VPN é um túnel que você levanta numa tarde por cima da
internet que tiver. O Direct Connect é uma porta, uma fibra e um contrato, encomendado ao longo de
semanas, e o que ele compra é um caminho cuja banda e cuja latência são as mesmas às nove da manhã e
às três da madrugada. Três peças o formam: uma **conexão** num **local**, uma ou mais **interfaces
virtuais** nela, e muitas vezes um **Direct Connect gateway** para alcançar VPCs além de uma região.

## Locais, e os dois tipos de conexão

**Um local do Direct Connect é um datacenter de colocation onde a AWS tem roteadores**, não uma
região da AWS. A lista de preços nomeia dois em São Paulo, `Equinix SP4` sob o código `TNDB` e `Tivit`
sob `TIVIT`, e uma conexão feita em qualquer um deles fica ligada a `sa-east-1`. O equipamento da
própria loja, ou o da operadora dela, tem de chegar a esse prédio; os últimos metros lá dentro são um
**cross-connect**, um cabo que o operador do prédio passa entre os dois racks.

| | conexão dedicada | conexão hospedada |
|---|---|---|
| encomendada de | AWS | um parceiro do AWS Direct Connect |
| velocidades | uma porta inteira: 1, 10 ou 100 Gbps | uma fatia da porta do parceiro: de 50 Mbps a 10 Gbps nesta lista de preços |
| o que você recebe | uma **Letter of Authorization (LOA-CFA)** para entregar ao prédio para o cross-connect | uma conexão que o parceiro provisiona, e que você aceita |
| para a loja | quando ela tem um rack nesse prédio | quando não tem, que é o caso comum de um escritório só |

## O que o moto responde

```
ana@laptop:~/aws$ aws directconnect describe-locations

aws: [ERROR]: An error occurred (500) when calling the DescribeLocations operation (reached max retries: 2): <!doctype html>
<html lang=en>
<title>500 Internal Server Error</title>
<h1>Internal Server Error</h1>
<p>The server encountered an internal error and was unable to complete your request. Either the server is overloaded or there is an error in the application.</p>
```

**O moto 5.2.3 não consegue listar locais**, então o código que esta lição usa é o que a lista de
preços deu, `TNDB`, e o moto teria aceitado qualquer texto. Uma conexão dedicada de 1 Gbps:

```
ana@laptop:~/aws$ aws directconnect create-connection --location TNDB --bandwidth 1Gbps --connection-name shop-dx-1 --query "[connectionId,connectionState,location,bandwidth,awsDevice]" --output text
arn:aws:directconnect:sa-east-1:123456789012:dx-con/dx-moto-shop-dx-1-20261016134801	available	TNDB	1Gbps	mock_device
```

Três coisas nessa linha são do moto e não da AWS. **O estado é `available` na hora**, enquanto a AWS
começa uma conexão dedicada em `requested`, a mantém ali até você baixar a LOA, e só a passa para
`available` quando o cross-connect está feito e há luz na fibra, o que leva de dias a semanas. **O id
é um ARN com uma data e hora dentro**, enquanto a AWS dá um id como `dxcon-` seguido de alguns
caracteres. E `mock_device` é o moto dizendo que não há equipamento. Guarde o id para o próximo
passo:

```
ana@laptop:~/aws$ dx=$(aws directconnect describe-connections --query "connections[0].connectionId" --output text)
```

## Interfaces virtuais: o que viaja no cabo

**Uma conexão é um cabo; uma interface virtual (VIF) é uma conversa nele**, uma VLAN com uma sessão
BGP própria, e uma conexão carrega várias. Há três tipos:

| VIF | alcança | a loja a usa para |
|---|---|---|
| privada | uma VPC, pelo virtual private gateway dela, ou várias por um Direct Connect gateway | os servidores do escritório falando com o banco de dados em `10.20.0.0/16` |
| de trânsito | Transit Gateways, por um Direct Connect gateway | toda VPC de toda conta, pelo Transit Gateway da lição 20 |
| pública | os endereços públicos da AWS, como os do S3, pelo cabo em vez da internet | backups para o `shop-backups` sem atravessar a internet |

O virtual private gateway da seção anterior é o mesmo objeto em que uma VIF privada chega, então a
VPC não precisa de uma segunda porta. O moto para aqui:

```
ana@laptop:~/aws$ aws directconnect create-private-virtual-interface --connection-id $dx --new-private-virtual-interface virtualInterfaceName=shop-prod,vlan=101,asn=65000,virtualGatewayId=$vgw,addressFamily=ipv4

aws: [ERROR]: An error occurred (500) when calling the CreatePrivateVirtualInterface operation (reached max retries: 2): <!doctype html>
<html lang=en>
<title>500 Internal Server Error</title>
<h1>Internal Server Error</h1>
<p>The server encountered an internal error and was unable to complete your request. Either the server is overloaded or there is an error in the application.</p>
```

**O moto 5.2.3 responde `500` a toda interface virtual e a todo Direct Connect gateway**, então daqui
em diante a seção é comportamento documentado da AWS, e nada dela foi rodado.

## O Direct Connect gateway

**Um Direct Connect gateway é um objeto global que liga interfaces virtuais a gateways em qualquer
região.** Sem ele, uma VIF privada alcança um virtual private gateway na região de origem da conexão;
com ele, a mesma VIF alcança virtual private gateways em várias regiões e contas, e uma VIF de
trânsito alcança Transit Gateways. Ele roteia entre as VIFs e as VPCs, não entre duas VPCs nem entre
dois escritórios: tráfego de uma VPC para outra por um Direct Connect gateway é recusado de propósito,
e esse é o trabalho da lição 20.

## O que o cabo não faz

**O Direct Connect é privado, e não é cifrado.** O tráfego atravessa um cabo que ninguém mais divide,
entre equipamentos que a loja e a AWS controlam, e ainda assim vai em texto claro nesse cabo. Duas
respostas, ambas documentadas pela AWS e nenhuma rodada aqui: o **MACsec**, cifragem de enlace em
conexões dedicadas de 10 e 100 Gbps; ou uma **VPN Site-to-Site por cima do Direct Connect**, os túneis
da seção anterior carregados numa VIF pública ou de trânsito em vez da internet. Para uma loja que
manda dados de pagamento entre o escritório e a VPC, uma das duas pertence ao projeto, sugira o que
sugerir a privacidade do cabo.
