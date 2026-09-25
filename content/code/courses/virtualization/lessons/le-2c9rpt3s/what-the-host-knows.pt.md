---
title: O que o host sabe de um convidado
version: 1
---

O host sabe tudo sobre o hardware de um convidado, porque foi ele que inventou esse hardware. O `virsh
dominfo` é o resumo:

```
ana@host:~$ virsh dominfo vm1
Id:             3
Name:           vm1
UUID:           5a98d7b8-1dda-4933-a865-34b0d2c48c15
OS Type:        hvm
State:          running
CPU(s):         2
CPU time:       197.4s
Max memory:     1048576 KiB
Used memory:    1048576 KiB
Persistent:     yes
Autostart:      disable
Managed save:   no
Security model: none
Security DOI:   0
```

`State: running`, `CPU(s): 2` e `Max memory: 1048576 KiB`, exatamente o 1 GiB que ele recebeu. `CPU time:
197.4s` é quanto tempo de processador o convidado usou desde que ligou, a maior parte dando boot sob
imitação. O `UUID` é a identidade do convidado dentro do libvirt, e continua o mesmo por mais que o
convidado seja renomeado. `Persistent: yes` quer dizer que o libvirt guarda a descrição depois que o
convidado desliga; `Autostart: disable` quer dizer que ele não liga junto com o host.

Essa descrição é um arquivo XML, e o `virsh dumpxml` a imprime. Algumas das linhas dela:

```
ana@host:~$ virsh dumpxml vm1 | grep -E "<(memory|vcpu|type|emulator|source file|mac address|model type|target dev)"
  <memory unit='KiB'>1048576</memory>
  <vcpu placement='static'>2</vcpu>
    <type arch='x86_64' machine='pc-q35-noble'>hvm</type>
    <emulator>/usr/bin/qemu-system-x86_64</emulator>
      <source file='/var/lib/libvirt/images/vm1.qcow2' index='2'/>
        <source file='/var/lib/libvirt/images/lab-base.qcow2'/>
      <target dev='vda' bus='virtio'/>
      <mac address='52:54:00:ce:da:4e'/>
      <target dev='vnet2'/>
      <model type='virtio'/>
```

Tudo o que o convidado vai acreditar sobre o próprio hardware está escrito aqui. **`<memory>` e
`<vcpu>`** são o que o `free` e o `lscpu` informam lá dentro. **`<type ... machine='pc-q35-noble'>`** é o
modelo de placa-mãe que o QEMU imita. **`<emulator>`** é o programa que o roda. O disco é o
`vm1.qcow2`, com o `lab-base.qcow2` debaixo dele como arquivo de apoio, mostrado ao convidado como `vda`
num barramento `virtio`. E a placa de rede tem um endereço MAC, `52:54:00:ce:da:4e`, escolhido pelo libvirt quando
o convidado foi feito.

Para mudar o hardware de um convidado, você muda essa descrição, com `virsh edit` ou com uma
ferramenta gráfica, e o convidado vê a mudança da próxima vez que for desligado e ligado de novo. A aula 8 faz isso com memória e
processadores.
