---
title: A recusa também fica registrada
version: 1
---

O journal tem uma linha para cada comando da tec, o que rodou e o que foi recusado:

```
ana@pc1:~$ sudo journalctl _COMM=sudo --no-pager -o cat | grep "^ *tec :"
     tec : PWD=/home/ana ; USER=root ; COMMAND=/usr/bin/systemctl restart cups
     tec : command not allowed ; PWD=/home/ana ; USER=root ; COMMAND=/usr/sbin/useradd bruno
```

O `command not allowed` fica no mesmo journal que todo o resto, com a conta e o comando exato. Nos servidores
de muitas organizações essas linhas são coletadas e alguém as revisa, porque uma conta tentando comandos que
não pode é o jeito que uma conta roubada aparece.

Então **"só para ver se funciona" não é uma tentativa inofensiva**. Deixa uma linha sobre a qual alguém pode
ter que perguntar. Um técnico que quer saber o que uma conta pode fazer roda `sudo -l`, que responde sem
tentar nada.
