---
title: Seguindo um pacote pelas regras
version: 1
---

**A pergunta que um NSG responde é sempre sobre um pacote: daqui, para lá, nesta porta, a primeira
regra que casa é um allow?** O Azure a responde com uma ferramenta chamada IP flow verify, no Network
Watcher, e mostra a lista combinada de uma máquina como as *effective security rules* dela. As duas
precisam de uma máquina no Azure. O que o laboratório consegue fazer é seguir à mão as mesmas regras
documentadas, e um programa curto as segue mais depressa que uma pessoa.

Salve isto como `~/azure/nsg/nsg.py`:

```schooling-example
{"language": "python", "file": "nsg.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"nsg.py TEMPLATE SOURCE DEST PORT: the course's model of one NSG judging an inbound TCP packet.\n\nA model of Azure's documented rules, not Azure: it reads the NSG out of a compiled template.\"\"\"\nimport ipaddress\nimport json\nimport re\nimport sys\n\nVNET = ipaddress.ip_network('10.20.0.0/16')\nPROBE = ipaddress.ip_address('168.63.129.16')\nMEMBERS = {'10.20.1.4': 'asg-shop-web', '10.20.1.5': 'asg-shop-web', '10.20.2.4': 'asg-shop-app'}\n\n", "note": "**Este é o modelo do curso, não o Azure.** Ele lê um NSG de um template compilado e segue as regras que a Microsoft documenta. `VNET` é a rede da loja, `PROBE` o endereço de onde vêm as sondas de saúde do Azure, e `MEMBERS` faz o papel das interfaces que o Azure saberia estarem em cada ASG: aqui, dois servidores web e um servidor de aplicação."}, {"code": "DEFAULTS = [\n    {'name': 'AllowVnetInBound', 'priority': 65000, 'access': 'Allow',\n     'source': 'VirtualNetwork', 'dest': 'VirtualNetwork', 'port': '*'},\n    {'name': 'AllowAzureLoadBalancerInBound', 'priority': 65001, 'access': 'Allow',\n     'source': 'AzureLoadBalancer', 'dest': '*', 'port': '*'},\n    {'name': 'DenyAllInBound', 'priority': 65500, 'access': 'Deny',\n     'source': '*', 'dest': '*', 'port': '*'},\n]\n\n\n", "note": "As três regras padrão de entrada, nas prioridades que o Azure dá a elas. Todo NSG as tem, então o modelo as acrescenta ao que o template disser."}, {"code": "def side(p, which):\n    groups = p.get(which + 'ApplicationSecurityGroups')\n    if groups:\n        return 'asg:' + re.findall(r\"'([^']+)'\", groups[0]['id'])[-1]\n    return p.get(which + 'AddressPrefix', '*')\n\n\n", "note": "Um lado de uma regra é um ASG ou um prefixo de endereço. No template, um ASG é uma expressão `resourceId(...)`, e a última palavra entre aspas é o nome dele."}, {"code": "def rules(path):\n    template = json.load(open(path))\n    nsg = next(r for r in template['resources']\n               if r['type'] == 'Microsoft.Network/networkSecurityGroups')\n    found = []\n    for r in nsg['properties']['securityRules']:\n        p = r['properties']\n        if p['direction'] == 'Inbound' and p['protocol'] in ('Tcp', '*'):\n            found.append({'name': r['name'], 'priority': p['priority'], 'access': p['access'],\n                          'source': side(p, 'source'), 'dest': side(p, 'destination'),\n                          'port': p['destinationPortRange']})\n    return sorted(found + DEFAULTS, key=lambda r: r['priority'])\n\n\n", "note": "Fica com as regras de entrada que podem casar com TCP, acrescenta as padrão e ordena pela prioridade: a ordem em que o Azure as lê."}, {"code": "def matches(spec, ip):\n    if spec == '*':\n        return True\n    if spec.startswith('asg:'):\n        return MEMBERS.get(str(ip)) == spec[4:]\n    if spec == 'VirtualNetwork':\n        return ip in VNET or ip == PROBE\n    if spec == 'AzureLoadBalancer':\n        return ip == PROBE\n    if spec[0].isdigit():\n        return ip in ipaddress.ip_network(spec)\n    sys.exit(f'the model does not know the service tag {spec}')\n\n\n", "note": "Como cada tipo de origem ou destino casa com um endereço. `VirtualNetwork` é a rede mais o endereço do host `168.63.129.16`, como a documentação diz; a tag de verdade também inclui redes com peering e escritórios, que esta rede ainda não tem. Uma tag que o modelo não conhece o faz parar em vez de chutar."}, {"code": "def main():\n    path, port = sys.argv[1], sys.argv[4]\n    src, dst = ipaddress.ip_address(sys.argv[2]), ipaddress.ip_address(sys.argv[3])\n    for r in rules(path):\n        hit = matches(r['source'], src) and matches(r['dest'], dst) and r['port'] in ('*', port)\n        print(f\"{r['priority']:>6}  {r['name']:<31}{r['access'] if hit else '-'}\")\n        if hit:\n            return\n\n\nmain()\n", "note": "Lê as regras em ordem, imprime cada uma com a decisão ou um traço, e **para no primeiro casamento**, que é tudo o que um NSG faz."}]}
```

