---
title: As peças dentro
version: 1
---

Às vezes o registro precisa de mais de uma linha por máquina: um aumento de memória para planejar, ou um
pedido de garantia que pede os dados de uma peça. O `lshw` lista as peças:

```
ana@pc1:~$ sudo lshw -short -class disk -class network -class memory 2>/dev/null
H/W path           Device      Class          Description
=========================================================
/0/0                           memory         96KiB BIOS
/0/1000                        memory         1GiB System Memory
/0/1000/0                      memory         1GiB DIMM RAM
/0/100/1/0                     network        Virtio 1.0 network device
/0/100/1/0/0       enp1s0      network        Ethernet interface
/0/100/1.3/0/0     /dev/vda    disk           8589MB Virtual I/O device
```

Um módulo de memória de **1GiB**, uma placa de rede **virtio**, e um disco de **8589MB**, que é a aula 8 do
curso de virtualização vista de dentro: os dispositivos que um hypervisor oferece aos convidados. Num
computador físico o mesmo comando nomeia os slots e a velocidade da memória, o modelo e o número de série do
disco e o fabricante da placa de rede, que é o que um fornecedor pede quando uma peça falha.

Mantenha o registro no nível de detalhe que alguém de fato usa. Uma linha por computador basta para a
maioria dos escritórios; peças valem ser acompanhadas quando são compradas, movidas ou reclamadas
separadamente, como os discos de um servidor.
