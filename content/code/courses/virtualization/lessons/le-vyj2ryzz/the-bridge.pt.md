---
title: A ponte
version: 1
---

Os convidados de um servidor normalmente precisam ser alcançáveis do escritório, então as placas de
rede deles são ligadas numa **ponte** (bridge), um switch feito de software dentro do host:

```
ana@host:~$ ip -br link show type bridge
virbr0           UP             52:54:00:0b:54:ea <BROADCAST,MULTICAST,UP,LOWER_UP> 
ana@host:~$ bridge link
18: vnet2: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 master virbr0 state forwarding priority 32 cost 2 
```

O laboratório tem uma, a `virbr0`, e o `bridge link` mostra o que está ligado nela: a `vnet2`, o cabo da
vm1 da aula 3. A `virbr0` do libvirt não está unida a nada físico, e o host roteia os convidados para
fora, que é o NAT da aula 11.

O instalador do Proxmox faz uma ponte chamada **`vmbr0`**, e liga nela a placa de rede de verdade do
servidor. Então um convidado novo do Proxmox na `vmbr0` fica direto na rede do escritório, recebe
endereço do DHCP do escritório, e qualquer um lá o alcança, como o modo bridged da aula 5. É o que um
servidor precisa, e é também por isso que **uma máquina de teste num servidor Proxmox está na rede de
verdade a menos que alguém decida o contrário**. A aula 15 é sobre decidir o contrário.
