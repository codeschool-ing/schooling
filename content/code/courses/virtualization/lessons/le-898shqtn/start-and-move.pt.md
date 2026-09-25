---
title: Ligando, e levando para outro lugar
version: 1
---

No seu computador, **Iniciar** abre o convidado numa janela, e `VBoxManage startvm lab1 --type headless`
o liga sem janela nenhuma, para convidados que você alcança pela rede. Neste:

```
ana@host:~$ VBoxManage startvm lab1 --type headless
VBoxManage: error: The virtual machine 'lab1' has terminated unexpectedly during startup with exit code 1 (0x1)
VBoxManage: error: Details: code NS_ERROR_FAILURE (0x80004005), component MachineWrap, interface IMachine
Waiting for VM "lab1" to power on...
```

`terminated unexpectedly during startup` é o driver que falta, da seção 02, e é a mensagem que um
cliente lê ao telefone quando falta no dele. A descrição da máquina está certa; é o host que não
consegue rodá-la.

O que não precisa do driver é mover máquinas entre hypervisors. O VirtualBox lê os discos de outros
hypervisors, e o disco base do QEMU do laboratório vira um do VirtualBox com um comando:

```
ana@host:~$ cd ~/"VirtualBox VMs"/lab1 && VBoxManage clonemedium /var/lib/libvirt/images/lab-base.qcow2 ubuntu.vdi --format VDI
0%...10%...20%...30%...40%...50%...60%...70%...80%...90%...100%
Clone medium created in format 'VDI'. UUID: 424c8fb9-e47d-4b5f-9f6d-7f0276cd0400
ana@host:~$ ls -lh /var/lib/libvirt/images/lab-base.qcow2 ~/"VirtualBox VMs"/lab1/ubuntu.vdi
-rw------- 1 ana          ana 860M Sep 25 19:15 /home/ana/VirtualBox VMs/lab1/ubuntu.vdi
-rw-r--r-- 1 libvirt-qemu kvm 318M Sep 25 18:28 /var/lib/libvirt/images/lab-base.qcow2
```

A cópia tem 860M contra os 318M da base, porque a imagem de nuvem do Ubuntu guarda os blocos
comprimidos e um VDI não. O conteúdo é o mesmo Ubuntu. E uma máquina inteira, descrição e disco, é
exportada como um **OVA**:

```
ana@host:~$ VBoxManage export lab1 -o ~/lab1.ova
0%...10%...20%...30%...40%...50%...60%...70%...80%...90%...100%
Successfully exported 1 machine(s).
ana@host:~$ tar tvf ~/lab1.ova
-rw-r----- vboxovf10/vbox_v7.0.16r162802 6160 2026-09-25 19:15 lab1.ovf
-rw-rw---- vboxovf10/vbox_v7.0.16r162802 70144 2026-09-25 19:15 lab1-disk001.vmdk
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 170\" role=\"img\" aria-label=\"Como uma máquina se move entre hypervisors. À esquerda, o QEMU e o libvirt guardam discos em qcow2. O VBoxManage clonemedium copia um para o formato do próprio VirtualBox, o VDI. O VBoxManage export então empacota a máquina como um OVA: uma descrição em OVF e o disco dela em VMDK, que qualquer hypervisor que importe OVF consegue ler, o VMware entre eles, na aula 5.\"><defs><marker id=\"fm-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"40\" width=\"150\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">QEMU e libvirt</text><text x=\"32\" y=\"84\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">lab-base.qcow2</text><rect x=\"270\" y=\"40\" width=\"150\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"282\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">VirtualBox</text><text x=\"282\" y=\"84\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">ubuntu.vdi</text><rect x=\"520\" y=\"30\" width=\"180\" height=\"80\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"532\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">lab1.ova</text><text x=\"532\" y=\"72\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">lab1.ovf</text><text x=\"532\" y=\"90\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">lab1-disk001.vmdk</text><path d=\"M172 70 L268 70\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#fm-ah)\"></path><text x=\"220\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">VBoxManage clonemedium</text><path d=\"M422 70 L518 70\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#fm-ah)\"></path><text x=\"470\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">VBoxManage export</text><text x=\"610\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">qualquer hypervisor que importe OVF</text><text x=\"610\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">importar, aula 5</text></svg>", "caption": "Cada hypervisor guarda discos num formato próprio, e cada um lê os dos outros. O OVF é o feito para carregar uma máquina inteira, descrição e discos, de um para outro.", "same": ["VirtualBox"]}
```

Um OVA é um arquivo `tar` com um **OVF**, uma descrição da máquina que outros hypervisors conseguem ler,
e o disco como **VMDK**, o formato do VMware. É assim que appliances são distribuídos, e é como uma
máquina feita no VirtualBox chega ao VMware, que é a próxima aula. *Arquivo* → *Importar Appliance* faz
o contrário.
