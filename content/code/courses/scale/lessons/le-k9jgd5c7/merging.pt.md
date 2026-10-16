---
title: Dados que se juntam sozinhos
version: 1
---

As duas junções da última seção que não perderam nada, a união dos carrinhos e o contador guardado
por réplica, têm algo em comum. **Elas não guardam valores; guardam o que aconteceu, numa forma em
que combinar duas histórias tem uma só resposta sensata.** Um conjunto de coisas acrescentadas se
junta por união. Um contador feito de uma entrada por réplica se junta pegando o maior valor de cada
entrada, porque cada entrada só cresce e só a própria réplica a muda.

Dados com esse formato têm nome: um **CRDT**, tipo de dado replicado livre de conflito
(*conflict-free replicated data type*). A junção dele tem três propriedades, e cada uma tira um
problema que um sistema distribuído teria de resolver:

- **Comutativa**: juntar A em B dá o mesmo que juntar B em A. A ordem em que duas réplicas ouvem uma
  da outra não importa.
- **Associativa**: juntar três cópias em qualquer agrupamento dá uma resposta só, então as réplicas
  podem trocar notícias em qualquer padrão.
- **Idempotente**: juntar a mesma cópia duas vezes não muda nada, então uma mensagem entregue duas
  vezes, coisa que redes fazem, é inofensiva.

Com essas três, **toda réplica que viu as mesmas atualizações tem o mesmo valor**, seja qual for a
ordem em que chegaram. Isso é consistência eventual sem relógio e sem coordenador, e sem escrita
perdida.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"A junção de um G-counter. Antes da partição as duas réplicas têm a: 50, b: 50. Durante ela, a réplica A sobe a própria entrada para 53 e a réplica B sobe a sua para 52. Juntar fica com o maior valor de cada entrada, dando a: 53, b: 52, total 105.\"><rect x=\"40\" y=\"90\" width=\"150\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"115\" y=\"105\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">antes</text><text x=\"115\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">a:50 b:50</text><path d=\"M190 115 L260 60\" stroke=\"var(--wire)\" stroke-width=\"1.5\" fill=\"none\"></path><path d=\"M260 60 L256.9 66.3 L253.2 61.5 Z\" fill=\"var(--wire)\" stroke=\"none\"></path><path d=\"M190 115 L260 170\" stroke=\"var(--wire)\" stroke-width=\"1.5\" fill=\"none\"></path><path d=\"M260 170 L253.2 168.5 L256.9 163.7 Z\" fill=\"var(--wire)\" stroke=\"none\"></path><rect x=\"260\" y=\"35\" width=\"170\" height=\"50\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"345\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">réplica A, +3</text><text x=\"345\" y=\"69\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">a:53 b:50</text><rect x=\"260\" y=\"145\" width=\"170\" height=\"50\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"345\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">réplica B, +2</text><text x=\"345\" y=\"179\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">a:50 b:52</text><path d=\"M430 60 L500 115\" stroke=\"var(--wire)\" stroke-width=\"1.5\" fill=\"none\"></path><path d=\"M500 115 L493.2 113.5 L496.9 108.7 Z\" fill=\"var(--wire)\" stroke=\"none\"></path><path d=\"M430 170 L500 115\" stroke=\"var(--wire)\" stroke-width=\"1.5\" fill=\"none\"></path><path d=\"M500 115 L496.9 121.3 L493.2 116.5 Z\" fill=\"var(--wire)\" stroke=\"none\"></path><rect x=\"500\" y=\"90\" width=\"180\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></rect><text x=\"590\" y=\"105\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">junção: máximo de cada</text><text x=\"590\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">a:53 b:52 = 105</text></svg>", "caption": "Cada réplica só aumenta a própria entrada, então ficar com o maior de cada entrada nunca perde uma venda."}
```

## A pequena família

O contador do programa é um **G-counter**, que só cresce (*grow-only*): `{'a': 53, 'b': 52}`, total
105, toda venda mantida. Alguns parentes cobrem a maior parte do que as aplicações precisam:

- **PN-counter**: dois G-counters, um para incrementos e um para decrementos, e o valor é a
  diferença. Um estoque que sobe e desce.
- **G-set**: um conjunto que só cresce, juntado por união. O carrinho do programa, se itens nunca
  forem removidos.
- **OR-set**, conjunto de remoção observada: um conjunto em que cada acréscimo leva uma etiqueta
  única e uma remoção nomeia as etiquetas que viu. Um item removido de um lado e acrescentado de novo
  do outro fica, que é o que um comprador que o pôs de volta espera.
- **LWW-register**: um valor só com um carimbo, juntado pela última escrita. Ele está na família
  porque a junção dele também tem as três propriedades; continua sendo o que perde escritas.

## O que eles não conseguem

Um CRDT garante que as cópias convergem. Não garante que o valor em que convergem respeite uma regra.
**Dois lados que vendem cada um o último lugar convergem para um contador de capacidade mais um**,
perfeitamente consistente e errado. Toda regra do tipo "nunca mais que", "no máximo um", "único"
precisa que os dois lados concordem antes da escrita, o que é coordenação, que é de novo a escolha
consistente da seção 02.

Essa é a fronteira da aula inteira, e a próxima seção a desenha para a bilheteria.
