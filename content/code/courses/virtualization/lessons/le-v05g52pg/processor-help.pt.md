---
title: Quando o processador ajuda
version: 1
---

O sistema operacional de um convidado espera mandar no processador. Ele quer trocar mapas de memória,
tratar interrupções e falar com dispositivos, e um convidado não pode fazer nada disso de verdade, ou
mandaria no host. Sem ajuda, um hypervisor precisa pegar ou traduzir cada instrução dessas em
software. O **VT-x** nos processadores Intel e o **AMD-V** nos AMD acrescentam um modo feito para
convidados: o processador roda as instruções do convidado diretamente e só para naquelas que o
hypervisor precisa ver. O Linux os mostra como as flags **`vmx`** e **`svm`** no `/proc/cpuinfo`.

Eis o que o host do curso tem:

```
ana@host:~$ lscpu | grep -E "^(Vendor ID|Model name|Virtualization|Hypervisor)"
Vendor ID:                               GenuineIntel
Model name:                              Intel(R) Xeon(R) Processor @ 2.10GHz
Hypervisor vendor:                       KVM
Virtualization type:                     full
ana@host:~$ grep -m1 "^flags" /proc/cpuinfo | grep -owE "vmx|svm|hypervisor"
hypervisor
ana@host:~$ systemd-detect-virt --vm
kvm
```

A primeira linha de flags tem `hypervisor` e nem `vmx` nem `svm`. A **flag `hypervisor` quer dizer que
este processador é, ele mesmo, de um convidado**, e o `lscpu` nomeia quem o roda, `KVM`, assim como o
`systemd-detect-virt --vm`. O computador em que este curso foi gravado é uma máquina virtual num data
center, e quem cuida desse data center não repassa o VT-x aos convidados.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Onde este curso foi gravado, em camadas. Embaixo, o hardware de um data center, cujo processador tem VT-x. Sobre ele, o KVM, o hypervisor que roda o host, e o processador ajuda nessa camada. Sobre o KVM, o próprio host, com Ubuntu, que é um convidado. Sobre o host, o QEMU, imitando um processador em software, porque nenhuma flag vmx chegou ao host, então o processador não ajuda nessa camada. Sobre o QEMU, a vm1.\"><defs><marker id=\"ns-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"14\" width=\"400\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"37\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">vm1</text><rect x=\"20\" y=\"60\" width=\"400\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"83\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">QEMU, imitando um processador em software</text><rect x=\"20\" y=\"106\" width=\"400\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"129\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">host: Ubuntu, ele mesmo um convidado</text><rect x=\"20\" y=\"152\" width=\"400\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"175\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">KVM, o hypervisor que roda o host</text><rect x=\"20\" y=\"198\" width=\"400\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"221\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o hardware de um data center, com VT-x</text><path d=\"M440 170 L470 170\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"480\" y=\"174\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">o processador ajuda aqui</text><path d=\"M440 78 L470 78\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"480\" y=\"82\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">e não aqui: nenhum vmx chegou ao host</text></svg>", "caption": "O host do curso é convidado do KVM de outra pessoa, e a ajuda do processador para nessa camada. Então os convidados do próprio host rodam num processador que o QEMU imita, e é isso que o resto desta aula mede."}
```

Então o KVM não funciona no host, e cada camada diz isso com as próprias palavras:

```
ana@host:~$ ls -l /dev/kvm
crw-rw-r-- 1 root kvm 10, 232 Sep 25 18:00 /dev/kvm
ana@host:~$ sudo qemu-system-x86_64 -accel kvm -machine none -display none
Could not access KVM kernel module: No such device
qemu-system-x86_64: -accel kvm: failed to initialize kvm: No such device
ana@host:~$ virsh domcapabilities --virttype kvm
error: failed to get emulator capabilities
error: invalid argument: the accel 'kvm' is not supported by '/usr/bin/qemu-system-x86_64' on this host

ana@host:~$ virsh capabilities | grep "domain type"
      <domain type='qemu'/>
      <domain type='qemu'/>
```

O `/dev/kvm` está lá, mas o kernel por trás dele não tem nada a oferecer, `No such device`. O `virsh
domcapabilities` para `kvm` é recusado, e as capacidades que o libvirt lista oferecem só `domain
type='qemu'`, uma vez para convidados de 32 bits e uma para os de 64. É por isso que todo convidado deste curso
é feito com `--virt-type qemu`.
