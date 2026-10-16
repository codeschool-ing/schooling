---
title: Sobreviver a uma falha, e escolher pela lista de preços
version: 1
---

**Um caminho de entrada desde o datacenter vale o que vale o segundo caminho.** Uma conexão Direct
Connect é uma porta, um cross-connect, um prédio e uma rota de fibra, e qualquer um deles pode falhar;
o escritório da loja então perde a VPC inteira, por mais rápido que o enlace fosse um minuto antes. A
imagem errada é que o Direct Connect é "o confiável" e a VPN o reserva de quem não pode pagar por ele.
Cada um é um caminho único até ser dobrado, e a lista de preços decide qual dobra a loja consegue
pagar.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 340\" role=\"img\" data-fig=\"l24-resilience\" aria-label=\"Dois jeitos de dobrar o caminho do escritório até a VPC. O roteador do escritório tem uma conexão Direct Connect até o local Equinix SP4, código TNDB, e dali uma interface virtual privada até o virtual private gateway da VPC em sa-east-1. Tracejado, o segundo caminho: ou uma segunda conexão Direct Connect no local Tivit, que sobrevive a um prédio inteiro apagar, ou uma VPN Site-to-Site pela internet, o reserva mais barato. Com BGP nos dois, a AWS prefere o caminho do Direct Connect enquanto ele está de pé.\"><defs><marker id=\"l24-resilience-af-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l24-resilience-af-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20.0\" y=\"110.0\" width=\"140.0\" height=\"110.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"90.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">o escritório</text><text x=\"90.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">roteador</text><text x=\"90.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">AS 65000</text><rect x=\"250.0\" y=\"40.0\" width=\"160.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"330.0\" y=\"61.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Equinix SP4</text><text x=\"330.0\" y=\"81.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">local TNDB</text><rect x=\"250.0\" y=\"140.0\" width=\"160.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"330.0\" y=\"161.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Tivit</text><text x=\"330.0\" y=\"181.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">local TIVIT</text><rect x=\"250.0\" y=\"250.0\" width=\"160.0\" height=\"50.0\" rx=\"24\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"330.0\" y=\"275.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">a internet</text><rect x=\"480.0\" y=\"30.0\" width=\"220.0\" height=\"280.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"6 4\"></rect><text x=\"494.0\" y=\"48.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">sa-east-1</text><rect x=\"520.0\" y=\"120.0\" width=\"150.0\" height=\"90.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"595.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">virtual private</text><text x=\"595.0\" y=\"165.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">gateway</text><text x=\"595.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">10.20.0.0/16</text><path d=\"M162.0 140.0 L246.0 80.0\" stroke=\"var(--phosphor)\" stroke-width=\"2.2\" fill=\"none\"></path><path d=\"M412.0 75.0 L516.0 140.0\" stroke=\"var(--phosphor)\" stroke-width=\"2.2\" fill=\"none\" marker-end=\"url(#l24-resilience-af-ah-phosphor)\"></path><text x=\"200.0\" y=\"96.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--phosphor)\">Direct Connect</text><text x=\"444.0\" y=\"118.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">VIF privada</text><path d=\"M162.0 170.0 L246.0 170.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"6 4\"></path><path d=\"M412.0 170.0 L516.0 168.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"6 4\" marker-end=\"url(#l24-resilience-af-ah-amber)\"></path><text x=\"205.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">ou uma segunda</text><path d=\"M162.0 200.0 L246.0 268.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"2 3\"></path><path d=\"M412.0 270.0 L516.0 200.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"2 3\" marker-end=\"url(#l24-resilience-af-ah-amber)\"></path><text x=\"195.0\" y=\"258.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">ou uma VPN</text><text x=\"360.0\" y=\"330.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">com BGP nos dois, a AWS prefere o Direct Connect enquanto ele está de pé</text></svg>", "caption": "Uma conexão é um prédio e uma fibra. O segundo caminho é outro prédio ou a internet.", "same": ["Direct Connect", "Equinix SP4", "Tivit", "gateway", "virtual private"]}
```

## Os modelos que a AWS documenta

A AWS descreve três arranjos para o Direct Connect, na própria orientação de resiliência:

| modelo | o que é | a que sobrevive |
|---|---|---|
| desenvolvimento e teste | duas conexões em **um** local, em equipamentos separados da AWS | a falha de um equipamento ou de uma porta |
| alta resiliência | uma conexão em cada um de **dois** locais | um prédio inteiro apagar |
| resiliência máxima | duas conexões em cada um de dois locais, em equipamentos separados | um prédio, e um equipamento no outro ao mesmo tempo |

**Uma VPN é o segundo caminho barato**, e a AWS a documenta como reserva do Direct Connect. Com BGP
nos dois, e o mesmo prefixo do escritório anunciado por cada um, a AWS prefere o caminho do Direct
Connect enquanto ele está de pé, e as rotas passam para os túneis da VPN quando não está. A VPN é mais
lenta e atravessa a internet, o que é aceitável por algumas horas de serviço degradado, e não como
projeto permanente.

O moto registra o segundo local com a mesma facilidade do primeiro, e é tudo o que ele consegue
mostrar de um projeto feito para sobreviver a uma falha:

```
ana@laptop:~/aws$ aws directconnect create-connection --location TIVIT --bandwidth 1Gbps --connection-name shop-dx-2 --query "[connectionName,location,connectionState]" --output text
shop-dx-2	TIVIT	available
```

```
ana@laptop:~/aws$ aws directconnect describe-connections --query "connections[].[connectionName,location,bandwidth]" --output text
shop-dx-1	TNDB	1Gbps
shop-dx-2	TIVIT	1Gbps
```

**Nada fez failover, porque nada carregava nada**: o comportamento acima é o da AWS, e testá-lo
significa derrubar um caminho numa conta real e ver as rotas BGP se moverem.

## Os preços

A conexão VPN está na oferta `AmazonVPC` que o curso `cloud` fixou:

```
ana@laptop:~/aws$ python3 price.py AmazonVPC 20260917190528 sa-east-1 SAE1-VPN-Usage-Hours:ipsec.1
AmazonVPC 20260917190528, published 2026-09-17, USD
SAE1-VPN-Usage-Hours:ipsec.1
          0 to       Inf Hrs  0.0500
