---
title: A impressora guarda uma cópia
version: 1
---

A Elisa imprimiu a carta mais cedo. O histórico da fila de impressão, o `lpstat` da aula 2, aparece assim para
a técnica:

```
ana@pc1:~$ lpstat -W completed -o
office-1                unknown           1024   Sat Sep 26 02:14:18 2026
ana@pc1:~$ sudo lpstat -W completed -o
office-1                elisa             1024   Sat Sep 26 02:14:18 2026
```

Sem `sudo`, o trabalho é de `unknown`: **o CUPS esconde de cada usuário quem imprimiu o quê**, a não ser que o
trabalho seja dele. É o padrão, a linha `JobPrivateValues default` em `/etc/cups/cupsd.conf`. Com `sudo`, o
nome aparece.

O histórico não é tudo o que o servidor de impressão guarda:

```
ana@pc1:~$ sudo ls -l /var/spool/cups
total 12
-rw------- 1 root lp 1107 Sep 26 02:14 c00001
-rw-r----- 1 root lp   14 Sep 26 02:14 d00001-001
drwxrwx--T 2 root lp 4096 Jun 11 11:49 tmp
ana@pc1:~$ sudo cmp /var/spool/cups/d00001-001 /home/elisa/letter-to-doctor.txt && echo identical
identical
```

O `d00001-001` é o próprio documento, guardado no spool depois que o trabalho terminou. Quanto tempo ele fica
é uma configuração do servidor de impressão. O `cmp` compara dois arquivos e não imprime nada quando são
iguais, então o `identical` diz que a cópia é a carta da Elisa, byte a byte, **e ninguém precisou lê-la para
descobrir**. Esse é o hábito que fica desta captura: quando o trabalho precisa saber se algo está lá,
descubra sem ler.

Uma impressora compartilhada de escritório costuma ser um servidor como este. Tudo o que o escritório imprime
passa por ele, e quem o administra alcança tudo.
