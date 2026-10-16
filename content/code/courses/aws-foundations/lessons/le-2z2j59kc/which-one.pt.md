---
title: Peering ou Transit Gateway, por contagem, por rota e por preço
version: 1
---

**Peering não custa nada para ter e cresce por pares; um Transit Gateway custa algo a cada hora e
cresce um attachment por rede.** Com duas ou três VPCs, o peering é mais barato e mais simples. Com
muitas, ou no momento em que uma rede precisa ser alcançada *através* de outra, o hub ganha, e a
lista de preços diz quanto ele cobra por ganhar.

## Os preços

Os dois estão na oferta da VPC de 17 de setembro de 2026:

```
ana@laptop:~/aws$ python3 price.py AmazonVPC 20260917190528 sa-east-1 SAE1-TransitGateway-Hours SAE1-TransitGateway-Bytes SAE1-VpcPeering-In-Bytes SAE1-VpcPeering-Out-Bytes
AmazonVPC 20260917190528, published 2026-09-17, USD
SAE1-TransitGateway-Hours
          0 to       Inf hour 0.0900
          0 to       Inf hour 0.0900
          0 to       Inf hour 0.0900
          0 to       Inf hour 0.0900
          0 to       Inf hour 0.0900
          0 to       Inf hour 0.0900
SAE1-TransitGateway-Bytes
          0 to       Inf GigaBytes 0.0200
          0 to       Inf GigaBytes 0.0200
          0 to       Inf GigaBytes 0.0200
          0 to       Inf GigaBytes 0.0200
SAE1-VpcPeering-In-Bytes
          0 to       Inf GB   0.0100
SAE1-VpcPeering-Out-Bytes
          0 to       Inf GB   0.0100
ana@laptop:~/aws$ python3 -c "import json, os; d = json.load(open(os.path.expanduser('~/.cache/aws-prices/AmazonVPC-20260917190528-sa-east-1.json'))); print(*sorted(p['attributes']['operation'] for p in d['products'].values() if p['attributes'].get('usagetype') == 'SAE1-TransitGateway-Hours'), sep='\\n')"
TransitGatewayConcentratorVPN
TransitGatewayConnect
TransitGatewayDirectConnect
TransitGatewayPeering
TransitGatewayVPC
TransitGatewayVPN
```

O `price.py` imprimiu **seis linhas para as horas e quatro para os bytes**, todas ao mesmo preço.
Elas são produtos separados na oferta, um para cada tipo de attachment. O segundo comando os lista
pelo nome: uma VPC, uma VPN, um link de Direct Connect, um attachment Connect, um peering entre dois
hubs e um concentrador de VPN. Seja o que for que esteja ligado, **0,09 dólar por hora por attachment
e 0,02 por gigabyte que o hub processa**.

As duas linhas de peering são **0,01 por gigabyte em cada sentido**. A documentação da AWS diz que o
tráfego por um peering dentro de uma zona é grátis, então essas linhas são o que custa atravessar
zonas por um peering, os mesmos 0,01 em cada sentido de qualquer travessia entre zonas da lição 1. O
peering não tem linha por hora nenhuma.

## Duas VPCs

Produção e staging trocam uns 500 GB por mês, todos atravessando zonas, para ficar com o pior caso:

| | peering | Transit Gateway |
|---|---|---|
| por hora | nada | 2 attachments × 730 × 0,09 = 131,40 |
| por gigabyte | 500 × (0,01 + 0,01) = 10,00 | 500 × 0,02 = 10,00 processados |
| **por mês** | **10,00** | **141,40**, antes de atravessar zonas |

**Para um par, o peering é a resposta óbvia**: um Transit Gateway cobra 131,40 por mês por ficar no
meio de uma conversa que não precisa de ninguém no meio.

## Dez VPCs

Pares crescem mais rápido que redes. Dez VPCs que conversam todas entre si precisam de 10 × 9 / 2 =
**45 peerings**, cada um pedido e aceito, e toda tabela de rotas de toda VPC carrega **nove rotas**,
uma por par; uma décima primeira VPC acrescenta mais dez peerings e uma rota em toda tabela da
organização. A AWS também limita por cota os peerings de uma VPC, 50 por padrão. O hub precisa de
**dez attachments** e uma linha por VPC na própria tabela, propagada sozinha:

| dez VPCs | peering | Transit Gateway |
|---|---|---|
| conexões a criar | 45 | 10 |
| rotas em cada tabela de VPC | 9 | 1, para `10.0.0.0/8` ou o bloco que o plano tiver |
| por hora, num mês | nada | 10 × 730 × 0,09 = 657,00 |
| por gigabyte | 0,01 em cada sentido entre zonas | 0,02 processados |

