---
title: O objetivo, e o orçamento que ele deixa
version: 1
---

**Um objetivo de nível de serviço é uma meta para um indicador num período**: 99,5% dos checkouts disponíveis, medidos na
semana. O número é escolha da loja, e um bom não é nem o melhor que o serviço já fez nem um desejo. É o nível abaixo do qual os clientes começam a perceber e a ir embora, e para uma loja isso é uma pergunta de negócio feita com dados.

**O orçamento de erro é o que o objetivo deixa falhar.** A 99,5% de 29.863 checkouts, a semana permite 149 com falha. Essa
permissão é o que torna o objetivo útil, porque transforma uma discussão sobre risco em aritmética:

```kql
// budget.kql: the week's error budget for checkout availability, at an objective of 99.5%
let objective = 99.5;
AppRequests
| where Name == "POST /checkout"
| summarize valid = count(), bad = countif(not(Success))
| extend allowed = round(valid * (100.0 - objective) / 100, 0)
| extend spent_pct = round(100.0 * bad / allowed, 1), left = allowed - bad
```

```
ana@laptop:~/azure/kusto$ python3 kql.py < budget.kql
valid  bad  allowed  spent_pct  left
29863  130  149.0    87.2       19.0
```

A semana cumpriu o objetivo, 130 falhas contra 149 permitidas, e **gastou 87% do orçamento**, quase tudo em 42 minutos na
tarde de quinta. Sobram dezenove falhas.

O que a loja faz com esse número fica escrito antes, como uma **política de orçamento de erro**, combinada entre quem entrega
e quem é chamado:

- orçamento saudável: entregas como sempre, experimentar à vontade;
- orçamento quase gasto: as entregas seguem, e cada uma espera o canário da lição 3 terminar limpo;
- orçamento esgotado: só correções e trabalho de confiabilidade entram até a janela passar dos dias ruins.

O ponto da política é que ninguém precisa ganhar uma discussão no dia. Com 19 falhas sobrando, a próxima entrega que quebrar
o checkout por cinco minutos esgota a semana, e todo mundo sabia disso antes de ela sair.
