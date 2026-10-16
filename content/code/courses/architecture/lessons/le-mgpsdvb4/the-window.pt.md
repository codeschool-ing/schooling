---
title: A janela, e o que a aumenta
version: 1
---

O tempo entre o dono mudar e uma cópia ficar sabendo é a **janela de inconsistência**. Observe-a de
fora: defina o café como 11, depois leia a loja `b` a cada meio segundo:

```
ana@vm:~/lab/eventual$ curl -s -X PUT localhost:8001/stock/coffee -d 11; for i in $(seq 6); do curl -s localhost:8003/product/coffee; sleep 0.5; done
coffee: 11 in stock, version 2
shop-b: coffee: 12 left, version 1
shop-b: coffee: 12 left, version 1
shop-b: coffee: 12 left, version 1
shop-b: coffee: 12 left, version 1
shop-b: coffee: 11 left, version 2
shop-b: coffee: 11 left, version 2
```

A loja `b` respondeu 12 por uns dois segundos depois de o serviço de estoque dizer 11, e então se
atualizou. É o `LAG` dela, o tempo que ela gasta em cada evento, e num sistema ocioso a janela tem mais
ou menos esse tamanho.

## A janela não é uma configuração

Agora mude o café dez vezes seguidas, como uma tarde movimentada faria, e olhe o dono, as duas lojas e
as filas do broker logo em seguida:

```
ana@vm:~/lab/eventual$ for n in $(seq 10 -1 1); do curl -s -X PUT localhost:8001/stock/coffee -d $n > /dev/null; done
ana@vm:~/lab/eventual$ curl -s localhost:8001/stock/coffee; curl -s localhost:8002/product/coffee; curl -s localhost:8003/product/coffee
coffee: 1 in stock, version 12
shop-a: coffee: 10 left, version 3
shop-b: coffee: 11 left, version 2
ana@vm:~/lab/eventual$ docker compose exec rabbitmq rabbitmqctl list_queues name messages
Timeout: 60.0 seconds ...
Listing queues for vhost / ...
name	messages
shop-a	3
shop-b	10
```

O dono está na versão 12 e a loja `b` ainda está na versão 2, porque os eventos estão **esperando na
fila dela**, e ela os trata um de cada vez, dois segundos cada. A janela para a última mudança agora é a
fila inteira: dez eventos vezes dois segundos, vinte segundos em que a loja `b` mostra um número que o
serviço de estoque já substituiu dez vezes. A loja `a` trata um em um quinto de segundo e também está
atrasada, só que menos. Espere, e as duas esvaziam as filas:

```
ana@vm:~/lab/eventual$ sleep 25; docker compose exec rabbitmq rabbitmqctl list_queues name messages
Timeout: 60.0 seconds ...
Listing queues for vhost / ...
name	messages
shop-a	0
shop-b	0
ana@vm:~/lab/eventual$ curl -s localhost:8002/product/coffee; curl -s localhost:8003/product/coffee
shop-a: coffee: 1 left, version 12
shop-b: coffee: 1 left, version 12
```

**A janela é o comprimento da fila vezes o tempo por evento**, então ela cresce exatamente quando o
sistema está mais ocupado, que é quando mais gente está olhando. E se o consumidor parar, cair ou for
publicado com defeito, a janela não tem fim: a fila guarda os eventos (ela é durável) e a cópia fica
onde estava até alguém perceber.

## Meça, porque ninguém vai perceber

Uma cópia atrasada não falha. Toda requisição dá certo, toda página é desenhada, e os números são
plausíveis. Então a janela tem de ser medida, e há dois jeitos de vê-la:

- **A profundidade da fila**, que o broker já informa, como acima. A maioria das ferramentas de
  monitoramento consegue alertar sobre ela, e uma fila que só cresce é um consumidor que parou de dar
  conta.
- **A idade do que a cópia guarda**, que é o número melhor, porque é em tempo e não em mensagens: se
  cada evento carrega o momento em que foi criado, a cópia sabe a idade do mais novo que tem. O Kafka
  informa a mesma coisa como **consumer lag**, a distância entre o fim de uma partição e a posição de um
  consumidor nela.

A pergunta a fazer a qualquer cópia não é "ela está consistente?", porque não está, mas **"quanto ela
está atrasada agora, e quem ficaria sabendo?"** A aula 12 volta à fila que enche mais rápido do que
esvazia, pelo outro lado: o que fazer quando ela não para de crescer.
