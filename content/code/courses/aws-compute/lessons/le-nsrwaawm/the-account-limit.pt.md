---
title: O limite da conta, e o que um throttle faz com cada chamador
version: 1
---

Toda função de uma conta divide um único pool. **Por padrão uma conta AWS pode rodar 1.000
ambientes de execução ao mesmo tempo em cada região, somando todas as suas funções**, e a
1.001ª requisição simultânea é recusada. O limite é por região, então os mil de São Paulo e os mil
da Virgínia são separados, e é por conta, então uma função de teste e a API de produção na mesma
conta tiram dos mesmos mil. Esse último ponto é o que dói: um teste de carga contra uma função pode
causar throttle em todas as outras funções da conta.

## Os números que a AWS documenta

Nada disto pode ser mostrado contra o moto, que não conta nada rodando e não faz throttle de
nada. É o comportamento documentado da AWS, descrito aqui e não executado.

- **O pool é uma cota, não uma parede.** Ele aparece no Service Quotas como *Concurrent
  executions*, e um pedido ali aumenta o valor, até dezenas de milhares para uma conta que mostre
  que precisa. A AWS também documenta que uma conta nova pode começar com um valor menor, aumentado
  automaticamente conforme a conta é usada, então confira o da sua antes de um lançamento, e não
  durante.
- **Uma função cresce num ritmo limitado.** Cada função pode acrescentar até 1.000 ambientes de
  execução a cada 10 segundos. Uma conta cuja cota subiu para 5.000 ainda precisa de pelo menos
  50 segundos para ir de nada a 5.000 numa função, e as requisições acima da contagem que está
  crescendo sofrem throttle enquanto ela cresce.
- **Existe também uma taxa de requisições.** O Lambda permite dez vezes a cota de concorrência em
  requisições por segundo, então 10.000 por segundo numa cota de 1.000. Uma função que roda por
  5 ms a 20.000 requisições por segundo precisa de apenas 20.000 × 0,005 = 100 ambientes pela lei
  de Little, e sofre throttle mesmo assim, por causa da taxa.

O que o moto responde é a pergunta, ou melhor, a ausência dela. Na AWS, o `get-account-settings`
imprime os limites da conta, entre eles `ConcurrentExecutions`, o pool, e
`UnreservedConcurrentExecutions`, o que sobra dele depois das reservas da próxima seção. O moto
5.2.3 não implementou essa operação, e o servidor web dele responde com uma página feita para um
navegador:

```
ana@laptop:~/aws$ aws lambda get-account-settings

aws: [ERROR]: An error occurred (404) when calling the GetAccountSettings operation: <!doctype html>
<html lang=en>
<title>404 Not Found</title>
<h1>Not Found</h1>
<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try again.</p>
```

O erro é um `404`, e o HTML nele é do moto; a AWS teria respondido com JSON. Guarde isso como a
cara de uma operação que falta no moto, porque a última seção desta lição encontra a mesma página
de novo.

## Um throttle é um erro com número

Quando o Lambda recusa uma requisição por falta de concorrência, a recusa é uma
`TooManyRequestsException` com o status HTTP 429, e a mensagem diz que a taxa foi excedida. **O que
acontece depois não é decidido pelo Lambda, e sim por quem o chamou**, e cada uma das três formas de
entrada da lição 15 se comporta de um jeito:

| como a função foi invocada | o que o throttle faz |
|---|---|
| de forma síncrona: API Gateway, uma function URL, uma chamada do SDK com `RequestResponse` | quem chamou recebe o erro na hora; nada é tentado de novo a menos que quem chamou tente, e o API Gateway o transforma numa resposta de erro para o próprio cliente |
| de forma assíncrona: S3, SNS, EventBridge | o evento fica na fila interna do Lambda e é tentado de novo, com espera crescente, por até seis horas, a idade máxima padrão de um evento; depois disso vai para o destino de falha ou para a dead-letter queue, se houver uma, e senão é descartado |
| por um event source mapping: SQS | o poller passa a ler mais devagar; as mensagens ficam na fila e voltam quando o visibility timeout expira, e uma mensagem recebida vezes demais vai para a dead-letter queue da fila |
| por um event source mapping: Kinesis, DynamoDB Streams | o lote é tentado de novo, e o shard espera atrás dele até dar certo ou até os registros expirarem |

**A linha síncrona é a única em que um usuário vê a falha**, e aquela em que uma nova tentativa
apressada piora as coisas: um cliente que tenta de novo na hora soma uma requisição a uma função que
já está no limite. As linhas assíncronas absorvem o throttle em silêncio, o que é mais gentil com o
usuário e mais duro com quem está observando, porque seis horas de novas tentativas parecem uma
função apenas lenta.

## Por que um limite é uma boa notícia

É tentador ler o pool como um incômodo a ser aumentado antes de qualquer outra coisa. Ele também é o
que impede um bug de virar uma fatura. Uma função que chama a si mesma por engano, ou uma fila que
transborda depois de uma queda, escalaria até a conta ou o banco de dados cederem. **O limite da
conta decide o tamanho que um erro pode ter.** A próxima seção mostra como decidir isso por função,
em vez de para a conta inteira, e as dead-letter queues da lição 15 são para onde vai esperar o
trabalho recusado.
