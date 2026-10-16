---
title: A conta, e a decisão
version: 1
---

O preço do Shield Advanced tem duas partes, e a lista de preços da lição 1 tem a segunda:

```
ana@laptop:~/aws$ python3 price.py AWSShield ELB
AWSShield, sa-east-1, published 2026-09-16
  SAE1-DataTransfer-Shield-Bytes           0.030000 USD per GB         Shield Data Transfer Out of ELB in GRU - Above 500 TB
  SAE1-DataTransfer-Shield-Bytes           0.040000 USD per GB         Shield Data Transfer Out of ELB in GRU - Next 400 TB
  SAE1-DataTransfer-Shield-Bytes           0.050000 USD per GB         Shield Data Transfer Out of ELB in GRU - First 100 TB
ana@laptop:~/aws$ curl -sS https://pricing.us-east-1.amazonaws.com/offers/v1.0/aws/AWSShield/20260916132208/aws-other/index.json | jq -r '.terms.OnDemand[][].priceDimensions[] | select(.description | test("Subscription")) | [.pricePerUnit.USD, .unit, .description] | @tsv'
3000.0000000000	month	$3,000 for First Subscription
0.0000000000	month	$0 for additional Subscriptions
ana@laptop:~/aws$ python3 price.py awswaf SAE1-ShieldProtected-RequestV2-Tier1
awswaf, sa-east-1, published 2026-09-14
  SAE1-ShieldProtected-RequestV2-Tier1     0.000000 USD per Request    $0 per million requests processed (Shield Protected)
```

O primeiro comando é a linha de transferência de dados: além da transferência de saída de sempre, **cada
gigabyte que um balanceador protegido envia** paga 0,05 USD, nos primeiros 100 TB do mês. A assinatura
em si não é uma linha de São Paulo, porque pertence à organização e não a uma região. Ela está no arquivo
`aws-other` da oferta, que o `price.py` não lê, então o segundo comando a lê com `curl` e `jq`, guardando
as linhas sobre a assinatura: **3.000 USD por mês pela primeira assinatura**, e nada pelas seguintes. Uma assinatura cobre todas as contas de uma organização que paga numa única conta. A terceira linha é
o preço de requisição do WAF para um recurso protegido, zero no nível base.

## Os números da loja

O balanceador da loja envia cerca de 2 TB por mês:

| linha | quantidade | USD por mês |
|---|---|---|
| assinatura | 1 | 3.000,00 |
| transferência de dados do Shield | 2.000 GB × 0,05 | 100,00 |
| requisições do WAF, agora incluídas | 50 milhões × 0 | 0,00 |
| **total** | | **3.100,00** |

Contra os 38 USD por mês do WAF sozinho na lição 15, e por um ano, já que o compromisso é de um ano:
**37.200 USD**, dos quais 456 USD são o WAF que a assinatura agora inclui.

## Quem deve comprar

A assinatura vale a pena quando **uma hora fora do ar, ou uma semana de escalonamento, custa mais que o
ano de assinatura**, ou quando alguém exige em contrato proteção e uma equipe de resposta. Três perguntas
resolvem:

1. **Quanto custa uma hora fora do ar?** Uma loja que vende 10.000 USD por dia perde cerca de 420 USD por
   hora, e 37.200 USD compram 89 horas disso. Uma plataforma de pagamentos que perde 50.000 USD por hora
   paga o ano com menos de uma.
2. **Quanto ela escala sob carga?** Um serviço com auto scaling transforma um ataque numa conta, e a
   proteção de custo é o que a devolve.
3. **Existe uma equipe para trabalhar com a equipe de resposta?** Os especialistas ajudam uma equipe que
   conhece o próprio tráfego. Uma equipe que nunca leu os logs do seu WAF vai passar o ataque aprendendo a
   lê-los.

Para a loja como ela é, a resposta é não: Standard, o web ACL da lição 15 e o CloudFront na frente.
Escrita, com os números, essa resposta é a decisão, e é revista quando os números mudam.
