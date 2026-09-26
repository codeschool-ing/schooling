---
title: Armazenamento
version: 1
---

Discos, ISOs e backups precisam morar em algum lugar, e um hypervisor que gerencia servidores dá nome a
esses lugares. O libvirt os chama de **pools**, e o laboratório tem um, a pasta de imagens:

```
ana@host:~$ virsh pool-list --all --details
 Name     State     Autostart   Persistent   Capacity     Allocation   Available
-----------------------------------------------------------------------------------
 images   running   yes         yes          251.97 GiB   17.42 GiB    234.55 GiB

ana@host:~$ virsh vol-list images --details
 Name                                      Path                                                              Type      Capacity   Allocation
----------------------------------------------------------------------------------------------------------------------------------------------
 lab-base.qcow2                            /var/lib/libvirt/images/lab-base.qcow2                            file      3.50 GiB   316.42 MiB
 SHA256SUMS                                /var/lib/libvirt/images/SHA256SUMS                                file      2.12 KiB   4.00 KiB
 ubuntu-24.04-minimal-cloudimg-amd64.img   /var/lib/libvirt/images/ubuntu-24.04-minimal-cloudimg-amd64.img   file      3.50 GiB   252.13 MiB
 vm1-seed.img                              /var/lib/libvirt/images/vm1-seed.img                              unknown   unknown    unknown
 vm1.qcow2                                 /var/lib/libvirt/images/vm1.qcow2                                 file      8.00 GiB   25.82 MiB
```

O pool é uma pasta num disco de 251.97 GiB, e cada arquivo nele é um **volume** com dois tamanhos:
**Capacity**, o que dizem ao convidado, e **Allocation**, o que ele ocupa no host. O disco da vm1 tem
8.00 GiB para o convidado e 25.82 MiB no host, o disco fino da aula 1 de novo.

O Proxmox chama a mesma ideia de **storage**, e uma instalação nova tem dois:

- **`local`**, uma pasta, `/var/lib/vz`, para ISOs, modelos de contêiner e backups.
- **`local-lvm`**, um *thin pool* de LVM, para os discos das máquinas virtuais. Fino, como os arquivos
  qcow2 daqui: o espaço é tomado conforme os convidados escrevem.

Outros são acrescentados em *Datacenter* → *Storage*: um pool ZFS, um compartilhamento NFS num servidor
de arquivos, ou Ceph espalhado pelos nós de um cluster. **O armazenamento onde um disco mora decide o que
dá para fazer com ele**: um snapshot precisa de um armazenamento que suporte snapshots, e mover uma
máquina ligada para outro servidor é mais simples quando os dois servidores alcançam o mesmo
armazenamento compartilhado.
