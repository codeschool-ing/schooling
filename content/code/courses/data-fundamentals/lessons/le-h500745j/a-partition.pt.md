---
title: Uma partição na sua própria máquina
version: 1
---

**O jeito mais rápido de acreditar no CAP é cortar um enlace você mesmo e ver as duas respostas
acontecerem.** O programa desta seção guarda três cópias de um número, isola uma cópia das outras
duas e manda a ela as mesmas duas requisições duas vezes: uma se comportando como um sistema que
escolheu a consistência, outra como um que escolheu a disponibilidade.

Tudo roda no laboratório que a aula 1 montou. Esta aula trabalha no seu próprio diretório:

```sh
mkdir -p ~/roda/cap && cd ~/roda/cap
```

## Três cópias e um corte

A rede aqui é um dicionário. Nada é enviado a lugar nenhum; um nó "alcança" outro quando os dois
estão do mesmo lado. Isso basta para mostrar a escolha, porque ela não depende de como uma mensagem
viaja, só de se ela chega. Salve em `~/roda/cap` como `replicas.py`:

```schooling-example
{"language": "python", "file": "cap/replicas.py", "parts": [{"code": "# cap/replicas.py\nimport sys\n\nMODE = sys.argv[1]  # \"cp\" or \"ap\"\nNODES = [\"n1\", \"n2\", \"n3\"]\nbikes = {n: 6 for n in NODES}  # bicycles docked at ST02, one copy per node\nside = {\"n1\": \"A\", \"n2\": \"A\", \"n3\": \"A\"}  # one side: nothing is cut\n", "note": "Três cópias de um número: as bicicletas presas nas docas da ST02, Rua XV. `side` diz de que lado de um corte cada nó está, e enquanto os três dizem `A`, todo nó alcança todos os outros. `MODE` vem da linha de comando, então um só programa mostra os dois comportamentos."}, {"code": "\n\ndef reach(node):\n    return [n for n in NODES if side[n] == side[node]]\n\n\ndef majority(node):\n    return len(reach(node)) > len(NODES) // 2\n", "note": "`reach` é a lista dos nós com que um nó ainda consegue falar, ele incluído. `majority` pergunta se essa lista passa da metade dos três: dois de três passa, um de três não."}, {"code": "\n\ndef write(node, value):\n    if MODE == \"cp\" and not majority(node):\n        return f\"{node} write {value}: refused, sees {len(reach(node))} of 3\"\n    for n in reach(node):\n        bikes[n] = value\n    return f\"{node} write {value}: ok on {' '.join(reach(node))}\"\n", "note": "Uma escrita no modo `cp` precisa de maioria, senão é recusada. Fora isso, ela é copiada para todo nó ao alcance, e só para esses, porque nada atravessa o corte. No modo `ap` a verificação não acontece."}, {"code": "\n\ndef read(node):\n    if MODE == \"cp\" and not majority(node):\n        return f\"{node} read: refused, sees {len(reach(node))} of 3\"\n    return f\"{node} read: {bikes[node]}\"\n", "note": "Uma leitura recusa pela mesma condição, porque um nó isolado da maioria não tem como saber se a sua cópia ainda é a mais recente. No modo `ap` ela devolve o que este nó tiver."}, {"code": "\n\nprint(MODE, \"before the cut:\", bikes)\nside[\"n3\"] = \"B\"  # the link between n3 and the others is cut\nprint(write(\"n1\", 5))  # a bicycle is taken, seen by n1\nprint(write(\"n3\", 7))  # a bicycle is returned, seen by n3\nprint(read(\"n2\"))\nprint(read(\"n3\"))\nprint(MODE, \"after the cut:\", bikes)\n", "note": "A história: o enlace até o `n3` é cortado, uma bicicleta é retirada num nó do lado maior e outra é devolvida no nó que ficou sozinho. Depois das duas, a ST02 volta a ter 6 de verdade."}]}
```

