---
title: Um computador num arquivo
version: 2
---

Uma **máquina virtual**, ou VM, é um computador feito de software, rodando num computador de verdade.
O de verdade é o **host** (hospedeiro) e a VM é um **convidado**. O programa que faz o convidado
acreditar que tem hardware é o **hypervisor**. Durante todo este curso o host é um computador chamado
`host`, com Ubuntu, e o hypervisor é o **QEMU**, comandado por uma camada de gerenciamento chamada
**libvirt**. As aulas 4 e 5 fazem as mesmas coisas com o VirtualBox e o VMware, que são o que a maioria
das pessoas instala no Windows e no Mac.

Um computador novo precisa de um disco antes de tudo. Este é um arquivo:

```
ana@host:~$ cd /var/lib/libvirt/images && sudo qemu-img create -f qcow2 -b lab-base.qcow2 -F qcow2 vm1.qcow2 8G
Formatting 'vm1.qcow2', fmt=qcow2 cluster_size=65536 extended_l2=off compression_type=zlib size=8589934592 backing_file=lab-base.qcow2 backing_fmt=qcow2 lazy_refcounts=off refcount_bits=16
```

O `qemu-img` fez um disco de 8 GiB, `size=8589934592` bytes, no formato **qcow2**, o formato do próprio
QEMU. São 8 GiB até onde o convidado sabe, e quase nada no host, porque um arquivo qcow2 só cresce
quando algo é escrito nele. A parte `-b lab-base.qcow2` o torna uma **sobreposição** (overlay): ele
começa como cópia do disco base da seção 04, que já tem o Ubuntu instalado, sem copiar nada.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Um disco feito de dois arquivos. A vm1 vê um disco só, o vda, de 8G. Por baixo dele, o vm1.qcow2, com 23M até agora, guarda só as mudanças da própria vm1, e aponta para o lab-base.qcow2, de 620M, a base, que é compartilhada e nunca escrita. Um bloco que a vm1 nunca mudou é lido da base.\"><defs><marker id=\"ov-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"680\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"36\" y=\"47\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">o único disco que a vm1 vê: vda, 8G</text><rect x=\"20\" y=\"92\" width=\"330\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"36\" y=\"114\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\" xml:space=\"preserve\">vm1.qcow2   23M</text><text x=\"36\" y=\"134\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">as mudanças da própria vm1, e só elas</text><rect x=\"20\" y=\"166\" width=\"680\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"36\" y=\"188\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\" xml:space=\"preserve\">lab-base.qcow2   620M</text><text x=\"36\" y=\"208\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a base, compartilhada e nunca escrita</text><path d=\"M185 66 L185 90\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ov-ah)\"></path><path d=\"M185 150 L185 164\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ov-ah)\"></path><path d=\"M530 164 L530 66\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ov-ah)\" stroke-dasharray=\"4 4\"></path><text x=\"380\" y=\"118\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">um bloco que a vm1 nunca mudou é lido da base</text></svg>", "caption": "O disco novo é uma lista de diferenças em relação à base. Começa quase vazio e só cresce conforme o convidado escreve, e é por isso que tinha 23M quando o convidado já tinha dado boot."}
```

Depois, a máquina em si. O `virt-install` a descreve para o libvirt, quanta memória, quantos
processadores, quais discos e qual rede, e a liga:

```
ana@host:~$ sudo virt-install --name vm1 --memory 1024 --vcpus 2 --import --disk /var/lib/libvirt/images/vm1.qcow2,bus=virtio --disk /var/lib/libvirt/images/vm1-seed.img,bus=virtio,format=raw --os-variant ubuntu24.04 --network network=default --graphics none --noautoconsole
WARNING  KVM acceleration not available, using 'qemu'
WARNING  Requested memory 1024 MiB is less than the recommended 3072 MiB for OS ubuntu24.04

Starting install...
Creating domain...                                          |    0 B  00:00     
Domain creation completed.
ana@host:~$ virsh list
 Id   Name   State
----------------------
 8    vm1    running
```

`--memory 1024` é 1 GiB de memória e `--vcpus 2` são dois processadores. O segundo disco é o seed da seção
05, e o `--import` diz que o primeiro já tem um sistema, então não há nada a instalar. O `virsh list` é a
lista de convidados ligados do libvirt, e a `vm1` está nela.

Os dois avisos são honestos. O Ubuntu pede mais de 1 GiB para um desktop, e este convidado não tem
desktop. E **`KVM acceleration not available, using 'qemu'`** é o computador em que este curso foi
gravado: ele mesmo é uma máquina virtual que não repassa os recursos de virtualização do processador,
então o QEMU imita o processador do convidado em software. Tudo funciona, só que mais devagar. No seu
computador, se o `kvm-ok` disse sim na seção 03, essa linha não aparece e o convidado roda no processador
de verdade. A aula 2 é exatamente sobre essa diferença.

O convidado leva um ou dois minutos para dar boot e se configurar. Até lá, o próximo comando imprime o
cabeçalho e nada embaixo. Depois o libvirt, que deu o endereço ao convidado, sabe dizer qual é, e uma
linha no `/etc/hosts` dá um nome ao endereço:

```
ana@host:~$ virsh domifaddr vm1
 Name       MAC address          Protocol     Address
-------------------------------------------------------------------------------
 vnet6      52:54:00:64:35:f5    ipv4         192.168.122.38/24

ana@host:~$ echo "192.168.122.38 vm1" | sudo tee -a /etc/hosts
192.168.122.38 vm1
ana@host:~$ ssh vm1 hostname
The authenticity of host 'vm1 (192.168.122.38)' can't be established.
ED25519 key fingerprint is SHA256:AtuxLgue5Nm22R40PjgqlXGl68o26ZwDykEqfpjG2ds.
This key is not known by any other names.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added 'vm1' (ED25519) to the list of known hosts.
vm1
```

O primeiro ssh para qualquer máquina pergunta se deve confiar na chave que ela apresenta, porque nada
ainda diz que é a máquina que você quis. Para um convidado que você fez um minuto atrás no seu próprio
computador, `yes` é a resposta. A `vm1` respondeu com o próprio nome, que veio do seed.
