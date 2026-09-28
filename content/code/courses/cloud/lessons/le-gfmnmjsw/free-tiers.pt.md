---
title: O que "grátis" quer dizer numa lista de preços
version: 1
---

"Está na camada gratuita" é dito como se quisesse dizer que a coisa não custa nada. **Uma camada
gratuita não é um preço de zero. É um preço de zero até um limite**, ou até uma data, e a conta começa no
momento em que um dos dois é passado. Três ofertas diferentes são chamadas de grátis, e cada uma termina
de um jeito.

## Uma franquia

Uma franquia é uma quantidade por mês que não é cobrada. A do Lambda está na tabela: 1.000.000 de
requisições e 400.000 GB-segundos por mês. Na lista de preços bruta ela é uma faixa, como a seção sobre
a lista de preços descreveu: uma dimensão de preço com preço zero e um fim.

```
ana@laptop:~/cloud$ curl -s "$url" | jq '(.products[] | select(.attributes.usagetype == "Global-Request") | .sku) as $s | .terms.OnDemand[$s][].priceDimensions[] | {description, beginRange, endRange, pricePerUnit}'
{
  "description": "AWS Lambda - Requests Free Tier - 1,000,000 Requests",
  "beginRange": "0",
  "endRange": "1000000",
  "pricePerUnit": {
    "USD": "0.0000000000"
  }
}
```

Duas coisas nessa resposta importam. O intervalo termina em `1000000`, e depois dele vale o preço
comum, 0.20 por milhão de requisições. E a consulta escolheu o produto pelo tipo de uso `Global-Request`,
não `SAE1-Request`: **a franquia é da conta, não de uma região nem de uma função.** Vinte funções em três
regiões dividem o mesmo milhão de requisições.

Faça uma conta. Uma função com 512 MB de memória roda 200 ms por requisição e é chamada 3 milhões de
vezes num mês. As requisições além da franquia são 2 milhões, que custam 0,40. O processamento é
3.000.000 × 0,2 s × 0,5 GB = 300.000 GB-segundos, dentro dos 400.000 gratuitos. **O mês custa 0,40
USD.**

Agora o produto cresce para 10 milhões de requisições. As requisições além da franquia são 9 milhões,
1,80. O processamento é 1.000.000 de GB-segundos, dos quais 600.000 passam da franquia, a 0.0000166667
cada: 10,00. O mês custa 11,80. Nada quebrou e nada mudou; a franquia simplesmente acabou, e a segunda
linha, que era zero desde que alguém olhou pela primeira vez, virou a maior parte da conta.

O tráfego também tem franquia, e ela não está na tabela, que imprime só as faixas pagas. Está na oferta de
transferência de dados, sob um tipo de uso que também começa com `Global`:

```
ana@laptop:~/cloud$ dt=https://pricing.us-east-1.amazonaws.com/offers/v1.0/aws/AWSDataTransfer/20260916132208/sa-east-1/index.json
ana@laptop:~/cloud$ curl -s "$dt" | jq -r '(.products[] | select(.attributes.usagetype == "Global-DataTransfer-Out-Bytes") | .sku) as $s | .terms.OnDemand[$s][].priceDimensions[].description'
$0 for 100GB of data transfer out to the internet, aggregated globally, each month
```

É por isso que os 500 GB de saída da estimativa seriam cobrados como 400: 60,00, e não os 75,00 que o
programa imprimiu contando todo gigabyte pelo preço da tabela.

## Um período de teste

Um período de teste é grátis por um tempo. Durante anos, o exemplo que todo mundo conhecia foram os doze
meses de uma máquina pequena numa conta nova da AWS. A máquina era grátis no mês doze e cobrada pelo
preço cheio por hora no mês treze, ainda ligada, porque **o fim do teste acaba com o desconto, não com o
recurso**. Ninguém recebe uma mensagem dizendo que a máquina agora é paga. A próxima conta é a mensagem.

## Créditos

Créditos são uma quantia para gastar em qualquer coisa, que em geral expira. O teste gratuito do Google
Cloud dá a um cliente novo 300 USD de crédito por 90 dias; a conta gratuita do Azure dá 200 USD por 30
dias. Os créditos se comportam diferente dos outros dois num ponto útil: quando esses créditos de teste
acabam, o provedor para os recursos em vez de cobrá-los, até você converter a conta numa conta paga.
Depois da conversão, essa proteção acaba.

## Uma camada gratuita não é um teto

Fora esse caso, **nada numa camada gratuita para o uso quando a parte grátis acaba**. Uma franquia
excedida é cobrada pelo preço de lista. Uma função chamada em loop por um bug não para em um milhão de
requisições; ela continua a 0.20 por milhão, e ao preço do GB-segundo, enquanto o loop rodar. Um limite
que pare o gasto precisa ser construído, e a seção sobre orçamentos é honesta sobre até onde as
ferramentas dos provedores chegam nisso.

Então trate uma camada gratuita pelo que ela é: um desconto nas primeiras unidades, útil para aprender e
para produtos pequenos, com uma data ou uma quantidade depois da qual a tabela comum vale. Estime como se
ela não existisse, e subtraia depois.
