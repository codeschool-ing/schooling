---
title: Por dentro
version: 1
---

A ana entra no convidado com `ssh vm1`, como entraria em qualquer servidor da rede, e pergunta a ele o
que ele é:

```
ana@vm1:~$ hostname; systemd-detect-virt
vm1
qemu
ana@vm1:~$ lscpu | grep -E "^(CPU\(s\)|Model name|Hypervisor vendor|Virtualization type)"
CPU(s):                                  2
Model name:                              QEMU Virtual CPU version 2.5+
ana@vm1:~$ free -h | head -2
               total        used        free      shared  buff/cache   available
Mem:           961Mi       231Mi       673Mi       772Ki       203Mi       729Mi
ana@vm1:~$ lsblk -d -o NAME,SIZE,TYPE
NAME  SIZE TYPE
vda     8G disk
vdb   128K disk
ana@vm1:~$ ip -br addr
lo               UNKNOWN        127.0.0.1/8 ::1/128 
enp1s0           UP             192.168.122.165/24 metric 100 fe80::5054:ff:fec7:f76e/64 
```

Para si mesma, a `vm1` é um computador. Tem um nome, `vm1`. Tem **2 processadores**, as duas `--vcpus`,
de modelo `QEMU Virtual CPU version 2.5+`, um processador que só existe no QEMU. Tem **961Mi de
memória**: o 1 GiB que recebeu, menos o que o kernel guarda para si antes de o `free` contar. Tem um
**disco de 8G** chamado `vda`, o arquivo de sobreposição, e um pequeno `vdb`, o disco de semente. Tem
uma placa de rede, `enp1s0`, com o endereço `192.168.122.165`.

Nada nessa lista diz "virtual", fora os nomes, e um convidado não foi feito para conseguir perceber. A
única linha que diz é a do `systemd-detect-virt`, que respondeu `qemu`: ele procura pistas que um
hypervisor deixa, como o nome do fabricante nas tabelas do firmware. O `grep` também pediu `Hypervisor
vendor` e `Virtualization type`, e o `lscpu` não imprimiu nenhum dos dois: eles precisam do nome de
um hypervisor, e o processador em software do QEMU não dá nenhum. A aula 2 mostra um processador sob
KVM que dá.

**Tudo o que você já sabe fazer numa máquina Linux funciona aqui sem mudança**: usuários, pacotes,
serviços, logs, a rede. Um convidado é um lugar para fazer essas coisas onde um erro
não custa nada.
