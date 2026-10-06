---
title: O time azul
version: 1
---

As cores vêm dos jogos de guerra militares, em que azul era o lado da casa e vermelho a força
adversária, e a convenção veio com eles para a segurança. **O time azul defende.** Na maioria das
organizações ele nem é uma unidade especial: é todo mundo cujo trabalho é manter os sistemas seguros e
perceber quando não estão.

O que o time azul faz se divide em três tipos de trabalho, que batem com as funções de controle da
aula 4:

| trabalho | o que quer dizer | na livraria |
|---|---|---|
| **prevenir** | endurecer sistemas, aplicar patches, escrever regras de firewall, gerir acessos | as zonas da aula 5, as permissões da aula 6, o MFA da aula 9 |
| **detectar** | coletar logs, escrever regras que transformam eventos em alertas, vigiá-los | o log do portal, e alguém que o leia |
| **responder** | conter um incidente, tirar o atacante, restaurar, aprender | revogar uma senha vazada, restaurar do backup |

Numa organização maior, o trabalho de detectar e responder mora num **centro de operações de segurança
(SOC)**: uma equipe que vigia alertas o tempo todo, separa os reais do ruído e começa a resposta. Na
livraria, o time azul é a ana, parte da semana dela, com a ajuda dos sócios quando é preciso decidir
algo. O trabalho é o mesmo; só a escala muda.

### A desvantagem do defensor

Costuma-se dizer que o defensor precisa acertar sempre e o atacante só uma vez. Isso é meia verdade.
Descreve a **prevenção**: um patch esquecido pode bastar para entrar. Não descreve a **detecção**, onde a
balança vira: um atacante que está dentro precisa ficar invisível em cada passo, achando o caminho,
alcançando mais máquinas, tirando os dados, e o defensor só precisa notar um deles. É por isso que a
aula 4 chamou a detecção de camada por direito próprio, e por isso tanto do trabalho do time azul é
sobre logs.

A fraqueza do time azul é a de todo construtor: **ele testa o que pensou.** O firewall da aula 5 foi
testado de três zonas porque quem o escreveu pensou em três zonas. Um atacante não tem obrigação
nenhuma de chegar por uma delas. As duas próximas seções tratam de conseguir um olhar que os
construtores não têm.
