---
title: Rotas, e qual delas um pacote toma
version: 1
---

**Uma rota diz para onde vão em seguida os pacotes de uma faixa de endereços.** Toda rede tem uma tabela delas,
global como a rede, e todo pacote saindo de uma máquina é comparado com ela. Três tipos enchem a tabela:

| tipo | feita por | exemplo |
|---|---|---|
| **rotas de sub-rede** | o Google, uma por faixa de sub-rede, enquanto a sub-rede existir | `10.10.0.0/20`, para a própria sub-rede |
| **a rota padrão** | o Google, quando a rede é feita; pode ser apagada | `0.0.0.0/0`, para `default-internet-gateway` |
| **rotas personalizadas** | uma pessoa: rotas **estáticas** escritas à mão, ou rotas **dinâmicas** aprendidas por um Cloud Router via BGP, lição 21 | `192.168.0.0/16`, para um túnel VPN |

O **gateway padrão de internet** não é uma máquina. É o nome da saída da rede rumo a endereços fora dela, a
internet e as próprias APIs públicas do Google entre eles, e uma rota apontando para ele é o que deixa um pacote
sair.

## Que rota decide

Para cada pacote, as rotas cujo destino contém o endereço são candidatas, e **o destino mais específico ganha**:
um `/20` ganha de um `/16`, que ganha de `/0`. Só entre rotas com o mesmo destino a **prioridade** conta, menor
número primeiro, a mesma regra da lição 16. Duas rotas personalizadas com o mesmo destino e a mesma prioridade
dividem o tráfego entre os próximos saltos delas. Numa rede comum, uma rota de sub-rede é por onde a própria
faixa dela é alcançada: os endereços de uma sub-rede são alcançados dentro da rede.

Salve a tabela do planner como `~/gcp/routes/routes.json`. Ela tem as duas sub-redes da lição 15, a rota padrão,
uma rota para a faixa privada de APIs do Google, e duas rotas para o escritório por dois túneis VPN, a segunda
ali para o caso de a primeira falhar:

```sh
mkdir -p ~/gcp/routes && cd ~/gcp/routes
```

```json
[
  {"name": "default-route", "kind": "default", "dest": "0.0.0.0/0", "priority": 1000,
   "next_hop": "default-internet-gateway"},
  {"name": "planner-sao-paulo", "kind": "subnet", "dest": "10.10.0.0/20", "next_hop": "the subnet"},
  {"name": "planner-santiago", "kind": "subnet", "dest": "10.11.0.0/20", "next_hop": "the subnet"},
  {"name": "private-googleapis", "kind": "static", "dest": "199.36.153.8/30", "priority": 1000,
   "next_hop": "default-internet-gateway"},
  {"name": "office-primary", "kind": "static", "dest": "192.168.0.0/16", "priority": 100,
   "next_hop": "tunnel office-1"},
  {"name": "office-backup", "kind": "static", "dest": "192.168.0.0/16", "priority": 200,
   "next_hop": "tunnel office-2"}
]
```

E o programa que escolhe uma rota, como `route.py`:

```schooling-example
{"language": "python", "file": "route.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"Picks the route a packet leaving a machine would take, as Google does.\n\n    python3 route.py ADDRESS [ADDRESS ...]\n\nThe network's routes are read from routes.json.\n\"\"\"\nimport ipaddress\nimport json\nimport sys\n\n", "note": "Como é chamado: um ou mais endereços de destino, cada um respondido com a rota pela qual um pacote para ele sairia."}, {"code": "routes = json.load(open('routes.json'))\nfor r in routes:\n    r['net'] = ipaddress.ip_network(r['dest'])\n\n", "note": "Ler as rotas da rede, e transformar cada destino numa rede com que a biblioteca padrão consiga comparar endereços."}, {"code": "def best(address):\n    found = [r for r in routes if address in r['net']]\n    if not found:\n        return None\n    longest = max(r['net'].prefixlen for r in found)\n    found = [r for r in found if r['net'].prefixlen == longest]\n    subnet = [r for r in found if r['kind'] == 'subnet']\n    return subnet[0] if subnet else min(found, key=lambda r: r['priority'])\n\n", "note": "A ordem do Google. As rotas cujo destino contém o endereço; delas, a mais específica, o prefixo mais longo; entre iguais, uma rota de sub-rede antes de qualquer outra, e senão o menor número de prioridade. Nenhuma rota significa que o pacote é descartado."}, {"code": "for arg in sys.argv[1:]:\n    route = best(ipaddress.ip_address(arg))\n    if route is None:\n        print(f'{arg:15} no route: dropped')\n    else:\n        print(f\"{arg:15} {route['dest']:16} {route['name']:19} -> {route['next_hop']}\")\n", "note": "Uma linha por endereço: o destino que casou, o nome da rota, e para onde ela manda o pacote."}]}
```

Quatro destinos: uma máquina em Santiago, um endereço público, um dos endereços privados de API do Google, e
uma máquina no escritório:

```
ana@laptop:~/gcp/routes$ python3 route.py 10.11.3.4 8.8.8.8 199.36.153.9 192.168.4.20
10.11.3.4       10.11.0.0/20     planner-santiago    -> the subnet
8.8.8.8         0.0.0.0/0        default-route       -> default-internet-gateway
199.36.153.9    199.36.153.8/30  private-googleapis  -> default-internet-gateway
192.168.4.20    192.168.0.0/16   office-primary      -> tunnel office-1
```

O endereço do escritório casou com duas rotas com o mesmo `/16`, e **a prioridade escolheu o túnel primário**.
Se a `office-primary` sumisse, a `office-backup` assumiria sem ninguém mudar nada, e é para isso que servem as
prioridades diferentes.

## Uma rede sem saída

A produção do planner não tem por que alcançar a internet diretamente, então a rede dela apaga a rota padrão.
Faça o mesmo com a tabela:

```
ana@laptop:~/gcp/routes$ jq 'map(select(.name != "default-route"))' routes.json > r.json && mv r.json routes.json
ana@laptop:~/gcp/routes$ python3 route.py 8.8.8.8 199.36.153.9
8.8.8.8         no route: dropped
199.36.153.9    199.36.153.8/30  private-googleapis  -> default-internet-gateway
```

**O endereço público agora não tem rota e é descartado, e a faixa de APIs do Google ainda sai**, pela rota
própria com o seu `/30`. Essa rota é o motivo de a tabela a ter: uma máquina que alcança o Cloud Storage ou o
Pub/Sub sem endereço público faz isso também pelo gateway padrão de internet, e apagar a rota padrão sem repor
essa parte dela corta a produção dos próprios serviços do Google. A última seção desta lição é sobre essa faixa.
