---
title: O cluster autoscaler acrescenta e remove máquinas
version: 1
---

Os dois autoscalers até aqui trabalham dentro dos nós que o cluster tem. Quando o HPA acrescenta pods
que não cabem, eles ficam `Pending`, como a quinta cópia da lição 19. **O cluster autoscaler observa
exatamente isso**: pods que não podem ser alocados por falta de espaço. Ele pede à nuvem mais uma
máquina num grupo de nós que os comporte, e o nó novo entra no cluster e recebe os pods.

Ele funciona na outra direção também. Um nó cujos pods todos caberiam em outro lugar, por um tempo, é
drenado, respeitando os PodDisruptionBudgets como o drain da lição 32, e a máquina é devolvida.

O kind não consegue crescer: os nós dele são containers criados junto com o cluster, então nada aqui
foi rodado, e esta seção só descreve.

| | cluster autoscaler | provisionamento automático de nós (Karpenter, GKE, AKS) |
|---|---|---|
| escolhe | quantas máquinas, em grupos de nós definidos antes | o tipo de máquina também, pelo que os pods pendentes pedem |
| reage a | pods `Pending` por falta de espaço | o mesmo |
| remove | nós cujos pods cabem em outro lugar | o mesmo, e pode trocar nós por outros mais baratos |

Duas configurações decidem a maior parte do comportamento dele. **Requests**, de novo: ele acrescenta um
nó quando os requests não cabem, nunca por causa do uso, então o desperdício da lição 21 vira máquinas
compradas à toa. E **PodDisruptionBudgets e anotações `safe-to-evict`**: um pod que ele não pode mover
mantém o nó vivo, então um único pod mal configurado pode manter uma máquina inteira na conta.

Os quatro juntos fazem o ciclo completo: o HPA acrescenta pods sob carga, o scheduler os aloca, o
cluster autoscaler compra uma máquina quando eles não cabem, e quando a carga vai embora, o HPA remove
pods e o cluster autoscaler devolve a máquina.
