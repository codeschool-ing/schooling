---
title: O orçamento de erros
version: 2
---

Um objetivo de 99,5% diz algo que uma meta de *o mais confiável possível* nunca diz: **0,5% dos
checkouts podem falhar, e tudo bem.** Esse meio por cento é o **orçamento de erros** (error budget), e
tratá-lo como orçamento, algo a ser gasto, é a ideia que faz os SLOs mudarem o jeito de uma equipe
trabalhar.

Cinquenta e cinco minutos depois de os clientes começarem, a janela de uma hora do `slo.yml` está
cheia:

```
ana@obs:~/shop$ ./promq 'sum(increase(http_server_requests_total{job="storefront",route="/checkout"}[1h]))'
  14849.60561599319
```

Uns quinze mil checkouts na hora. A 99,5%, **setenta e quatro deles podem falhar** antes de o objetivo
ser descumprido. As séries gravadas dizem onde as coisas estão:

```
ana@obs:~/shop$ ./promq '{__name__=~"checkout:.*_1h|checkout:.*rate1h"}'
__name__=checkout:sli_availability:ratio_rate1h  1
__name__=checkout:sli_latency:ratio_rate1h  1
__name__=checkout:error_budget_remaining:ratio_1h  1
```

Todo checkout deu certo e foi respondido em até meio segundo, então o orçamento está intacto: 1, ele
inteiro. Em 28 dias no mesmo ritmo, o orçamento seria de uns cinquenta mil checkouts com falha, ou 3
horas e 22 minutos de tudo falhando.

**Para que serve o orçamento?** Para tudo que arrisca uma falha e vale a pena fazer mesmo assim:

- lançamentos, já que todo lançamento pode quebrar algo;
- migrações, experimentos, uma versão nova do banco, uma troca de região na nuvem;
- as falhas que ninguém escolheu: a queda de um fornecedor, um disco ruim, um bug do mês passado.

Ele transforma uma briga em aritmética. Quem constrói funcionalidades quer lançar; quem atende o
plantão quer estabilidade. Sem um orçamento cada lado argumenta pela experiência. **Com um, a
pergunta é se ainda há orçamento**, e a resposta é um número que os dois leem no mesmo painel.

O orçamento é medido em falhas, não em tempo, e isso importa de noite: uma queda às quatro da manhã,
com dez clientes comprando, gasta muito menos dele que a mesma queda na hora do almoço.
