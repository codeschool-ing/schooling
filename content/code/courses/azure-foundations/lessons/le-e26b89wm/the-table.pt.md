---
title: Quais tipos se movem, lido na própria tabela da Microsoft
version: 1
---

**Nem todo recurso pode se mover, e a resposta é por tipo, não por recurso.** A Microsoft mantém uma
página que lista todo tipo de recurso com duas respostas: se ele pode ir para outro grupo de recursos,
e se pode ir para outra assinatura. As duas costumam diferir, e é a segunda que pega, porque mover
entre assinaturas é o que uma reorganização pede.

Essa página é publicada em Markdown no repositório público de documentação da Microsoft no GitHub,
então pode ser lida por um programa em vez de a olho. Crie o diretório da lição e salve isto como
`moves.py`:

```sh
mkdir -p ~/azure/moves && cd ~/azure/moves
```

```schooling-example
{"language": "python", "file": "moves.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"moves.py [TYPE...]: which Azure resource types can move, from Microsoft's own table.\"\"\"\nimport re\nimport sys\nimport urllib.request\n\nURL = ('https://raw.githubusercontent.com/MicrosoftDocs/azure-docs/main/articles/'\n       'azure-resource-manager/management/move-support-resources.md')\n\n\n", "note": "A Microsoft publica a documentação dela como Markdown num repositório público do GitHub, e uma página dela é **a tabela de todos os tipos de recurso e de se cada um pode se mover**. `URL` é essa página, lida direto do repositório: sem conta, sem chave."}, {"code": "def verdict(cell):\n    cell = re.sub(r'\\[([^]]*)\\]\\([^)]*\\)', r'\\1', cell).replace('*', '').lower()\n    words = set(re.findall(r'[a-z]+', cell))\n    if 'yes' in words and 'no' in words:\n        return 'depends'\n    return 'yes' if 'yes' in words else 'no'\n\n\n", "note": "Cada célula da tabela diz Yes ou No, às vezes em negrito, às vezes com um link ou uma condição depois. Uma célula que diz as duas coisas, como *Yes para o SKU Basic, No para o Standard*, é informada como `depends`, que quer dizer: leia a linha."}, {"code": "def table():\n    text = urllib.request.urlopen(URL, timeout=60).read().decode('utf-8')\n    rows, namespace = {}, None\n    for line in text.splitlines():\n        if line.startswith('## '):\n            namespace = line[3:].strip()\n        elif line.startswith('> |') and namespace and '---' not in line:\n            cells = [c.strip() for c in line[3:].split('|')]\n            if len(cells) >= 3 and cells[0] != 'Resource type':\n                rows[f'{namespace}/{cells[0]}'.lower()] = (verdict(cells[1]), verdict(cells[2]))\n    return rows\n\n\n", "note": "Todo título `## ` é um namespace de provider, e toda linha de tabela debaixo dele é um tipo. A primeira coluna é o movimento para outro **grupo de recursos**, a segunda para outra **assinatura**. A chave vai em minúsculas, porque a lição 2 mostrou que o Azure compara nomes de tipo sem ligar para maiúsculas."}, {"code": "rows = table()\nif len(sys.argv) == 1:\n    for i, scope in enumerate(('to another group', 'to another subscription')):\n        count = {v: sum(1 for r in rows.values() if r[i] == v) for v in ('yes', 'depends', 'no')}\n        print(f'{len(rows)} types, {scope}: ' + ', '.join(f'{v} {n}' for v, n in count.items()))\nfor name in sys.argv[1:]:\n    group, sub = rows.get(name.lower(), ('?', '?'))\n    print(f'{name:<44} group {group:<8} subscription {sub}')\n", "note": "Sem argumentos ele conta; com nomes de tipo ele procura cada um. Um tipo que a tabela não lista responde `?`, que é uma pergunta a fazer antes do movimento, não um sim."}]}
```

Rode uma vez sem nada, para contar, e uma vez com os tipos de que a rede e as máquinas da loja são
feitas:

```
ana@laptop:~/azure/moves$ python3 moves.py
756 types, to another group: yes 201, depends 2, no 553
756 types, to another subscription: yes 186, depends 3, no 567
```

```
ana@laptop:~/azure/moves$ python3 moves.py Microsoft.Network/virtualNetworks Microsoft.Network/publicIPAddresses Microsoft.Network/loadBalancers Microsoft.Network/bastionHosts Microsoft.Network/natGateways Microsoft.Network/azureFirewalls Microsoft.Compute/virtualMachines Microsoft.KeyVault/vaults
Microsoft.Network/virtualNetworks            group yes      subscription yes
Microsoft.Network/publicIPAddresses          group yes      subscription yes
Microsoft.Network/loadBalancers              group yes      subscription depends
Microsoft.Network/bastionHosts               group yes      subscription no
Microsoft.Network/natGateways                group no       subscription no
Microsoft.Network/azureFirewalls             group no       subscription no
Microsoft.Compute/virtualMachines            group yes      subscription yes
Microsoft.KeyVault/vaults                    group yes      subscription yes
```

**A tabela foi lida em 30 de outubro de 2026**, e a Microsoft a edita: um tipo que diz No hoje pode
dizer Yes no ano que vem. Rode o programa de novo antes de um movimento de verdade em vez de confiar
nos números daqui.

## O que os números dizem

**A maioria das 756 linhas diz No, e isso é menos alarmante do que parece.** Muitas linhas não são
coisas que alguém cria: registros de operação, categorias de diagnóstico, tipos que o portal usa
internamente. O que importa é a linha do tipo que você tem, e para os recursos da loja o quadro é
misturado:

- **a rede virtual, a máquina, o key vault e o endereço IP público vão para qualquer lugar**, pela
  tabela. As sub-redes da rede e as extensões da máquina viajam com elas, como filhas;
- **o host do Bastion vai entre grupos mas não entre assinaturas**;
- **o balanceador de carga depende**: a tabela diz que o Basic vai entre assinaturas e o Standard
  não, o que é um fato sobre uma versão de produto e não sobre balanceamento de carga;
- **o NAT gateway e o Azure Firewall não se movem de jeito nenhum.** Para ter um em outro grupo,
  você cria um novo lá e apaga o antigo.

**Um Yes na tabela não encerra a pergunta.** O endereço IP público diz Yes para assinaturas, e a
orientação de rede para a qual a linha aponta acrescenta o que a célula deixa de fora: um recurso
associado a um endereço IP público **Standard** não pode ser movido entre assinaturas. Todo namespace
com condições tem uma página assim, apontada pela seção dele na tabela, e ela é a segunda coisa a ler.

## Quando a resposta é No

Um tipo que não se move é movido do jeito honesto: **crie-o de novo onde ele deve ficar, passe para
ele as coisas que usam o antigo, e apague o antigo.** Para um firewall isso é uma janela de
manutenção; para um NAT gateway, alguns minutos de endereços de saída trocados. Esse é o argumento
mais forte para o hábito que a lição 26 constrói, descrever recursos num arquivo: com o arquivo,
recriar algo em outro lugar é uma implantação, e sem ele, um trabalho de arqueologia.
