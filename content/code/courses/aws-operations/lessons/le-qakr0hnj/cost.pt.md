---
title: Quanto custa o Config, e a conta que surpreendeu o dono
version: 1
---

```
ana@laptop:~/aws$ python3 price.py AWSConfig ConfigurationItemRecorded
AWSConfig, sa-east-1, published 2026-09-11
  SAE1-ConfigurationItemRecorded           0.003000 USD per SAE1-ConfigurationItemRecorded $0.003 per  Configuration Item recorded in South America (Sao Paulo) region
  SAE1-ConfigurationItemRecordedDaily      0.012000 USD per ConfigurationItemRecordedDaily $0.012 per ConfigurationItemRecordedDaily
ana@laptop:~/aws$ python3 price.py AWSConfig SAE1-ConfigRuleEvaluations
AWSConfig, sa-east-1, published 2026-09-11
  SAE1-ConfigRuleEvaluations               0.000500 USD per ConfigRuleEvaluations $0.0005 for 500,001 evaluations and more in South America (Sao Paulo) region
  SAE1-ConfigRuleEvaluations               0.000800 USD per ConfigRuleEvaluations $0.0008 for the next 400,000 evaluations in South America (Sao Paulo) region
  SAE1-ConfigRuleEvaluations               0.001000 USD per ConfigRuleEvaluations $0.001 for the first 100,000 evaluations in South America (Sao Paulo) region
```

O Config cobra pelos **itens de configuração gravados**, 0,003 USD cada com gravação contínua, e pelas
avaliações de regra, 0,001 USD cada nas primeiras 100.000 do mês e menos depois; as avaliações de
conformance pack têm as mesmas faixas. A **gravação diária**, a segunda linha, grava no máximo um item por
recurso por dia a 0,012 USD.

Para uma conta tranquila a conta é pequena: duzentos recursos mudando poucas vezes por mês geram uns mil
itens, 3 USD, e dez regras avaliando-os, alguns dólares a mais. A surpresa vem dos **recursos que mudam o
dia todo**:

| rotatividade | itens por mês | contínua, USD | diária, USD |
|---|---|---|---|
| 200 recursos, poucas mudanças cada | 1.000 | 3,00 | até 12,00 |
| um auto scaling group trocando 300 instâncias por dia, cada uma com volume e interface de rede | cerca de 54.000 | 162,00 | depende dos recursos vivos a cada dia |

Cada instância criada e encerrada gera itens para a instância, o volume e a interface de rede, a cada
mudança. **Gravar todo tipo continuamente, numa conta que escala, faz do Config uma das maiores linhas
dela.** As correções são um grupo de gravação que deixa de fora os tipos que ninguém consulta, ou gravação
diária para os tipos que mudam muitas vezes por dia, onde um item por dia a quatro vezes o preço sai mais
barato que dezenas ao preço normal.
