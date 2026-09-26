---
title: Dispositivos feitos para convidados
version: 1
---

Um hypervisor pode dar a um convidado dois tipos de dispositivo. Pode **imitar um de verdade**, uma placa
de rede Intel ou uma controladora de disco IDE antiga, para os quais todo sistema operacional já tem
driver, ao custo de imitar cada registrador de um hardware que nunca foi pensado para ser imitado. Ou
pode oferecer um dispositivo **feito para convidados**, que faz o mesmo trabalho em bem menos passos e
precisa de um driver que o conheça. No QEMU o segundo tipo se chama **virtio**, e um convidado Linux já
tem os drivers:

```
ana@vm1:~$ ls /sys/bus/virtio/drivers
virtio_balloon
virtio_blk
virtio_console
virtio_iommu
virtio_net
virtio_rng
virtio_rproc_serial
virtio_scsi
```

O `virtio_blk` é o disco da vm1, o `virtio_net` a placa de rede dela, o `virtio_balloon` o balão da seção
04, o `virtio_console` o canal do agente, e o `virtio_rng` uma fonte de números aleatórios vinda do host.
Um convidado Linux no QEMU os usa sem ninguém pedir.

Um **convidado Windows não**: o Windows não tem drivers virtio próprios. Instalar o Windows num disco
virtio mostra um instalador que não acha disco nenhum, até os drivers serem carregados da ISO
*virtio-win* com *Carregar driver*. A alternativa é dar a ele um disco SATA imitado e uma placa de rede
Intel, que funcionam na hora e são mais lentos. Todo hypervisor tem os próprios dispositivos feitos para
convidados, com a mesma troca: os do VMware são o VMXNET3 e o PVSCSI, instalados com o VMware Tools; os
do Hyper-V vêm com os Serviços de Integração.
