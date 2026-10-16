---
title: O mesmo total, por um laço e pelo pipeline
version: 1
---

O laço na aplicação não está errado por ser um laço. Ele está errado por causa de **para onde os
dados precisam ir** para ele rodar: todo documento que o laço lê atravessa do servidor para o
programa, e o servidor só precisava mandar um número.

## Medindo os dois

`measure` roda um trabalho e informa quanto tempo levou e quantos bytes o servidor mandou nesse
meio-tempo, lidos do `serverStatus` antes e depois. O primeiro trabalho é o laço: buscar cada pedido
não cancelado e somar os totais em JavaScript. O segundo é um pipeline de dois estágios. O
terceiro, uma contagem simples, mede quanto o próprio `measure` custa:

```
ana@vm:~$ docker exec -it mongo mongosh --quiet shop
shop> function measure(work) {
|   const before = db.serverStatus().network.bytesOut;
|   const start = Date.now();
|   const result = work();
|   return { result: result, ms: Date.now() - start, bytesOut: db.serverStatus().network.bytesOut - before };
| }
[Function: measure]
shop> measure(() => {
|   let revenue = 0, orders = 0;
|   db.orders.find({ status: { $ne: "cancelled" } }).forEach((o) => { revenue += parseFloat(o.total.toString()); orders++; });
|   return { orders: orders, revenue: revenue };
| })
{
  result: { orders: 98958, revenue: 206042969.6000362 },
  ms: 6989,
  bytesOut: 24564648
}
shop> measure(() => db.orders.aggregate([
|   { $match: { status: { $ne: "cancelled" } } },
|   { $group: { _id: null, orders: { $sum: 1 }, revenue: { $sum: "$total" } } }
| ]).toArray())
{
  result: [ { _id: null, orders: 98958, revenue: Decimal128('206042969.60') } ],
  ms: 78,
  bytesOut: 111198
}
shop> measure(() => db.orders.countDocuments())
{ result: 100000, ms: 29, bytesOut: 111172 }
shop> exit
```

| | documentos enviados | bytes enviados | tempo no laboratório | receita |
|---|---|---|---|---|
| laço no mongosh | 98.958 | 24.564.648 | 6.989 ms | `206042969.6000362` |
| pipeline | 1 | 111.198 | 78 ms | `Decimal128('206042969.60')` |
| uma contagem, como escala | 1 | 111.172 | 29 ms | |

**As contagens de bytes incluem as duas respostas do `serverStatus`** que o `measure` pede, cerca de
111 KB, que a contagem mostra sozinha. Tire isso e o pipeline mandou quase nada, enquanto o laço
mandou 24,5 MB: a coleção inteira, menos os pedidos cancelados, por uma conexão que aqui nem saiu do
contêiner. Entre duas máquinas, são 24,5 MB de rede a cada execução de um relatório.

**Os tempos são desta execução, no laboratório, e variam**: rode duas vezes e os dois números
mudam. O tamanho da diferença não muda, cerca de noventa vezes aqui, porque o custo do laço é
dominado por mover e decodificar cada documento, e o do pipeline por lê-los uma vez onde eles já
estão.

## E o laço errou o dinheiro

O total do pipeline é `206042969.60`. O do laço é `206042969.6000362`. O laço precisou transformar
cada `Decimal128` em algo que o JavaScript consiga somar, e `parseFloat` o transformou num double,
então cada soma carregou o erro de arredondamento binário que a aula 6 mediu em três teclados.
Depois de 98.958 somas, o total estava errado em 0,0000362. É um número pequeno, e é um número
errado, num relatório cujo trabalho é bater com o banco até o centavo.

Um laço pode ser escrito corretamente, com uma biblioteca decimal ou com centavos inteiros. O
pipeline não precisou ser: **a aritmética rodou onde o tipo é exato**, e o programa recebeu a
resposta no tipo em que ela estava guardada.

## Quando o laço está certo

O pipeline ganha quando o resultado é pequeno e a entrada é grande: totais, contagens, os dez mais,
qualquer coisa que termine num `$group` ou num `$limit`. Ele não ganha quando o programa precisa de
todo documento de qualquer forma, para gravar cada um num arquivo ou chamar outro serviço por
pedido; aí os documentos atravessam a conexão de um jeito ou de outro, e um pipeline só acrescenta
um estágio. E uma lógica que os operadores do pipeline não conseguem expressar, ou só expressam de
forma ilegível, pertence à aplicação, alimentada por um `$match` e um `$project` que lhe mandem o
mínimo possível.
