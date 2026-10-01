---
title: Um backup que falhou tem que dizer isso
version: 1
---

Para a execução seguinte, o servidor SSH do edge2 foi parado, do jeito que um roteador para de
responder depois de um crash, de uma ACL errada ou de uma chave trocada:

```
ana@ctl:~$ cd net && python backup.py; echo "exit status $?"
edge2: FAILED, kept the previous copy: TCP connection to device failed.
no change since the last backup
exit status 1
```

Leia a segunda linha. **`no change since the last backup` é verdade**, e é exatamente essa a
armadilha: o repositório ainda tem um `edge2.conf`, da última noite em que ele respondeu, e o
histórico de commits parece o mesmo de uma noite tranquila. Sem a primeira linha, um job de backup
que não alcança o edge2 há um mês parece idêntico a um que o alcançou ontem à noite.

Então a falha é relatada duas vezes. A linha nomeia o roteador e o motivo, e **o status de saída é
1**, que é aquilo sobre o que um agendador, um pipeline ou uma checagem de monitoramento consegue
agir sem ler a saída. Um job que imprimisse a falha e saísse com 0 deixaria isso para alguém lendo
o log toda manhã, ou seja, para ninguém.

Os outros dois roteadores tiveram backup mesmo assim; o Nornir roda cada host independentemente
dos outros, como a aula 8 mostrou. O servidor SSH do edge2 foi iniciado de novo depois desta
execução.
