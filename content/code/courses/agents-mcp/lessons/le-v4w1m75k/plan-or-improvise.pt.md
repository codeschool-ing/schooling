---
title: Planejar antes, ou decidir no caminho?
version: 1
---

Os agentes da aula 3 decidiam um passo de cada vez: olhar o último resultado, escolher a próxima chamada. Isso funciona bem em tarefas curtas e mal em longas, em que o modelo pode perder de vista a segunda metade de um pedido enquanto persegue a primeira. O outro extremo é escrever o plano inteiro antes de agir e depois executá-lo, o que funciona mal sempre que o resultado de um passo muda o que os passos seguintes deveriam ser. **A maioria dos agentes úteis faz as duas coisas: escreve um plano, age sobre ele e o reescreve quando um resultado diz que o plano estava errado.**

| | decidir no caminho | planejar, depois executar | planejar, agir, revisar |
|---|---|---|---|
| como | cada passo escolhido pelo último resultado | todos os passos escritos antes, depois rodados em ordem | um plano escrito, atualizado conforme os resultados chegam |
| bom em | tarefas curtas; surpresas | tarefas longas de forma conhecida | tarefas longas com surpresas |
| falha quando | o pedido tem várias partes e uma é esquecida | o resultado de um passo invalida o resto | o plano e o trabalho se desencontram (seção 06) |
| visível a uma pessoa | só pelo rastro | como plano, antes de qualquer coisa rodar | como um plano que muda, e por quê |

A terceira coluna é o que esta aula constrói. A vantagem prática dela é que **o plano vira um objeto que o hospedeiro guarda**, e não um pensamento dentro do modelo. O hospedeiro pode imprimi-lo, armazená-lo, mostrá-lo ao cliente como progresso, entregá-lo a uma pessoa quando a execução para e compará-lo com o que as ferramentas de fato devolveram.

## Por que escrever o plano

Um modelo a quem se pede para planejar "de cabeça" planeja no texto da resposta, que some de vista no momento em que a próxima resposta chega e não tem estrutura que algo possa conferir. Um plano escrito por uma chamada de ferramenta tem um esquema: uma lista de passos, cada um com um status de um conjunto fechado. Isso permite três coisas que o texto livre não permite:

- **o progresso é contável**: três passos, um feito;
- **uma execução parada pode ser retomada por uma pessoa**: eis o que foi planejado e até onde chegou;
- **um plano mudado fica visível**: um passo marcado `dropped` diz que o modelo decidiu não fazê-lo, em vez de esquecê-lo em silêncio.

Agentes de código fazem exatamente isso com uma lista de tarefas que vão atualizando enquanto trabalham, pelos mesmos motivos. O custo são alguns passos e tokens a mais por execução, que a seção 04 conta.
