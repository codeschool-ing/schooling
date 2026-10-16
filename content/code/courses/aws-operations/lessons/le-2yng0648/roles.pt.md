---
title: Papéis, e as mensagens que saem
version: 1
---

A pessoa mais capaz de consertar o problema é a pior para coordená-lo: a atenção dela pertence ao
sistema. Incidentes acima dos menores separam os trabalhos, e **cada papel fica com uma pessoa por
vez**, nomeada no canal:

| papel | o trabalho | não é o trabalho |
|---|---|---|
| comandante do incidente | decide, distribui, controla o relógio, declara o fim | digitar comandos |
| líder de operações | investiga e muda o sistema, diz o que vai fazer antes de fazer | atualizar os clientes |
| líder de comunicação | escreve as atualizações, internas e externas, no horário | adivinhar a causa |
| escriba | registra decisões e horários no canal enquanto acontecem | decidir |

Numa equipe pequena uma pessoa fica com dois papéis, e o do comandante é o que nunca se divide com
operações. **Passar um papel é explícito**: "estou passando o comando para o Bruno", "o Bruno está com o
comando", no canal, para ninguém ter de adivinhar quem decide.

## Atualizações com hora marcada

Clientes perdoam uma queda muito mais facilmente que o silêncio. O líder de comunicação manda
atualizações num intervalo fixo, a cada trinta minutos num SEV1, **mesmo sem nada novo**, porque "ainda
investigando, próxima atualização às 15:30" diz aos clientes que alguém está cuidando. Uma atualização
diz quatro coisas:

> **Erros no checkout: em investigação.** Desde 14:02 (horário de Brasília), alguns clientes veem um
> erro ao pagar. Pedidos já feitos não foram afetados. Estamos investigando e atualizamos até 14:45.

O que foi observado, desde quando, o que **não** foi afetado, e quando vem a próxima atualização. O que
ela nunca diz: a causa antes de ser conhecida, um prazo de conserto que ninguém pode prometer, uma
pessoa ou equipe para culpar.

## Mitigar primeiro, entender depois

A primeira pergunta do comandante não é "por quê", e sim "**o que estanca o sangramento?**" Um rollback
(lição 3), tirar o tráfego de uma zona ruim, desligar a funcionalidade atrás de uma flag: cada um
restaura o serviço antes de alguém entender a causa, e essa é a ordem certa. **O tempo para mitigar é o
número que os clientes sentem**; a investigação pode continuar depois de o gráfico ficar verde, com o
sistema sem fogo e as pessoas sem relógio.
