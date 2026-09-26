---
title: Completo ou ligado?
version: 1
---

Todo hypervisor oferece os dois tipos de clone, com estes nomes ou parecidos:

| | clone completo | clone ligado |
|---|---|---|
| disco | uma cópia completa, 804M aqui | uma camada fina, 196K aqui quando novo |
| feito em | o tempo de copiar o disco | um instante |
| depende de | nada | do modelo, que nunca pode mudar |
| levá-lo para outro lugar | copiar um arquivo | copiar a cadeia inteira, ou torná-lo completo antes |
| serve para | uma máquina que vai viver sozinha | um laboratório, e muitas cópias de vida curta |

O diálogo *Clonar* do VirtualBox pergunta *Clone completo* ou *Clone ligado*, e um ligado precisa de um
snapshot da original para se pendurar. O VMware Workstation pergunta o mesmo, a partir de um snapshot ou
do estado atual. O Proxmox faz clones ligados de um modelo quando o armazenamento os suporta.

Seja qual for o tipo, vale a regra da primeira metade desta aula: **clone um modelo selado, não uma
máquina que alguém usou.** Um clone de uma máquina usada é uma segunda cópia daquela máquina, nome e
chaves incluídos, e os problemas começam no momento em que as duas estão na mesma rede.
