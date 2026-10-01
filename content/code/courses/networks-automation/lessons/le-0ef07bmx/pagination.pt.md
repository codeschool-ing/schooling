---
title: Paginação
version: 1
---

Uma lista pode ser mais longa do que uma resposta deveria carregar. A tabela de roteamento de um
roteador pode ter um milhão de rotas; um controlador pode gerenciar dez mil equipamentos. **Por
isso um recurso de lista responde uma página de cada vez**, e diz como pedir a próxima:

```
ana@ctl:~$ curl -s --cacert lab-ca.pem -H "Authorization: Bearer $(cat .token)" "https://edge1.example.net/api/v1/interfaces?limit=2"
{
  "count": 4,
  "next": "https://edge1.example.net/api/v1/interfaces?limit=2&offset=2",
  "previous": null,
  "results": [
    {
      "name": "eth0",
      "description": "",
      "enabled": true,
      "oper_status": "up",
      "mtu": 1500,
      "mac_address": "52:54:00:00:02:0c",
      "addresses": [
        "192.0.2.12/24"
      ]
    },
    {
      "name": "eth1",
      "description": "uplink to core1",
      "enabled": true,
      "oper_status": "up",
      "mtu": 1500,
      "mac_address": "52:54:00:33:64:02",
      "addresses": [
        "198.51.100.2/30"
      ]
    }
  ]
}
```

`count` é o total, 4. `results` contém esta página, duas interfaces porque a requisição pediu
`limit=2`. `next` é o endereço da página seguinte, e `previous` o da anterior; a primeira página
não tem anterior, então ele é `null`.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"Lendo quatro interfaces de duas em duas. O cliente pede limit=2 e recebe eth0 e eth1, um count de 4 e um link next com offset=2. Ele pede esse link e recebe eth2 e lo, com next igual a null, e é assim que sabe que tem tudo.\"><defs><marker id=\"pg-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"150\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">o script da ana no ctl</text><text x=\"570\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">a API do edge1</text><path d=\"M150 38 L150 318\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M570 38 L570 318\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M152 64 L566 78\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pg-ah)\"></path><text x=\"360\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">GET /interfaces?limit=2</text><path d=\"M568 104 L154 118\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pg-ah)\"></path><rect x=\"200\" y=\"124\" width=\"320\" height=\"58\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"137.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">página 1 de 2</text><text x=\"360.0\" y=\"153.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">&quot;count&quot;: 4,  results: eth0, eth1</text><text x=\"360.0\" y=\"169.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">&quot;next&quot;: &quot;…?limit=2&amp;offset=2&quot;</text><path d=\"M152 198 L566 212\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pg-ah)\"></path><text x=\"360\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">GET /interfaces?limit=2&amp;offset=2</text><path d=\"M568 238 L154 252\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pg-ah)\"></path><rect x=\"200\" y=\"258\" width=\"320\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"275.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">página 2 de 2</text><text x=\"360.0\" y=\"291.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">results: eth2, lo   &quot;next&quot;: null</text><text x=\"20\" y=\"283\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">null: parar</text></svg>", "caption": "Duas requisições para quatro interfaces. O cliente segue next até ele ser null, e nunca calcula um offset por conta própria."}
```

Esse estilo se chama **paginação por offset**: `offset` diz quantos itens pular. É o que o
NetBox usa na aula 12, e muitos controladores fazem o mesmo. Outras APIs paginam com um
**cursor**, uma string opaca que o servidor devolve, ou com um cabeçalho `Link` em vez de um
campo no corpo. A regra para o cliente é a mesma em todas elas: **siga o link que o servidor te
dá, e não monte o próximo endereço você mesmo.** Um cliente que calcula `offset=2` sozinho quebra
no dia em que o servidor muda o jeito de paginar; um que segue `next` nem percebe.

`Device.all` em `devapi.py` é essa regra como um generator: ele entrega os itens de uma página,
depois busca `next`, até `next` ser `null`. Quem chama vê um fluxo de rotas e nunca uma página:

```schooling-example
{
  "language": "python",
  "file": "routes.py",
  "parts": [
    {
      "code": "from devapi import Device\n\nedge1 = Device(\"edge1\")"
    },
    {
      "code": "for route in edge1.all(\"/routes\", limit=3):\n    hops = \", \".join(h.get(\"ip\") or h[\"interface\"] for h in route[\"next_hops\"])\n    mark = \">\" if route[\"selected\"] else \" \"\n    print(f\"{mark} {route['prefix']:<18} {route['protocol']:<10} via {hops}\")",
      "note": "**`limit=3` pede páginas pequenas**, para que o punhado de rotas do laboratório precise de várias. O laço não sabe quantas páginas houve."
    }
  ]
}
```

```
ana@ctl:~$ python routes.py
  192.0.2.0/24       ospf       via 198.51.100.1
> 192.0.2.0/24       connected  via eth0
> 192.0.2.128/25     static     via 198.51.100.1
  198.51.100.0/30    ospf       via eth1
> 198.51.100.0/30    connected  via eth1
> 198.51.100.4/30    ospf       via 198.51.100.1
  203.0.113.0/26     ospf       via eth2
> 203.0.113.0/26     connected  via eth2
> 203.0.113.64/26    ospf       via 198.51.100.1
> 203.0.113.251/32   ospf       via 198.51.100.1
> 203.0.113.252/32   connected  via lo
> 203.0.113.253/32   ospf       via 198.51.100.1
```

A tabela de roteamento levou várias páginas com `limit=3`, e o script não precisou saber
quantas. As linhas marcadas com `>` são as rotas que o FRR selecionou. Os prefixos duplicados são
reais: o `edge1` conhece `198.51.100.0/30` tanto como conectada quanto pelo OSPF, e a rota
conectada vence.

**O tamanho da página é escolha do cliente dentro dos limites do servidor.** Esta API permite de
1 a 100 e usa 50 por padrão. Uma página menor custa mais requisições; uma maior custa memória dos
dois lados. E uma lista que muda enquanto está sendo lida pode mover um item de uma página para
outra, então um programa cuidadoso trata uma leitura paginada como uma visão de um momento e não
como uma transação.
