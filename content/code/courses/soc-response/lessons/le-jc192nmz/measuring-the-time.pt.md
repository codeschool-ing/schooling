---
title: Medir o tempo que ele economiza
version: 1
---

Um SOC mede a própria velocidade com três intervalos, e eles respondem a perguntas diferentes:

| medida | de | até | o que diz |
|---|---|---|---|
| **MTTD**, tempo médio para detectar | o evento | o alerta | quão boas são as regras |
| **MTTA**, tempo médio para reconhecer | o alerta | uma pessoa assumi-lo | quão bem a fila é atendida e ordenada |
| **MTTR**, tempo médio para responder | o alerta | a contenção | quão rápido a equipe, e a automação dela, agem |

A *média* é sobre muitos incidentes; um incidente dá um valor de cada. Aqui vai um exemplo calculado da
noite de quinta, **com horários supostos para ilustrar**, não tirados de nenhum log. O login foi às 02:33:07
e a regra da aula 4 rodava a cada cinco minutos, então o alerta disparou às 02:35. Ninguém estava de
sobreaviso; a ana chegou às 08:05, assumiu o alerta às 08:12, rodou o playbook, leu a proposta e aprovou o
bloqueio às 08:16.

| | intervalo | valor |
|---|---|---|
| detectar | 02:33 a 02:35 | 2 minutos |
| reconhecer | 02:35 a 08:12 | 5 horas e 37 minutos |
| responder | 02:35 a 08:16 | 5 horas e 41 minutos |

O playbook economizou talvez dez minutos do intervalo de resposta, e **cinco horas e meia foram gastas
esperando uma pessoa.** É a lição que a maioria das equipes aprende na primeira medição: o passo mais lento
raramente é o trabalho, é fazer o trabalho chegar a alguém. A automação mais barata daquela noite não era o
bloqueio; era mandar o alerta crítico para um celular às 02:35, com o chamado do playbook anexado.

Meça o playbook também. Em cada execução, o chamado diz o que ele propôs; uma pessoa diz depois se a
proposta estava certa. **A fração de propostas que uma pessoa rejeitou** é o número que decide quando um
passo de aprovação pode sair, e quando um playbook deve ser reescrito.
