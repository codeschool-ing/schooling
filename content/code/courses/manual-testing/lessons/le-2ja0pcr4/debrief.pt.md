---
title: A conversa final
version: 1
---

Uma sessão não termina quando o tempo fixo acaba. Ela termina depois de uma **conversa final**, o
*debrief* em inglês: uma conversa curta, de dez ou quinze minutos, entre o testador e quem lidera o
teste, feita o mais perto possível do fim da sessão. Equipes que a pulam acabam com folhas de sessão
que ninguém lê, e as notas de uma sessão são escritas na abreviação do testador e fazem sentido
completo por mais ou menos um dia. **A conversa final é onde as notas viram decisões**: o que é
relatado, o que entra numa suíte, qual é a próxima sessão.

## PROOF

Jonathan Bach, um dos dois autores da gestão de teste baseada em sessões, deu à conversa final uma
lista que soletra o próprio nome em inglês, *PROOF*: passado, resultados, obstáculos, perspectivas e
sentimentos. A conversa final da Ana sobre a sessão da seção 05, com a líder de teste do teatro,
passou por ela assim.

**Past, o passado: o que aconteceu?** Sessenta minutos sobre a vida de um pedido, na 1.1. Nove dos
vinte pares de ação e estado, no navegador e com o curl, e uma pergunta sobre o tempo, montada na
sessão e terminada à noite.

**Results, os resultados: o que foi encontrado?** Dois defeitos novos, cada um com a transcrição: as
mensagens de recusa colam `ed` na ação, e um pedido pago é reembolsado depois que o espetáculo
começou. Um defeito conhecido visto de novo, o reembolso de um pedido usado, que não precisa de nada
novo. A primeira pergunta da líder é se os dois novos são mesmo dois, e a resposta é sim: um é uma
regra de redação em toda recusa, o outro é uma regra que falta na única ação que não é recusada
quando devia ser. Têm causas diferentes, correções diferentes e severidades diferentes, então são
dois relatórios.

**Obstacles, os obstáculos: o que atrapalhou?** O relógio. Com o `BOXOFFICE_NOW` o tempo da aplicação
fica parado, e sem ele o tempo só anda tão rápido quanto a noite real; nada deixa um testador mover
o relógio enquanto a aplicação guarda os pedidos. **Isso é um problema de testabilidade, e vai para o
Rui como pedido, não como defeito**: um jeito de mover o relógio de uma aplicação em execução, ou
pedidos que sobrevivam a um reinício, transformaria a hora de espera num minuto. Um obstáculo anotado
numa conversa final muitas vezes é a melhoria mais barata que uma equipe já fez, porque ninguém mais
sabia que ele existia.

**Outlook, as perspectivas: o que ainda falta?** Onze pares não foram tentados. As duas oportunidades
da folha estão perto da missão e são pequenas: a contagem de lugares depois de um reembolso tardio, e
reservar exatamente às 18:59 e às 19:00. A líder transforma as três numa missão nova, *explore os
estados do pedido e o horário de fechamento com os pares que faltam e o `BOXOFFICE_NOW` ajustado em
volta das 19:00, para descobrir o que mais o R4 e o R6 deixam em aberto*, e a põe no topo da lista da
semana que vem.

**Feelings, os sentimentos: como o testador se sente sobre a área?** Este soa vago e não é. A Ana diz
que a área de pedidos parece mais frágil do que os casos roteirizados a faziam parecer: os três
defeitos dela aparecem no momento em que um pedido muda de estado, e dois foram encontrados em uma
hora por alguém que não estava procurando por eles. Isso é evidência sobre a probabilidade, nas
palavras da aula 1, e sobe o risco C, um reembolso que não devia acontecer, na ordem de riscos. Os
casos roteirizados não tinham dito nada disso, porque passavam.

## O que uma sessão deixa

Uma conversa final termina com o resultado da sessão entregue a alguém:

| o quê | para onde vai | quem |
|---|---|---|
| dois relatórios de defeito | o rastreador, na forma que a aula 15 ensina | a Ana, hoje |
| um caso para cada defeito | a suíte de regressão da aula 10, para as correções ficarem depois de feitas | a Ana, quando os relatórios estiverem abertos |
| o pedido de testabilidade | a lista do Rui, ao lado dos defeitos | a líder |
| a missão nova | a lista de missões, no topo | a líder |
| a folha da sessão | o registro de sessões por área | a Ana |

A última linha é o que torna a exploração relatável. **Sessões são contadas por área como casos são
contados por requisito**: quatro sessões sobre pedidos, uma sobre cadastro, nenhuma sobre a página
Shows nesta versão. Um gerente que lê essa lista vê por onde a exploração passou e por onde não
passou, e pode discordar dela, que é o que a aula 1 pediu de toda parte de um plano. A aula 19 põe
números como esses no relatório de uma página que a liderança lê.
