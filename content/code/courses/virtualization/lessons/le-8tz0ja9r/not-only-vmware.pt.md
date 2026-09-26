---
title: Não só do VMware
version: 1
---

Um VMDK é só um disco, e qualquer hypervisor que leia o formato consegue dar boot nele. Aqui o QEMU liga
um convidado cujo disco é um VMDK, com o mesmo `virt-install` da aula 1 e `format=vmdk`:

```
ana@host:~$ cd /var/lib/libvirt/images && sudo qemu-img convert -O vmdk lab-base.qcow2 vmw1.vmdk
ana@host:~$ sudo virt-install --name vmw1 --virt-type qemu --memory 1024 --vcpus 2 --import --disk /var/lib/libvirt/images/vmw1.vmdk,format=vmdk,bus=virtio --disk /var/lib/libvirt/images/vmw1-seed.img,bus=virtio,format=raw --os-variant ubuntu24.04 --network network=default --graphics none --noautoconsole
WARNING  Requested memory 1024 MiB is less than the recommended 3072 MiB for OS ubuntu24.04

Starting install...
Creating domain...                                          |    0 B  00:00     
Domain creation completed.
ana@vmw1:~$ hostname; lsblk -d -o NAME,SIZE,TYPE /dev/vda
vmw1
NAME  SIZE TYPE
vda   3.5G disk
ana@host:~$ virsh domblklist vmw1
 Target   Source
-------------------------------------------------
 vda      /var/lib/libvirt/images/vmw1.vmdk
 vdb      /var/lib/libvirt/images/vmw1-seed.img
```

A `vmw1` deu boot, respondeu ao ssh e vê um disco comum de 3.5G. O `virsh domblklist` mostra que o
arquivo é o `.vmdk`. O convidado não sabe, e não se importa, em que formato o hypervisor guarda o disco
dele.

É isso que torna o formato útil para um técnico. **Um disco de uma instalação VMware morta pode ser
aberto pelo VirtualBox ou pelo QEMU**, e uma máquina que precisa mudar de hypervisor pode ir só como o
disco, se nada mais sobreviver. O que não vem junto é o `.vmx`: as configurações precisam ser refeitas do
outro lado, e o convidado pode precisar dos drivers para o hardware virtual novo.
