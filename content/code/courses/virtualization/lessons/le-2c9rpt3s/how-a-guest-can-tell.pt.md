---
title: Como um convidado percebe
version: 1
---

Por dentro, um convidado não foi feito para perceber, mas o hardware dele tem nome de fabricante como
qualquer outro, e o fabricante é o hypervisor:

```
ana@vm1:~$ cat /sys/class/dmi/id/sys_vendor /sys/class/dmi/id/product_name
QEMU
Ubuntu 24.04 PC (Q35 + ICH9, 2009)
ana@vm1:~$ sudo dmesg | grep -m1 "DMI:"
[    0.000000] DMI: QEMU Ubuntu 24.04 PC (Q35 + ICH9, 2009), BIOS 1.16.3-debian-1.16.3-2 04/01/2014
```

O `/sys/class/dmi/id` guarda o que o firmware informa sobre a máquina: o fabricante é `QEMU` e o
produto é `Ubuntu 24.04 PC (Q35 + ICH9, 2009)`, a mesma placa-mãe `q35` que o XML pediu. O kernel
registrou a mesma coisa como primeira linha, com a versão do firmware que o QEMU fornece. Foi aqui que o
`systemd-detect-virt` achou a resposta dele na aula 1.

Num PC de verdade esses arquivos nomeiam Dell, Lenovo ou quem o montou, e um técnico de suporte os lê
para achar um número de modelo sem abrir o gabinete. Num convidado eles nomeiam VirtualBox, VMware,
Microsoft ou QEMU. **Software que se recusa a rodar em máquina virtual costuma olhar aqui**, e uma
checagem de licença que conta máquinas também.
