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

@@fence@@

Dois membros, distinguidos pelo `CONSUMER-ID`: um tem as partições 0 e 1, o outro a partição 2. Três
partições entre dois membros não se dividem por igual, e um membro fica com duas. Os offsets são os que
o `a` alcançou lendo sozinho, 4, 4 e 2, então quem agora tiver uma partição continua dali; **a posição
pertence ao grupo, não ao membro**.

Agora inicie `python consumer.py c --group shelf` em outro shell, e o `d` do mesmo jeito em mais um, e
mande mais dez vendas:

@@fence@@

Depois pare os quatro com Ctrl+C e veja o que cada um imprimiu. O `a` leu o tópico inteiro primeiro,
sozinho, e depois:

@@fence@@

@@fence@@

@@fence@@

**Cada uma das dez vendas novas foi lida uma vez, por um membro**: o `a` leu as duas da partição 2, o
`b` as quatro da partição 1, o `c` as quatro da partição 0. O `b` começou com as partições 0 e 1, abriu
mão da 0 quando o `c` chegou, e ficou com a 1. E o `d` não leu nada; a próxima seção trata do porquê.

@@fig:l4-group@@

## Dois grupos, dois leitores

O grupo `stock` da seção anterior não foi afetado por nada disso. É outro grupo, então tem os próprios
offsets, ainda em 4, 4 e 2, e as dez vendas novas estão esperando por ele. **Acrescentar um grupo
nunca tira nada de outro grupo.** É assim que os quatro sistemas da lição 2 leem as mesmas vendas: o
sistema de estoque como um grupo, o programa de fidelidade como outro, cada um com quantos membros a
sua carga pedir.
