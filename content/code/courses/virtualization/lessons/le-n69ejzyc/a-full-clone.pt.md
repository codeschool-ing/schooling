---
title: Um clone completo
version: 1
---

Um **clone** é uma máquina virtual nova feita copiando uma existente. O `virt-clone` faz isso para o
libvirt, com a original desligada para o disco dela não estar mudando:

```
ana@host:~$ virsh shutdown vm1
Domain 'vm1' is being shutdown

ana@host:~$ sudo virt-clone --original vm1 --name vm2 --auto-clone
Allocating 'vm2.qcow2'                                      | 490 MB  00:00 ... 

Clone 'vm2' created successfully.
ana@host:~$ sudo ls -lsh /var/lib/libvirt/images/vm1.qcow2 /var/lib/libvirt/images/vm2.qcow2
 27M -rw-r--r-- 1 root root  27M Sep 25 20:50 /var/lib/libvirt/images/vm1.qcow2
804M -rw------- 1 root root 804M Sep 25 20:50 /var/lib/libvirt/images/vm2.qcow2
ana@host:~$ virsh domiflist vm1; virsh domiflist vm2
 Interface   Type      Source    Model    MAC
-------------------------------------------------------------
 -           network   default   virtio   52:54:00:bb:a6:55

 Interface   Type      Source    Model    MAC
-------------------------------------------------------------
 -           network   default   virtio   52:54:00:c9:25:bc

ana@host:~$ virsh start vm1 && virsh start vm2
Domain 'vm1' started

Domain 'vm2' started
```

O clone ganhou **um disco próprio**, e grande: o disco da vm1 era uma sobreposição de 27M, e o da vm2
tem 804M, porque um **clone completo** copia tudo o que o convidado consegue ler, inclusive a base por
baixo. Ele é independente: a original pode ser apagada e o clone nem percebe.

O `virt-clone` também mudou as duas coisas que são do hypervisor. A vm2 tem **um MAC novo**, `52:54:00:c9:25:bc` onde
a vm1 tem `52:54:00:bb:a6:55`, e um UUID novo no libvirt. Duas placas com um MAC numa rede brigariam por cada pacote,
então todo hypervisor muda o MAC ao clonar, a menos que mandem não mudar: o diálogo de clonagem do
VirtualBox chama isso de *política de endereço MAC*, e manter os MACs antigos só é certo para um clone
que nunca vai rodar ao lado da original.

As duas foram ligadas, e foi aí que deu errado.
