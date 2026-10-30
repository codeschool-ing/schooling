---
title: Cortando o intervalo em sub-redes
version: 1
---

**Uma sub-rede é uma fatia do intervalo da VNet, e tudo o que recebe um endereço no Azure o recebe de
uma sub-rede.** A interface de rede de uma máquina, um private endpoint, o front end privado de um
balanceador de carga, um firewall: cada um é colocado numa sub-rede e pega um endereço dela. A
sub-rede também é onde as duas próximas lições prendem as suas regras: um network security group na
lição 17, uma tabela de rotas na lição 18. Então **uma sub-rede é a unidade de uma política**. Coisas
que precisam da mesma filtragem e das mesmas rotas dividem uma, e coisas que precisam de outras não.

A loja corta a `vnet-shop-prod` por camada, que é o corte de onde a maioria dos desenhos parte:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 360\" role=\"img\" data-fig=\"l16-subnets\" aria-label=\"A rede virtual vnet-shop-prod, 10.20.0.0/16, na região brazilsouth, desenhada sobre as três zonas de disponibilidade da região. Quatro sub-redes atravessam as três zonas: snet-web 10.20.1.0/24, snet-app 10.20.2.0/24, snet-data 10.20.3.0/24, delegada ao PostgreSQL, e snet-pe 10.20.4.0/24, para private endpoints. Cada uma oferece 251 endereços utilizáveis. O resto do intervalo fica livre.\"><rect x=\"16.0\" y=\"14.0\" width=\"688.0\" height=\"332.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"32.0\" y=\"32.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">região</text><text x=\"688.0\" y=\"32.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">brazilsouth</text><rect x=\"200.0\" y=\"46.0\" width=\"156.0\" height=\"286.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"278.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">zona 1</text><rect x=\"368.0\" y=\"46.0\" width=\"156.0\" height=\"286.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"446.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">zona 2</text><rect x=\"536.0\" y=\"46.0\" width=\"156.0\" height=\"286.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"614.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">zona 3</text><text x=\"36.0\" y=\"92.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">vnet-shop-prod</text><text x=\"36.0\" y=\"110.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">10.20.0.0/16</text><rect x=\"36.0\" y=\"128.0\" width=\"650.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"48.0\" y=\"145.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">snet-web</text><text x=\"150.0\" y=\"145.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10.20.1.0/24</text><text x=\"440.0\" y=\"145.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a camada web</text><text x=\"674.0\" y=\"145.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">251 utilizáveis</text><rect x=\"36.0\" y=\"174.0\" width=\"650.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"48.0\" y=\"191.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">snet-app</text><text x=\"150.0\" y=\"191.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10.20.2.0/24</text><text x=\"440.0\" y=\"191.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a aplicação</text><text x=\"674.0\" y=\"191.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">251 utilizáveis</text><rect x=\"36.0\" y=\"220.0\" width=\"650.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"48.0\" y=\"237.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">snet-data</text><text x=\"150.0\" y=\"237.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10.20.3.0/24</text><text x=\"440.0\" y=\"237.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">delegada ao PostgreSQL</text><text x=\"674.0\" y=\"237.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">251 utilizáveis</text><rect x=\"36.0\" y=\"266.0\" width=\"650.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"48.0\" y=\"283.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">snet-pe</text><text x=\"150.0\" y=\"283.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10.20.4.0/24</text><text x=\"440.0\" y=\"283.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">private endpoints, lição 19</text><text x=\"674.0\" y=\"283.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">251 utilizáveis</text><text x=\"360.0\" y=\"322.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">o resto do intervalo fica livre para o que ninguém planejou ainda</text></svg>", "caption": "Uma rede, quatro sub-redes, e cada sub-rede nas três zonas ao mesmo tempo."}
```

## Cinco endereços nunca são seus

**O Azure tira cinco endereços de toda sub-rede, seja qual for o tamanho**: os quatro primeiros e o
último.

| endereço em `snet-app` | para que o Azure o usa |
|---|---|
| `10.20.2.0` | o endereço de rede |
| `10.20.2.1` | o gateway padrão, a porta da sub-rede para todo o resto |
| `10.20.2.2` e `10.20.2.3` | para mapear o DNS do Azure dentro da rede |
| `10.20.2.255` | o endereço de broadcast, embora o Azure não transporte broadcast |

Então um `/24` guarda 256 endereços e oferece 251, e a menor sub-rede que o Azure permite, um `/29`,
oferece três dos seus oito. A conta é curta e fácil de errar com pressa, então o plano é conferido
por um programa. Salve isto como `~/azure/vnet/plan.py`:

```schooling-example
{"language": "python", "file": "plan.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"plan.py VNET NAME=RANGE ...: check a subnet plan against a VNet, counting addresses Azure's way.\"\"\"\nimport ipaddress\nimport sys\n\nRESERVED = 5\n\n\n", "note": "Só a biblioteca padrão. `RESERVED` é o número de endereços que o Azure tira de **toda** sub-rede, seja qual for o tamanho: os quatro primeiros e o último."}, {"code": "def subnet(vnet, arg, taken):\n    name, _, text = arg.partition('=')\n    try:\n        net = ipaddress.ip_network(text)\n    except ValueError as e:\n        return f'{name}: refused, {e}'\n", "note": "O `ip_network` recusa um intervalo que não começa na sua própria fronteira, como `10.20.7.0/23`, e diz isso. O Azure também o recusa."}, {"code": "    if not net.subnet_of(vnet):\n        return f'{name}: refused, {net} is not inside {vnet}'\n    for other, used in taken:\n        if net.overlaps(used):\n            return f'{name}: refused, {net} overlaps {other} ({used})'\n    if net.prefixlen > 29:\n        return f'{name}: refused, /{net.prefixlen} is smaller than the /29 Azure allows'\n", "note": "As três regras que o Azure aplica a uma sub-rede: dentro do intervalo da rede, sem se sobrepor a nenhuma outra sub-rede, e não menor que um `/29`, oito endereços dos quais três são utilizáveis."}, {"code": "    taken.append((name, net))\n    first, last = net.network_address + 4, net.broadcast_address - 1\n    return f'{name:<20}{str(net):<16}{str(first):<15}{str(last):<15}{net.num_addresses - RESERVED:>6}'\n\n\n", "note": "O primeiro endereço que uma máquina pode receber é o quinto do intervalo, e o último é o anterior ao fim. O que se imprime é o que sobra para usar."}, {"code": "def main():\n    vnet = ipaddress.ip_network(sys.argv[1])\n    taken = []\n    print(f'{\"subnet\":<20}{\"range\":<16}{\"first usable\":<15}{\"last usable\":<15}{\"usable\":>6}')\n    for arg in sys.argv[2:]:\n        print(subnet(vnet, arg, taken))\n    left = vnet.num_addresses - sum(n.num_addresses for _, n in taken)\n    print(f'{vnet} holds {vnet.num_addresses} addresses; {left} are in no subnet yet')\n\n\nmain()\n", "note": "Uma linha por sub-rede, na ordem dada, e uma última linha com o que resta da rede para as sub-redes em que ninguém pensou ainda."}]}
```

Dê a ele o intervalo de produção e as quatro camadas:

```
ana@laptop:~/azure/vnet$ python3 plan.py 10.20.0.0/16 snet-web=10.20.1.0/24 snet-app=10.20.2.0/24 snet-data=10.20.3.0/24 snet-pe=10.20.4.0/24
subnet              range           first usable   last usable    usable
snet-web            10.20.1.0/24    10.20.1.4      10.20.1.254       251
snet-app            10.20.2.0/24    10.20.2.4      10.20.2.254       251
snet-data           10.20.3.0/24    10.20.3.4      10.20.3.254       251
snet-pe             10.20.4.0/24    10.20.4.4      10.20.4.254       251
10.20.0.0/16 holds 65536 addresses; 64512 are in no subnet yet
```

**Quatro `/24` usam menos de 2% de um `/16`**, e isso é de propósito. Uma sub-rede só pode ser
redimensionada enquanto está vazia, então a hora barata de deixar espaço é agora: os 64.512 endereços
que sobram são onde vão entrar uma quinta camada, uma camada web maior ou um serviço que exige uma
sub-rede só dele. O intervalo `10.20.0.0/24` também fica sem uso de propósito, para que a primeira
sub-rede que ninguém planejou tenha uma casa óbvia, e a lição 22 pega o seguinte, `10.20.5.0/24`, como
`snet-agw` para o Application Gateway da loja.

Depois, um plano com quatro erros, do tipo que cada um já cometeu uma vez com pressa:

```
ana@laptop:~/azure/vnet$ python3 plan.py 10.20.0.0/16 snet-web=10.20.1.0/24 snet-cache=10.20.1.128/25 snet-jobs=10.20.7.0/23 snet-tiny=10.20.9.0/30 snet-batch=10.30.0.0/24
subnet              range           first usable   last usable    usable
snet-web            10.20.1.0/24    10.20.1.4      10.20.1.254       251
snet-cache: refused, 10.20.1.128/25 overlaps snet-web (10.20.1.0/24)
snet-jobs: refused, 10.20.7.0/23 has host bits set
snet-tiny: refused, /30 is smaller than the /29 Azure allows
snet-batch: refused, 10.30.0.0/24 is not inside 10.20.0.0/16
10.20.0.0/16 holds 65536 addresses; 65280 are in no subnet yet
```

A `snet-cache` cai dentro da `snet-web`. `10.20.7.0/23` não começa onde um `/23` pode começar, que é
num terceiro número par. Um `/30` está abaixo do mínimo do Azure. E `10.30.0.0/24` é o intervalo de
staging, fora desta rede. **O próprio Azure também recusaria cada um destes**, no momento de criar a
sub-rede; o programa diz isso antes de alguém perguntar.

## Sub-redes com nomes que o Azure escolhe

Alguns serviços exigem uma sub-rede só deles, com **um nome que eles decidem** e um tamanho mínimo. A
rede hub da loja tem três delas, que as lições 18 e 23 preenchem:

```
ana@laptop:~/azure/vnet$ python3 plan.py 10.0.0.0/16 AzureFirewallSubnet=10.0.1.0/26 AzureBastionSubnet=10.0.2.0/26 GatewaySubnet=10.0.255.0/27
subnet              range           first usable   last usable    usable
AzureFirewallSubnet 10.0.1.0/26     10.0.1.4       10.0.1.62          59
AzureBastionSubnet  10.0.2.0/26     10.0.2.4       10.0.2.62          59
GatewaySubnet       10.0.255.0/27   10.0.255.4     10.0.255.30        27
10.0.0.0/16 holds 65536 addresses; 65376 are in no subnet yet
```

| sub-rede | ela guarda | o tamanho pedido |
|---|---|---|
| `AzureFirewallSubnet` | o Azure Firewall, lição 18 | pelo menos um `/26` |
| `AzureBastionSubnet` | o Azure Bastion, o serviço que abre uma sessão remota numa máquina sem endereço público | pelo menos um `/26` |
| `GatewaySubnet` | os gateways de VPN e de ExpressRoute, lição 23 | um `/27` ou maior é o conselho da Microsoft |

**O nome é o contrato**: um firewall implantado numa sub-rede chamada `snet-firewall` é recusado, por
maior que ela seja. Os nomes se escrevem exatamente como na tabela, maiúsculas incluídas, e nada mais
pode ser colocado nessas sub-redes.
