---
title: Quanto custa um web ACL
version: 1
---

O WAF é cobrado por três coisas: os web ACLs, as regras dentro deles e as requisições que inspecionam. A
lista de preços da lição 1 tem cada uma delas, para São Paulo:

```
ana@laptop:~/aws$ python3 price.py awswaf SAE1-WebACLV2
awswaf, sa-east-1, published 2026-09-14
  SAE1-WebACLV2                            5.000000 USD per Month      $5.00 per web ACL created (prorated hourly)
ana@laptop:~/aws$ python3 price.py awswaf SAE1-RuleV2
awswaf, sa-east-1, published 2026-09-14
  SAE1-RuleV2                              1.000000 USD per Month      $1.00 per rule created (prorated hourly)
ana@laptop:~/aws$ python3 price.py awswaf SAE1-RequestV2-Tier
awswaf, sa-east-1, published 2026-09-14
  SAE1-RequestV2-Tier0                     0.000001 USD per Request    $0.60 per million Request for Request Processed Tier0 in South America (Sao Paulo)
  SAE1-RequestV2-Tier1                     0.000001 USD per Request    $0.60 per million requests processed
  SAE1-RequestV2-Tier2-2000WCU             0.000001 USD per Request    $0.80 per million requests processed
  SAE1-RequestV2-Tier3-2500WCU             0.000001 USD per Request    $1.00 per million requests processed
  SAE1-RequestV2-Tier4-3000WCU             0.000001 USD per Request    $1.20 per million requests processed
  SAE1-RequestV2-Tier5-3500WCU             0.000001 USD per Request    $1.40 per million requests processed
  SAE1-RequestV2-Tier6-4000WCU             0.000002 USD per Request    $1.60 per million requests processed
  SAE1-RequestV2-Tier7-4500WCU             0.000002 USD per Request    $1.80 per million requests processed
  SAE1-RequestV2-Tier8-5000WCU             0.000002 USD per Request    $2.00 per million requests processed
```

Leia a frase da direita em vez do número, já que o programa imprime seis casas decimais e um preço de 60
centavos por milhão de requisições é 0,0000006 por requisição. **Um web ACL custa 5 USD por mês, cada
regra 1 USD por mês**, ambos proporcionais à hora, e um grupo de regras gerenciado conta como uma regra,
quantas regras ele tiver. **Requisições custam 0,60 USD por milhão** enquanto o web ACL fica dentro de
1.500 WCU, as duas linhas `Tier0` e `Tier1` com o mesmo preço, e cada 500 WCU além disso somam 0,20 USD
por milhão, até 2,00 no limite de 5.000.

O web ACL da loja, a 50 milhões de requisições por mês:

| linha | quantidade | USD por mês |
|---|---|---|
| web ACL | 1 × 5,00 | 5,00 |
| regras | 3 × 1,00 | 3,00 |
| requisições, ≤ 1.500 WCU | 50 milhões × 0,60 | 30,00 |
| **total** | | **38,00** |

**As requisições são a maior parte**, e crescem com o tráfego e não com as regras. Três decisões mudam o
total, e cada uma está visível na lista de preços antes de ser tomada:

- **capacidade além de 1.500 WCU** muda o preço de toda requisição: os mesmos 50 milhões no nível de
  2.000 WCU custam 0,80 × 50 = 40 USD em vez de 30, então somar um grupo de 200 unidades a um web ACL em
  1.400 custa 10 USD por mês em requisições, além de 1 USD como regra;
- **os grupos gerenciados pagos** cobram à parte: o nível comum do Bot Control custa 10 USD por mês, e
  sua linha por requisição diz 1 USD por milhão além das requisições que ele inclui;
- **CAPTCHA** custa 0,40 USD por mil tentativas, mil vezes o preço de uma requisição comum, então uma
  ação CAPTCHA num caminho movimentado é uma linha a vigiar na conta.

`SAE1-` é o prefixo que a conta usa para São Paulo, como na lição 1, e estas linhas aparecem nela sob os
tipos de uso acima. A lição 24 lê uma conta por eles, e a lição 25 dispara alarme numa que se mexe.
