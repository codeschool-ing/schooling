---
title: A secure score, e o que ela conta
version: 1
---

**A secure score é uma porcentagem, e ela conta recursos, não recomendações.** As recomendações são agrupadas em **controles
de segurança**, como *habilitar MFA*, *cifrar dados em trânsito* ou *restringir acesso de rede não autorizado*, e cada
controle tem um número máximo de pontos. Um controle ganha os pontos na proporção da fração dos seus recursos que está
saudável:

```
control score = max points × healthy resources ÷ (healthy + unhealthy resources)
secure score  = sum of control scores ÷ sum of max points × 100
```

Um exemplo calculado, escrito pelo curso: *restringir acesso de rede não autorizado* vale 4 pontos e se aplica aos 10
recursos da loja com superfície de rede, dos quais 6 estão saudáveis. Ele contribui com 4 × 6 ÷ 10 = 2,4 pontos. Consertar
mais um recurso soma 0,4.

Daí saem três consequências, e cada uma molda comportamento.

- **Crédito parcial conta.** Consertar três recursos de dez mexe na pontuação; um controle não precisa estar terminado para
  valer o trabalho.
- **Um controle com muitos recursos anda devagar.** Mais um recurso saudável em cinquenta vale um cinquenta avos do controle;
  um em dois vale metade. Uma equipe correndo atrás do número conserta primeiro os controles pequenos, o que não é o mesmo
  que consertar primeiro as coisas perigosas.
- **Isenções tiram um recurso da conta.** Uma recomendação que não se aplica, um recurso de teste ou um risco aceito de
  propósito podem ser isentados com um motivo e uma data de validade, e a pontuação para de contá-los. Uma isenção sem
  validade é um buraco que alguém vai esquecer.

Então a pontuação é uma boa linha de tendência e uma lista de tarefas ruim. Ela diz se a postura melhora mês a mês; não diz o
que consertar hoje à tarde. Isso é a próxima seção.
