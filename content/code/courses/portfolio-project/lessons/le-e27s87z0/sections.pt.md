---
title: As seções, em ordem
version: 1
---

Abaixo da primeira tela, um README é referência, lida pelos poucos que vão além. O do loanbook tem seis
seções:

```
ana@laptop:~/loanbook$ grep -n '^## ' README.md
10:## What it does
17:## Run it
31:## Deploy
45:## Decisions
60:## Not yet
65:## Licence
```

| seção | a pergunta que responde | quem precisa |
|---|---|---|
| What it does | o que eu consigo fazer com isto? | quem contrata |
| Run it | como vejo isto na minha máquina? | a entrevista técnica |
| Deploy | como isto roda num servidor? | quem avalia e se importa com como roda, e você daqui a seis meses |
| Decisions | por que é construído assim? | todo mundo que lê até aqui |
| Not yet | o que você deixou de fora, de propósito? | quem avalia e está para perguntar |
| Licence | posso usar? | aula 18 |

A ordem segue os leitores da aula 1: **o quê** antes de **como**, e **como rodar** antes de **como
funciona**. Quem para depois de *What it does* ainda aprendeu o escopo do projeto; quem para depois de *Run
it* ainda consegue experimentar.

Mantenha cada seção no que a pergunta dela pede. *Run it* são quatro comandos, não um tutorial de como
instalar Python. *Deploy* cita os dois arquivos em `deploy/` e os cinco comandos, não um guia de systemd. Um
README é um mapa, e o detalhe pertence aos arquivos para onde ele aponta, onde é mantido em dia com o
código.
