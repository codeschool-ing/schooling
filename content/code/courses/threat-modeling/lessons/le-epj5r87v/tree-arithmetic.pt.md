---
title: Fazendo contas numa árvore
version: 1
---

Uma árvore com números nas folhas pode ser avaliada, e avaliá-la responde à pergunta que quem
defende de fato tem: **se pusermos este controle no lugar, quanto custa agora o caminho mais barato
até o objetivo?** A regra é a que está embaixo da figura da seção anterior: um nó OU vale o filho
mais barato, um nó E vale a soma dos filhos. Um controle torna uma folha impossível, o que dá a ela
custo infinito.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" data-fig=\"l05-tree-numbers\" aria-label=\"A árvore de ataque com as estimativas da equipe do esforço de alguém de fora, em dias, nas folhas. Forjar o webhook precisa do endereço, 1 dia, e de um pedido aceito, 1 dia: um nó AND, 2 dias. Mudar a situação no console precisa de uma conta da equipe, 5 dias, e de chegar ao console, 2: 7 dias. Mudar a linha no banco precisa do worker de lembretes, 10 dias, e da conta de dono dele, 1: 11 dias. A raiz é um OR, que vale o filho mais barato: 2 dias.\"><rect x=\"220.0\" y=\"10.0\" width=\"280.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"360.0\" y=\"26.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">marcar como pago sem pagar</text><text x=\"360.0\" y=\"43.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">OR = filho mais barato: 2 dias</text><path d=\"M360.0 54.0 L120.0 100.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"20.0\" y=\"100.0\" width=\"200.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"120.0\" y=\"116.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">forjar o webhook</text><text x=\"120.0\" y=\"133.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">AND 1 + 1 = 2</text><path d=\"M120.0 144.0 L65.0 200.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"13.0\" y=\"200.0\" width=\"104.0\" height=\"52.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"65.0\" y=\"216.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">endereço</text><text x=\"65.0\" y=\"238.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">1 dia</text><path d=\"M120.0 144.0 L175.0 200.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"123.0\" y=\"200.0\" width=\"104.0\" height=\"52.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"175.0\" y=\"216.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">pedido aceito</text><text x=\"175.0\" y=\"238.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">1 dia</text><path d=\"M360.0 54.0 L360.0 100.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"260.0\" y=\"100.0\" width=\"200.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"116.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">usar o console</text><text x=\"360.0\" y=\"133.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">AND 5 + 2 = 7</text><path d=\"M360.0 144.0 L305.0 200.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"253.0\" y=\"200.0\" width=\"104.0\" height=\"52.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"305.0\" y=\"216.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">conta da equipe</text><text x=\"305.0\" y=\"238.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">5 dias</text><path d=\"M360.0 144.0 L415.0 200.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"363.0\" y=\"200.0\" width=\"104.0\" height=\"52.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"415.0\" y=\"216.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">chegar ao console</text><text x=\"415.0\" y=\"238.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">2 dias</text><path d=\"M360.0 54.0 L600.0 100.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"500.0\" y=\"100.0\" width=\"200.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"600.0\" y=\"116.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">mudar a linha</text><text x=\"600.0\" y=\"133.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">AND 10 + 1 = 11</text><path d=\"M600.0 144.0 L545.0 200.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"493.0\" y=\"200.0\" width=\"104.0\" height=\"52.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"545.0\" y=\"216.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">tomar o worker</text><text x=\"545.0\" y=\"238.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">10 dias</text><path d=\"M600.0 144.0 L655.0 200.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"603.0\" y=\"200.0\" width=\"104.0\" height=\"52.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"655.0\" y=\"216.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">conta de dono</text><text x=\"655.0\" y=\"238.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">1 dia</text><text x=\"360.0\" y=\"278.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">AND soma os filhos; OR fica com o mais barato</text></svg>", "caption": "Sem controles, o webhook é a rota mais barata com folga, e é por isso que a conferência da assinatura vem primeiro."}
```

O `tree.py` é a árvore da seção anterior, escrita como tuplas aninhadas, com quatro controles que a
equipe estava discutindo:

```schooling-example
{"language": "python", "file": "tree.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"An attack tree for one goal, and what controls do to the cheapest way to reach it.\"\"\"\nimport sys\n\nNEVER = float(\"inf\")\n", "note": "Só a biblioteca padrão. Uma folha impossível custa infinito, o que toda soma e todo mínimo tratam sem caso especial."}, {"code": "# A node is (\"OR\" or \"AND\", name, children), or (days, name) for a leaf.\n# Days are the team's estimate of an outsider's effort, not a measurement.\nTREE = (\"OR\", \"Mark a booking paid without paying\", [\n    (\"AND\", \"Forge the gateway's webhook\", [\n        (1, \"Learn the webhook's address\"),\n        (1, \"Send a request the portal accepts\"),\n    ]),\n    (\"AND\", \"Change the status in the staff console\", [\n        (5, \"Take over a staff account\"),\n        (2, \"Reach the console\"),\n    ]),\n    (\"AND\", \"Change the row in the database\", [\n        (10, \"Take over the reminder worker\"),\n        (1, \"Use its owner account\"),\n    ]),\n])\n", "note": "A árvore da figura. Um nó é um tipo, um nome e os filhos; uma folha é uma estimativa e um nome. As estimativas são da equipe, em dias de esforço de alguém de fora."}, {"code": "# Each control makes one leaf impossible.\nCONTROLS = {\n    \"signature\": \"Send a request the portal accepts\",\n    \"mfa\": \"Take over a staff account\",\n    \"clinic-only\": \"Reach the console\",\n    \"least-privilege\": \"Use its owner account\",\n}\n\n", "note": "Cada controle que a equipe discutiu, e a folha que ele torna impossível. Um controle real pode bloquear várias folhas; estes bloqueiam uma cada."}, {"code": "def cheapest(node, blocked):\n    \"\"\"The attacker's cheapest cost for a node, and the leaves on that route.\"\"\"\n    if not isinstance(node[0], str):\n        days, name = node\n        return (NEVER if name in blocked else days), [name]\n    kind, _, children = node\n    routes = [cheapest(child, blocked) for child in children]\n    if kind == \"OR\":\n        return min(routes, key=lambda route: route[0])\n    return sum(days for days, _ in routes), [leaf for _, leaves in routes for leaf in leaves]\n\n", "note": "O método inteiro numa função. Uma folha devolve a estimativa, ou infinito se bloqueada. Um OU devolve o filho mais barato; um E soma os filhos e guarda cada folha do caminho."}, {"code": "chosen = sys.argv[1:]\ndays, leaves = cheapest(TREE, {CONTROLS[c] for c in chosen})\nprint(\"controls:\", \", \".join(chosen) or \"none\")\nif days == NEVER:\n    print(\"cheapest: unreachable\")\nelse:\n    print(f\"cheapest: {days:g} days\")\n    for leaf in leaves:\n        print(\"  -\", leaf)", "note": "Os controles vêm da linha de comando, e o programa imprime o caminho mais barato que sobra."}]}
```

Rode sem controles, e depois acrescente um de cada vez, na ordem que a equipe propôs:

```
(.venv) ana@vm:~/tm/portal-model$ python3 tree.py
controls: none
cheapest: 2 days
  - Learn the webhook's address
  - Send a request the portal accepts
