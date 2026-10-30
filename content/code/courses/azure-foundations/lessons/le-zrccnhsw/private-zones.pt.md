---
title: Zonas privadas, registro automático e o resolvedor para o escritório
version: 1
---

**Uma zona privada só responde às redes virtuais ligadas a ela, e ninguém na internet consegue
perguntar nada a ela.** A lição 19 usou uma para assumir o elo do meio do nome de uma storage account.
A loja usa outra para nomes próprios: `shop.internal`, uma zona em que `db.shop.internal` é o endereço
do banco de dados e toda máquina de produção tem o nome anotado sem ninguém escrevê-lo.

## A zona, um link e um registro, em Bicep

Salve isto como `private.bicep` em `~/azure/dns`:

```bicep
resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' existing = {
  name: 'vnet-shop-prod'
}

resource zone 'Microsoft.Network/privateDnsZones@2024-06-01' = {
  name: 'shop.internal'
  location: 'global'
}

resource link 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = {
  parent: zone
  name: 'link-vnet-shop-prod'
  location: 'global'
  properties: {
    virtualNetwork: {
      id: vnet.id
    }
    registrationEnabled: true
  }
}

resource db 'Microsoft.Network/privateDnsZones/A@2024-06-01' = {
  parent: zone
  name: 'db'
  properties: {
    ttl: 300
    aRecords: [
      {
        ipv4Address: '10.20.3.10'
      }
    ]
  }
}
```

```
ana@laptop:~/azure/dns$ az bicep build --file private.bicep --stdout | jq -c '.resources[] | {type, name, registration: .properties.registrationEnabled}'
{"type":"Microsoft.Network/privateDnsZones","name":"shop.internal","registration":null}
{"type":"Microsoft.Network/privateDnsZones/virtualNetworkLinks","name":"[format('{0}/{1}', 'shop.internal', 'link-vnet-shop-prod')]","registration":true}
{"type":"Microsoft.Network/privateDnsZones/A","name":"[format('{0}/{1}', 'shop.internal', 'db')]","registration":null}
```

Três recursos, e o do meio faz o trabalho. Um **link de rede virtual** liga a zona à
`vnet-shop-prod`, e daí em diante o resolvedor do Azure em `168.63.129.16`, a quem toda máquina daquela
rede pergunta por padrão, responde os nomes de `shop.internal` a partir da zona. O registro `db` guarda
o endereço que o banco recebeu na `snet-data`.

**`registrationEnabled: true` é o registro automático.** Toda máquina virtual que liga na rede ligada
ganha um registro `A` na zona com o próprio nome e o endereço privado, e o registro é removido quando a
máquina é apagada. Ninguém mantém uma lista, então a lista nunca está desatualizada. Dois limites vêm
junto: **uma rede só registra numa zona privada**, e registra máquinas virtuais, não os serviços de
plataforma nem os private endpoints da lição 19, cujos registros vêm dos zone groups.

## O mesmo nome, dentro e fora

Nada impede a loja de ter uma zona pública `shop.example` e uma zona privada `shop.example` ao mesmo
tempo. Uma máquina numa rede ligada recebe então as respostas privadas, e a internet recebe as
públicas: **DNS de horizonte dividido**, o mesmo mecanismo da lição 19, aplicado a um nome que é seu. É
útil e fácil de errar de um jeito específico. **Uma zona privada responde por todo nome dentro dela, e
diz "esse nome não existe" para todo nome que não guarda**; ela não cai para a zona pública. Uma
`shop.example` privada só com `api` dentro faz o `www.shop.example` sumir para toda máquina da rede
ligada, enquanto funciona perfeitamente no notebook de todo mundo.

## Quando a pergunta vem de fora do Azure

