---
title: Uma zona pública, a sua delegação e os seus registros alias
version: 1
---

**O Azure DNS não é dono de um domínio; ele responde por um que alguém delegou a ele.** A loja compra
`shop.example` de um registrador, e o trabalho do registrador termina numa coisa: dizer à zona pai,
`.example`, quais servidores de nomes respondem por `shop.example`. Criar a zona no Azure dá esses
servidores de nomes; escrevê-los no registrador é a **delegação**, e até ela ser feita a zona no Azure
responde certo a quem pergunta direto a ela e a ninguém que pergunta à internet.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l21-delegation\" aria-label=\"Como uma pergunta sobre shop.example chega ao Azure DNS. Um resolvedor pergunta à raiz, que o encaminha aos servidores de .example. Esses guardam a delegação que o registrador escreveu: quatro registros NS citando ns1-01.azure-dns.com, ns2-01.azure-dns.net, ns3-01.azure-dns.org e ns4-01.azure-dns.info. O resolvedor pergunta a um deles, e a zona shop.example no Azure DNS responde com os seus registros. Os números dos servidores de nomes são um exemplo.\"><defs><marker id=\"l21-delegation-af-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l21-delegation-af-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l21-delegation-af-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20.0\" y=\"110.0\" width=\"130.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"85.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">resolvedor</text><text x=\"85.0\" y=\"152.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">pergunta por você</text><rect x=\"230.0\" y=\"20.0\" width=\"160.0\" height=\"50.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"310.0\" y=\"45.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a raiz</text><rect x=\"230.0\" y=\"115.0\" width=\"160.0\" height=\"50.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"310.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">.example</text><text x=\"310.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">guarda a delegação</text><rect x=\"470.0\" y=\"20.0\" width=\"230.0\" height=\"260.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"585.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">Azure DNS</text><text x=\"585.0\" y=\"64.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">ns1-01.azure-dns.com</text><text x=\"585.0\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">ns2-01.azure-dns.net</text><text x=\"585.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">ns3-01.azure-dns.org</text><text x=\"585.0\" y=\"118.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">ns4-01.azure-dns.info</text><rect x=\"495.0\" y=\"150.0\" width=\"180.0\" height=\"112.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"585.0\" y=\"168.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">zona</text><text x=\"585.0\" y=\"186.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">shop.example</text><text x=\"585.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">@  A  (alias)</text><text x=\"585.0\" y=\"228.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">www  CNAME</text><text x=\"585.0\" y=\"246.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">@  MX  10</text><path d=\"M151.0 120.0 L229.0 52.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l21-delegation-af-ah-paper-dim)\"></path><text x=\"176.0\" y=\"76.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">1</text><path d=\"M151.0 140.0 L229.0 140.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l21-delegation-af-ah-paper-dim)\"></path><text x=\"190.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">2</text><path d=\"M151.0 160.0 L300.0 215.0 L494.0 205.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l21-delegation-af-ah-phosphor)\"></path><text x=\"300.0\" y=\"232.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">3  pergunta a um servidor da delegação</text><path d=\"M391.0 140.0 L469.0 100.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l21-delegation-af-ah-amber)\"></path><text x=\"400.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">NS</text></svg>", "caption": "Escritos no registrador, os quatro registros NS mandam todo resolvedor ao Azure.", "same": ["Azure DNS"]}
```

## A zona, em Bicep

Uma zona pública é um recurso com `location: 'global'`, porque o DNS não tem região, e cada conjunto
de registros é filho dela. Salve isto como `public.bicep` em `~/azure/dns`:

```bicep
resource zone 'Microsoft.Network/dnsZones@2018-05-01' = {
  name: 'shop.example'
  location: 'global'
}

resource pip 'Microsoft.Network/publicIPAddresses@2024-05-01' existing = {
  name: 'pip-shop-web'
}

resource apex 'Microsoft.Network/dnsZones/A@2018-05-01' = {
  parent: zone
  name: '@'
  properties: {
    TTL: 300
    targetResource: {
      id: pip.id
    }
  }
}

resource www 'Microsoft.Network/dnsZones/CNAME@2018-05-01' = {
  parent: zone
  name: 'www'
  properties: {
    TTL: 3600
    CNAMERecord: {
      cname: 'shop.example'
    }
  }
}

