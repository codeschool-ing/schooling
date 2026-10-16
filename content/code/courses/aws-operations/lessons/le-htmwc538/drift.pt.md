---
title: Drift, e comparar o que é com o que se quis
version: 1
---

Uma stack sabe o que criou e com quais propriedades. Ela não sabe o que aconteceu depois. Alguém baixa
a retenção dos logs no console às duas da manhã, para segurar um custo, e vai dormir. **O template
ainda diz 14 dias, a stack ainda diz 14 dias, e o grupo de logs guarda um.** Essa diferença é o
**drift**, e a próxima atualização da stack pode pôr 14 de volta em silêncio, ou falhar, dependendo da
propriedade.

O laboratório faz o papel da pessoa no console com um comando:

```
ana@laptop:~/aws/cfn$ aws logs put-retention-policy --log-group-name /shop/web --retention-in-days 1
```

## Detecção, que o moto não faz

O CloudFormation compara cada recurso com o que a stack espera, quando se pede:

```
ana@laptop:~/aws/cfn$ aws cloudformation detect-stack-drift --stack-name shop-base 2>&1 | grep -m1 ERROR
aws: [ERROR]: Unable to parse response (syntax error: line 1, column 0), invalid XML received. Further retries may succeed:
```

O moto falha com um erro interno. Na AWS, `detect-stack-drift` inicia uma comparação e devolve um id;
`describe-stack-resource-drifts` então lista cada recurso como **`IN_SYNC`**, **`MODIFIED`**,
**`DELETED`** ou **`NOT_CHECKED`**, e, para um modificado, cada propriedade com o valor esperado e o
real. Para esta stack ele mostraria `WebLogs` como `MODIFIED`, com `RetentionInDays` esperado 14 e
real 1. Nem todo tipo de recurso suporta detecção de drift, e uma propriedade que o template não define
não é comparada, que é o que `NOT_CHECKED` e o silêncio significam.

## A mesma comparação, à mão

A ideia não precisa de serviço: leia o que se quis, leia o que é, compare.

```
ana@laptop:~/aws/cfn$ aws cloudformation describe-stacks --stack-name shop-base --query 'Stacks[0].Parameters[?ParameterKey==`Retention`].ParameterValue' --output text
14
ana@laptop:~/aws/cfn$ aws logs describe-log-groups --log-group-name-prefix /shop/web --query 'logGroups[0].retentionInDays'
1
```

Catorze pretendidos, um real. Essa comparação de duas linhas é o que a detecção de drift faz para cada
propriedade de cada recurso, e fazê-la à mão para a propriedade que importa é o jeito de conferir uma
correção antes de haver um serviço para conferi-la.

## O que fazer com o drift

Só há duas respostas honestas, e as duas terminam com o template e o recurso concordando:

- **a mudança estava errada**: atualize a stack com o template como está, e a propriedade volta ao que
  se pretendia;
- **a mudança estava certa**: ponha-a no template, revise-a como qualquer mudança e atualize a stack,
  para a próxima atualização não desfazê-la.

A terceira resposta, deixar como está, é a que mais custa: o drift fica ali até a próxima atualização
sem relação nenhuma desfazer uma correção de emergência no pior momento. O AWS Config, da lição 21,
consegue vigiar drift continuamente; o hábito por baixo é este: **o arquivo é a verdade, e qualquer
outra coisa é uma mudança que ainda não foi escrita**.
