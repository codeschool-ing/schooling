---
title: Escolher a disponibilidade, e a conta que chega depois
version: 1
---

**Um sistema que escolhe a disponibilidade responde dos dois lados de um corte e paga depois: quando
o enlace volta, duas histórias precisam virar uma.** Esse sistema é chamado de AP. Durante a
partição ele parece melhor que um sistema CP, porque ninguém vê erro. O custo chega depois, como uma
decisão sobre qual de duas histórias verdadeiras guardar.

## Onde responder é o certo

O Dynamo da Amazon, descrito num artigo em 2007, é o caso clássico. O exemplo dele era o carrinho de
compras: um cliente que acrescenta um item nunca pode ouvir que volte mais tarde, e se duas cópias de
um carrinho discordam, o carrinho combinado pode ficar com os dois itens e o cliente tira um. Um
carrinho errado por um minuto custa menos que um erro no botão que faz dinheiro.

Na Roda Livre, o mesmo raciocínio serve para **o mapa de docas do aplicativo**. Um mapa que mostra a
Rua XV com 7 bicicletas quando ela tem 6 não leva ninguém muito longe do certo. Um mapa que mostra
um erro manda o cliente ir até lá a pé para ver.

## Três jeitos de duas cópias virarem uma

Quando o enlace volta, `n1` e `n2` dizem 5 e o `n3` diz 7. Os sistemas que escolheram a
disponibilidade resolvem isso de um de três jeitos.

| jeito | o que acontece | o custo |
|---|---|---|
| a última escrita vence | fica o valor escrito por último, pelo seu horário | a outra escrita é jogada fora |
| guardar as duas e perguntar | as duas versões são guardadas e entregues à aplicação na próxima leitura | a aplicação precisa saber combiná-las |
| combinar por construção | o dado é guardado num formato em que quaisquer duas cópias se combinam | só alguns dados têm esse formato |

O primeiro e o terceiro são fáceis de rodar lado a lado. Salve em `~/roda/cap` como `merge.py`:

```python
# cap/merge.py
# ST02 had 6 bicycles when the link to n3 was cut. During the cut,
# n1 saw one taken at 08:02 and n3 saw one returned at 08:05.

# Last write wins: each copy is a value and the time it was written.
n1 = {"value": 5, "at": "2025-10-03 08:02"}
n3 = {"value": 7, "at": "2025-10-03 08:05"}
print("last write wins:", max(n1, n3, key=lambda c: c["at"])["value"])

# A counter that merges: each node counts only what it saw itself.
START = 6
n1c = {"taken": {"n1": 1}, "returned": {}}
n3c = {"taken": {}, "returned": {"n3": 1}}


def merge(a, b):
    out = {}
    for kind in ("taken", "returned"):
        nodes = set(a[kind]) | set(b[kind])
        out[kind] = {n: max(a[kind].get(n, 0), b[kind].get(n, 0)) for n in nodes}
    return out


def value(c):
    return START - sum(c["taken"].values()) + sum(c["returned"].values())


m = merge(n1c, n3c)
print("merged counter:", value(m))
print("either order:", merge(n3c, n1c) == m)
print("merged twice:", merge(m, n3c) == m)
```

```
ana@lab:~/roda/cap$ python merge.py
last write wins: 7
merged counter: 6
either order: True
merged twice: True
```

## A última escrita vence perdeu uma bicicleta

A devolução das 08:05 é posterior à viagem das 08:02, então a regra da última escrita ficou com 7 e
jogou a viagem fora. **Nenhum nó estava errado sobre o que viu; foi a regra que descartou um deles.**
E nada avisa. A Rua XV mostra uma bicicleta a mais do que tem até alguém ir lá e contar.

A regra tem uma segunda fraqueza, que a aula 9 já nomeou: ela confia nos relógios. Se o relógio do
`n3` estivesse alguns minutos adiantado, uma escrita que aconteceu antes ainda assim venceria. O
Cassandra resolve escritas em conflito exatamente assim, pelo horário, um valor de cada vez — e é por
isso que quem o opera se importa tanto com os relógios das suas máquinas.

## O contador que se combina

A segunda metade do programa guarda outra coisa. Em vez da contagem, cada nó guarda quantas
bicicletas **ele próprio** viu sair e voltar. Dois registros assim sempre se combinam: pegue, para
cada nó, o maior dos dois números que ele informou, já que a contagem própria de um nó só cresce. O
contador combinado diz 6, que é a verdade.

As duas últimas linhas são a razão de isso ser seguro. **A ordem da combinação não importa, e
combinar a mesma cópia duas vezes não muda nada.** Então as cópias podem ser combinadas sempre que se
encontram, em qualquer ordem, quantas vezes a rede as entregar. Um tipo de dado construído para ter
essas propriedades se chama **CRDT**, *conflict-free replicated data type*, um nome de 2011.
Contadores, conjuntos e registradores têm todos versões assim.

O limite é aquele de onde a seção 04 partiu. Uma contagem se combina. "A
bicicleta `B017` está destravada para este cliente" não: não há como combinar dois clientes com uma
bicicleta só numa resposta correta. **Dado que se combina pode morar do lado AP; uma decisão que não
se combina pertence ao lado CP.**
