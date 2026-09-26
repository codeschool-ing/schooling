---
title: Como um snapshot é guardado
version: 1
---

Os snapshots de cima moravam dentro do `vm1.qcow2`. O outro jeito de guardar um é como uma **camada**: o
disco atual é congelado, e um arquivo novo é posto por cima para receber toda escrita dali em diante. É
assim que funcionam os arquivos `-000001.vmdk` do VMware e os `.avhdx` do Hyper-V, e o libvirt faz um com
`--disk-only`:

```
ana@host:~$ virsh snapshot-create-as vm1 before-update --disk-only --atomic
Domain snapshot before-update created
ana@host:~$ virsh domblklist vm1
 Target   Source
-----------------------------------------------------
 vda      /var/lib/libvirt/images/vm1.before-update

ana@vm1:~$ dd if=/dev/urandom of=big bs=1M count=100 status=none && sync
ana@host:~$ cd /var/lib/libvirt/images && ls -lsh vm1.qcow2 vm1.before-update
106M -rw------- 1 libvirt-qemu kvm 106M Sep 25 20:28 vm1.before-update
 27M -rw-r--r-- 1 libvirt-qemu kvm 1.3G Sep 25 20:28 vm1.qcow2
ana@host:~$ sudo qemu-img info -U --backing-chain /var/lib/libvirt/images/vm1.before-update | grep -E "^(image|backing file):"
image: /var/lib/libvirt/images/vm1.before-update
backing file: /var/lib/libvirt/images/vm1.qcow2
image: /var/lib/libvirt/images/vm1.qcow2
backing file: /var/lib/libvirt/images/lab-base.qcow2
image: /var/lib/libvirt/images/lab-base.qcow2
```

O disco do convidado agora é o `vm1.before-update`, e quando o convidado escreveu 100 MB o arquivo novo
os recebeu, 106M, enquanto o `vm1.qcow2` ficou em 27M. O `--backing-chain` mostra a cadeia: a camada
nova lê do `vm1.qcow2`, que lê da base. É a sobreposição da aula 1 um nível acima.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" aria-label=\"A cadeia de arquivos por trás da vm1 depois de um snapshot externo. No topo, o vm1.before-update, com 106M, onde caem as escritas novas. Debaixo dele, o vm1.qcow2, com 27M, o disco da vm1 como era, congelado pelo snapshot. No fundo, o lab-base.qcow2, a base compartilhada, só leitura. Apagar o snapshot quer dizer fundir a camada de cima para baixo. O commit padrão vai para o fundo da cadeia, a base compartilhada, e foi recusado. Com --shallow ele desce uma camada, para o vm1.qcow2.\"><defs><marker id=\"ch-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"16\" width=\"330\" height=\"54\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\" xml:space=\"preserve\">vm1.before-update   106M</text><text x=\"34\" y=\"58\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">as escritas novas caem aqui</text><rect x=\"20\" y=\"92\" width=\"330\" height=\"54\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"114\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\" xml:space=\"preserve\">vm1.qcow2   27M</text><text x=\"34\" y=\"134\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o disco da vm1, congelado pelo snapshot</text><rect x=\"20\" y=\"168\" width=\"330\" height=\"54\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"190\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">lab-base.qcow2</text><text x=\"34\" y=\"210\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a base compartilhada, só leitura</text><path d=\"M 352 42 C 420 42, 420 110, 352 110\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ch-ah)\"></path><text x=\"462\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">--shallow: uma camada abaixo</text><path d=\"M 352 36 C 480 36, 480 190, 352 190\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ch-ah)\" stroke-dasharray=\"4 3\"></path><text x=\"500\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">commit padrão: para o fundo da cadeia</text><text x=\"500\" y=\"178\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">Permission denied</text></svg>", "caption": "Apagar um snapshot externo é uma fusão, e a pergunta é em qual camada. A resposta padrão é a do fundo, que aqui é a base de todos os convidados."}
```

Isso explica as duas reclamações clássicas sobre snapshots em servidores VMware e Hyper-V. **Um snapshot
deixado no lugar cresce enquanto existir**, porque toda escrita desde que foi tirado cai na camada dele;
um esquecido pode encher um datastore. E **toda leitura pode ter de atravessar cada camada**, então uma
máquina com uma cadeia comprida de snapshots velhos fica mais lenta.
