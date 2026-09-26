---
title: Tirando um
version: 1
---

Dentro da vm1 há um arquivo que vale guardar. Depois, um snapshot, pelo host:

```
ana@vm1:~$ echo "checked, all fine" > notes.txt; cat notes.txt
checked, all fine
ana@host:~$ virsh snapshot-create-as vm1 clean --description "before the change"
Domain snapshot clean created
ana@host:~$ virsh snapshot-list vm1
 Name    Creation Time               State
----------------------------------------------
 clean   2026-09-25 20:26:55 -0300   running

ana@host:~$ sudo qemu-img info -U /var/lib/libvirt/images/vm1.qcow2 | sed -n "/^Snapshot list/,/^Format/p" | head -3
Snapshot list:
ID        TAG               VM SIZE                DATE     VM CLOCK     ICOUNT
1         clean             426 MiB 2026-09-25 20:26:55 00:01:57.460           
ana@host:~$ ls -lsh /var/lib/libvirt/images/vm1.qcow2
453M -rw-r--r-- 1 libvirt-qemu kvm 453M Sep 25 20:26 /var/lib/libvirt/images/vm1.qcow2
```

O `snapshot-create-as` tirou um snapshot chamado `clean` de um convidado **ligado**, e o `snapshot-list`
mostra o estado dele como `running`. Ele guarda o disco como estava e a **memória** como estava também,
então voltar a ele põe o convidado de volta no meio do que fazia, programas abertos, em vez de desligado.
O `qemu-img info` mostra para onde ele foi: dentro do próprio `vm1.qcow2`, com um `VM SIZE` de 426 MiB, a
memória salva. O arquivo cresceu para 453M.

Um snapshot de um convidado desligado guarda só o disco, e é menor e mais rápido. Os dois se chamam
snapshot em todo lugar: o *Tirar* do VirtualBox, o *Snapshot Manager* do VMware, o `qm snapshot` do
Proxmox. O Hyper-V os chama de *checkpoints*, aula 7.

**Dê a ele um nome que diga por que existe**, e uma descrição se o nome não conseguir. Daqui a um mês,
`clean` não quer dizer nada e `antes-driver-impressora-3.2` ainda quer.
