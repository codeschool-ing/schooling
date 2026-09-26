---
title: Rodando convidados num servidor
version: 1
---

Os convidados de um servidor precisam voltar sozinhos depois que o servidor reinicia, de madrugada, sem
ninguém olhando. No libvirt é um comando:

```
ana@host:~$ virsh autostart vm1
Domain 'vm1' marked as autostarted

ana@host:~$ virsh dominfo vm1 | grep -E "^(Name|State|Autostart)"
Name:           vm1
State:          running
Autostart:      enable
```

O Proxmox tem a mesma chave como *Start at boot* nas *Options* de uma máquina, com uma ordem de partida e
uma espera, para o banco de dados subir antes da aplicação que precisa dele.

Na interface web, o *Create VM* passa por abas que são as aulas deste curso em ordem: *General* (o número
e o nome), *OS* (a ISO), *System* (firmware e o agente do convidado, aula 3), *Disks*, *CPU* e *Memory*
(aula 8), *Network* (a ponte). Uma máquina ligada tem uma aba *Console* que mostra a tela dela no
navegador, e é assim que você instala um sistema num servidor sem ninguém na frente. Na linha de
comando, o mesmo trabalho é o `qm` para máquinas e o `pct` para contêineres:

```sh
qm create 100 --name lab1 --ostype l26 --memory 2048 --cores 2 \
   --scsihw virtio-scsi-pci --scsi0 local-lvm:32 \
   --ide2 local:iso/ubuntu-24.04-live-server-amd64.iso,media=cdrom \
   --net0 virtio,bridge=vmbr0 --boot 'order=scsi0;ide2'   # a VM, id 100
qm start 100                                   # start it
qm list                                        # every VM on this node
qm config 100                                  # its settings, from /etc/pve/qemu-server/100.conf
qm showcmd 100 --pretty                        # the QEMU command line Proxmox will run
qm snapshot 100 clean                          # a snapshot called clean, lesson 9
qm template 100                                # turn it into a template, lesson 10
qm clone 100 101 --name lab2 --full            # a full clone of it, id 101
qm disk import 101 lab-base.qcow2 local-lvm    # bring a disk from another hypervisor
pct create 200 local:vztmpl/TEMPLATE.tar.zst --hostname ct1 --memory 512   # a container
vzdump 100 --storage local --mode snapshot     # back VM 100 up while it runs
```

**Nenhum deles foi rodado para esta aula.** `TEMPLATE` está no lugar de um modelo de contêiner baixado
pela interface web, cujo nome de arquivo muda a cada versão.

Dois recursos são o motivo de uma empresa escolher um hypervisor de servidor em vez de um de laptop.
**Backups** de máquinas ligadas, com o `vzdump` ou com um Proxmox Backup Server separado, com horário
marcado. E **clusters**:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Um cluster Proxmox de três nós, pve1, pve2 e pve3, todos ligados a um armazenamento compartilhado onde moram os discos dos convidados. Um convidado vai do pve1 para o pve2 por migração a quente e continua rodando enquanto muda. Com três nós, dois podem vencer um na votação, e é isso que deixa o cluster decidir qual nó caiu de verdade.\"><defs><marker id=\"cl-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"200\" height=\"80\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"42\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">pve1</text><text x=\"80\" y=\"42\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">nó</text><rect x=\"34\" y=\"56\" width=\"90\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"46\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">vm 100</text><path d=\"M120 102 L120 158\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#cl-ah)\" marker-start=\"url(#cl-ah)\"></path><rect x=\"260\" y=\"20\" width=\"200\" height=\"80\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"274\" y=\"42\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">pve2</text><text x=\"320\" y=\"42\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">nó</text><rect x=\"274\" y=\"56\" width=\"90\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"286\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">vm 100</text><path d=\"M360 102 L360 158\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#cl-ah)\" marker-start=\"url(#cl-ah)\"></path><rect x=\"500\" y=\"20\" width=\"200\" height=\"80\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"514\" y=\"42\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">pve3</text><text x=\"560\" y=\"42\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">nó</text><path d=\"M600 102 L600 158\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#cl-ah)\" marker-start=\"url(#cl-ah)\"></path><path d=\"M 126 70 C 180 70, 220 70, 252 70\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#cl-ah)\"></path><rect x=\"20\" y=\"160\" width=\"680\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"183\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">armazenamento compartilhado: os discos moram aqui</text><text x=\"20\" y=\"220\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">migração a quente: o convidado continua rodando enquanto muda</text><text x=\"20\" y=\"240\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">três nós, para dois poderem vencer um na votação</text></svg>", "caption": "Num cluster os discos ficam num armazenamento que todo nó alcança, então mover um convidado só move a memória e o estado do processador. É isso que torna possível fazer manutenção num nó sem desligar ninguém."}
```

Com três ou mais servidores unidos num cluster e os discos num armazenamento compartilhado, uma máquina
ligada pode ser **migrada** de um servidor para outro sem ser desligada, e com *alta disponibilidade*
ligada o cluster a liga de novo em outro lugar quando o servidor dela morre. Três é o mínimo que
importa: com dois, quando um perde o outro de vista nenhum sabe se o outro morreu ou só ficou
inalcançável, e um convidado ligado duas vezes sobre um disco compartilhado o destrói.
