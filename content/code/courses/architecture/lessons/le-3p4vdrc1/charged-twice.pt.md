---
title: Cobrado duas vezes
version: 1
---

Peça um pagamento, o pedido `q-1` de 3.290 centavos, e processe com o consumidor ingênuo, que não guarda
registro do que já tratou, mandado cair depois de cobrar e antes de confirmar:

```
ana@vm:~/lab/delivery$ $R publish.py q-1 3290
confirmed by the broker: q-1
ana@vm:~/lab/delivery$ $R pay.py --naive --crash-after-charge
charged q-1: 3290 cents (redelivered: False)
crashing before the acknowledgement
```

A cobrança foi gravada, `redelivered: False` porque era a primeira entrega, e então o processo morreu.
**O RabbitMQ nunca recebeu a confirmação**, então, até onde o broker sabe, a mensagem nunca foi tratada.
Ela continua na fila, marcada como entregue uma vez. Inicie o consumidor ingênuo de novo, agora sem a
queda:

```
ana@vm:~/lab/delivery$ $R pay.py --naive
charged q-1: 3290 cents (redelivered: True)
ana@vm:~/lab/delivery$ $R pay.py --list
charged q-1 3290
charged q-1 3290
```

A mesma mensagem voltou, `redelivered: True`, e foi cobrada de novo. A lista de cobranças tem **`q-1`
duas vezes: um cliente, um pedido, 6.580 centavos tirados por uma cesta de 3.290.**

Cada peça fez o seu trabalho. O broker guardou uma mensagem que ninguém confirmou, que é exatamente o que
pelo menos uma vez promete. O consumidor cobrou toda mensagem que recebeu. A duplicata é uma propriedade
da combinação, e a queda só precisou cair nos poucos microssegundos entre o `commit` e o `basic_ack`. Em
produção, com milhares de mensagens por hora e um deploy que para os consumidores toda tarde, essa janela
é atingida com regularidade.

## O que a marca de reentrega não é

O RabbitMQ marca uma mensagem como `redelivered` quando ela já foi entregue antes, e é tentador tratar
isso como "pule esta". **É uma pista, não uma resposta**: a marca também aparece quando o primeiro
consumidor caiu *antes* de fazer o trabalho, e nesse caso pular perde o pagamento. A marca não distingue
os dois, porque o broker não enxerga o banco do consumidor. Só o consumidor enxerga.
