---
title: A camada do sistema
version: 1
---

A mensagem falou de espaço, então a primeira checagem do sistema é espaço:

```
ana@pc1:~$ df -h /srv/shared
Filesystem      Size  Used Avail Use% Mounted on
/dev/loop0       56M   55M     0 100% /srv/shared
ana@pc1:~$ sudo du -sh /srv/shared/*
55M     /srv/shared/logs
16K     /srv/shared/lost+found
4.0K    /srv/shared/reports
ana@pc1:~$ sudo tail -n 2 /srv/shared/logs/export.log; echo
2026-09-26 export: retrying connection to the sales database
2026-0
```

- O `df -h` responde pelo sistema de arquivos que guarda `/srv/shared`: **100% usado, 0
  disponível**. A mensagem era literal.
- O `du -sh` diz para onde o espaço foi: **`logs` ocupa 55M**, e o `reports` do Daniel quase nada.
- As últimas linhas do `export.log` mostram o que o escrevia: a mesma linha, um programa tentando de novo
  uma conexão com o banco de vendas, sem parar. A última linha para no meio, em `2026-0`: o programa foi
  cortado no meio da linha quando o disco encheu.

Essa é a causa: **um log que cresceu até o disco compartilhado encher**, e toda escrita depois disso
falhou, o relatório do Daniel inclusive. O relatório nunca foi o problema; foi a primeira coisa que alguém
notou.