```

Dois dias, pelo webhook: a T01 é de longe o caminho mais barato até o objetivo.

```
(.venv) ana@vm:~/tm/portal-model$ python3 tree.py signature
controls: signature
cheapest: 7 days
  - Take over a staff account
  - Reach the console
```

**Verificar a assinatura do gateway não torna o objetivo inalcançável. Ela empurra o atacante para o
ramo seguinte**, que custa sete dias em vez de dois. É a lição mais comum que uma árvore de ataque
ensina: um controle vale o que ele acrescenta ao caminho mais barato que sobra, e não o que ele tira
do caminho que bloqueia.

```
(.venv) ana@vm:~/tm/portal-model$ python3 tree.py signature mfa
controls: signature, mfa
cheapest: 11 days
  - Take over the reminder worker
  - Use its owner account
```

Com segundo fator para a equipe, o ramo do console some também, e o caminho mais barato passa a ser
o worker, com onze dias.

```
(.venv) ana@vm:~/tm/portal-model$ python3 tree.py signature mfa clinic-only
controls: signature, mfa, clinic-only
cheapest: 11 days
  - Take over the reminder worker
  - Use its owner account
```

**Acrescentar `clinic-only` não mudou nada.** Manter o console fora da internet é um bom controle, e
a T12 da aula 3 é uma ameaça real, mas o ramo do console já estava quebrado pelo `mfa`. Para este
objetivo, esse dinheiro não compra nada. Para outro objetivo, como ler todos os prontuários, pode
comprar muito, e é por isso que se desenha uma árvore por objetivo.

```
(.venv) ana@vm:~/tm/portal-model$ python3 tree.py signature mfa least-privilege
controls: signature, mfa, least-privilege
cheapest: unreachable
```

A conta de banco com mínimo privilégio quebra o último ramo, e o objetivo fica inalcançável por
todos os caminhos que esta árvore conhece. Essa última frase importa: **a árvore só conhece os
caminhos que alguém desenhou.** "Inalcançável" significa que a equipe não achou outro jeito no
desenho, não que não exista nenhum, e a próxima revisão deveria começar perguntando que ramo está
faltando.

### O que os números são

Os dias são estimativas da equipe, numa unidade escolhida porque era fácil de discutir. Não são
medições, e o resultado da árvore herda isso. O que sobrevive à incerteza é a **comparação**: se um
controle leva o caminho mais barato de dois para sete dias é algo que resiste aos números exatos,
porque a ordem dos ramos só muda se uma estimativa estiver muito errada. As aulas 9 e 10 voltam às
estimativas, e a faixas em vez de números únicos.
