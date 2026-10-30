---
title: Tabelas de rotas que mandam o tráfego pelo firewall
version: 1
---

**Uma tabela de rotas é um recurso que guarda rotas definidas pelo usuário, e não faz nada até ser
presa a uma sub-rede.** Cada rota é um prefixo e um próximo salto; uma sub-rede tem no máximo uma
tabela de rotas, e uma tabela pode servir a muitas sub-redes. Uma vez presa, as rotas dela se juntam
às rotas de sistema da sub-rede e vencem onde dividem um prefixo, pela regra da seção anterior.

O próximo salto de uma rota definida pelo usuário é um de uma lista curta:

| próximo salto | para onde o pacote vai |
|---|---|
| `VirtualAppliance` | para um endereço privado que você cita: um firewall, ou uma máquina que inspeciona tráfego |
| `VirtualNetworkGateway` | para o gateway de VPN ou de ExpressRoute da rede, lição 23 |
| `VnetLocal` | para dentro da rede, como a rota de sistema faria |
| `Internet` | direto para fora, de propósito |
| `None` | para lugar nenhum: o pacote é descartado |

## O desenho da loja: tudo sai pelo hub

A loja põe um **Azure Firewall** na rede hub, em `10.0.1.4` na `AzureFirewallSubnet`, e manda três
tipos de tráfego da produção para ele: tudo o que vai para a internet, tudo o que vai para o staging,
tudo o que vai para o escritório.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"l18-hub\" aria-label=\"O roteamento da loja. A rede de produção vnet-shop-prod, 10.20.0.0/16, tem snet-web, snet-app e snet-data; o tráfego entre elas fica local. A tabela de rotas rt-shop-prod manda três prefixos para o firewall em 10.0.1.4 na AzureFirewallSubnet da rede hub vnet-shop-hub, 10.0.0.0/16: 0.0.0.0/0 para a internet, 10.30.0.0/16 para o staging e 192.168.0.0/16 para o escritório. Do firewall, o tráfego segue para a internet, para o staging e para o escritório.\"><defs><marker id=\"l18-hub-af-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l18-hub-af-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20.0\" y=\"20.0\" width=\"250.0\" height=\"290.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"36.0\" y=\"38.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">vnet-shop-prod</text><text x=\"36.0\" y=\"56.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10.20.0.0/16</text><rect x=\"40.0\" y=\"74.0\" width=\"140.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"110.0\" y=\"93.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">snet-web</text><rect x=\"40.0\" y=\"126.0\" width=\"140.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"110.0\" y=\"145.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">snet-app</text><rect x=\"40.0\" y=\"178.0\" width=\"140.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"110.0\" y=\"197.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">snet-data</text><text x=\"110.0\" y=\"246.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">local entre sub-redes</text><rect x=\"40.0\" y=\"262.0\" width=\"210.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"145.0\" y=\"279.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">rt-shop-prod</text><rect x=\"330.0\" y=\"90.0\" width=\"170.0\" height=\"150.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"346.0\" y=\"108.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">vnet-shop-hub</text><rect x=\"346.0\" y=\"140.0\" width=\"138.0\" height=\"70.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"415.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Azure Firewall</text><text x=\"415.0\" y=\"182.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">10.0.1.4</text><text x=\"415.0\" y=\"225.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">AzureFirewallSubnet</text><path d=\"M272.0 130.0 L328.0 130.0\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l18-hub-af-ah-amber)\"></path><path d=\"M272.0 175.0 L328.0 175.0\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l18-hub-af-ah-amber)\"></path><path d=\"M272.0 220.0 L328.0 220.0\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l18-hub-af-ah-amber)\"></path><text x=\"300.0\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">três rotas</text><rect x=\"570.0\" y=\"40.0\" width=\"130.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"635.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a internet</text><path d=\"M502.0 123.0 L568.0 60.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l18-hub-af-ah-paper-dim)\"></path><rect x=\"570.0\" y=\"145.0\" width=\"130.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"635.0\" y=\"165.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">staging</text><path d=\"M502.0 165.0 L568.0 165.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l18-hub-af-ah-paper-dim)\"></path><rect x=\"570.0\" y=\"250.0\" width=\"130.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"635.0\" y=\"270.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o escritório</text><path d=\"M502.0 207.0 L568.0 270.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l18-hub-af-ah-paper-dim)\"></path><text x=\"300.0\" y=\"322.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">0.0.0.0/0, 10.30.0.0/16 e 192.168.0.0/16 apontam todos para o firewall</text></svg>", "caption": "As três fronteiras da produção passam pelo firewall do hub; o tráfego dentro da produção não.", "same": ["Azure Firewall", "staging"]}
```

**O tráfego dentro da rede não passa pelo firewall**, e isso também é uma escolha: a camada web
alcançando a aplicação fica local, filtrada pelos NSGs da lição 17. O firewall vê o que atravessa uma
fronteira, que é onde a loja quer um registro só de quem falou com quem. O endereço `10.0.1.4` só é
alcançável a partir da produção depois que as duas redes fizerem peering, que é a lição 20; a tabela
de rotas é escrita agora, e funciona a partir desse dia.

Salve isto como `~/azure/routes/rt.bicep`:

```bicep
param location string = 'brazilsouth'

@description('The private address of the shop\'s firewall, in the hub.')
param firewallIp string = '10.0.1.4'

