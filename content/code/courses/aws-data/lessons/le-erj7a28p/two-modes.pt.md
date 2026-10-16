---
title: Provisionada e sob demanda
version: 1
---

**Há dois jeitos de pagar pelas mesmas unidades, e eles diferem no que você promete antes.** Sob
demanda, o modo de todas as tabelas até aqui, você não promete nada: cada requisição é contada em
**unidades de requisição**, as unidades da seção anterior, e cobrada por milhão. Provisionada, você
declara um número de **unidades de capacidade por segundo**, leitura e escrita separadas, e paga por
elas por hora, use-as alguém ou não. Uma tabela provisionada com 100 unidades de escrita absorve 100
escritas de 1 KB por segundo; é cobrada por 100 em toda hora do mês, às três da manhã também.

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

**Por unidade de trabalho, a provisionada é mais barata, e a diferença é o argumento inteiro.** Um milhão
de escritas sob demanda custa 0,9375 dólar. Uma unidade de escrita provisionada por uma hora custa
0,000975 dólar e carrega 3.600 escritas, então um milhão de escritas com ela em uso total custa 0,000975
× 1.000.000 / 3.600 = 0,27 dólar, menos de um terço. As leituras mantêm a mesma proporção: 0,1875 sob
demanda contra 0,000195 × 1.000.000 / 3.600 = 0,054. O problema é o "em uso total". Uma unidade que
ninguém usa ainda custa a sua hora, e a próxima seção acha onde isso deixa de valer a pena. A tabela de
preços lê a segunda faixa das duas linhas provisionadas porque a lista da AWS deixa a primeira de graça,
uma franquia mensal de 25 unidades de cada.

## Trocando o modo de uma tabela

A tabela products foi criada sob demanda, e informa o warm throughput de uma tabela nova sob demanda.
Passá-la para provisionada nomeia a capacidade; mudar a capacidade depois é o mesmo comando:

```
ana@laptop:~/aws$ aws dynamodb describe-table --table-name products --query 'Table.[BillingModeSummary.BillingMode,WarmThroughput]'
[
    "PAY_PER_REQUEST",
    {
        "ReadUnitsPerSecond": 12000,
        "WriteUnitsPerSecond": 4000,
        "Status": "ACTIVE"
    }
]
ana@laptop:~/aws$ aws dynamodb update-table --table-name products --billing-mode PROVISIONED --provisioned-throughput ReadCapacityUnits=10,WriteCapacityUnits=5 --query 'TableDescription.[BillingModeSummary.BillingMode,ProvisionedThroughput]'
[
    "PROVISIONED",
    {
        "ReadCapacityUnits": 10,
        "WriteCapacityUnits": 5
    }
]
ana@laptop:~/aws$ aws dynamodb update-table --table-name products --provisioned-throughput ReadCapacityUnits=10,WriteCapacityUnits=3 --query 'TableDescription.ProvisionedThroughput'
{
    "ReadCapacityUnits": 10,
    "WriteCapacityUnits": 3
}
ana@laptop:~/aws$ aws dynamodb update-table --table-name products --billing-mode PAY_PER_REQUEST --query 'TableDescription.BillingModeSummary.BillingMode'
"PAY_PER_REQUEST"
ana@laptop:~/aws$ aws dynamodb update-table --table-name products --billing-mode PROVISIONED --provisioned-throughput ReadCapacityUnits=10,WriteCapacityUnits=5 --query 'TableDescription.BillingModeSummary.BillingMode'
"PROVISIONED"
```

**O moto trocou a tabela de um modo para o outro quantas vezes foi pedido, e a AWS não faria isso.** A
documentação da AWS permite trocar de provisionada para sob demanda no máximo quatro vezes em 24 horas
corridas, e trocar no sentido contrário a qualquer hora. Ela também só permite um número limitado de
reduções de capacidade por dia, contadas no `NumberOfDecreasesToday` que o `describe-table` informa.
Esses limites não foram rodados aqui; o moto não tem nenhum deles. Uma tabela provisionada baixa demais
se conserta aumentando, o que é sempre permitido, e uma provisionada alta demais custa dinheiro até as
reduções do dia permitirem baixá-la.

**Com qual começar não é uma decisão apertada para uma tabela nova.** Sob demanda não fica
subprovisionada e não custa nada parada, então é o modo de uma tabela cuja carga ninguém mediu ainda. A
AWS também deixa uma tabela nova sob demanda receber, sem aviso, até 4.000 escritas e 12.000 leituras por
segundo, que é o que o `WarmThroughput` de uma tabela sob demanda informa, no moto como na AWS.
Provisionada é o modo de uma carga que alguém mediu, e a próxima seção é como saber se a medida a
justifica.
