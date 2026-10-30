---
title: Passando pacotes pelas regras
version: 1
---

**Se um pacote entra é uma pergunta com uma resposta, e a resposta pode ser calculada à mão**: pegue as regras
que casam, ordene-as por prioridade com deny primeiro no empate, e leia a primeira. O Google faz isso para todo
pacote. Sem uma rede por onde mandar pacotes, o laboratório faz isso com um programa curto sobre as regras do
planner, escritas como dados. Nada nesta seção chega a uma rede; o que o programa aplica é a ordem das duas
seções anteriores, e as regras são o desenho do planner.

Salve as regras como `~/gcp/firewall/rules.json`. As duas faixas de endereços da primeira regra são de onde os
balanceadores de carga do Google mandam verificações de saúde, e a faixa da segunda é de onde vêm as conexões
SSH do Identity-Aware Proxy: três faixas reais que o Google publica. A última regra tira o SSH de máquinas com
a tag `frozen`, a palavra do planner para uma máquina guardada para uma investigação:

```json
[
  {"name": "allow-health-checks", "priority": 1000, "action": "allow", "ports": [8080],
   "source_ranges": ["35.191.0.0/16", "130.211.0.0/22"], "target_service_accounts": ["web"]},
  {"name": "allow-ssh-from-iap", "priority": 1000, "action": "allow", "ports": [22],
   "source_ranges": ["35.235.240.0/20"]},
  {"name": "allow-web-to-db", "priority": 1000, "action": "allow", "ports": [5432],
   "source_service_accounts": ["web"], "target_service_accounts": ["db"]},
  {"name": "deny-ssh-to-frozen", "priority": 900, "action": "deny", "ports": [22],
   "source_ranges": ["0.0.0.0/0"], "target_tags": ["frozen"]}
]
```

E o programa, como `~/gcp/firewall/walk.py`:

```schooling-example
{"language": "python", "file": "walk.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"Walks one incoming packet through a network's firewall rules, as Google does.\n\n    python3 walk.py FROM TO PORT\n\nFROM is an address, or sa:NAME for a machine of the network running as that\nservice account. TO is sa:NAME, optionally with ,tag:TAG after it. The rules\nare read from rules.json.\n\"\"\"\nimport ipaddress\nimport json\nimport sys\n\n", "note": "Como é chamado: de onde o pacote vem, para onde vai, e a porta. Uma origem é ou um endereço, para tráfego de fora, ou `sa:NAME`, para uma máquina da rede rodando como aquela conta."}, {"code": "IMPLIED = {'name': 'implied deny ingress', 'priority': 65535, 'action': 'deny', 'ports': None,\n           'any_source': True}\n\n", "note": "A regra implícita em 65535, escrita como uma regra qualquer para ser ordenada junto com as outras. Ela casa com toda origem e toda porta, e é isso que a faz ser o piso."}, {"code": "def parse(spec):\n    sa, tags, ip = None, [], None\n    for part in spec.split(','):\n        kind, _, value = part.partition(':')\n        if kind == 'sa':\n            sa = value\n        elif kind == 'tag':\n            tags.append(value)\n        else:\n            ip = ipaddress.ip_address(part)\n    return sa, tags, ip\n\n", "note": "Transformar `sa:web,tag:frozen` nas suas partes: a conta de serviço, as tags, e o endereço se um foi dado."}, {"code": "def matches(rule, src, dst, port):\n    src_sa, _, src_ip = src\n    dst_sa, dst_tags, _ = dst\n    if rule['ports'] is not None and port not in rule['ports']:\n        return False\n    if 'target_tags' in rule and not set(rule['target_tags']) & set(dst_tags):\n        return False\n    if 'target_service_accounts' in rule and dst_sa not in rule['target_service_accounts']:\n        return False\n    by_range = src_ip is not None and any(src_ip in ipaddress.ip_network(r) for r in rule.get('source_ranges', []))\n    by_account = src_sa is not None and src_sa in rule.get('source_service_accounts', [])\n    return rule.get('any_source', False) or by_range or by_account\n\n", "note": "Se uma regra casa com um pacote: a porta é uma das portas dela, o alvo é um dos alvos dela, e a origem está numa das faixas dela ou roda como uma das contas dela."}, {"code": "src, dst, port = parse(sys.argv[1]), parse(sys.argv[2]), int(sys.argv[3])\nrules = json.load(open('rules.json')) + [IMPLIED]\nrules.sort(key=lambda r: (r['priority'], r['action'] != 'deny'))\nfor rule in rules:\n    if matches(rule, src, dst, port):\n        print(f\"{sys.argv[1]} -> {sys.argv[2]}:{port}  {rule['action'].upper()} by {rule['name']} ({rule['priority']})\")\n        break\n", "note": "A ordem do Google: menor número de prioridade primeiro, e no mesmo número deny antes de allow. A primeira regra que casa decide, e nada depois dela é lido."}]}
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" data-fig=\"l16-order\" aria-label=\"Um pacote, SSH de 35.235.240.7 para uma máquina web com a tag frozen, conferido contra as regras do planner na ordem em que o Google as lê. As regras estão listadas do menor número de prioridade para baixo: deny-ssh-to-frozen em 900, depois allow-health-checks, allow-ssh-from-iap e allow-web-to-db em 1000, depois o deny implícito de entrada em 65535. O pacote casa com a primeira regra, em 900, e é negado; as regras abaixo dela nunca são lidas, inclusive a allow-ssh-from-iap, que também teria casado.\"><defs><marker id=\"l16-order-af-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"20.0\" y=\"110.0\" width=\"190.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"115.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">um pacote</text><text x=\"115.0\" y=\"146.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">35.235.240.7 → :22</text><text x=\"115.0\" y=\"162.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">web, tag frozen</text><rect x=\"280.0\" y=\"30.0\" width=\"420.0\" height=\"36.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"320.0\" y=\"48.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">900</text><text x=\"360.0\" y=\"48.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">deny-ssh-to-frozen</text><text x=\"540.0\" y=\"48.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">deny</text><text x=\"690.0\" y=\"48.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">casa: decide</text><rect x=\"280.0\" y=\"76.0\" width=\"420.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"320.0\" y=\"94.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1000</text><text x=\"360.0\" y=\"94.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">allow-health-checks</text><text x=\"540.0\" y=\"94.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">allow</text><text x=\"690.0\" y=\"94.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">não lida</text><rect x=\"280.0\" y=\"122.0\" width=\"420.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"320.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1000</text><text x=\"360.0\" y=\"140.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">allow-ssh-from-iap</text><text x=\"540.0\" y=\"140.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">allow</text><text x=\"690.0\" y=\"140.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">casaria; não lida</text><rect x=\"280.0\" y=\"168.0\" width=\"420.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"320.0\" y=\"186.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1000</text><text x=\"360.0\" y=\"186.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">allow-web-to-db</text><text x=\"540.0\" y=\"186.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">allow</text><text x=\"690.0\" y=\"186.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">não lida</text><rect x=\"280.0\" y=\"214.0\" width=\"420.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"320.0\" y=\"232.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">65535</text><text x=\"360.0\" y=\"232.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">implied deny ingress</text><text x=\"540.0\" y=\"232.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">deny</text><text x=\"690.0\" y=\"232.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">não lida</text><path d=\"M212.0 130.0 L276.0 50.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#l16-order-af-ah-amber)\"></path><text x=\"360.0\" y=\"278.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">menor número primeiro; no empate, deny primeiro; a primeira que casa decide</text></svg>", "caption": "A primeira regra que casa decide, e nada abaixo dela é lido."}
```

