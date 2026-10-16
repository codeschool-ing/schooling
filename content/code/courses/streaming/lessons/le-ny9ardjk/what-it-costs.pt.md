---
title: O que a replicação custa, e o que este laboratório não consegue mostrar
version: 1
---

**Um fator de replicação 3 guarda cada byte três vezes, manda cada byte pela rede pelo menos três
vezes, e só protege contra as falhas que as três cópias não compartilham.** As duas primeiras coisas
são uma conta; a terceira é uma decisão de projeto que este laboratório, numa máquina só, não
consegue demonstrar.

## Disco e rede

O `wc -c` da seção sobre líderes e seguidores mediu a primeira: o mesmo segmento, com o mesmo
número de bytes, uma vez por nó. Trezentas vendas ocuparam **32.443 bytes** em cada nó, 97.329 ao
todo. Toda conta de capacidade de um cluster Kafka tem o fator de replicação dentro, e a lição 17
faz essa conta para a Ponto Final.

A rede é o custo menos óbvio. Cada registro atravessa a rede uma vez do produtor até o líder, e
mais uma vez **para cada seguidor** que o busca, então um fator de replicação 3 põe duas cópias a
mais de cada escrita no fio entre os brokers, antes de qualquer consumidor ler qualquer coisa. Um
cluster espalhado por três data centers ou zonas de nuvem, que é onde um fator de replicação 3 se
paga, paga esse tráfego ao preço do tráfego entre zonas, que nas nuvens públicas é cobrado e
costuma ser o maior item de uma conta de streaming depois das próprias máquinas.

## Domínios de falha

Três cópias protegem contra a perda de uma ou duas delas só se as três não falharem juntas. Três
brokers num rack compartilham uma fonte de energia e um switch; três brokers numa zona de nuvem
compartilham as quedas daquela zona. A configuração que os espalha é **`broker.rack`**: dê a cada
broker o nome do seu rack ou zona, e o Kafka põe as réplicas de cada partição em racks diferentes
quando cria um tópico. Com o `replica.selector.class` dos brokers apontando para o seletor do
Kafka que conhece racks, os consumidores podem então receber **`client.rack`** para ler do
seguidor na própria zona em vez de cruzar até o líder, a leitura em seguidores mencionada na seção
sobre líderes e seguidores.

**Nada neste laboratório é um domínio de falha de verdade.** Os três nós são três processos numa
máquina virtual, com um disco e uma fonte de energia: perder a máquina perde os três. Toda falha
desta lição foi um processo terminando, que é o tipo de falha que a replicação trata, e nenhuma foi
um disco, um rack ou uma zona, que são os tipos para os quais ela existe. O comportamento que você
viu é o mesmo; a proteção só existe em hardware separado.

## Escolhendo um fator de replicação

| fator de replicação | `min.insync.replicas` | sobrevive, ainda gravando | usado para |
|---|---|---|---|
| 1 | 1 | nada | um laboratório, ou dados que podem ser refeitos de outro lugar |
| 2 | 1 | uma falha, mas aí uma cópia só recebe as escritas | raramente uma boa troca |
| 3 | 2 | uma falha, com cada escrita em dois discos | o padrão de produção |
| 5 | 3 | duas falhas | dados cuja perda seria um desastre, a um preço alto |

**Um fator de replicação 2 é a armadilha dessa tabela.** Com `min.insync.replicas=2` ele para de
receber escritas quando qualquer um dos nós cai, o que é toda janela de manutenção; com 1, recebe
escritas num disco só sempre que um nó está fora. Três é o menor número com uma resposta que não é
nenhuma das duas.
