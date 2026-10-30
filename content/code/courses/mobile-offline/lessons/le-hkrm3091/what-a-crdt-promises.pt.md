---
title: O que um CRDT promete, e o que não promete
version: 1
---

**Um CRDT é um tipo de dado cujas cópias sempre podem ser mescladas, em qualquer ordem, no mesmo
estado.** A sigla vem de *conflict-free replicated data type*, tipo de dado replicado sem conflito.
As aulas 13 e 14 pegaram um dado comum, uma linha com campos, e perguntaram o que fazer quando duas
cópias discordam. Um CRDT começa pela outra ponta: dá ao dado uma forma em que todo par de mudanças
concorrentes tem uma mescla escrita de antemão, e nunca sobra pergunta a fazer.

A promessa se apoia em três propriedades da mescla, e cada uma responde a um problema que uma camada
de sincronização tem de verdade.

| propriedade | o que diz | o problema que remove |
|---|---|---|
| **comutativa** | mesclar A em B dá o mesmo que mesclar B em A | os aparelhos sincronizam na ordem em que acham rede |
| **associativa** | mesclar A e B, depois C, dá o mesmo que A com B-e-C | as atualizações podem viajar por outros aparelhos, em grupos |
| **idempotente** | mesclar a mesma atualização duas vezes não muda nada | as novas tentativas da aula 9 entregam algumas atualizações mais de uma vez |

Juntas, elas dão a **consistência eventual forte**: duas cópias quaisquer que receberam o mesmo
conjunto de atualizações estão no mesmo estado, qualquer que tenha sido a ordem de chegada e quantas
vezes elas chegaram. Ninguém precisa coordenar, nenhum servidor precisa decidir, e um aparelho que
ficou offline uma semana converge no momento em que se atualiza.

## A promessa é convergência, não intenção

A crença comum é que um CRDT resolve conflitos do jeito que a pessoa queria. Ele não resolve, e não
diz que resolve. **Ele garante que todo aparelho termina concordando; não garante que aquilo em que
concordam está certo.** Onde dois aparelhos põem o mesmo valor ao mesmo tempo, um CRDT ainda precisa
ficar com um deles, e faz isso por uma regra fixa, a mesma em todo aparelho. É a última escrita
vence da aula 13 com um desempate melhor, não uma leitura da mente de ninguém.

O que faz os CRDTs merecerem uma aula é que, para alguns tipos de dado, a mescla que eles escrevem é
exatamente o que as pessoas querem dizer:

- **um contador** em que toda soma conta, então +30 e +45 dão +75;
- **um conjunto** em que um item acrescentado num aparelho e outro removido num segundo valem os
  dois;
- **uma lista ou um texto** em que duas pessoas inserindo no mesmo lugar mantêm as palavras das duas,
  numa ordem com que todo aparelho concorda.

A próxima seção constrói os dois primeiros à mão, em poucas linhas cada, para a garantia poder ser
conferida em vez de acreditada. A seguinte usa uma biblioteca para o terceiro, que ninguém deveria
escrever à mão.
