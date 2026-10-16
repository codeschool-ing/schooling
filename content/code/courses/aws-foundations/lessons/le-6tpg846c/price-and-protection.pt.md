---
title: Quanto custa o CloudFront, e o que ele deixa de fora
version: 1
---

**O CloudFront cobra por onde está quem vê**, não por onde está a loja. Um gigabyte mandado a um
cliente em Recife é cobrado como América do Sul e um gigabyte a um em Lisboa como Europa, seja qual
for a região em que a origem mora. Três linhas fazem a maior parte da fatura: os bytes de saída para
quem vê, as requisições, e os caminhos de invalidação além de uma cota. E uma linha que importa é a
que não custa nada. A imagem errada comum é que uma CDN é uma camada extra de custo por cima da da
região. Para bytes que saem da AWS, ela costuma ser a porta mais barata.

## As linhas da lista de preços

A oferta do CloudFront, como a do Route 53, guarda os preços sob `aws-other`, com a parte do mundo de
quem vê no começo de cada tipo de uso:

```
ana@laptop:~/aws$ python3 price.py AmazonCloudFront 20260916132208 aws-other SA-DataTransfer-Out-Bytes US-DataTransfer-Out-Bytes Invalidations
AmazonCloudFront 20260916132208, published 2026-09-16, USD
SA-DataTransfer-Out-Bytes
          0 to    10,240 GB   0.1100
     10,240 to    51,200 GB   0.1050
     51,200 to   153,600 GB   0.0900
    153,600 to   512,000 GB   0.0800
    512,000 to 1,048,576 GB   0.0600
  1,048,576 to 5,242,880 GB   0.0500
  5,242,880 to       Inf GB   0.0400
US-DataTransfer-Out-Bytes
          0 to    10,240 GB   0.0850
     10,240 to    51,200 GB   0.0800
     51,200 to   153,600 GB   0.0600
    153,600 to   512,000 GB   0.0400
    512,000 to 1,048,576 GB   0.0300
  1,048,576 to 5,242,880 GB   0.0250
  5,242,880 to       Inf GB   0.0200
Invalidations
          0 to     1,000 URL  0.0000
      1,000 to       Inf URL  0.0050
```

Requisições são cobradas por requisição, pequenas demais para quatro casas decimais, então o
`per-million.py` da lição 21 as lê do arquivo que o `price.py` acabou de baixar:

```
ana@laptop:~/aws$ python3 per-million.py AmazonCloudFront 20260916132208 aws-other SA-Requests-Tier2-HTTPS US-Requests-Tier2-HTTPS
SA-Requests-Tier2-HTTPS
  from             0  2.20 per million
US-Requests-Tier2-HTTPS
  from             0  1.00 per million
```

E a linha que não custa nada está na oferta de transferência de dados que a lição 1 leu, ao lado dos
0,15 que ela citou de São Paulo para a internet:

```
ana@laptop:~/aws$ python3 price.py AWSDataTransfer 20260916132208 sa-east-1 SAE1-CloudFront-Out-Bytes SAE1-DataTransfer-Out-Bytes
AWSDataTransfer 20260916132208, published 2026-09-16, USD
SAE1-CloudFront-Out-Bytes
          0 to       Inf GB   0.0000
SAE1-DataTransfer-Out-Bytes
          0 to    10,240 GB   0.1500
     10,240 to    51,200 GB   0.1380
     51,200 to   153,600 GB   0.1260
    153,600 to       Inf GB   0.1140
```

As duas ofertas carregam a versão `20260916132208`, publicada em **16 de setembro de 2026**, em
dólares:

| | para quem vê na América do Sul | para quem vê nos EUA |
|---|---|---|
| um GB saindo do CloudFront, primeiros 10 TB do mês | 0,110 | 0,085 |
| um milhão de requisições HTTPS | 2,20 | 1,00 |
| um GB de `sa-east-1` para o CloudFront | grátis | grátis |
| um GB de `sa-east-1` direto para a internet, primeiros 10 TB | 0,150 | 0,150 |
| um caminho de invalidação, primeiros 1.000 do mês | grátis | grátis |
| um caminho de invalidação depois disso | 0,005 | 0,005 |