Esses 657 dólares por mês compram **um lugar só onde o roteamento é decidido**, o que, com duas
pessoas operando a plataforma, vale boa parte deles.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"l20-mesh-or-hub\" aria-label=\"Cinco VPCs ligadas de duas maneiras. À esquerda, todo par com peering: dez linhas entre cinco VPCs. À direita, as mesmas cinco VPCs, cada uma ligada uma vez a um Transit Gateway no meio: cinco linhas. Com n VPCs, uma malha completa de peerings precisa de n vezes n menos um sobre dois conexões; o hub precisa de n attachments, cada um cobrado por hora.\"><path d=\"M197.8 72.9 L257.3 116.2\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M186.8 80.9 L232.0 220.0\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M173.2 80.9 L128.0 220.0\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M162.2 72.9 L102.7 116.2\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M268.3 150.0 L245.6 220.0\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M257.3 142.0 L139.0 228.0\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M253.1 129.1 L106.9 129.1\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M216.8 240.9 L143.2 240.9\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M221.0 228.0 L102.7 142.0\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M114.4 220.0 L91.7 150.0\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\"></path><circle cx=\"180.0\" cy=\"60.0\" r=\"20\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.4\"></circle><text x=\"180.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">v1</text><circle cx=\"275.1\" cy=\"129.1\" r=\"20\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.4\"></circle><text x=\"275.1\" y=\"129.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">v2</text><circle cx=\"238.8\" cy=\"240.9\" r=\"20\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.4\"></circle><text x=\"238.8\" y=\"240.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">v3</text><circle cx=\"121.2\" cy=\"240.9\" r=\"20\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.4\"></circle><text x=\"121.2\" y=\"240.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">v4</text><circle cx=\"84.9\" cy=\"129.1\" r=\"20\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.4\"></circle><text x=\"84.9\" y=\"129.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">v5</text><path d=\"M540.0 82.0 L540.0 130.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\"></path><path d=\"M614.2 135.9 L568.5 150.7\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\"></path><path d=\"M585.8 223.1 L557.6 184.3\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\"></path><path d=\"M494.2 223.1 L522.4 184.3\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\"></path><path d=\"M465.8 135.9 L511.5 150.7\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\"></path><circle cx=\"540.0\" cy=\"160.0\" r=\"28\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></circle><text x=\"540.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">TGW</text><circle cx=\"540.0\" cy=\"60.0\" r=\"20\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.4\"></circle><text x=\"540.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">v1</text><circle cx=\"635.1\" cy=\"129.1\" r=\"20\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.4\"></circle><text x=\"635.1\" y=\"129.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">v2</text><circle cx=\"598.8\" cy=\"240.9\" r=\"20\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.4\"></circle><text x=\"598.8\" y=\"240.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">v3</text><circle cx=\"481.2\" cy=\"240.9\" r=\"20\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.4\"></circle><text x=\"481.2\" y=\"240.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">v4</text><circle cx=\"444.9\" cy=\"129.1\" r=\"20\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.4\"></circle><text x=\"444.9\" y=\"129.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">v5</text><text x=\"180.0\" y=\"292.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">peering: 10 conexões</text><text x=\"180.0\" y=\"310.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">nada por hora</text><text x=\"540.0\" y=\"292.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">Transit Gateway: 5 attachments</text><text x=\"540.0\" y=\"310.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">5 × 65,70 = 328,50 por mês</text></svg>", "caption": "Pares crescem como n(n-1)/2, attachments como n. Dez VPCs são 45 peerings ou 10 attachments.", "same": ["Transit Gateway: 5 attachments"]}
```

## Quando cada um ganha

- **Peering** quando as VPCs são poucas, o tráfego entre elas é pesado e todo par simplesmente
  conversa com todo outro. Ele não tem custo por hora, nem cobrança de processamento, nem nada no
  meio para falhar.
- **Transit Gateway** quando as VPCs são muitas ou não param de chegar, quando o roteamento precisa
  ser **transitivo**, como uma VPN até o escritório (lição 24) que toda VPC usa, e quando a loja
  precisa de **segmentos**, o staging mantido longe da produção enquanto os dois alcançam ferramentas
  compartilhadas, o que só as tabelas de rotas do hub conseguem dizer.
- **Nenhum dos dois** quando um único serviço é tudo o que precisa ser compartilhado, num sentido só.
  Isso é o PrivateLink, lição 19, e ele não se importa se os intervalos se sobrepõem.

A loja, com produção, staging e uma cópia de recuperação de desastre, começa com **peering**. No dia
em que a VPN do escritório chegar, ou uma quarta e uma quinta conta, ela passa para o hub, e a
mudança é o `replace-route` da seção anterior, uma tabela de cada vez.