resource rt 'Microsoft.Network/routeTables@2024-05-01' = {
  name: 'rt-shop-prod'
  location: location
  properties: {
    disableBgpRoutePropagation: true
    routes: [
      {
        name: 'internet-via-firewall'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: firewallIp
        }
      }
      {
        name: 'staging-via-firewall'
        properties: {
          addressPrefix: '10.30.0.0/16'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: firewallIp
        }
      }
      {
        name: 'office-via-firewall'
        properties: {
          addressPrefix: '192.168.0.0/16'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: firewallIp
        }
      }
    ]
  }
}
```

`disableBgpRoutePropagation: true` impede que as rotas que o gateway aprende do escritório cheguem a
estas sub-redes, para que o único caminho até o escritório seja a rota pelo firewall. Sem isso, um
gateway anunciando `192.168.10.0/24` daria à produção um prefixo mais longo que o `/16` da tabela e um
caminho por fora do firewall. Compile e leia as rotas de volta:

```
ana@laptop:~/azure/routes$ az bicep build --file rt.bicep --outfile rt.json && jq -c '.resources[0].properties.routes[] | [.name, .properties.addressPrefix, .properties.nextHopIpAddress]' rt.json
["internet-via-firewall","0.0.0.0/0","[parameters('firewallIp')]"]
["staging-via-firewall","10.30.0.0/16","[parameters('firewallIp')]"]
["office-via-firewall","192.168.0.0/16","[parameters('firewallIp')]"]
```

Os próximos saltos ainda são `[parameters('firewallIp')]`: um parâmetro é preenchido quando o
template é implantado, e é por isso que o `route.py` lê o valor padrão dele no template. Agora os seis
pacotes:

```
ana@laptop:~/azure/routes$ python3 route.py rt.json 203.0.113.80
User    0.0.0.0/0       VirtualAppliance 10.0.1.4  chosen
Default 0.0.0.0/0       Internet
ana@laptop:~/azure/routes$ python3 route.py rt.json 10.20.3.4
Default 10.20.0.0/16    VnetLocal                  chosen
Default 10.0.0.0/8      None
User    0.0.0.0/0       VirtualAppliance 10.0.1.4
Default 0.0.0.0/0       Internet
ana@laptop:~/azure/routes$ python3 route.py rt.json 10.30.1.4
User    10.30.0.0/16    VirtualAppliance 10.0.1.4  chosen
Default 10.0.0.0/8      None
User    0.0.0.0/0       VirtualAppliance 10.0.1.4
Default 0.0.0.0/0       Internet
ana@laptop:~/azure/routes$ python3 route.py rt.json 10.99.0.1
Default 10.0.0.0/8      None                       chosen
User    0.0.0.0/0       VirtualAppliance 10.0.1.4
Default 0.0.0.0/0       Internet
ana@laptop:~/azure/routes$ python3 route.py rt.json 10.0.1.4
Default 10.0.0.0/16     VNetPeering                chosen
Default 10.0.0.0/8      None
User    0.0.0.0/0       VirtualAppliance 10.0.1.4
Default 0.0.0.0/0       Internet
ana@laptop:~/azure/routes$ python3 route.py rt.json 192.168.10.5
User    192.168.0.0/16  VirtualAppliance 10.0.1.4  chosen
Default 192.168.0.0/16  None
User    0.0.0.0/0       VirtualAppliance 10.0.1.4
Default 0.0.0.0/0       Internet
```

Leia-os em ordem. A internet agora vai para o firewall: o mesmo prefixo `/0`, e uma rota de usuário
vence uma de sistema. O `10.20.3.4`, o banco, fica local, porque `/16` é mais longo que `/0`. O staging
vai para o firewall, pelo `/16` que vence o `10.0.0.0/8`. **O `10.99.0.1`, que não fica em lugar
nenhum, é descartado**, pela rota `None` de `10.0.0.0/8`, em vez de seguir o padrão até o firewall. O
endereço do próprio firewall vai direto pelo peering, como precisa ser: uma rota que mandasse o
endereço do firewall para o firewall seria um laço. E o escritório vai para o firewall, cuja rota tem
o mesmo prefixo da rota de sistema `None` e vence por ser de usuário.

## Três jeitos de errar isto

**Prender a tabela à própria sub-rede do firewall.** Um `0.0.0.0/0` para `10.0.1.4` na
`AzureFirewallSubnet` manda o tráfego do firewall de volta para ele mesmo. A sub-rede do firewall
mantém as próprias rotas; a próxima seção diz quando ela ganha uma tabela só dela.

**Pôr uma rota `0.0.0.0/0` na `GatewaySubnet`.** A documentação da Microsoft diz com todas as letras
que uma tabela de rotas com rota padrão na sub-rede do gateway pode impedir o gateway de funcionar. O
gateway precisa alcançar os serviços do próprio Azure diretamente.

**Esquecer o caminho de volta.** Um pacote que sai pelo firewall precisa voltar por ele, ou o
firewall, que acompanha as conexões, descarta a resposta como uma estranha. Uma máquina com endereço
público próprio é o caso que mais quebra isso: um pedido chega direto na máquina, a resposta segue o
`0.0.0.0/0` até o firewall, e o firewall nunca viu a conversa. **Depois que o tráfego sai por um
firewall, o caminho de entrada passa por ele também**: os clientes da loja chegam à camada web por um
balanceador de carga e pelo firewall, nunca pelo endereço próprio de uma máquina.
