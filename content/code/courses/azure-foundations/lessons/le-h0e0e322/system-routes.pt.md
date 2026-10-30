---
title: Rotas de sistema, e como uma é escolhida
version: 1
---

**Toda sub-rede no Azure tem uma tabela de rotas antes de alguém escrever uma.** O Azure a enche de
**rotas de sistema**, e elas são o motivo de a rede da lição 16 ter funcionado sem nada configurado:
uma máquina na `snet-app` alcança a `snet-data` porque uma rota de sistema diz que o intervalo da
própria rede é local, e alcança a internet porque outra diz que todo o resto vai para lá. As rotas não
têm aparelho por trás: não há roteador em que entrar, e o `10.20.2.1`, o endereço de gateway da
sub-rede, é respondido pela própria rede do Azure.

As rotas de sistema de uma sub-rede da `vnet-shop-prod` são estas:

| prefixo | próximo salto | o que diz |
|---|---|---|
| `10.20.0.0/16` | rede virtual | o intervalo da própria rede fica dentro dela |
| `0.0.0.0/0` | internet | tudo o que não casa com um prefixo mais longo sai |
| `10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16`, `100.64.0.0/10` | nenhum | intervalos privados que ninguém reivindicou são descartados, não mandados à internet |

e mais rotas aparecem conforme a rede cresce: uma para cada rede com peering na lição 20, rotas
aprendidas de um gateway de VPN ou de ExpressRoute na lição 23, rotas para os service endpoints da
lição 19.

**Um próximo salto `None` descarta o pacote.** Essa linha é fácil de pular na leitura e é uma regra
de segurança: um erro de digitação que manda tráfego para `10.99.0.1`, um endereço de rede nenhuma, é
jogado fora dentro do Azure em vez de ser oferecido à internet.

## Prefixo mais longo, depois a origem

Quando várias rotas contêm o destino, o Azure escolhe uma em dois passos:

1. **o prefixo mais longo vence**: uma rota para `10.20.0.0/16` vence uma para `10.0.0.0/8`, que vence
   `0.0.0.0/0`, porque um prefixo mais longo descreve o destino com mais exatidão;
2. **entre rotas com o mesmo prefixo, uma rota definida pelo usuário vence uma aprendida por BGP, que
   vence uma rota de sistema.** É assim que alguém substitui a rota de sistema de `0.0.0.0/0`:
   escrevendo uma rota com o mesmo prefixo.

Uma exceção está na documentação da Microsoft e importa mais adiante: rotas de sistema da própria
rede, de redes com peering e de service endpoints têm preferência até sobre uma rota mais específica
aprendida por BGP. Um escritório não consegue tomar o intervalo da própria loja anunciando um prefixo
mais longo dele.

## Perguntando ao modelo

O Azure mostra as rotas combinadas de uma máquina como as **effective routes** dela, e o *next hop*
do Network Watcher responde para um destino; os dois precisam de uma máquina no Azure. O laboratório
tem um modelo no lugar. Crie o diretório da lição e salve isto como `~/azure/routes/route.py`:

```sh
mkdir -p ~/azure/routes && cd ~/azure/routes
```

```schooling-example
{"language": "python", "file": "route.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"route.py ROUTE-TABLE DEST: the course's model of how Azure picks a route out of snet-app.\n\nA model of Azure's documented rules, not Azure. ROUTE-TABLE is a compiled template, or - for none.\"\"\"\nimport ipaddress\nimport json\nimport sys\n\n", "note": "**O modelo do curso, não o Azure**: ele aplica o jeito documentado de escolher uma rota a uma sub-rede, a `snet-app`, e lê a sua tabela de rotas de um template compilado."}, {"code": "SYSTEM = [\n    ('Default', '10.20.0.0/16', 'VnetLocal', ''),\n    ('Default', '10.0.0.0/16', 'VNetPeering', ''),\n    ('Default', '0.0.0.0/0', 'Internet', ''),\n    ('Default', '10.0.0.0/8', 'None', ''),\n    ('Default', '172.16.0.0/12', 'None', ''),\n    ('Default', '192.168.0.0/16', 'None', ''),\n    ('Default', '100.64.0.0/10', 'None', ''),\n]\n", "note": "As rotas de sistema que o Azure dá a toda sub-rede da `vnet-shop-prod`: o próprio intervalo, o hub com que ela vai fazer peering na lição 20, a internet para todo o resto, e `None`, que descarta o pacote, para os intervalos privados que ninguém reivindicou."}, {"code": "RANK = {'User': 0, 'BGP': 1, 'Default': 2}\n\n\n", "note": "Quando duas rotas têm o mesmo prefixo, uma rota definida pelo usuário vence uma aprendida por BGP, que vence uma rota de sistema."}, {"code": "def user_routes(path):\n    if path == '-':\n        return []\n    template = json.load(open(path))\n    table = next(r for r in template['resources']\n                 if r['type'] == 'Microsoft.Network/routeTables')\n    found = []\n    for r in table['properties']['routes']:\n        p = r['properties']\n        ip = p.get('nextHopIpAddress', '')\n        if ip.startswith(\"[parameters('\"):\n            ip = template['parameters'][ip[13:-3]]['defaultValue']\n        found.append(('User', p['addressPrefix'], p['nextHopType'], ip))\n    return found\n\n\n", "note": "Transforma as rotas de uma tabela compilada no mesmo formato. Um próximo salto escrito como parâmetro é lido do valor padrão do parâmetro, que é o que uma implantação sem sobrescrita usaria."}, {"code": "def main():\n    dest = ipaddress.ip_address(sys.argv[2])\n    routes = user_routes(sys.argv[1]) + SYSTEM\n    found = [r for r in routes if dest in ipaddress.ip_network(r[1])]\n    found.sort(key=lambda r: (-ipaddress.ip_network(r[1]).prefixlen, RANK[r[0]]))\n    for i, (source, prefix, hop, ip) in enumerate(found):\n        mark = 'chosen' if i == 0 else ''\n        print(f'{source:<8}{prefix:<16}{hop:<17}{ip:<10}{mark}'.rstrip())\n\n\nmain()\n", "note": "Fica com as rotas cujo prefixo contém o destino, ordena **o prefixo mais longo primeiro** e depois pela origem, e marca a primeira. Toda rota que casou é impressa, para você ver quem a vencedora venceu."}]}
```

Sem tabela de rotas sua, `-`, pergunte para onde vai um pacote destinado a um endereço da internet:

```
ana@laptop:~/azure/routes$ python3 route.py - 203.0.113.80
Default 0.0.0.0/0       Internet                   chosen
```

Direto para fora, pela única rota que o contém: **a rota para a internet está lá antes de alguém
escrever uma**, o mesmo tipo de padrão que a lição 17 encontrou nas regras de NSG. Se uma máquina
consegue usá-la é outra pergunta, a que a lição 16 respondeu com sub-redes privadas: nas sub-redes da
loja uma máquina não tem endereço próprio com que sair, então a rota não leva a lugar nenhum até
existir uma saída explícita. A próxima seção faz dessa saída o firewall, e escreve a tabela de rotas
que manda tudo para ele.
