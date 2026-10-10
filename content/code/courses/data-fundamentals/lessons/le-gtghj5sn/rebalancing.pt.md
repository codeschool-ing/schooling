---
title: Acrescentar uma máquina, e quanto precisa mudar de lugar
version: 1
---

**Quando uma quinta máquina se junta a quatro, o resultado justo é que um quinto dos dados vá para ela
e nada mais mude de lugar. Particionar por `hash % N` não faz isso: mude o N e quase toda chave muda
de máquina.** Mover dados entre máquinas é a parte cara de crescer, porque custa rede, disco e tempo
enquanto o sistema continua respondendo perguntas, e por isso quanto precisa mudar de lugar é a
medida de um esquema.

A conta é curta. Uma chave fica onde estava só se o hash dela deixa o mesmo resto quando dividido por
4 e quando dividido por 5. Em cada vinte números seguidos, isso acontece com quatro deles, de 0 a 3,
então quatro chaves em cinco mudam de máquina.

## O anel

**O hashing consistente põe as máquinas e as chaves no mesmo círculo, e uma chave pertence à primeira
máquina depois dela, no sentido horário.** Calcule o hash do nome de cada máquina para ter um ponto no
círculo, calcule o hash de cada chave também, e ande para a frente a partir da chave até encontrar
uma máquina. Quando uma máquina nova entra, ela cai em algum ponto do círculo e assume as chaves entre
ela e a máquina anterior. Todas as outras chaves continuam encontrando a mesma máquina primeiro, então
nada mais muda de lugar.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 320\" role=\"img\" aria-label=\"Um círculo de valores de hash com quatro nós, de n1 a n4, e chaves como pontinhos. Cada chave pertence ao primeiro nó no sentido horário a partir dela. Um quinto nó, n5, entra entre o n1 e o n2; as chaves do arco entre o n1 e o n5 passam do n2 para o n5, e todas as outras ficam onde estavam.\" data-fig=\"ring\"><defs><marker id=\"ring-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><circle cx=\"175\" cy=\"160\" r=\"112\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"2\"></circle><path d=\"M 213.3 54.8 A 112 112 0 0 1 280.2 121.7\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"6\"></path><circle cx=\"234.4\" cy=\"65.0\" r=\"3.5\" fill=\"var(--amber)\" stroke=\"var(--ink)\" stroke-width=\"1\"></circle><circle cx=\"254.2\" cy=\"80.8\" r=\"3.5\" fill=\"var(--amber)\" stroke=\"var(--ink)\" stroke-width=\"1\"></circle><circle cx=\"270.0\" cy=\"100.6\" r=\"3.5\" fill=\"var(--amber)\" stroke=\"var(--ink)\" stroke-width=\"1\"></circle><circle cx=\"286.6\" cy=\"169.8\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"var(--ink)\" stroke-width=\"1\"></circle><circle cx=\"231.0\" cy=\"257.0\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"var(--ink)\" stroke-width=\"1\"></circle><circle cx=\"184.8\" cy=\"271.6\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"var(--ink)\" stroke-width=\"1\"></circle><circle cx=\"83.3\" cy=\"224.2\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"var(--ink)\" stroke-width=\"1\"></circle><circle cx=\"64.1\" cy=\"175.6\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"var(--ink)\" stroke-width=\"1\"></circle><circle cx=\"95.8\" cy=\"80.8\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"var(--ink)\" stroke-width=\"1\"></circle><circle cx=\"146.0\" cy=\"51.8\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"var(--ink)\" stroke-width=\"1\"></circle><circle cx=\"213.3\" cy=\"54.8\" r=\"9\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"2.5\"></circle><text x=\"222.2\" y=\"30.3\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">n1</text><circle cx=\"280.2\" cy=\"198.3\" r=\"9\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"2.5\"></circle><text x=\"304.7\" y=\"207.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">n2</text><circle cx=\"136.7\" cy=\"265.2\" r=\"9\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"2.5\"></circle><text x=\"127.8\" y=\"289.7\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">n3</text><circle cx=\"69.8\" cy=\"121.7\" r=\"9\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"2.5\"></circle><text x=\"45.3\" y=\"112.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">n4</text><circle cx=\"280.2\" cy=\"121.7\" r=\"9\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2.5\"></circle><text x=\"304.7\" y=\"112.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\" font-weight=\"600\">n5</text><text x=\"175\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">valores de hash</text><text x=\"175\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">sentido horário</text><text x=\"380\" y=\"72\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Uma chave pertence ao primeiro nó</text><text x=\"380\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">no sentido horário a partir dela.</text><text x=\"380\" y=\"136\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">O n5 entra entre o n1 e o n2.</text><text x=\"380\" y=\"180\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">As chaves do arco grosso iam primeiro</text><text x=\"380\" y=\"200\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">ao n2; agora vão primeiro ao n5.</text><text x=\"380\" y=\"244\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Todas as outras chaves encontram</text><text x=\"380\" y=\"264\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">o mesmo nó de antes, e ficam.</text></svg>", "caption": "Um anel com um ponto por nó, para ficar claro. O n5 entra entre o n1 e o n2 e fica só com as chaves do arco grosso, todas vindas do n2."}
```

Um ponto por máquina deixa os arcos desiguais, já que quatro pontos ao acaso raramente cortam um
círculo em quatro pedaços iguais. Por isso cada máquina é colocada em muitos pontos, que costumam ser
chamados de **nós virtuais**, e a parte dela é a soma de muitos arcos pequenos, o que fica mais perto
do justo.

O programa abaixo coloca 10.000 ids de viagem em quatro nós, acrescenta um quinto e conta o que mudou
de lugar, uma vez por módulo e uma vez num anel com cem pontos por nó. Salve como `rebalance.py`:

```schooling-example
{"language": "python", "file": "spread/rebalance.py", "parts": [
{"code": "# spread/rebalance.py\nimport bisect\nimport hashlib\nfrom collections import Counter\n\n\ndef h(text):\n    return int(hashlib.md5(text.encode()).hexdigest(), 16)\n\n\nKEYS = [f\"R{i:06d}\" for i in range(1, 10001)]\n\n\n", "note": "O mesmo hash de antes, e dez mil ids de viagem como chaves."},
{"code": "def modulo(nodes):\n    return {k: nodes[h(k) % len(nodes)] for k in KEYS}\n\n\n", "note": "Posicionamento por módulo: o hash, dividido pelo número de nós, e o resto escolhe um."},
{"code": "def ring(nodes, points=100):\n    marks = sorted((h(f\"{node}#{p}\"), node) for node in nodes for p in range(points))\n    spots = [spot for spot, _ in marks]\n    return {k: marks[bisect.bisect(spots, h(k)) % len(marks)][1] for k in KEYS}\n\n\n", "note": "Posicionamento num anel. Cada nó é colocado no círculo em cem pontos, de `n1#0` a `n1#99`, e os pontos são ordenados. Uma chave pertence ao primeiro ponto a partir do seu próprio hash, que o `bisect` encontra; depois do último ponto ela dá a volta até o primeiro, que é o `%`."},
{"code": "four = [\"n1\", \"n2\", \"n3\", \"n4\"]\nfive = four + [\"n5\"]\nfor name, place in ((\"modulo\", modulo), (\"ring\", ring)):\n    before, after = place(four), place(five)\n    moved = [k for k in KEYS if before[k] != after[k]]\n    went = Counter(after[k] for k in moved)\n    print(f\"{name:7} {len(moved):5} of {len(KEYS)} rides moved;\",\n          f\"{went['n5']} to the new node, {len(moved) - went['n5']} between old ones\")\n    print(f\"{'':7} rides per node after:\", sorted(Counter(after.values()).items()))\n", "note": "As duas formas, antes e depois de um quinto nó entrar. Uma chave mudou de lugar se o nó dela mudou; o programa conta quantas mudaram, quantas dessas foram para o nó novo e quantas viagens cada nó guarda depois."}
]}
```

```
ana@lab:~/roda/spread$ python rebalance.py
modulo   7966 of 10000 rides moved; 2018 to the new node, 5948 between old ones
        rides per node after: [('n1', 1926), ('n2', 2012), ('n3', 1999), ('n4', 2045), ('n5', 2018)]
