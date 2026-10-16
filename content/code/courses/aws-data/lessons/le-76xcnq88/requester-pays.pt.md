---
title: Requester pays, e para quem vai a conta
version: 1
---

**Por padrão, o dono de um bucket paga por tudo o que é feito nele, inclusive por outros.** Um parceiro
em us-east-1 que copia os 5 TB de histórico de pedidos da Quitanda, com acesso que a Quitanda
concedeu, tira 5 TB da região, e a transferência cai na conta da Quitanda. Requester pays é a
configuração que passa dois dos três medidores para quem pede.

Num bucket com requester pays ligado, como a AWS documenta:

- **quem pede paga as requisições e a transferência**; o dono continua pagando o armazenamento;
- **toda requisição precisa dizer que aceita a cobrança**, com o cabeçalho
  `x-amz-request-payer: requester`, que a linha de comando manda com `--request-payer requester`.
  Uma requisição sem ele é recusada com `403`;
- **requisições anônimas são recusadas**, já que não haveria a quem cobrar. Um bucket requester pays
  não pode servir o público também;
- quem pede precisa ser uma conta da AWS, e a fatura dela mostra as cobranças.

Serve para dados compartilhados com outras empresas, que os leem no próprio ritmo: um conjunto de
dados vendido a parceiros, ou um conjunto público de pesquisa cujo dono paga só para guardá-lo. Não
serve para nada que os próprios times da Quitanda leem, já que as cobranças passariam de uma conta da
Quitanda para outra e nada seria economizado.

## No moto

```
ana@laptop:~/aws$ aws s3 mb s3://quitanda-curated-prod
make_bucket: quitanda-curated-prod
ana@laptop:~/aws$ printf 'order_id,customer_id,total_cents\nord-01-1,c-17,4590\n' > history.csv && aws s3 cp history.csv s3://quitanda-curated-prod/shared/history.csv
upload: ./history.csv to s3://quitanda-curated-prod/shared/history.csv
ana@laptop:~/aws$ aws s3api put-bucket-request-payment --bucket quitanda-curated-prod --request-payment-configuration Payer=Requester

aws: [ERROR]: An error occurred (IllegalLocationConstraintException) when calling the PutBucketRequestPayment operation: The unspecified location constraint is incompatible for the region specific endpoint this request was sent to.
ana@laptop:~/aws$ aws s3api get-bucket-request-payment --bucket quitanda-curated-prod
ana@laptop:~/aws$ aws s3api get-object --bucket quitanda-curated-prod --key shared/history.csv history-copy.csv --request-payer requester --query ContentLength
52
```

**O moto 5.2.3 não implementa essa configuração.** O `put-bucket-request-payment` falhou com
`IllegalLocationConstraintException`, o erro de criar um bucket no lugar errado, que é o mesmo
desvio que a lição 2 encontrou com o Intelligent-Tiering: a requisição caiu no código que cria
buckets. O `get-bucket-request-payment` respondeu com nada, onde o S3 responde `{"Payer":
"BucketOwner"}` para um bucket que nunca foi mudado. E um `GET` com `--request-payer requester` deu
certo num bucket que nunca o exigiu, o que no S3 também dá certo: o cabeçalho é uma promessa de pagar,
e um bucket que não cobra nada o ignora.

Então nada de requester pays foi rodado aqui além disso. O que ele faz com uma conta é a aritmética das
seções anteriores com o pagador trocado: a cópia de 5 TB do parceiro para us-east-1 custa
5.120 × 0,13800 = 706,56 seja quem for que pague, e o requester pays decide em que conta ela entra.
