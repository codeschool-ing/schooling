---
title: Grupos de logs, e a retenção que ninguém definiu
version: 1
---

O CloudWatch Logs guarda linhas em **grupos de logs**, um por aplicação ou componente, e dentro de
cada grupo em **streams de log**, um por origem: um contêiner, uma instância, o ambiente de execução de
uma função. O grupo é onde as decisões são tomadas: quem pode lê-lo, por quanto tempo guarda linhas, o
que é extraído delas. Crie o grupo da API da loja e olhe para ele:

```
ana@laptop:~/aws/logs$ aws logs create-log-group --log-group-name /shop/api
ana@laptop:~/aws/logs$ aws logs describe-log-groups --log-group-name-prefix /shop/api --query 'logGroups[0].[logGroupName,retentionInDays,storedBytes]' --output text
/shop/api	None	0
ana@laptop:~/aws/logs$ aws logs put-retention-policy --log-group-name /shop/api --retention-in-days 30
ana@laptop:~/aws/logs$ aws logs describe-log-groups --log-group-name-prefix /shop/api --query 'logGroups[0].[logGroupName,retentionInDays]' --output text
/shop/api	30
```

`None` é a retenção que um grupo novo recebe, e significa **nunca expirar**. Cada linha escrita fica,
e é cobrada todo mês enquanto a conta existir. Ninguém escolhe isso; é o que acontece quando ninguém
escolhe. `put-retention-policy` define um número de dias da mesma lista fixa que o cfn-lint conhecia
na lição 4, e linhas mais velhas que isso são apagadas pelo CloudWatch.

## Quanto custa um gigabyte de logs

```
ana@laptop:~/aws/logs$ python3 price.py AmazonCloudWatch SAE1-DataProcessing-Bytes
AmazonCloudWatch, sa-east-1, published 2026-10-07
  SAE1-DataProcessing-Bytes                0.900000 USD per GB         $0.90 per GB custom log data ingested in Standard log class - South America (Sao Paulo)
ana@laptop:~/aws/logs$ python3 price.py AmazonCloudWatch TimedStorage-ByteHrs
AmazonCloudWatch, sa-east-1, published 2026-10-07
  Global-TimedStorage-ByteHrs              0.000000 USD per GB-Mo      Global
  SAE1-TimedStorage-ByteHrs                0.040800 USD per GB-Mo      $0.0408 per GB-mo of log storage - South America (Sao Paulo)
```

As duas linhas cobram coisas diferentes, e a diferença decide como economizar:

- **ingestão**: 0,90 USD por gigabyte escrito, uma vez, quando chega;
- **armazenamento**: 0,0408 USD por gigabyte por mês, a cada mês em que fica guardado.

A API da loja escreve 5 GB de logs por dia. A ingestão é de 150 GB por mês, 135 USD, qualquer que seja
a retenção. O armazenamento com retenção de 30 dias guarda uns 150 GB, uns 6 USD por mês; sem
retenção ele cresce 150 GB a cada mês, e depois de dois anos guarda 3,6 TB, uns 147 USD por mês e
ainda crescendo. **A ingestão é a conta maior, e a retenção é a que cresce sozinha.** Logar menos
(menos linhas, linhas mais curtas, nada de corpo de requisição) economiza ingestão; uma política de
retenção em cada grupo para o crescimento.

A lista de preços também traz uma classe de log Infrequent Access, mais barata de ingerir e guardar,
com menos recursos. Ela é escolhida na criação do grupo, e serve para logs guardados para auditoria e
raramente consultados.

## Quem pode lê-lo

Linhas de log carregam o que a aplicação escreveu nelas, e aplicações escrevem mais do que deviam: um
e-mail numa mensagem de erro, um token numa URL de requisição. As permissões de um grupo de logs são,
portanto, permissões sobre dados. Acesso de leitura a `/shop/api` deve ser concedido como acesso de
leitura à tabela de pedidos, e uma **política de proteção de dados** no grupo pode mascarar padrões como
e-mails e números de cartão quando chegam, o que o moto não implementa e não foi executado aqui.
