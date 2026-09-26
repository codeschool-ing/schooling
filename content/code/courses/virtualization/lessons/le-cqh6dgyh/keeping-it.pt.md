---
title: Quanto o laboratório custa, e como mantê-lo
version: 1
---

Três convidados ligados ao mesmo tempo, e quanto o host paga por eles:

```
ana@host:~$ virsh list --all; free -h | head -2
 Id   Name     State
------------------------
 1    client   running
 2    server   running
 4    target   running

               total        used        free      shared  buff/cache   available
Mem:            15Gi       4.3Gi       9.7Gi        13Mi       1.9Gi        11Gi
ana@host:~$ ps -o rss= -C qemu-system-x86_64 | awk "{ s += \$1 } END { print s, \"KiB for\", NR, \"guests\" }"
3933004 KiB for 3 guests
ana@host:~$ for m in client server target; do virsh shutdown $m; done
Domain 'client' is being shutdown

Domain 'server' is being shutdown

Domain 'target' is being shutdown

ana@host:~$ virsh list --all; virsh snapshot-list target
 Id   Name     State
-------------------------
 -    client   shut off
 -    server   shut off
 -    target   shut off

 Name     Creation Time               State
-----------------------------------------------
 broken   2026-09-25 22:46:28 -0300   running
```

**3933004 KiB para três convidados**, cerca de 3,8 GiB, num host com 15Gi. Neste computador, a maior parte
do custo de cada convidado é o processador imitado, aula 8; com KVM, três convidados pequenos custam bem
menos. De qualquer jeito vale a regra da aula 1: desligue o que você não está usando. Os três foram
desligados, e os snapshots sobrevivem ao desligamento, então a próxima prática começa do `broken` quando
vier.

Dois hábitos mantêm um laboratório útil por muito tempo:

- **Guarde a receita, não só as máquinas.** Tudo nesta aula são alguns comandos e, anotados num script,
  eles refazem o laboratório em minutos em qualquer computador. O próprio laboratório deste curso é
  exatamente isso, o `lab.sh`.
- **Um laboratório por finalidade.** Um laboratório que também é o servidor de teste de alguém acumula
  mudanças de que ninguém lembra, e no dia em que for revertido, o trabalho de alguém vai junto.
