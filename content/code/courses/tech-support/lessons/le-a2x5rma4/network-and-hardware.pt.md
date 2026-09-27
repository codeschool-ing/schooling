---
title: Descartando a rede e o hardware
version: 1
---

Uma causa foi achada, e duas camadas não foram olhadas. Dois comandos as fecham:

```
ana@pc1:~$ findmnt -o TARGET,SOURCE,FSTYPE /srv/shared
TARGET      SOURCE     FSTYPE
/srv/shared /dev/loop0 ext4
ana@pc1:~$ sudo dmesg --level=err,crit,alert,emerg | wc -l
0
```

- **Rede**: o `findmnt` diz de onde vem `/srv/shared`. A origem é um dispositivo local, não um servidor na
  rede, então nada neste caminho atravessa um cabo. Se ele dissesse `nfs` ou `cifs`, a pasta moraria em
  outra máquina, e um disco cheio seria problema *daquela* máquina para relatar.
- **Hardware**: o `dmesg` guarda as mensagens do kernel, e pedindo só erros e piores ele devolve **0**
  linhas. Um disco falhando costuma reclamar ali primeiro, em palavras como `I/O error`.

Checar as camadas que estão bem não é trabalho perdido. É o que deixa o chamado dizer *o disco está
cheio* em vez de *o disco está cheio, provavelmente*, e é o que o próximo técnico vai querer ver antes de
confiar.
