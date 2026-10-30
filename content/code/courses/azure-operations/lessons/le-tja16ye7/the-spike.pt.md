---
title: Da conta à causa
version: 1
---

**Um dia marcado diz que a conta se mexeu; a próxima pergunta é qual medidor.** A semana antes do dia 9 contra a semana depois, por
categoria de medidor:

```kql
// which.kql: the week before the jump against the week after, by meter
CostDaily
| where Date between (datetime(2026-10-02) .. datetime(2026-10-15))
| extend week = iff(Date < datetime(2026-10-09), "before", "after")
| summarize cost = sum(Cost) by MeterCategory, week
| evaluate pivot(week, sum(cost))
| extend change = round(after - before, 2), before = round(before, 2), after = round(after, 2)
| order by change desc
| take 3
```

```
ana@laptop:~/azure/kusto$ python3 kql.py < which.kql
MeterCategory  after  before  change
Log Analytics  89.34  28.12   61.22
SQL Database   105.0  104.55  0.45
Storage        22.21  21.97   0.24
```

`evaluate pivot()` transforma os dois valores de `week` em duas colunas, para a mudança ser uma subtração. **O Log Analytics foi de 28 USD
por semana para 89**; todo o resto se mexeu menos de um dólar. O degrau é um medidor, triplicado.

Daqui, a investigação são as lições 9 e 21, em ordem. No workspace, a tabela `Usage` diz qual tabela teve a ingestão aumentada no dia 9, e
para a loja seria a `AppTraces`: as linhas de log da própria aplicação. O activity log diz o que mudou no dia 8 ou 9, e uma configuração de
aplicação mudada por um deploy está nele, como a identidade da esteira escrevendo em `app-shop-api`. A causa, quando a equipe dona do
medidor olhou, foi a que a lição 9 usou como exemplo: **um nível de log posto em `Debug` para uma investigação e nunca voltado**,
multiplicando os traces que cada requisição escreve.

A correção é uma configuração, e a lição é a forma do incidente, que é a da lição 15 aplicada a dinheiro. **Detecção**: a verificação
diária marcou o primeiro dia. **Mitigação**: voltar o nível de log para o custo no dia seguinte. **Postmortem, sem culpados**: por que um
nível de debug conseguia chegar à produção sem prazo, e por que ninguém viu a conta por uma semana? As ações da loja foram uma
transformação numa data collection rule que descarta traces `Debug` em produção, a ferramenta da lição 8, e uma data de expiração em toda
mudança temporária de nível de log. O custo da semana, cerca de 60 USD, foi o preço de aprender as duas.

É aqui que este curso termina: a esteira que entrega, o monitoramento que percebe, a segurança que segura, e a conta lida como mais um
sinal do que o sistema está fazendo.
