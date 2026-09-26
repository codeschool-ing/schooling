---
title: O mesmo motor
version: 1
---

Seja quem for que o gerencie, um convidado QEMU acaba sendo uma linha de comando comprida: o libvirt
escreve uma para o `virsh`, e o Proxmox escreve uma para o `qm`. Eis a do laboratório, para a vm1, com as
opções que descrevem o hardware separadas, uma por linha:

```
ana@host:~$ tr "\0" "\n" < /proc/$(pgrep -o qemu-system)/cmdline | awk "/^-(name|machine|accel|m|smp|blockdev|netdev|device)\$/ { o = \$0; getline; if (\$0 !~ /pcie-root-port/) print o, \$0 }"
-name guest=vm1,debug-threads=on
-machine pc-q35-noble,usb=off,dump-guest-core=off,memory-backend=pc.ram,hpet=off,acpi=on
-accel tcg
-m size=1048576k
-smp 2,sockets=2,cores=1,threads=1
-device {"driver":"qemu-xhci","p2":15,"p3":15,"id":"usb","bus":"pci.2","addr":"0x0"}
-device {"driver":"virtio-serial-pci","id":"virtio-serial0","bus":"pci.3","addr":"0x0"}
-blockdev {"driver":"file","filename":"/var/lib/libvirt/images/lab-base.qcow2","node-name":"libvirt-3-storage","auto-read-only":true,"discard":"unmap"}
-blockdev {"node-name":"libvirt-3-format","read-only":true,"driver":"qcow2","file":"libvirt-3-storage","backing":null}
-blockdev {"driver":"file","filename":"/var/lib/libvirt/images/vm1.qcow2","node-name":"libvirt-2-storage","auto-read-only":true,"discard":"unmap"}
-blockdev {"node-name":"libvirt-2-format","read-only":false,"driver":"qcow2","file":"libvirt-2-storage","backing":"libvirt-3-format"}
-device {"driver":"virtio-blk-pci","bus":"pci.4","addr":"0x0","drive":"libvirt-2-format","id":"virtio-disk0","bootindex":1}
-blockdev {"driver":"file","filename":"/var/lib/libvirt/images/vm1-seed.img","node-name":"libvirt-1-storage","auto-read-only":true,"discard":"unmap"}
-blockdev {"node-name":"libvirt-1-format","read-only":false,"driver":"raw","file":"libvirt-1-storage"}
-device {"driver":"virtio-blk-pci","bus":"pci.5","addr":"0x0","drive":"libvirt-1-format","id":"virtio-disk1"}
-netdev {"type":"tap","fd":"31","id":"hostnet0"}
-device {"driver":"virtio-net-pci","netdev":"hostnet0","id":"net0","mac":"52:54:00:17:24:6d","bus":"pci.1","addr":"0x0"}
-device {"driver":"isa-serial","chardev":"charserial0","id":"serial0","index":0}
-device {"driver":"virtserialport","bus":"virtio-serial0.0","nr":1,"chardev":"charchannel0","id":"channel0","name":"org.qemu.guest_agent.0"}
-device {"driver":"virtio-balloon-pci","id":"balloon0","bus":"pci.6","addr":"0x0"}
-device {"driver":"virtio-rng-pci","rng":"objrng0","id":"rng0","bus":"pci.7","addr":"0x0"}
```

Lida de cima para baixo, é o XML da aula 3 nas palavras do próprio QEMU. **`-accel tcg`** é o processador
em software da aula 2; num servidor Proxmox diz `kvm`. **`-m size=1048576k`** e **`-smp 2`** são a
memória e os processadores. As linhas **`-blockdev`** vêm em pares, um arquivo e um formato, e o segundo
par nomeia o primeiro como `backing`: é a sobreposição sobre o disco base da aula 1. A placa
`virtio-net-pci` tem o MAC `52:54:00:17:24:6d`, a `virtserialport` chamada `org.qemu.guest_agent.0` é o canal do
agente da aula 3, e o dispositivo `virtio-balloon-pci` volta na aula 8.

Num servidor Proxmox, `qm showcmd 100 --pretty` imprime o mesmo tipo de linha para a máquina 100. Você
raramente vai precisar, mas quando uma máquina não liga e a interface web só diz que a partida falhou,
**a linha de comando e o erro que o QEMU imprimiu são os fatos**, e todo gerenciador consegue mostrar os
dois.
