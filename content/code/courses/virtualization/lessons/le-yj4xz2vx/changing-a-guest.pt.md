---
title: Mudando um convidado
version: 1
---

A maior parte do hardware de um convidado é fixa enquanto ele roda, e é mudada na descrição para a
próxima partida. Aqui a vm1 desce para uma vCPU e recebe a configuração de disco da seção 06:

```
ana@host:~$ virsh setvcpus vm1 1 --config && virsh vcpucount vm1

maximum      config         2
maximum      live           2
current      config         1
current      live           2

ana@host:~$ virt-xml vm1 --edit target=vda --disk driver.discard=unmap
Domain 'vm1' defined successfully.
Changes will take effect after the domain is fully powered off.
ana@host:~$ virsh shutdown vm1
Domain 'vm1' is being shutdown

ana@host:~$ virsh start vm1
Domain 'vm1' started

ana@vm1:~$ nproc
1
```

O `--config` mudou a descrição e deixou o convidado ligado como estava, e é por isso que o `vcpucount`
mostra `current config 1` ao lado de `current live 2`. O `virt-xml` editou o disco e disse com todas as
letras: **Changes will take effect after the domain is fully powered off**. *Fully*: um reboot de dentro
do convidado mantém o mesmo processo do QEMU rodando, e é o processo que guarda o hardware antigo.
Depois de desligar e ligar de verdade, o `nproc` lá dentro diz 1.

A mesma regra vale em todo hypervisor, com outras palavras. O VirtualBox deixa cinza a maioria das
configurações enquanto a máquina roda. O VMware e o Proxmox aceitam algumas mudanças com a máquina
ligada, como acrescentar memória ou processadores a um convidado que suporte isso, e marcam o resto como
pendente até o próximo *desligar*. Quando um cliente diz "mudei e não aconteceu nada", a primeira pergunta
é se a máquina foi **desligada e ligada**, e não reiniciada.
