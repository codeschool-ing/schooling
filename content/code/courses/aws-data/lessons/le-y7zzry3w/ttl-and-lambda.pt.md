---
title: Time to live, Lambda e Kinesis
version: 1
---

## Itens que se apagam sozinhos

**O time to live apaga um item depois do momento escrito num dos atributos dele, e a remoção chega ao
stream como um `REMOVE`.** O atributo guarda um horário em segundos desde 1970, e a tabela diz qual
atributo é. Os carrinhos da Quitanda são o caso: um carrinho abandonado por uma semana deveria sumir, e
ninguém deveria ter de rodar um job para isso. O moto aceita tudo:

```
ana@laptop:~/aws$ aws dynamodb update-time-to-live --table-name quitanda --time-to-live-specification Enabled=true,AttributeName=expires_at
{
    "TimeToLiveSpecification": {
        "Enabled": true,
        "AttributeName": "expires_at"
    }
}
ana@laptop:~/aws$ aws dynamodb put-item --table-name quitanda --item '{"pk": {"S": "CART#c-18"}, "sk": {"S": "CART"}, "expires_at": {"N": "1760000000"}}'
ana@laptop:~/aws$ date -d @1760000000
Thu Oct  9 05:53:20 -03 2025
ana@laptop:~/aws$ aws dynamodb get-item --table-name quitanda --key '{"pk": {"S": "CART#c-18"}, "sk": {"S": "CART"}}' --query 'Item.expires_at.N'
"1760000000"
```

**O carrinho venceu em 9 de outubro de 2025 e continua lá.** O moto registra a configuração e não apaga
nada, e nada sobre o vencimento real foi rodado aqui. Na AWS, o TTL apaga um item vencido em segundo
plano, tipicamente em alguns dias depois do horário do atributo e não exatamente nele, então uma leitura
que não pode ver um item vencido filtra ela mesma por `expires_at`. A remoção não custa unidades de
escrita. Ela chega ao stream como um `REMOVE` cujo registro traz um `userIdentity` que nomeia o serviço,
`dynamodb.amazonaws.com`, e é assim que um consumidor distingue um vencimento de um cliente esvaziando o
carrinho. Os marcadores que o `totals.py` deixa são o outro uso: escritos com um `expires_at` dois dias à
frente, mais do que o stream guarda um registro, eles se limpariam sozinhos.

## O Lambda como consumidor

**Uma função Lambda é ligada a um stream por um event source mapping**, um registro que manda o Lambda
consultar os shards do stream e chamar a função com lotes. A função precisa de código, de um papel com
que roda e do mapping. `handler.py`:

```python
def handler(event, context):
    return len(event['Records'])
```

`trust.json`, que deixa o Lambda assumir o papel:

```json
{"Version": "2012-10-17", "Statement": [{"Effect": "Allow",
  "Principal": {"Service": "lambda.amazonaws.com"}, "Action": "sts:AssumeRole"}]}
```

```
ana@laptop:~/aws$ python3 -m zipfile -c function.zip handler.py
ana@laptop:~/aws$ aws iam create-role --role-name quitanda-totals --assume-role-policy-document file://trust.json --query Role.Arn
"arn:aws:iam::123456789012:role/quitanda-totals"
ana@laptop:~/aws$ aws lambda create-function --function-name quitanda-totals --runtime python3.12 --handler handler.handler --role arn:aws:iam::123456789012:role/quitanda-totals --zip-file fileb://function.zip --query State
"Active"
ana@laptop:~/aws$ aws lambda create-event-source-mapping --function-name quitanda-totals --event-source-arn "$ARN" --starting-position TRIM_HORIZON --batch-size 100 --maximum-retry-attempts 2 --bisect-batch-on-function-error --query '[State,BatchSize,MaximumRetryAttempts,BisectBatchOnFunctionError]' --output text
Enabled	100	2	True
ana@laptop:~/aws$ aws lambda list-event-source-mappings --query 'EventSourceMappings[].[State,LastProcessingResult]' --output text
Enabled	None
```

**O mapping está `Enabled`, e aqui ele nunca vai chamar a função.** O moto cria funções e mappings como
registros, e só roda o código de uma função dentro do Docker, que este laboratório não usa; nenhum lote
foi entregue e o `LastProcessingResult` está vazio. Tudo o que a seção anterior diz sobre novas tentativas
é o comportamento documentado da AWS e não foi rodado. O mapping leva as duas configurações que ela
descreveu: duas novas tentativas, e um lote que falha dividido ao meio.

## Kinesis Data Streams for DynamoDB

**O outro caminho para fora de uma tabela é para um data stream do Kinesis**, o serviço da lição 20, que
guarda registros por até um ano e deixa muitos consumidores lê-los. O moto não o implementa:

```
ana@laptop:~/aws$ aws kinesis create-stream --stream-name quitanda-changes --shard-count 1
ana@laptop:~/aws$ aws dynamodb enable-kinesis-streaming-destination --table-name quitanda --stream-arn arn:aws:kinesis:sa-east-1:123456789012:stream/quitanda-changes 2>&1 | head -2

aws: [ERROR]: An error occurred (500) when calling the EnableKinesisStreamingDestination operation (reached max retries: 2): <!doctype html>
```

**O `500` é o moto falhando, e é a resposta honesta.** Pela documentação da AWS, a troca é retenção e
vários leitores contra duas garantias. Num stream do Kinesis os registros de um item podem chegar fora de
ordem e mais de uma vez, então um consumidor os ordena por `ApproximateCreationDateTime` e remove ele
mesmo as duplicatas. O DynamoDB Streams dá ordem e nenhuma duplicata dentro das 24 horas dele; o Kinesis
dá um ano e mais leitores. Nenhum dos dois elimina as duplicatas do consumidor da seção anterior.

## Quanto custa ler um stream

```
ana@laptop:~/aws$ python3 prices.py dynamodb
AWS public price list, sa-east-1, USD, excluding tax

DynamoDB, USD
  on demand, per million write request units            0.93750  million
  on demand, per million read request units             0.18750  million
  provisioned, per WCU-hour                            0.000975  WCU-hour
  provisioned, per RCU-hour                            0.000195  RCU-hour
  storage beyond 25 GB                                  0.37500  GB-month
  storage, Standard-IA table class                      0.15000  GB-month
  streams, per million read requests beyond free        0.30000  million
  point-in-time recovery                                0.30000  GB-month
```

**Ler um stream do DynamoDB é cobrado por chamada `GetRecords`**, a 0,30 dólar por milhão além de uma
franquia mensal gratuita, devolva a chamada o que devolver, então um leitor que consulta um shard parado
paga por respostas vazias. Quatro chamadas por segundo num shard por um mês de 30 dias são 4 × 86.400 ×
30 = 10.368.000 chamadas, 3,11 dólares a esse preço. Pela página de preços da AWS, as chamadas que o
Lambda faz para um gatilho não são cobradas, mais um motivo para o Lambda ser o consumidor comum.
