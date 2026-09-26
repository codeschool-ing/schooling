---
title: Onde eles se encontram
version: 1
---

Host e convidado são ligados por dispositivos que têm uma ponta de cada lado. As duas pontas podem ser
casadas:

```
ana@host:~$ virsh domblklist vm1
 Target   Source
---------------------------------------------
 vda      /var/lib/libvirt/images/vm1.qcow2

ana@host:~$ virsh domiflist vm1
 Interface   Type      Source    Model    MAC
-------------------------------------------------------------
 vnet2       network   default   virtio   52:54:00:ce:da:4e

ana@vm1:~$ ip -br link show enp1s0
enp1s0           UP             52:54:00:ce:da:4e <BROADCAST,MULTICAST,UP,LOWER_UP> 
```

**O disco** é o `vda` lá dentro e o `/var/lib/libvirt/images/vm1.qcow2` aqui fora. **A placa de rede** é
a `enp1s0` lá dentro e a `vnet2` aqui fora, e as duas mostram o mesmo MAC, `52:54:00:ce:da:4e`. É um cabo virtual
só: a `vnet2` é a ponta do host, uma porta ligada no switch da rede chamada `default`, e a `enp1s0` é a
ponta do convidado. Quando um convidado está sem rede, é esse o par a conferir, e a aula 11 monta outras
redes com as mesmas peças.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"Host e convidado lado a lado, ligados em três lugares. À esquerda, o host, com o kernel 6.18.44-fc-v37, o libvirt guardando a descrição do convidado, o processo qemu-system-x86 e o switch virbr0 em 192.168.122.1. À direita, a vm1, com o próprio kernel 6.8.0-139-generic. O arquivo vm1.qcow2 no host é o disco vda na vm1. A porta vnet2 no virbr0 e a placa enp1s0 na vm1 são as duas pontas de um cabo virtual com um MAC, 52:54:00:ce:da:4e. E o serviço qemu-guest-agent na vm1 responde ao libvirt pelo canal do agente.\"><defs><marker id=\"sd-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"14\" width=\"270\" height=\"236\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"36\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">host</text><rect x=\"430\" y=\"14\" width=\"270\" height=\"236\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"444\" y=\"36\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">vm1</text><text x=\"34\" y=\"56\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">kernel 6.18.44-fc-v37</text><text x=\"444\" y=\"56\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">kernel 6.8.0-139-generic</text><rect x=\"34\" y=\"72\" width=\"242\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"46\" y=\"91\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">libvirt: a descrição, virsh</text><rect x=\"34\" y=\"116\" width=\"242\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"46\" y=\"135\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o processo qemu-system-x86</text><rect x=\"444\" y=\"116\" width=\"242\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"456\" y=\"135\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">qemu-guest-agent</text><path d=\"M278 131 L442 131\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#sd-ah)\" marker-start=\"url(#sd-ah)\" stroke-dasharray=\"4 3\"></path><text x=\"360\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">o canal do agente</text><rect x=\"34\" y=\"160\" width=\"242\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"46\" y=\"179\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">vm1.qcow2: um arquivo</text><rect x=\"444\" y=\"160\" width=\"242\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"456\" y=\"179\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">vda: um disco</text><path d=\"M278 175 L442 175\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#sd-ah)\" marker-start=\"url(#sd-ah)\"></path><rect x=\"34\" y=\"204\" width=\"242\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"46\" y=\"223\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\" xml:space=\"preserve\">virbr0  192.168.122.1</text><text x=\"264\" y=\"223\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">vnet2</text><rect x=\"444\" y=\"204\" width=\"242\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"456\" y=\"223\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">enp1s0</text><text x=\"674\" y=\"223\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">52:54:00:ce:da:4e</text><path d=\"M278 219 L442 219\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#sd-ah)\" marker-start=\"url(#sd-ah)\"></path><text x=\"360\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">um cabo virtual, um MAC</text></svg>", "caption": "Dois sistemas, cada um com o próprio kernel, ligados por dispositivos que têm uma ponta de cada lado. O host vê um arquivo, uma porta e um canal; o convidado vê um disco, uma placa de rede e a porta em que o agente dele responde.", "same": ["kernel 6.18.44-fc-v37", "kernel 6.8.0-139-generic"]}
```

Casar MACs também é como você descobre qual convidado é qual, quando a lista de um switch ou um log de
DHCP mostra um endereço que você não reconhece. Todo convidado que o libvirt faz recebe um MAC que
começa com `52:54:00`, o prefixo que o QEMU usa, então um endereço `52:54:00` numa rede é um convidado
QEMU em algum lugar.