## O mês da loja, dos dois jeitos

Digamos que a loja manda 5 TB por mês a clientes no Brasil, em 50 milhões de requisições HTTPS.

- **Direto da região**: 5.120 GB × 0,150 = **768,00 dólares** de transferência.
- **Pelo CloudFront**: 5.120 GB × 0,110 = **563,20 dólares** de transferência, mais
  50 × 2,20 = **110,00** de requisições, então 673,20, e a transferência do bucket e do balanceador
  para o CloudFront é grátis.

**A CDN sai 94,80 dólares por mês mais barata antes de economizar qualquer outra coisa**, e ela
economiza mais. Toda requisição respondida no ponto de presença é uma que o balanceador não contou
nas unidades de capacidade, e uma que o bucket não contou como `GET`. Os números só vão para o outro
lado em tráfego que não pode ficar em cache nenhum e é feito de requisições pequenas, em que a linha
de requisições pesa mais que a transferência que ela economiza.

**A classe de preço é a configuração que pode desfazer isso em silêncio.** `PriceClass_All`, que a
distribuição da loja usa, atende todo mundo pelo ponto de presença mais próximo. As duas classes
mais baratas, `PriceClass_100` e `PriceClass_200`, deixam de fora as partes mais caras do mundo.
Segundo a documentação da AWS, a América do Sul fica de fora das duas. Um cliente brasileiro seria
então atendido por um ponto de presença na América do Norte, a um preço menor por gigabyte e com uma
latência que o cliente sente. Para uma loja cujos clientes estão no Brasil, a classe não é economia,
é o ponto de presença errado.

As invalidações, por último: os 1.500 caminhos da loja num mês movimentado custam 500 × 0,005 =
**2,50 dólares**, e o mesmo mês com nomes de arquivo com versão não custa nada.

## O que uma distribuição deixa de fora

Uma distribuição também é a porta da frente, e quatro coisas podem ser configuradas nela. **Nenhuma
delas foi posta à prova aqui**: o moto guarda algumas e não aplica nenhuma, então o comportamento
abaixo é o documentado pela AWS.

- **Um comportamento pode exigir assinatura em toda requisição**, numa URL assinada ou num cookie
  assinado feitos com uma chave que a loja guarda. O CloudFront a confere com a metade pública,
  guardada num **grupo de chaves** (*key group*) da distribuição. Um download vendido a um cliente
  ganha uma URL que funciona até uma hora que a loja escolheu, e o link de mais ninguém funciona.
- **Uma distribuição pode recusar países inteiros**, ou permitir só alguns, pelo endereço de quem vê.
  O moto guarda a configuração, e a desta distribuição diz que ninguém é recusado:

```
ana@laptop:~/aws$ aws cloudfront get-distribution-config --id $id --query "DistributionConfig.Restrictions"
{
    "GeoRestriction": {
        "RestrictionType": "none",
        "Quantity": 0
    }
}
```

- **O AWS WAF filtra requisições no ponto de presença**, por uma web ACL presa à distribuição, antes
  que elas custem qualquer coisa à origem: limites de taxa por endereço, regras contra ataques comuns,
  bloqueios por país ou cabeçalho. Para o CloudFront a web ACL é criada com o escopo `CLOUDFRONT`, em
  `us-east-1`, a regra da primeira seção desta lição mais uma vez.
- **O AWS Shield Standard está ligado em toda distribuição**, sem custo, contra as enxurradas de tráfego mais comuns. O **Shield Advanced**, pago, acrescenta uma equipe de resposta e proteção de
  custo.

**A origem também tem de ser fechada.** Uma distribuição na frente de um balanceador que qualquer um
ainda alcança direto é uma porta da frente ao lado de uma janela aberta. O OAC fecha o bucket, como
a primeira seção fez. Para o balanceador, a AWS publica uma lista de prefixos gerenciada com os
endereços do CloudFront. Uma regra de grupo de segurança que admite só essa lista, assunto da lição
18, deixa o CloudFront como o único caminho de entrada.