## O rascunho, e a porta que ele deixa aberta

Comece de um rascunho do NSG com só a primeira regra, a que deixa a camada web entrar na 8080. O `jq`
remove as duas regras seguintes do template compilado, que é como o arquivo era antes de elas serem
escritas:

```
ana@laptop:~/azure/nsg$ jq 'del(.resources[2].properties.securityRules[1,2])' nsg.json > draft.json && python3 nsg.py draft.json 10.20.1.4 10.20.2.4 8080
   100  AllowWebToApp                  Allow
```

Um servidor web alcançando a aplicação na 8080: a regra 100 casou, que é para isso que foi escrita.
Agora o mesmo servidor web tentando SSH na porta 22:

```
ana@laptop:~/azure/nsg$ python3 nsg.py draft.json 10.20.1.4 10.20.2.4 22
   100  AllowWebToApp                  -
 65000  AllowVnetInBound               Allow
```

**Permitido, por uma regra que ninguém na loja escreveu.** O `AllowVnetInBound` em 65000 deixa
qualquer coisa da rede alcançar qualquer coisa da rede em qualquer porta, e o rascunho nunca disse o
contrário. Um servidor web tomado por um atacante poderia alcançar o SSH da aplicação, as portas de
depuração, qualquer coisa que esteja escutando. É por isso que o NSG da loja fecha a porta em 4000.

## O deny, e a sonda que ele pegou

Com o deny em 4000 e sem a regra em 3900, que é o template menos a segunda regra, pergunte sobre o
pacote que o balanceador de carga do Azure manda para conferir se a aplicação está viva:

```
ana@laptop:~/azure/nsg$ jq 'del(.resources[2].properties.securityRules[1])' nsg.json > noprobe.json && python3 nsg.py noprobe.json 168.63.129.16 10.20.2.4 8080
   100  AllowWebToApp                  -
  4000  DenyVnetInBound                Deny
```

**Negado, em 4000, e a regra padrão das sondas em 65001 nunca teve a vez.** A documentação da
Microsoft lista o `168.63.129.16` dentro de `VirtualNetwork`, então um deny em `VirtualNetwork` pega a
sonda também, e um balanceador cujas sondas falham marca todas as máquinas como doentes e não manda
tráfego para nenhuma. O modelo segue a documentação aqui; **o efeito não foi observado no Azure**, já
que nada neste curso roda lá. O remédio é um allow para `AzureLoadBalancer` acima do deny, que é a
regra em 3900 do arquivo de verdade:

```
ana@laptop:~/azure/nsg$ python3 nsg.py nsg.json 168.63.129.16 10.20.2.4 8080
   100  AllowWebToApp                  -
  3900  AllowLoadBalancerProbe         Allow
```

## Mais três pacotes

SSH a partir do servidor web de novo, um pedido da internet direto na aplicação, e um servidor web
alcançando uma máquina de aplicação nova, `10.20.2.5`, que alguém construiu e esqueceu de pôr no
`asg-shop-app`:

```
ana@laptop:~/azure/nsg$ python3 nsg.py nsg.json 10.20.1.4 10.20.2.4 22
   100  AllowWebToApp                  -
  3900  AllowLoadBalancerProbe         -
  4000  DenyVnetInBound                Deny
ana@laptop:~/azure/nsg$ python3 nsg.py nsg.json 203.0.113.50 10.20.2.4 8080
   100  AllowWebToApp                  -
  3900  AllowLoadBalancerProbe         -
  4000  DenyVnetInBound                -
 65000  AllowVnetInBound               -
 65001  AllowAzureLoadBalancerInBound  -
 65500  DenyAllInBound                 Deny
ana@laptop:~/azure/nsg$ python3 nsg.py nsg.json 10.20.1.4 10.20.2.5 8080
   100  AllowWebToApp                  -
  3900  AllowLoadBalancerProbe         -
  4000  DenyVnetInBound                Deny
```

O primeiro para em 4000, onde deve. O segundo percorre a lista inteira até o `DenyAllInBound`: a
internet nunca teve um caminho para dentro, e a camada de aplicação não precisa de um, porque os
clientes chegam à camada web por um balanceador de carga e só a camada web alcança a aplicação. **O
terceiro é o que vale lembrar**: uma máquina fora do seu ASG não é alcançada pela regra escrita para o
papel dela, e o deny a pega. A regra estava certa; a participação estava errada, e o sintoma é um
servidor de aplicação que a camada web não enxerga. Quando uma regra que cita um ASG parece não
funcionar, olhe a interface antes da regra.