resource mx 'Microsoft.Network/dnsZones/MX@2018-05-01' = {
  parent: zone
  name: '@'
  properties: {
    TTL: 3600
    MXRecords: [
      {
        preference: 10
        exchange: 'mail.shop.example'
      }
    ]
  }
}

output nameServers array = zone.properties.nameServers
```

```
ana@laptop:~/azure/dns$ az bicep build --file public.bicep --stdout | jq -c '(.resources[] | {type, name}), .outputs'
{"type":"Microsoft.Network/dnsZones","name":"shop.example"}
{"type":"Microsoft.Network/dnsZones/A","name":"[format('{0}/{1}', 'shop.example', '@')]"}
{"type":"Microsoft.Network/dnsZones/CNAME","name":"[format('{0}/{1}', 'shop.example', 'www')]"}
{"type":"Microsoft.Network/dnsZones/MX","name":"[format('{0}/{1}', 'shop.example', '@')]"}
{"nameServers":{"type":"array","value":"[reference(resourceId('Microsoft.Network/dnsZones', 'shop.example'), '2018-05-01').nameServers]"}}
```

Quatro recursos: a zona e três **conjuntos de registros**. Um conjunto de registros é todos os
registros de um tipo num nome, e é por isso que há um conjunto `A` em `@` e um conjunto `MX` em `@`,
dois recursos com o mesmo nome e tipos diferentes. `@` quer dizer o topo da zona, o próprio
`shop.example`.

A saída `nameServers` é uma expressão, `reference(...)`, e não uma lista: **o Azure escolhe os quatro
servidores de nomes da zona quando ela é criada**, então ninguém, nem o compilador, sabe quais são
antes. Eles vêm de quatro domínios de topo diferentes, no formato `ns1-01.azure-dns.com`,
`ns2-01.azure-dns.net`, `ns3-01.azure-dns.org` e `ns4-01.azure-dns.info`, com números que mudam de
zona para zona. Quatro pais em vez de um quer dizer que uma falha no operador do `.com` não derruba
todas as zonas do Azure junto.

## A delegação, e como conferi-la

Com a zona criada, os quatro nomes vão para o formulário do registrador de `shop.example`, e o pai
começa a responder. **Nada disto foi executado**: não há zona, nem registrador. Na sua máquina, a
conferência para qualquer domínio delegado é o mesmo par de comandos:

```sh
dig NS shop.example +short
dig SOA shop.example +short
```

O primeiro lista os servidores de nomes que a internet recebeu, e eles precisam ser os quatro que o
Azure deu, todos os quatro. O segundo responde a partir da própria zona, e o primeiro campo é o nome de
um deles. Uma delegação que lista dois dos quatro funciona e é metade tão resistente; uma que lista os
servidores do próprio registrador quer dizer que a zona no Azure não está respondendo a ninguém.

**Mudar uma delegação é lento de propósito.** Os registros `NS` do pai têm um TTL, muitas vezes de dois
dias, e todo resolvedor que guardou a resposta antiga a mantém até o TTL acabar. Levar um domínio para o
Azure DNS se faz copiando antes todos os registros para a zona nova, conferindo-a com perguntas diretas
aos servidores novos com `dig @<servidor>`, e só então mudando o registrador.

## Registros alias, e o topo da zona

A tabela da seção anterior tinha uma regra: o topo de uma zona não pode ser um CNAME. Então o próprio
`shop.example` não pode ser "o endereço que o front end da loja tiver hoje"; ele precisa de um registro
`A`, e um endereço escrito num registro `A` está errado no dia em que o front end ganha outro.

**Um conjunto de registros alias é a saída do Azure.** Em vez de um valor, ele carrega
`targetResource`: o id de um recurso do Azure, aqui o IP público `pip-shop-web`, e o Azure DNS
responde com o endereço que esse recurso tiver no momento da pergunta. Na rede ele continua sendo um
registro `A`, então é permitido no topo; e quando o recurso é apagado, o registro não responde nada em
vez de apontar para um endereço que agora é de outra pessoa. Esse último caso tem nome, um **registro
pendurado**, e é como um subdomínio da própria empresa acaba servindo a página de um estranho.

Um alias pode apontar para um endereço IP público, para um perfil do Traffic Manager, para um endpoint
do Front Door, ou para outro conjunto de registros da mesma zona. O `www` do arquivo é um CNAME comum
para o topo, o que é permitido porque `www` não é o topo.
