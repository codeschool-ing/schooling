---
title: A ordem, e uma cópia que nunca converge
version: 1
---

"No fim as cópias concordam" supõe, sem dizer, que a cópia aplica as mudanças na ordem em que foram
feitas. A aula 7 mostrou que um broker não promete isso: uma mensagem é reentregue depois de um
consumidor cair, dois consumidores numa fila terminam em qualquer ordem, e uma nova tentativa chega
depois da mensagem que a substituiu. O serviço de estoque consegue imitar o primeiro caso com
`POST /resend`, que publica de novo um evento velho, atrasado.

Defina o café como 5 e depois como 4, espere as lojas, e então deixe a versão 15 chegar de novo:

```
ana@vm:~/lab/eventual$ curl -s -X PUT localhost:8001/stock/coffee -d 5; curl -s -X PUT localhost:8001/stock/coffee -d 4
coffee: 5 in stock, version 15
coffee: 4 in stock, version 16
ana@vm:~/lab/eventual$ sleep 5; curl -s -X POST localhost:8001/resend/coffee/15
sent again: coffee = 5, version 15
ana@vm:~/lab/eventual$ sleep 3; curl -s localhost:8001/stock/coffee; curl -s localhost:8003/product/coffee
coffee: 4 in stock, version 16
shop-b: coffee: 5 left, version 15
```

O dono diz 4. A loja `b` diz 5, e **vai dizer 5 até o café mudar de novo**, o que pode levar dias. O log
dela mostra por quê: ela aplicou o que chegou por último.

```
ana@vm:~/lab/eventual$ docker compose logs shop-b --tail 3
shop-b-1  | shop-b: coffee = 5, version 15
shop-b-1  | shop-b: coffee = 4, version 16
shop-b-1  | shop-b: coffee = 5, version 15
```

Isso é pior que uma janela. Uma janela fecha; esta cópia convergiu para um valor errado, e de fora nada a
distingue de uma cópia certa. A promessa era consistência eventual, e uma mensagem atrasada bastou para
quebrá-la.

## A cópia também precisa da versão

A versão das seções anteriores conserta isso também, na outra ponta. Um evento que carrega a versão que
produziu deixa a cópia recusar qualquer coisa mais velha do que o que ela já tem. Isso é
`CHECK_VERSION=1`, que reinicia as lojas com a verificação ligada (e, como elas guardam tudo em memória,
com as cópias vazias):

```
ana@vm:~/lab/eventual$ CHECK_VERSION=1 docker compose up -d
 Container eventual-rabbitmq-1 Running 
 Container eventual-stock-1 Running 
 Container eventual-shop-a-1 Recreate 
 Container eventual-shop-b-1 Recreate 
 Container eventual-shop-a-1 Recreated 
 Container eventual-shop-b-1 Recreated 
 Container eventual-shop-b-1 Starting 
 Container eventual-shop-a-1 Starting 
 Container eventual-shop-b-1 Started 
 Container eventual-shop-a-1 Started 
ana@vm:~/lab/eventual$ curl -s -X PUT localhost:8001/stock/coffee -d 5; curl -s -X PUT localhost:8001/stock/coffee -d 4
coffee: 5 in stock, version 17
coffee: 4 in stock, version 18
ana@vm:~/lab/eventual$ sleep 5; curl -s -X POST localhost:8001/resend/coffee/17
sent again: coffee = 5, version 17
ana@vm:~/lab/eventual$ sleep 3; curl -s localhost:8001/stock/coffee; curl -s localhost:8003/product/coffee
coffee: 4 in stock, version 18
shop-b: coffee: 4 left, version 18
ana@vm:~/lab/eventual$ docker compose logs shop-b --tail 3
shop-b-1  | shop-b: coffee = 5, version 17
shop-b-1  | shop-b: coffee = 4, version 18
shop-b-1  | shop-b: ignored coffee version 17, already at 18
```

A versão 17 chegou atrasada, depois da 18, e a loja `b` a ignorou, então a cópia e o dono concordam. A
aula 7 disse que **projetar eventos para que a ordem não importe costuma ser mais barato que garanti-la**,
e é assim que isso fica. Cada evento carrega o **estado inteiro** de uma coisa ("o café está em 4, versão
18") em vez de uma mudança ("dois pacotes vendidos"), e a cópia guarda a versão mais nova de cada coisa.
Eventos em qualquer ordem, repetidos quantas vezes for, terminam no mesmo lugar.

Duas condições fazem isso funcionar, e as duas são fáceis de não ver:

- **A versão vem do dono**, o único lugar que ordena as mudanças daquela coisa. Um relógio não é uma
  versão: os relógios de duas máquinas discordam, e "o carimbo de tempo mais recente" vindo de duas delas
  pode ser a mudança mais velha. Esse é o problema da próxima seção.
- **Uma mudança tem de poder ser expressa como estado.** "Dois pacotes vendidos" aplicado duas vezes
  vende quatro. Se um evento tem de ser uma mudança, a cópia precisa do consumidor idempotente da aula 7,
  e dos eventos em ordem.
