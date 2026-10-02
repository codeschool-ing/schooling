---
title: Três perguntas com consequências diferentes
version: 1
---

"O serviço está saudável?" parece uma pergunta só. **São três, feitas por máquinas diferentes, e cada
resposta dispara uma ação diferente**, e é por isso que um `/health` único que responde as três acaba
não respondendo bem a nenhuma.

| pergunta | quem pergunta | se a resposta é não |
|---|---|---|
| **liveness**: o processo travou sem volta? | o Kubernetes | o contêiner é morto e iniciado de novo |
| **readiness**: ele consegue atender uma requisição agora? | o Kubernetes, balanceadores de carga | o tráfego para de ir até ele até ele dizer sim |
| **startup**: ele terminou de iniciar? | o Kubernetes | as outras duas sondas esperam |

As consequências decidem o que cada sonda pode verificar. **Um reinício conserta só o que está errado
dentro do processo**: um deadlock, um vazamento que comeu a memória, um pool de threads travado.
Então a liveness deve verificar que o processo consegue responder, e nada fora dele. Um reinício não
traz um banco de dados de volta, e a pior demonstração desta aula é uma sonda de liveness que tenta.

**A readiness é sobre tráfego**, e pode olhar mais longe: um serviço que não alcança o banco não
consegue receber um pedido, e mandar pedidos a ele só produz erros. Tirá-lo do rodízio deixa o
balanceador mandar a requisição para uma cópia que consegue.

Há um quarto perguntador sem botão de reiniciar e sem tráfego para mover: **a sonda de fora**. O
blackbox exporter da aula 5 pergunta ao `/health` da vitrine a cada quinze segundos, e uma verificação
sintética de outro país faz o mesmo para um produto hospedado. Ela não decide nada sozinha; é uma
medição, e só é tão boa quanto a pergunta que faz.