ring     2177 of 10000 rides moved; 2177 to the new node, 0 between old ones
        rides per node after: [('n1', 1622), ('n2', 1865), ('n3', 2164), ('n4', 2172), ('n5', 2177)]
```

Por módulo, 7966 das 10.000 viagens mudaram de lugar. Só 2018 delas foram para o nó novo; as outras
5948 passaram de um nó antigo para outro, por nenhum motivo além da aritmética. No anel, 2177
viagens mudaram, todas para o `n5`, e nenhuma passou entre nós antigos.

O anel também não é perfeitamente uniforme. Com cem pontos cada, os cinco nós ficam entre 1622 e 2177
viagens, contra uma parte justa de 2000. Mais pontos por nó aproximam esses números, ao custo de uma
lista maior para procurar.

## Onde você vai encontrar isso

O Cassandra posiciona os dados num anel desse tipo, e o Dynamo também posicionava, o armazenamento
interno que a Amazon descreveu num artigo de 2007 e que muitos bancos posteriores copiaram. O outro
desenho que você vai encontrar fixa o número de partições quando o conjunto de dados é criado, muito
mais partições do que máquinas, e move partições inteiras quando uma máquina entra. A partição de uma
chave então nunca muda, só a máquina onde essa partição mora. Os dois respondem à mesma pergunta, e é a
pergunta a fazer a qualquer sistema que diz crescer acrescentando máquinas: quando uma entra, o que
muda de lugar?
