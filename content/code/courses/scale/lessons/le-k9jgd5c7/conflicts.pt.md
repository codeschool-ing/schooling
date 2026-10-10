---
title: Conflitos, e a escrita que some
version: 1
---

A réplica do PostgreSQL nunca escreve, então nunca discorda do primário; ela só pode estar
atrasada. **Um sistema que deixa os dois lados de uma partição aceitarem escritas** tem um problema
mais difícil: quando a partição se fecha, duas cópias têm dois valores diferentes para a mesma
coisa, cada um uma escrita que alguém ouviu que deu certo.

Esse é o preço de escolher disponibilidade para escritas. Um carrinho de compras é o caso clássico e
o motivo de o Dynamo da Amazon ter sido construído assim: um comprador que não consegue pôr algo no
carrinho porque um data center está inalcançável é uma venda perdida, então o carrinho aceita a
escrita do lado que o comprador alcança, e o sistema reconcilia depois.

Como ele reconcilia decide se uma escrita se perde. Este programa encena duas escritas
particionadas e dois jeitos de juntar cada uma:

```schooling-example
{"language": "python", "file": "merge.py", "parts": [{"code": "# merge.py\n\"\"\"Two replicas accept writes during a partition. Then the partition heals.\"\"\"\n\n# A cart, kept as one value with the time it was written. Replica B's clock\n# runs 40 ms behind replica A's, which is well within what real clocks do.\na = {\"cart\": ([\"vinyl\"], 10.000)}            # written on A at 10.000 by A's clock\nb = {\"cart\": ([\"poster\"], 10.010 - 0.040)}   # written on B 10 ms LATER, read by B's clock\n\nwinner = max(a[\"cart\"], b[\"cart\"], key=lambda item: item[1])\nprint(\"last write wins:\", winner[0])", "note": "O carrinho de um comprador é escrito dos dois lados de uma partição: um disco em A, e **dez milissegundos depois**, um pôster em B. Cada réplica carimba a escrita com o próprio relógio, e o de B está 40 ms atrasado. Quando elas se encontram, **a última escrita vence** fica com a escrita de carimbo maior."}, {"code": "\n# The same two writes kept as additions to a set, which merges by union.\nprint(\"merge by union: \", sorted(set(a[\"cart\"][0]) | set(b[\"cart\"][0])))", "note": "As mesmas duas escritas, entendidas como **acrescentar um item**. Dois conjuntos de acréscimos se juntam pegando tudo o que está em qualquer um."}, {"code": "\n# A counter of tickets sold. A sells 3 and B sells 2 while they cannot talk.\nplain_a, plain_b = 100 + 3, 100 + 2\nprint(\"one number, last write wins:\", max(plain_a, plain_b), \"sold, after\", 100 + 3 + 2, \"sales\")", "note": "Um contador que valia 100 antes da partição, guardado como um número só. Cada lado soma as próprias vendas à sua cópia, e quando elas se encontram só um dos dois números pode sobreviver."}, {"code": "\n# The same counter as one entry per replica; each replica only adds to its own.\ncounts_a = {\"a\": 50 + 3, \"b\": 50}\ncounts_b = {\"a\": 50, \"b\": 50 + 2}\nmerged = {r: max(counts_a[r], counts_b[r]) for r in counts_a}\nprint(\"one entry per replica:\", merged, \"=\", sum(merged.values()), \"sold\")", "note": "O mesmo contador guardado como **uma entrada por réplica**, que só a própria réplica aumenta. Juntar fica com o maior valor de cada entrada, e o total é a soma delas. A seção 09 explica por que isso não perde uma venda."}]}
```

```
ana@lab:~/tickets$ python3 merge.py
last write wins: ['vinyl']
merge by union:  ['poster', 'vinyl']
one number, last write wins: 103 sold, after 105 sales
one entry per replica: {'a': 53, 'b': 52} = 105 sold
```

## A última escrita vence, e o relógio que mente

**A última escrita vence**, LWW (*last write wins*), fica com o valor de carimbo mais recente e
descarta o outro. É a regra mais comum porque é a mais simples, e duas propriedades dela estão na
primeira linha da saída:

- **Uma das duas escritas é descartada.** O comprador pôs um disco de um lado e um pôster do outro,
  e o carrinho agora tem um deles. Ninguém é avisado.
- **"Mais recente" quer dizer mais recente pelo relógio de alguém.** O pôster foi escrito dez
  milissegundos **depois** do disco, mas o relógio de B está 40 ms atrasado, então o carimbo dele é
  anterior e **a escrita mais antiga venceu**. Relógios de máquinas diferentes discordam por
  milissegundos como coisa normal, e por muito mais depois de uma sincronização ruim. O LWW
  transforma essa discordância em dado perdido.

O LWW é a regra certa só quando perder uma escrita concorrente é aceitável, que é o caso de um valor
trocado inteiro e cuja última versão é a única que alguém quer: o nome de exibição de um usuário, a
posição de um player.

## O contador

A terceira linha é pior porque parece plausível. Um contador de ingressos vendidos estava em 100; um
lado vendeu três e o outro dois. Guardado como um número, cada lado tem o seu total, 103 e 102, e o
que sobreviver **esquece as vendas do outro lado**. A bilheteria informa 103 ingressos vendidos
depois de vender 105, e cada um dos cinco compradores tem um ingresso válido.

A correção da última linha, e a união da segunda, são o assunto da próxima seção: as duas chegam à
resposta certa sem perguntar qual escrita veio por último, porque nunca precisaram saber.