## Sete pacotes

Uma verificação de saúde de um balanceador chegando a uma máquina web na 8080, e a mesma porta a partir de um
endereço na internet:

```
ana@laptop:~/gcp/firewall$ python3 walk.py 35.191.4.20 sa:web 8080
35.191.4.20 -> sa:web:8080  ALLOW by allow-health-checks (1000)
ana@laptop:~/gcp/firewall$ python3 walk.py 203.0.113.9 sa:web 8080
203.0.113.9 -> sa:web:8080  DENY by implied deny ingress (65535)
```

O segundo é recusado por nada que o planner escreveu: **a regra implícita recusa o que nenhuma regra permite**,
e é por isso que a lista do planner não tem regra dizendo *negar todo o resto*.

SSH pelo Identity-Aware Proxy para uma máquina web, e para uma que recebeu a tag `frozen`:

```
ana@laptop:~/gcp/firewall$ python3 walk.py 35.235.240.7 sa:web 22
35.235.240.7 -> sa:web:22  ALLOW by allow-ssh-from-iap (1000)
ana@laptop:~/gcp/firewall$ python3 walk.py 35.235.240.7 sa:web,tag:frozen 22
35.235.240.7 -> sa:web,tag:frozen:22  DENY by deny-ssh-to-frozen (900)
```

O segundo pacote casou com `allow-ssh-from-iap` em 1000 e com `deny-ssh-to-frozen` em 900; **900 é lida
primeiro**, e o allow nunca é alcançado. Mova o deny para a mesma prioridade do allow e passe de novo:

```
ana@laptop:~/gcp/firewall$ sed -i 's/"priority": 900/"priority": 1000/' rules.json
ana@laptop:~/gcp/firewall$ python3 walk.py 35.235.240.7 sa:web,tag:frozen 22
35.235.240.7 -> sa:web,tag:frozen:22  DENY by deny-ssh-to-frozen (1000)
```

Ainda negado, agora em 1000: no empate, deny ganha. O planner mantém os denies em 900 mesmo assim, porque uma
regra cujo efeito depende de um desempate é uma regra que alguém vai ler errado.

Por último, o banco, a partir de uma máquina web e do job de relatórios:

```
ana@laptop:~/gcp/firewall$ python3 walk.py sa:web sa:db 5432
sa:web -> sa:db:5432  ALLOW by allow-web-to-db (1000)
ana@laptop:~/gcp/firewall$ python3 walk.py sa:reports sa:db 5432
sa:reports -> sa:db:5432  DENY by implied deny ingress (65535)
```

O job de relatórios roda como `reports@`, a conta da lição 5, e nenhuma regra o deixa alcançar o banco: ele é
recusado pela regra implícita como o estranho na internet. Se ele deve ler o banco, o conserto é uma regra
nomeando `reports` como origem, escrita e revisada como as outras, e não uma faixa mais larga na que existe.

**O que o programa não faz** é tudo o que o Google faz em volta disso: políticas de firewall acima da rede,
regras de saída, protocolos que não são TCP, e o tráfego sempre permitido. Ele percorre a única lista que o
planner escreveu, na única ordem em que o Google a lê.
