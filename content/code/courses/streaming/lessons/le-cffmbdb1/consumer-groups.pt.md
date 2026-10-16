---
title: Um consumer group divide as partições
version: 1
---

**Cópias de um programa que usam o mesmo `group.id` dividem entre si as partições de um tópico: cada
partição é lida por exatamente um membro do grupo.** É assim que o Kafka espalha o trabalho de um
programa por vários processos ou máquinas, e é o comportamento de fila que a lição 2 prometeu: dentro
de um grupo, cada mensagem é tratada uma vez. Entre grupos nada é dividido. Todo grupo lê toda
mensagem, no seu próprio lugar, que é o comportamento de log.

Para isto você precisa de mais shells; abra-os como a lição 1 mostrou, com `multipass shell stream` em
mais janelas do terminal do seu computador. Em dois deles, inicie dois membros de um grupo novo,
`shelf`, um depois do outro: `python consumer.py a --group shelf` num, e alguns segundos depois
`python consumer.py b --group shelf` no seguinte.

O `a` começou sozinho e leu as dez vendas de todas as partições, como o `c1` fez. Quando o `b` entrou,
as partições foram distribuídas de novo. Num terceiro shell, pergunte quem tem o quê:

```
ubuntu@stream:~/work$ kafka-consumer-groups.sh --bootstrap-server localhost:9092 --describe --group shelf

GROUP           TOPIC           PARTITION  CURRENT-OFFSET  LOG-END-OFFSET  LAG             CONSUMER-ID                                  HOST            CLIENT-ID
shelf           sales           0          4               4               0               rdkafka-6ca0753c-f173-40e0-9a91-f0f99a179b6a /127.0.0.1      rdkafka
shelf           sales           1          4               4               0               rdkafka-6ca0753c-f173-40e0-9a91-f0f99a179b6a /127.0.0.1      rdkafka
shelf           sales           2          2               2               0               rdkafka-9547e082-fcb7-45cf-834b-6beee12b671b /127.0.0.1      rdkafka
```

Dois membros, distinguidos pelo `CONSUMER-ID`: um tem as partições 0 e 1, o outro a partição 2. Três
partições entre dois membros não se dividem por igual, e um membro fica com duas. Os offsets são os que
o `a` alcançou lendo sozinho, 4, 4 e 2, então quem agora tiver uma partição continua dali; **a posição
pertence ao grupo, não ao membro**.

Agora inicie `python consumer.py c --group shelf` em outro shell, e o `d` do mesmo jeito em mais um, e
mande mais dez vendas:

```
ubuntu@stream:~/work$ python producer.py
delivered per partition: {0: 4, 1: 4, 2: 2}
```

Depois pare os quatro com Ctrl+C e veja o que cada um imprimiu. O `a` leu o tópico inteiro primeiro,
sozinho, e depois:

```
ubuntu@stream:~/work$ python consumer.py a --group shelf
a: assigned [0, 1, 2]
a: partition 2 offset 0 rec-000005
a: partition 2 offset 1 rec-000010
a: partition 1 offset 0 car-000002
a: partition 1 offset 1 nat-000003
a: partition 1 offset 2 car-000007
a: partition 1 offset 3 nat-000008
a: partition 0 offset 0 oli-000001
a: partition 0 offset 1 joa-000004
a: partition 0 offset 2 oli-000006
a: partition 0 offset 3 joa-000009
a: revoked [0, 1, 2]
a: assigned [2]
a: revoked [2]
a: assigned [2]
a: revoked [2]
a: assigned [2]
a: partition 2 offset 2 rec-000005
a: partition 2 offset 3 rec-000010
a: revoked [2]
```

```
ubuntu@stream:~/work$ python consumer.py b --group shelf
b: assigned [0, 1]
b: revoked [0, 1]
b: assigned [1]
b: revoked [1]
b: assigned [1]
b: partition 1 offset 4 car-000002
b: partition 1 offset 5 nat-000003
b: partition 1 offset 6 car-000007
b: partition 1 offset 7 nat-000008
b: revoked [1]
```

```
ubuntu@stream:~/work$ python consumer.py c --group shelf
c: assigned [0]
c: revoked [0]
c: assigned [0]
c: partition 0 offset 4 oli-000001
c: partition 0 offset 5 joa-000004
c: partition 0 offset 6 oli-000006
c: partition 0 offset 7 joa-000009
c: revoked [0]
```

**Cada uma das dez vendas novas foi lida uma vez, por um membro**: o `a` leu as duas da partição 2, o
`b` as quatro da partição 1, o `c` as quatro da partição 0. O `b` começou com as partições 0 e 1, abriu
mão da 0 quando o `c` chegou, e ficou com a 1. E o `d` não leu nada; a próxima seção trata do porquê.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"O tópico sales com as partições 0, 1 e 2 no meio. À direita, o grupo shelf com quatro membros: c lê a partição 0, b a partição 1, a a partição 2, e d não tem partição. À esquerda, o grupo stock com um membro, c1, que lê as três partições. Cada grupo guarda os próprios offsets.\" data-fig=\"l4-group\"><defs><marker id=\"l4-group-ah-8343\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"360\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">tópico sales</text><rect x=\"290\" y=\"70\" width=\"140\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"85\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">partição 0</text><rect x=\"290\" y=\"120\" width=\"140\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"135\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">partição 1</text><rect x=\"290\" y=\"170\" width=\"140\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"185\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">partição 2</text><rect x=\"30\" y=\"95\" width=\"170\" height=\"80\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"115\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">grupo stock</text><rect x=\"80\" y=\"125\" width=\"70\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"115\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">c1</text><path d=\"M 286 85 L 154 140\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l4-group-ah-8343)\"></path><path d=\"M 286 135 L 154 140\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l4-group-ah-8343)\"></path><path d=\"M 286 185 L 154 140\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l4-group-ah-8343)\"></path><rect x=\"520\" y=\"45\" width=\"170\" height=\"195\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"605\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">grupo shelf</text><rect x=\"570\" y=\"83\" width=\"70\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"605\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">c</text><line x1=\"434\" y1=\"85\" x2=\"566\" y2=\"96\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" marker-end=\"url(#l4-group-ah-8343)\"></line><rect x=\"570\" y=\"123\" width=\"70\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"605\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">b</text><line x1=\"434\" y1=\"135\" x2=\"566\" y2=\"136\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" marker-end=\"url(#l4-group-ah-8343)\"></line><rect x=\"570\" y=\"163\" width=\"70\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"605\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">a</text><line x1=\"434\" y1=\"185\" x2=\"566\" y2=\"176\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" marker-end=\"url(#l4-group-ah-8343)\"></line><rect x=\"570\" y=\"201\" width=\"70\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"605\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">d</text><text x=\"665\" y=\"214\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">ocioso</text></svg>", "caption": "Dentro de um grupo cada partição tem um leitor; entre grupos, todo grupo lê tudo."}
```

## Dois grupos, dois leitores

O grupo `stock` da seção anterior não foi afetado por nada disso. É outro grupo, então tem os próprios
offsets, ainda em 4, 4 e 2, e as dez vendas novas estão esperando por ele. **Acrescentar um grupo
nunca tira nada de outro grupo.** É assim que os quatro sistemas da lição 2 leem as mesmas vendas: o
sistema de estoque como um grupo, o programa de fidelidade como outro, cada um com quantos membros a
sua carga pedir.
