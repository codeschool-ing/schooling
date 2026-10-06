---
title: Promover também é uma regra
version: 1
---

O mesmo script, os mesmos critérios, com o 1.6.1 no green:

```
ana@laptop:~/shipquote$ ops/deploy.sh production-green dist/shipquote-1.6.1.tar.gz
smoke: http://127.0.0.1:8302 is up and running 1.6.1
ana@laptop:~/shipquote$ python3 ops/canary.py ~/envs/routes.json http://127.0.0.1:8300; echo "exit $?"
canary at   5%: green 0/21 = 0.0%, blue 0/379 = 0.0%
        21 answers is too few to judge; carrying on
canary at  25%: green 0/98 = 0.0%, blue 0/302 = 0.0%
canary at  50%: green 0/209 = 0.0%, blue 0/191 = 0.0%
canary at 100%: green 0/400 = 0.0%, blue 0/0 = 0.0%
promote: green takes all traffic
exit 0
ana@laptop:~/shipquote$ cat ~/envs/routes.json; echo
{"backends": {"blue": "http://127.0.0.1:8301", "green": "http://127.0.0.1:8302"}, "weights": {"blue": 0, "green": 100}}
```

Quatro passos, 728 requisições no green, nenhum erro, e os pesos terminam em 0 e 100: o green tem
todos os clientes. A saída 0 diz ao pipeline que ele pode continuar.

## O que "promover" deveria querer dizer

Um canário limpo é evidência de que o release novo **não é pior que o antigo, nas coisas que foram
medidas, para o tráfego que veio**. Não é evidência de que o release está correto. Daí vêm três
consequências:

- **O que não foi medido não foi verificado.** Este canário contou erros. Um release que respondesse
  toda requisição com 200 e um preço errado seria promovido do mesmo jeito. Se a métrica de negócio
  importa, ela entra nos critérios.
- **O blue não é jogado fora na promoção.** Ele fica, parado e pronto, até o green ter atendido o
  bastante para problemas lentos aparecerem: um vazamento, uma tarefa noturna, a primeira manhã de
  segunda-feira. Depois o próximo release vai para o blue, como a aula 10 descreveu.
- **Toda promoção é registrada**: que versão, quando, com que números passou. Quando algo aparece dois
  dias depois, a primeira pergunta é o que mudou, e o registro responde.

O mesmo raciocínio vale para o fim da liberação de uma feature flag: chegar a 100% é uma decisão com
critérios próprios, e a data de remoção da flag começa a contar dali.