Duas linhas decidem tudo. `majority` é como um sistema que escolheu a consistência sabe que está do
lado autorizado a falar: um nó que alcança dois de três pode ter certeza de que nenhum outro grupo
de nós está aceitando escritas no mesmo momento, porque não existe um segundo grupo de dois. E a
verificação de `MODE` é a única diferença entre os dois comportamentos. O resto do programa é igual.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Dois painéis, cada um com os nós n1 e n2 de um lado de um enlace cortado e o n3 sozinho do outro. Consistência escolhida: n1 e n2 têm 5, o n3 ainda tem 6 e recusa leituras e escritas. Disponibilidade escolhida: n1 e n2 têm 5, o n3 aceitou uma devolução e tem 7. A contagem verdadeira é 6.\" data-fig=\"partition\"><defs><marker id=\"partition-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"180\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\" font-weight=\"600\">consistência escolhida (cp)</text><rect x=\"16\" y=\"36\" width=\"214\" height=\"116\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"26\" y=\"48\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">lado A</text><rect x=\"30\" y=\"62\" width=\"82\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"71.0\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">n1</text><text x=\"71.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">5</text><rect x=\"134\" y=\"62\" width=\"82\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"175.0\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">n2</text><text x=\"175.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">5</text><line x1=\"112\" y1=\"92\" x2=\"134\" y2=\"92\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></line><rect x=\"258\" y=\"36\" width=\"86\" height=\"116\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"268\" y=\"48\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">lado B</text><rect x=\"262\" y=\"62\" width=\"78\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"301.0\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">n3</text><text x=\"301.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">6</text><line x1=\"216\" y1=\"92\" x2=\"232\" y2=\"92\" stroke=\"var(--amber)\" stroke-width=\"2\"></line><line x1=\"246\" y1=\"92\" x2=\"262\" y2=\"92\" stroke=\"var(--amber)\" stroke-width=\"2\"></line><text x=\"239\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\" font-weight=\"600\">corte</text><text x=\"123\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">continua funcionando</text><text x=\"301\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">recusa escritas</text><text x=\"301\" y=\"183\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">e leituras</text><text x=\"180\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">toda resposta é verdadeira;</text><text x=\"180\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">o n3 responde com erro</text><text x=\"540\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\" font-weight=\"600\">disponibilidade escolhida (ap)</text><rect x=\"376\" y=\"36\" width=\"214\" height=\"116\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"386\" y=\"48\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">lado A</text><rect x=\"390\" y=\"62\" width=\"82\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"431.0\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">n1</text><text x=\"431.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">5</text><rect x=\"494\" y=\"62\" width=\"82\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"535.0\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">n2</text><text x=\"535.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">5</text><line x1=\"472\" y1=\"92\" x2=\"494\" y2=\"92\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></line><rect x=\"618\" y=\"36\" width=\"86\" height=\"116\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"628\" y=\"48\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">lado B</text><rect x=\"622\" y=\"62\" width=\"78\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"661.0\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">n3</text><text x=\"661.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">7</text><line x1=\"576\" y1=\"92\" x2=\"592\" y2=\"92\" stroke=\"var(--amber)\" stroke-width=\"2\"></line><line x1=\"606\" y1=\"92\" x2=\"622\" y2=\"92\" stroke=\"var(--amber)\" stroke-width=\"2\"></line><text x=\"599\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\" font-weight=\"600\">corte</text><text x=\"483\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">continua funcionando</text><text x=\"661\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">aceita a</text><text x=\"661\" y=\"183\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">bicicleta devolvida</text><text x=\"540\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">o n2 diz 5, o n3 diz 7;</text><text x=\"540\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">a Rua XV tem 6 de verdade</text></svg>", "caption": "O mesmo corte, duas escolhas. À esquerda o nó isolado recusa e toda resposta continua verdadeira; à direita ele aceita, e duas cópias discordam até o enlace voltar."}
```

## Consistência escolhida

```
ana@lab:~/roda/cap$ python replicas.py cp
cp before the cut: {'n1': 6, 'n2': 6, 'n3': 6}
n1 write 5: ok on n1 n2
n3 write 7: refused, sees 1 of 3
n2 read: 5
n3 read: refused, sees 1 of 3
cp after the cut: {'n1': 5, 'n2': 5, 'n3': 6}
```

O `n1` alcançou dois dos três nós, uma maioria, então a bicicleta retirada na Rua XV ficou registrada
no `n1` e no `n2`. O `n3` viu um de três e recusou tanto a bicicleta devolvida quanto a leitura. A
cliente no `n3` recebeu um erro.

Repare no que continua verdadeiro. **Nada do que alguém leu estava errado.** O `n2` respondeu 5, que
era a última escrita aceita. A cópia do `n3` ainda diz 6, mas ninguém pôde lê-la enquanto ela podia
estar velha. E o sistema não caiu: os dois nós do lado maior continuaram funcionando, que é o que a
maioria dos seus usuários viu.

## Disponibilidade escolhida

```
ana@lab:~/roda/cap$ python replicas.py ap
ap before the cut: {'n1': 6, 'n2': 6, 'n3': 6}
n1 write 5: ok on n1 n2
n3 write 7: ok on n3
n2 read: 5
n3 read: 7
ap after the cut: {'n1': 5, 'n2': 5, 'n3': 7}
```

Agora toda requisição recebeu resposta. A devolução no `n3` foi aceita, então a cliente fica
satisfeita, e quem lê do `n3` vê 7. No mesmo momento, quem lê do `n2` vê 5.

**Dois leitores fizeram a mesma pergunta no mesmo instante e receberam duas respostas diferentes**, e
a contagem verdadeira não é nenhuma delas: uma bicicleta saiu e uma voltou, então a Rua XV tem 6. É
essa a cara de abrir mão da linearizabilidade. Nenhum nó mentiu — cada um relatou o que viu — e a
discordância dura até o enlace voltar e alguém decidir como 5 e 7 viram um número só. A seção 05 toma essa decisão de três jeitos.

## O que a simulação deixa de fora

Duas coisas, e as duas tornam o caso real mais difícil, não mais fácil.

- **Um nó de verdade não sabe que está particionado.** Aqui, `side` conta para ele. Numa rede, o
  `n3` só vê que as suas mensagens ficam sem resposta, e a aula 9 mostrou que um timeout não
  distingue um enlace cortado de um par lento ou morto. Um sistema real escolhe um timeout e trata o
  silêncio como corte, e às vezes erra.
- **O número de nós importa.** Com dois nós em vez de três, um corte deixa cada lado vendo um de
  dois, e um não passa da metade. Um sistema que escolheu a consistência recusaria então dos **dois**
  lados. É por isso que esses sistemas rodam com um número ímpar de nós, três ou cinco: um quarto nó
  acrescenta uma máquina sem deixar o sistema perder uma a mais.
