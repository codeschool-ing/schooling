---
title: Cobertura, utilização, e o que o laboratório não mostra
version: 1
---

Dois números descrevem um compromisso depois que ele existe, e o Cost Explorer informa os dois:

- **utilização**: quanto do compromisso foi usado. Abaixo de 100% é dinheiro pago por nada, a coluna
  ociosa da seção anterior;
- **cobertura**: quanto do uso elegível os compromissos cobriram. O resto foi pago sob demanda.

Eles puxam para lados opostos. 100% de utilização com 40% de cobertura quer dizer um compromisso seguro e
pequeno; 90% de cobertura com 80% de utilização quer dizer um grande e em parte desperdiçado. A escolha de
seis da loja dá 100% de utilização e 68% de cobertura, e esse é um bom lugar para estar: o terço sem
cobertura é a parte da frota que vai e vem.

O Cost Explorer também **recomenda** um compromisso a partir dos últimos 7, 30 ou 60 dias de uso. A
recomendação é a mesma conta do `commit.py`, sobre o histórico real, e vale ler o período que ela usou:
sessenta dias que incluem uma promoção vão recomendar um compromisso que o ano não consegue usar.

## O que o moto mostra no lugar

```
ana@laptop:~/aws/commit$ aws ec2 describe-reserved-instances-offerings --instance-type m7g.large --query 'ReservedInstancesOfferings[:3].[Duration,OfferingType,FixedPrice,UsagePrice]' --output text
31536000	No Upfront	0.0	0.05
31536000	Partial Upfront	208.0	0.05
31536000	All Upfront	261.0	0.0
ana@laptop:~/aws/commit$ aws ce get-savings-plans-purchase-recommendation --savings-plans-type COMPUTE_SP --term-in-years ONE_YEAR --payment-option NO_UPFRONT --lookback-period-in-days SIXTY_DAYS 2>&1 | grep -m1 ERROR
aws: [ERROR]: An error occurred (500) when calling the GetSavingsPlansPurchaseRecommendation operation (reached max retries: 2): <!doctype html>
```

O moto lista ofertas de reserved instance de `m7g.large` com preços que ele **inventa**, e inventa de novo
a cada execução. As três acima são as primeiras de dezenas que ele listou: um prazo de um ano em segundos,
um preço adiantado e um por hora, para uma instância cujo preço real de um ano com pagamento total
adiantado a seção anterior leu como 659 USD. É por isso que este curso só tira preços da lista de preços. E
ele não tem recomendações, nem o serviço de Savings Plans, nem relatórios de utilização, então os
compromissos desta lição são contas sobre preços públicos e um mês inventado, que é o que uma recomendação
também é, sobre um mês real.

## Antes de comprar

- **Um compromisso não pode ser cancelado.** Savings Plans não podem ser vendidos; RIs standard podem ser
  anunciadas no RI Marketplace, para um comprador, e as convertible só trocadas.
- **Ajuste o tamanho primeiro.** Comprometer instâncias que têm o dobro do tamanho necessário prende o
  desperdício pelo prazo; a lição 23 é sobre achá-lo.
- **O desconto cobre só computação.** Transferência de dados, armazenamento e requisições são pagos como
  antes, e uma conta da qual computação é um terço não pode cair mais de um terço com compromisso nenhum.
