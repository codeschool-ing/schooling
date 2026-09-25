---
title: VMDK, o disco que todos leem
version: 1
---

O **VMDK** é o formato de disco do VMware, e virou a língua comum das imagens de disco: o VirtualBox, o
QEMU e a maioria dos importadores de nuvem o leem. O `qemu-img` escreve um
a partir do disco base do laboratório:

```
ana@host:~$ qemu-img convert -O vmdk /var/lib/libvirt/images/lab-base.qcow2 ~/lab.vmdk
ana@host:~$ qemu-img info ~/lab.vmdk | head -5
image: /home/ana/lab.vmdk
file format: vmdk
virtual size: 3.5 GiB (3758096384 bytes)
disk size: 816 MiB
cluster_size: 65536
ana@host:~$ ls -lh /var/lib/libvirt/images/lab-base.qcow2 ~/lab.vmdk
-rw-r--r-- 1 ana          ana 817M Sep 25 19:24 /home/ana/lab.vmdk
-rw-r--r-- 1 libvirt-qemu kvm 318M Sep 25 18:28 /var/lib/libvirt/images/lab-base.qcow2
```

O mesmo disco de 3,5 GiB, 817M como VMDK contra 318M como o qcow2 comprimido do Ubuntu. Como o qcow2 e o
VDI, este VMDK é *esparso*: espaço que o convidado nunca escreveu não é guardado.

O assistente do Workstation também oferece **dividir o disco em vários arquivos**, e máquinas antigas
quase sempre são feitas assim. É isto que dividir quer dizer:

```
ana@host:~$ mkdir -p ~/split && qemu-img convert -O vmdk -o subformat=twoGbMaxExtentSparse /var/lib/libvirt/images/lab-base.qcow2 ~/split/lab.vmdk && ls -lh ~/split
total 817M
-rw-r--r-- 1 ana ana 770M Sep 25 19:24 lab-s001.vmdk
-rw-r--r-- 1 ana ana  48M Sep 25 19:24 lab-s002.vmdk
-rw-r--r-- 1 ana ana  512 Sep 25 19:24 lab.vmdk
ana@host:~$ tr -d '\0' < ~/split/lab.vmdk
# Disk DescriptorFile
version=1
CID=cf663534
parentCID=ffffffff
createType="twoGbMaxExtentSparse"

# Extent description
RW 4194304 SPARSE "lab-s001.vmdk"
RW 3145728 SPARSE "lab-s002.vmdk"

# The Disk Data Base
#DDB

ddb.virtualHWVersion = "4"
ddb.geometry.cylinders = "7281"
ddb.geometry.heads = "16"
ddb.geometry.sectors = "63"
ddb.adapterType = "ide"
ddb.toolsVersion = "2147483647"
```

O `lab.vmdk` agora é um arquivo de texto de 512 bytes, um **descritor**, e os dados estão no
`lab-s001.vmdk` e no `lab-s002.vmdk`. As linhas `RW` do descritor os listam com os tamanhos em setores
de 512 bytes: 4194304 setores são exatamente 2 GiB, e 3145728 são o 1,5 GiB restante. O limite vem de sistemas de
arquivos como o FAT32, que não guardam um arquivo de 4 GiB ou mais, e do tempo em que discos eram levados
neles.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"Um VMDK dividido. O arquivo lab.vmdk é um descritor, 512 bytes de texto. Ele lista duas extensões: lab-s001.vmdk, 4194304 setores, os primeiros 2 GiB do disco, ocupando 770M no host; e lab-s002.vmdk, 3145728 setores, o 1,5 GiB restante, ocupando 48M.\"><defs><marker id=\"ex-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"240\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"42\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">lab.vmdk</text><text x=\"34\" y=\"64\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o descritor: texto, 512 bytes</text><rect x=\"360\" y=\"20\" width=\"340\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"374\" y=\"42\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\" xml:space=\"preserve\">lab-s001.vmdk   770M</text><text x=\"374\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">RW 4194304 SPARSE</text><text x=\"374\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">os primeiros 2 GiB do disco</text><path d=\"M262 50 L358 55\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ex-ah)\"></path><rect x=\"360\" y=\"110\" width=\"340\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"374\" y=\"132\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\" xml:space=\"preserve\">lab-s002.vmdk   48M</text><text x=\"374\" y=\"152\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">RW 3145728 SPARSE</text><text x=\"374\" y=\"170\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o 1,5 GiB restante</text><path d=\"M262 50 L358 145\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ex-ah)\"></path></svg>", "caption": "Um disco dividido é um arquivo de texto pequeno que nomeia os pedaços, cada um cobrindo no máximo 2 GiB. Abra o descritor e o hypervisor lê os pedaços; perca um pedaço e o disco se foi."}
```

Duas coisas decorrem disso para o suporte. **Copie todos os pedaços**: um disco dividido sem um dos
`-s00N.vmdk` não abre, e um cliente que "copiou a VM" a partir de uma lista ordenada por tamanho pode ter
deixado os pedaços pequenos para trás. E **nunca edite o descritor à mão** sem saber por quê; ele é
texto, e essa é a tentação.
