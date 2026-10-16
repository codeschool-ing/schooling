---
title: O que a aplicação faz a respeito
version: 1
---

Nenhuma das três anomalias se resolve esperando o armazenamento alcançar. Cada uma se resolve com algo
que a aplicação faz de propósito, e os três hábitos abaixo cobrem quase tudo o que uma loja precisa.
São baratos, e **cada um precisa ser projetado desde o início**, porque nenhum pode ser acrescentado
por uma configuração no servidor.

## Leia as próprias escritas de onde as gravou

A correção mais simples para a primeira anomalia é mandar as leituras de um usuário para a cópia que
recebeu a escrita dele, pelo tempo em que isso importar. Na prática, isso significa **o primário**,
para aquele usuário, por um curto período depois de ele mudar algo. A página de endereço da loja lê
do primário para a pessoa que acabou de salvar, e o resto do site pode continuar lendo das réplicas.

Duas variantes são comuns. A aplicação pode lembrar o horário da última escrita de um usuário e ler
do primário só nos segundos seguintes a ela. Ou, no MongoDB, uma **sessão causalmente consistente**
carrega a posição da última escrita e faz um secundário esperar até tê-la alcançado; a aula 9 mostra
as preferências de leitura e as configurações por trás delas. As duas corrigem também as leituras
monotônicas, se as leituras de um usuário ficam numa cópia só em vez de passear entre réplicas.

## Torne uma repetição inofensiva

Com consistência eventual, e em qualquer rede, um cliente muitas vezes não sabe se uma escrita
aconteceu: o pedido deu timeout, e a escrita pode ou não ter sido aplicada. A resposta segura é
mandá-la de novo, o que só é seguro se **fazer duas vezes tiver o efeito de fazer uma**. O jeito
usual é um id que o cliente inventa antes da primeira tentativa:

```
ana@vm:~$ docker exec -it mongo mongosh --quiet shop
shop> db.payments.insertOne({ _id: "pay-1001-a7f3", order: 1001, amount: Decimal128("268.80") })
{ acknowledged: true, insertedId: 'pay-1001-a7f3' }
shop> db.payments.insertOne({ _id: "pay-1001-a7f3", order: 1001, amount: Decimal128("268.80") })
Uncaught 
MongoServerError: E11000 duplicate key error collection: shop.payments index: _id_ dup key: { _id: "pay-1001-a7f3" }
shop> db.payments.countDocuments({ order: 1001 })
1
shop> exit
```

O `_id` do pagamento foi escolhido pela aplicação, `pay-1001-a7f3`, antes de ela mandar qualquer
coisa. A repetição chegou com o mesmo id e foi recusada com `E11000 duplicate key error`, e a
contagem de pagamentos do pedido ficou em `1`. **O erro de chave duplicada é o caso de sucesso
aqui**: significa que a primeira tentativa tinha chegado, e a aplicação pode tratá-lo como "já
feito". Um pagamento com um `ObjectId` gerado pelo servidor a cada tentativa teria sido cobrado duas
vezes.

## Atualize só se ninguém mais atualizou: um número de versão

A atualização perdida se corrige tornando a escrita condicional ao valor que o cliente leu. Cada
produto carrega uma `version`, e toda atualização a confere e a incrementa:

```
ana@vm:~$ docker exec -it mongo mongosh --quiet shop
shop> db.products.insertOne({ _id: "MN-330", name: "27-inch monitor", stock: 1, version: 1 })
{ acknowledged: true, insertedId: 'MN-330' }
shop> db.products.updateOne({ _id: "MN-330", version: 1 }, { $inc: { stock: -1, version: 1 } })
{
  acknowledged: true,
  insertedId: null,
  matchedCount: 1,
  modifiedCount: 1,
  upsertedCount: 0
}
shop> db.products.updateOne({ _id: "MN-330", version: 1 }, { $inc: { stock: -1, version: 1 } })
{
  acknowledged: true,
  insertedId: null,
  matchedCount: 0,
  modifiedCount: 0,
  upsertedCount: 0
}
shop> db.products.findOne({ _id: "MN-330" })
{ _id: 'MN-330', name: '27-inch monitor', stock: 0, version: 2 }
shop> exit
```

Os dois checkouts leram o monitor na versão 1 e os dois mandaram a mesma atualização. A primeira
casou, levou o estoque a 0 e a versão a 2. A segunda pediu `version: 1`, que não existia mais, e
recebeu **`matchedCount: 0`**: nada foi mudado, e nenhum erro foi levantado. Esse zero é o mecanismo
inteiro. A aplicação precisa olhar para ele e, quando for zero, ler o produto de novo e decidir outra
vez: aqui, que o monitor esgotou.

Isso se chama **concorrência otimista**: ninguém trava nada, e um conflito é detectado na escrita em
vez de evitado na leitura. Funciona porque o filtro e a atualização são uma operação só sobre um
documento só, que o MongoDB aplica de forma atômica. A mesma ideia aparece no Cassandra como uma
lightweight transaction, `UPDATE ... IF version = 1`, a um preço mais alto que a aula 17 mede.
