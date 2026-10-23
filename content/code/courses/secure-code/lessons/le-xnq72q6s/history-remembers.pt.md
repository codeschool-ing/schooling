---
title: O histórico lembra
version: 1
---

O código novo está limpo, e é tentador achar que o problema acabou. Faça commit da correção e olhe o
repositório:

```
(.venv) ana@vm:~/sc/secrets$ git add .gitignore app.py
(.venv) ana@vm:~/sc/secrets$ git commit -q -m "Read secrets from the environment"
(.venv) ana@vm:~/sc/secrets$ git log --oneline
0018102 Read secrets from the environment
5b3eb3e Send reminders by SMS
(.venv) ana@vm:~/sc/secrets$ git log -p -S sms_live_ --format='%h %s' -- app.py | grep -E '^[0-9a-f]{7} |sms_live_'
0018102 Read secrets from the environment
-SMS_API_KEY = "sms_live_4f9a1c7e2b8d6a3f"
5b3eb3e Send reminders by SMS
+SMS_API_KEY = "sms_live_4f9a1c7e2b8d6a3f"
```

O `git log -S` procura em todo commit um que tenha acrescentado ou removido uma string. A chave saiu
do código no último commit, e o commit anterior ainda a guarda, linha por linha. Qualquer um que
clonar o repositório, hoje ou daqui a cinco anos, a tem. **Tirar um segredo do código não o tira do
histórico.**

### A correção é a rotação

Depois que um segredo foi para um commit e para o repositório remoto, assuma que foi lido. A única
correção confiável é a **rotação**: emitir uma chave nova no provedor, levá-la pelo ambiente e revogar
a antiga, para que a cópia no histórico não abra nada. A ordem importa: leve a chave nova antes de
revogar a antiga, ou os lembretes param nos minutos entre uma coisa e outra.

Reescrever o histórico, com ferramentas como o `git filter-repo`, tira a string dos clones futuros do
repositório e vale a pena num repositório que a equipe controla. É um segundo passo, nunca o
primeiro: todo clone, fork, cache e log de CI feito antes da reescrita ainda tem o histórico antigo,
e uma reescrita não os alcança. A rotação alcança.

### O que tornou o vazamento possível

Duas coisas, as duas baratas de evitar. A chave foi digitada no código porque não havia outro lugar
para pô-la naquele dia; uma função `required()` e um arquivo `.env` desde o primeiro commit tiram esse
motivo. E nada olhou o commit antes de ele ser feito; o scanner da segunda seção desta aula, no hook
da aula 19, o teria recusado.