```

Se a VPN terminar num Transit Gateway, a associação tem uma hora própria e todo gigabyte que passa
por ela é processado e cobrado. O tipo de uso é compartilhado por todo tipo de associação, então o
`ops.py` da lição 22 os separa:

```
ana@laptop:~/aws$ python3 ops.py AmazonVPC 20260917190528 sa-east-1 SAE1-TransitGateway-Hours SAE1-TransitGateway-Bytes
SAE1-TransitGateway-Hours
  TransitGatewayConcentratorVPN 0.09000 per hour
  TransitGatewayConnect      0.09000 per hour
  TransitGatewayDirectConnect 0.09000 per hour
  TransitGatewayPeering      0.09000 per hour
  TransitGatewayVPC          0.09000 per hour
  TransitGatewayVPN          0.09000 per hour
SAE1-TransitGateway-Bytes
  TransitGatewayConcentratorVPN 0.02000 per GigaBytes
  TransitGatewayDirectConnect 0.02000 per GigaBytes
  TransitGatewayVPC          0.02000 per GigaBytes
  TransitGatewayVPN          0.02000 per GigaBytes
```

O Direct Connect tem oferta própria, com o código de cada local dentro de cada tipo de uso, então as
linhas da Equinix SP4 levam `TNDB`:

```
ana@laptop:~/aws$ python3 price.py AWSDirectConnect 20260917204010 sa-east-1 SAE1-TNDB-PortUsage:1G SAE1-TNDB-PortUsage:10G SAE1-TNDB-HCPortUsage:1G SAE1-TNDB-DataXfer-Out:dc.3
AWSDirectConnect 20260917204010, published 2026-09-17, USD
SAE1-TNDB-PortUsage:1G
          0 to       Inf hours 0.3000
SAE1-TNDB-PortUsage:10G
          0 to       Inf hours 2.2500
SAE1-TNDB-HCPortUsage:1G
          0 to       Inf hours 0.3300
SAE1-TNDB-DataXfer-Out:dc.3
          0 to       Inf GB   0.1100
```

`dc.3` é a linha do tráfego que sai da AWS por uma interface virtual privada. Nas listas de **17 de
setembro de 2026** das duas ofertas, em dólares:

| | por hora | por GB saindo da AWS |
|---|---|---|
| uma conexão VPN | 0,05 | o da internet, 0,15 nos primeiros 10 TB, da lição 1 |
| uma associação VPN no Transit Gateway, por cima | 0,09 | mais 0,02 processados |
| uma porta dedicada de 1 Gbps na Equinix SP4 | 0,30 | 0,11 por uma VIF privada |
| uma porta dedicada de 10 Gbps | 2,25 | 0,11 |
| uma conexão hospedada de 1 Gbps | 0,33 | 0,11 |

**O tráfego que entra na AWS é grátis nos dois caminhos**, como é vindo da internet: a fatura é das
horas e do que sai.

## O mês da loja, dos dois jeitos

O escritório puxa 2 TB por mês da VPC: relatórios, backups restaurados, imagens para o catálogo. Um mês
tem 730 horas.

- **VPN até o virtual private gateway**: 730 × 0,05 = 36,50 pelas horas, 2.048 × 0,15 = 307,20 pelos
  bytes, então **343,70 dólares**.
- **Uma porta dedicada de 1 Gbps do Direct Connect**: 730 × 0,30 = 219,00 pela porta,
  2.048 × 0,11 = 225,28 pelos bytes, então **444,28 dólares**, antes do cross-connect e do circuito
  do escritório até o prédio, que o prédio e a operadora cobram e a lista de preços não traz.

**Com 2 TB a VPN sai mais barata; os bytes decidem onde isso muda.** A porta custa 182,50 por mês a
mais que as horas da VPN, e cada gigabyte pelo Direct Connect economiza 0,04, então os dois se
encontram em 182,50 / 0,04 = **4.562,5 GB**, cerca de 4,5 TB por mês. Acima disso o cabo é mais barato
só pela lista de preços, e ele já era o caminho mais estável.

Essa conta é para um caminho só. Um projeto de alta resiliência são duas portas em dois locais, 438,00
por mês em horas antes de um byte se mover. A dobra mais barata, para um escritório do tamanho da
loja, é a que abriu esta seção: **uma conexão Direct Connect, com uma VPN atrás dela**, por
219,00 + 36,50 = 255,50 por mês em horas.
