---
title: Montando sem um Secret
version: 1
---

O desenho do operador tem uma propriedade que alguns times recusam: **o valor acaba num Secret do
Kubernetes**, no etcd, legível por quem pode ler Secrets naquele namespace. O **Secrets Store CSI
Driver** evita isso. Ele é um driver de volume: um pod monta um volume da classe
`secrets-store.csi.k8s.io`, e quando o pod sobe o driver busca as entradas no cofre, com a
identidade do próprio pod, e as escreve num volume em memória dentro só daquele pod.

| | External Secrets Operator | Secrets Store CSI Driver |
|---|---|---|
| onde o valor fica | num Secret, e em todo pod que o monta | num volume em cada pod que pede |
| quem entra no cofre | o operador, como uma ServiceAccount que você nomeia | o driver, como a ServiceAccount do próprio pod |
| quando é lido | periodicamente, haja pod rodando ou não | quando o pod sobe, e opcionalmente na rotação |
| variáveis de ambiente | sim, pelo Secret | só sincronizando também um Secret, o que abre mão do ponto |
| funciona com o cofre fora do ar | pods sobem com o último valor | pods que sobem não conseguem montá-lo |

A última linha é a troca. O Secret do operador é uma cópia, o que é um risco e também uma reserva:
um cofre fora do ar, ou um Vault que reiniciou selado, para valores novos, não pods novos. O driver
não tem cópia, então a disponibilidade do cofre vira a de todo pod. **A maioria dos times começa
pelo operador** e passa algumas cargas para o driver onde um Secret no etcd não é aceitável. Este
curso roda o operador e não instala o driver.
