---
title: Escolher a consistência, e quanto custa recusar
version: 1
---

**Um sistema que escolhe a consistência só responde quando pode ter certeza de que a resposta está
atual, e do lado errado de um corte isso quer dizer responder com um erro.** Esse sistema é chamado
de CP. O nome parece uma propriedade do sistema inteiro, mas o que ele descreve é uma regra que cada
nó segue quando não consegue alcançar os outros em número suficiente.

## Como um sistema CP sabe que pode falar

A regra no `replicas.py` era uma maioria, e os sistemas reais usam a mesma ideia. Os quóruns da aula
9 mostraram que uma escrita confirmada por uma maioria e uma leitura que consulta uma maioria
precisam se cruzar em pelo menos um nó, e assim a leitura vê a escrita. Um sistema CP dá um segundo
uso à maioria: só um grupo de nós pode tê-la de cada vez, então só um grupo pode aceitar escritas.

Manter um grupo de máquinas de acordo sobre a ordem de cada escrita, atravessando quedas e enlaces
cortados, se chama **consenso**, e vale reconhecer dois algoritmos pelo nome. O **Paxos**, de Leslie
Lamport, é o mais antigo. O **Raft**, publicado em 2014, foi desenhado para ser mais fácil de
entender e de implementar corretamente. O etcd, o banco em que o Kubernetes guarda o seu estado, roda
Raft. O ZooKeeper roda um protocolo próprio, o ZAB, construído sobre a mesma ideia de maioria. Nenhum
dos dois algoritmos cabe a este curso ensinar; o que importa aqui é quanto custa usar um.

## Quanto custa

Recusar durante uma partição é o custo que todo mundo vê. Outros dois são pagos nos dias comuns, e
costumam ser a conta maior.

| custo | quando é pago | na Roda Livre |
|---|---|---|
| o lado minoritário recusa | só durante uma partição | a cliente no `n3` não consegue devolver a bicicleta pelo aplicativo |
| toda escrita espera que uma maioria a confirme | em toda escrita, com ou sem partição | cada destravamento espera uma segunda máquina responder |
| perder o líder para as escritas até que um novo seja escolhido | cada vez que cai a máquina que coordena as escritas | uma pausa em que nenhuma bicicleta pode ser destravada |

A segunda linha é a que o teorema não menciona, porque o teorema só fala durante uma partição. A
seção 06 dá um nome a ela.

## Onde recusar é o certo

**Escolha a consistência onde duas respostas diferentes seriam piores do que nenhuma.** O teste é
imaginar os dois lados de um corte dizendo sim ao mesmo tempo, e perguntar se dá para desfazer isso.

- **Uma bicicleta é destravada para um cliente.** Se a `B017` fosse destravada para duas pessoas, uma
  de cada lado de um corte, a segunda encontraria uma doca vazia e uma cobrança por uma viagem que
  nunca fez.
- **Um pagamento é cobrado uma vez.** Cobrar duas vezes, ou registrar uma cobrança que não
  aconteceu, é um incidente com um cliente ao telefone.
- **Uma máquina está no comando.** Quando um grupo de máquinas elege uma para coordenar as outras,
  dois líderes ao mesmo tempo, o chamado *split brain*, é a falha que a eleição existe para evitar.

Uma recusa também é o tipo de falha que a aula 1 chamou de tipo bom. Ela é barulhenta: o cliente
recebe um erro que pode tentar de novo, e as novas tentativas com escrita idempotente da aula 9
tornam essa nova tentativa segura. Um sistema que escolhesse a disponibilidade para um pagamento não
falharia de forma barulhenta. Ele teria sucesso duas vezes.