O `168.63.129.16` só responde a máquinas dentro do Azure: o endereço não quer dizer nada no escritório.
A lição 19 terminou num notebook na VPN que pergunta o nome de uma storage account ao DNS do escritório
e recebe a resposta pública. O **Azure DNS Private Resolver** é a peça que fecha essa lacuna. Ele mora
no hub, em sub-redes próprias, e tem duas metades:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" data-fig=\"l21-resolver\" aria-label=\"O escritório perguntando os nomes privados do Azure. Um notebook no escritório pergunta ao servidor DNS do escritório. Um encaminhador condicional manda as perguntas sobre shop.internal e sobre as zonas privatelink pela VPN até o inbound endpoint do Private Resolver no hub, que responde com o resolvedor do Azure e as zonas privadas ligadas. No sentido contrário, o outbound endpoint e um conjunto de regras de encaminhamento mandam as perguntas sobre corp.shop.example para o servidor DNS do escritório.\"><defs><marker id=\"l21-resolver-af-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l21-resolver-af-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l21-resolver-af-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><path d=\"M20 30 H250 V250 H20 Z\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"36.0\" y=\"48.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o escritório</text><text x=\"234.0\" y=\"48.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">192.168.0.0/16</text><rect x=\"45.0\" y=\"70.0\" width=\"120.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"105.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">notebook</text><rect x=\"45.0\" y=\"160.0\" width=\"180.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"135.0\" y=\"178.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">servidor DNS do escritório</text><text x=\"135.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">192.168.1.10</text><path d=\"M105.0 111.0 L105.0 159.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l21-resolver-af-ah-paper-dim)\"></path><path d=\"M440 30 H700 V250 H440 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"456.0\" y=\"48.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">vnet-shop-hub</text><rect x=\"465.0\" y=\"70.0\" width=\"210.0\" height=\"50.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"570.0\" y=\"88.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">inbound endpoint</text><text x=\"570.0\" y=\"106.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Private Resolver</text><rect x=\"465.0\" y=\"140.0\" width=\"210.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"570.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">zonas privadas, ligadas</text><rect x=\"465.0\" y=\"195.0\" width=\"210.0\" height=\"45.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"570.0\" y=\"211.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">outbound endpoint</text><text x=\"570.0\" y=\"228.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">e as suas regras</text><path d=\"M226.0 175.0 L340.0 120.0 L464.0 95.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l21-resolver-af-ah-phosphor)\"></path><text x=\"320.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">shop.internal</text><text x=\"320.0\" y=\"108.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">zonas privatelink</text><path d=\"M570.0 121.0 L570.0 139.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l21-resolver-af-ah-paper-dim)\" marker-start=\"url(#l21-resolver-af-ah-paper-dim)\"></path><path d=\"M464.0 218.0 L340.0 230.0 L226.0 205.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l21-resolver-af-ah-amber)\"></path><text x=\"340.0\" y=\"246.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">corp.shop.example</text></svg>", "caption": "Cada lado encaminha ao outro os nomes que só ele conhece, pela VPN.", "same": ["Private Resolver", "inbound endpoint", "outbound endpoint"]}
```

- **um inbound endpoint**, um endereço privado no hub que responde perguntas de DNS com tudo o que o
  resolvedor do Azure sabe, zonas privadas incluídas. O DNS do escritório ganha um **encaminhador
  condicional**: perguntas sobre `shop.internal` e sobre cada zona `privatelink` vão para esse endereço
  pela VPN;
- **um outbound endpoint com um conjunto de regras de encaminhamento**, para o sentido contrário:
  regras como "perguntas sobre `corp.shop.example` vão para `192.168.1.10`", para que as máquinas no
  Azure consigam resolver os nomes que só o DNS do escritório conhece.

**Nada nesta seção foi criado**, e nenhuma pergunta foi feita a uma zona privada: elas só respondem de
dentro de uma rede do Azure ligada, e o laboratório não é uma. O que foi conferido é o formato da zona
e do link, e o que a lição diz sobre respostas é o comportamento documentado da Microsoft. A lição 23
monta a VPN por onde as perguntas do escritório viajam.
