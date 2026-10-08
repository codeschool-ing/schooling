---
title: Instalando o QEMU e o libvirt
version: 1
---

Primeiro, se o processador pode ajudar. O `kvm-ok`, do pacote `cpu-checker`, procura o VT-x ou o AMD-V e o
módulo KVM do kernel, e diz numa linha se os convidados vão rodar no processador de verdade:

```bash
sudo apt install cpu-checker
```

```
ana@host:~$ sudo kvm-ok
INFO: Your CPU does not support KVM extensions
KVM acceleration can NOT be used
```

No computador em que este curso foi gravado a resposta é **não**, e a seção 11 diz o que isso significa e
o que tentar. No seu computador, instalado como o primeiro caminho da seção 02 descreve, ela deve dizer
`KVM acceleration can be used`. De qualquer jeito o laboratório funciona; um não só o deixa mais lento.

Depois os programas, todos dos pacotes do próprio Ubuntu, numa linha:

```bash
sudo apt install qemu-system-x86 qemu-utils libvirt-daemon-system virtinst cloud-image-utils libguestfs-tools isc-dhcp-client
```

O `qemu-system-x86` é o hypervisor e o `qemu-utils` a ferramenta de discos dele, o `qemu-img`. O
`libvirt-daemon-system` é o libvirt, com o `virsh` para comandá-lo e uma rede pronta chamada `default`. O
`virtinst` traz o `virt-install`, que cria convidados. O `cloud-image-utils` faz o disco pequeno que diz a
um convidado novo o nome dele, seção 05, e o `libguestfs-tools` muda uma imagem de disco sem ligá-la,
seção 04. O `isc-dhcp-client` está ali só por causa do `libguestfs-tools`, que precisa dele no Ubuntu
24.04 e não avisa; a seção 11 mostra o que acontece sem ele. O apt lista algumas centenas de pacotes e
pergunta antes de instalá-los.

A instalação também põe você num grupo chamado **libvirt**, e é isso que deixa você rodar o `virsh` sem
`sudo`. Um grupo só conta a partir do próximo login, então logo depois da instalação, no mesmo terminal:

```
ana@host:~$ groups; virsh uri; virsh list --all
ana sudo
qemu:///session

 Id   Name   State
--------------------
```

Saia e entre de novo, ou reinicie o computador, e pergunte outra vez:

```
ana@host:~$ groups; virsh uri
ana sudo libvirt
qemu:///system

ana@host:~$ virsh net-list --all
 Name      State    Autostart   Persistent
--------------------------------------------
 default   active   yes         yes
```

O `groups` agora lista `libvirt`, e o `virsh uri` responde **`qemu:///system`**, os convidados que o
computador inteiro compartilha. Antes, ele respondia `qemu:///session`: um conjunto particular de
convidados só do seu usuário, onde o `virsh list` não mostra nada e nada reclama, enquanto todo convidado
feito com `sudo` vive no outro. A rede `default` está **ativa** e sobe com o computador, e o primeiro
convidado vai ser ligado nela.
