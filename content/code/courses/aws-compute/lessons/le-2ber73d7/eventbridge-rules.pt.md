---
title: "Regras do EventBridge: um padrão decide quem é chamado"
version: 1
---

As origens até aqui nomeiam cada uma a função que chamam. **O EventBridge inverte isso: quem publica
um evento não nomeia ninguém, e uma regra no barramento decide, comparando um padrão com o evento,
quais alvos o recebem.** O checkout da loja publica `OrderPlaced` e não sabe nada da função que
confere pedidos grandes em busca de fraude; essa função é ligada por uma regra que casa com pedidos
acima de mil reais. A aula 21 compara barramentos com filas e tópicos; esta seção é a regra que chama
uma função.

## Um padrão é um formato em que o evento precisa caber

Salve isto como `~/aws/pattern.json`:

```json
{
  "source": ["shop.orders"],
  "detail-type": ["OrderPlaced"],
  "detail": {
    "total": [{"numeric": [">", 1000]}]
  }
}
```

**Um padrão lista só os campos que lhe interessam, e todo campo listado precisa casar.** Cada valor é
uma lista do que é aceito: `source` precisa ser `shop.orders`, `detail-type` precisa ser
`OrderPlaced`, e dentro de `detail`, o conteúdo do próprio evento, `total` precisa ser um número maior
que 1000. Um campo que o padrão não menciona pode ter qualquer coisa, e um evento sem um campo que o
padrão menciona não casa. A regra, a permissão e o alvo:

```
ana@laptop:~/aws$ aws events put-rule --name big-orders --event-pattern file://pattern.json --query RuleArn
"arn:aws:events:sa-east-1:123456789012:rule/big-orders"
ana@laptop:~/aws$ aws lambda add-permission --function-name orders --statement-id big-orders --action lambda:InvokeFunction --principal events.amazonaws.com --source-arn arn:aws:events:sa-east-1:123456789012:rule/big-orders --query Statement --output text | jq -c .Condition
{"ArnLike":{"AWS:SourceArn":"arn:aws:events:sa-east-1:123456789012:rule/big-orders"}}
ana@laptop:~/aws$ aws events put-targets --rule big-orders --targets Id=orders,Arn=arn:aws:lambda:sa-east-1:123456789012:function:orders
{
    "FailedEntryCount": 0,
    "FailedEntries": []
}
```

A permissão é a mesma ideia da do bucket na seção 03, com a regra como a única origem que pode
invocar `orders`, e o EventBridge então a invoca de forma assíncrona, então um evento que falha
recebe as duas novas tentativas do Lambda e o destino da seção 02. O moto registra a regra e o alvo
e, como antes, não chama função nenhuma.

## Testando um padrão, e o que o moto não responde

O EventBridge tem uma API exatamente para a pergunta que um padrão levanta, se um dado evento casa com
ele. Pergunte sobre um pedido de 99,9:

```
ana@laptop:~/aws$ aws events test-event-pattern --event-pattern file://pattern.json --event '{"id": "1", "account": "123456789012", "source": "shop.orders", "time": "2026-10-16T12:00:00Z", "region": "sa-east-1", "resources": [], "detail-type": "OrderPlaced", "detail": {"total": 99.9}}'; echo "exit status $?"
exit status 0
```

**Nada voltou, e o comando ainda assim terminou com status 0.** Na AWS, `test-event-pattern` responde
`{"Result": false}` para este evento, e `true` para um acima de mil. O moto 5.2.3 tem a chamada na
lista e um corpo vazio por trás dela, então responde sem resultado nenhum, e um script que só
conferisse o status de saída leria o silêncio como sucesso. Isto não foi executado contra a AWS.

## Vendo o que uma regra casa

O moto casa padrões, sim, quando um evento é publicado, e entrega a um alvo SQS. Então, como com o
bucket, uma fila pode ficar no lugar da função e mostrar quais eventos passaram. O alvo da função sai
para o experimento, já que a tentativa do moto de executá-la atrapalharia:

```
ana@laptop:~/aws$ aws sqs create-queue --queue-name rule-witness --query QueueUrl
"http://localhost:4567/123456789012/rule-witness"
ana@laptop:~/aws$ aws events put-targets --rule big-orders --targets Id=witness,Arn=arn:aws:sqs:sa-east-1:123456789012:rule-witness --query FailedEntryCount
0
ana@laptop:~/aws$ aws events remove-targets --rule big-orders --ids orders --query FailedEntryCount
0
ana@laptop:~/aws$ aws events put-events --entries '[{"Source": "shop.orders", "DetailType": "OrderPlaced", "Detail": "{\"order\": \"A-1\", \"total\": 1299.9}"}, {"Source": "shop.orders", "DetailType": "OrderPlaced", "Detail": "{\"order\": \"A-2\", \"total\": 99.9}"}, {"Source": "shop.payments", "DetailType": "OrderPlaced", "Detail": "{\"order\": \"A-3\", \"total\": 5000}"}]' --query FailedEntryCount
0
ana@laptop:~/aws$ aws sqs receive-message --queue-url http://localhost:4567/123456789012/rule-witness --max-number-of-messages 10 --query 'Messages[].Body' | jq -r '.[]' | jq -c '{source, detail}'
{"source":"shop.orders","detail":{"order":"A-1","total":1299.9}}
```

Três eventos publicados, um entregue. `A-1` casou com todos os campos. `A-2` falhou no teste
numérico, já que `99.9` não é maior que 1000. `A-3` tinha o `detail-type` certo e um total de 5000, e
veio de `shop.payments`, então falhou no `source`. **Uma regra casa em todo campo que nomeia, e nada
mais é consultado**, e é também assim que uma regra dá errado: escreva `detail-type` errado no padrão
e nada nunca casa, sem erro em lugar nenhum, que é o motivo para testar um padrão contra eventos de
verdade antes de confiar nele.

## Escolhendo um gatilho

| você precisa de | use |
| --- | --- |
| quem chama esperando a resposta | uma URL de função ou o API Gateway, síncrono |
| reagir a algo que um serviço faz, como um envio | a notificação do próprio serviço, assíncrona |
| amortecer trabalho e controlar a taxa, em lotes | SQS e um mapeamento de origem de eventos |
| toda mudança de uma tabela, em ordem | DynamoDB Streams e um mapeamento de origem de eventos |
| reagir a eventos cujo publicador não deve saber quem escuta | uma regra do EventBridge |

Cada linha é um dos três formatos da seção 02, e o formato traz as suas novas tentativas junto. A
escolha do gatilho é feita uma vez e convive-se com ela enquanto a função rodar, e por isso vale
decidir por quem espera e quem tenta de novo, e não pelo serviço onde o evento por acaso começa.
