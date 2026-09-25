---
title: Processadores virtuais
version: 1
---

A vm1 foi feita com dois processadores virtuais, **vCPUs**, e o libvirt consegue dizer o que cada um está
fazendo:

```
ana@host:~$ virsh vcpucount vm1
maximum      config         2
maximum      live           2
current      config         2
current      live           2

ana@host:~$ virsh vcpuinfo vm1 | grep -E "^(VCPU|CPU|State|CPU time)"
VCPU:           0
CPU:            3
State:          running
CPU time:       90.2s
CPU Affinity:   yyyy
VCPU:           1
CPU:            1
State:          running
CPU time:       90.4s
CPU Affinity:   yyyy
ana@vm1:~$ nproc
2
```

O `vcpucount` mostra quatro números porque um convidado tem um **máximo**, fixado quando ele liga, e uma
contagem **atual** que pode subir até ele, e cada um existe tanto na descrição salva (`config`) quanto no
convidado ligado (`live`). O `vcpuinfo` mostra que cada vCPU roda **em algum processador de verdade do
host**: naquele momento, a vCPU 0 no processador 3 do host e a vCPU 1 no processador 1. `CPU
Affinity: yyyy` quer dizer que qualquer uma pode rodar em qualquer um dos quatro do host; o escalonador
do host as move como move qualquer thread. Cada uma usou uns 90,2 segundos de
processador, a maior parte dando boot sob imitação.

Então uma vCPU é uma promessa de vez, não um processador reservado. Dois convidados com duas vCPUs cada
num host de quatro processadores cabem; dez deles também ligam, e revezam, e cada um roda mais devagar.
Isso serve para convidados quase sempre parados, que é a maior parte de um laboratório, e é ruim para
convidados todos ocupados ao mesmo tempo. Lá dentro, o `nproc` diz 2, e o convidado não tem como saber
que está dividindo.

Duas regras decorrem disso. **Dê a um convidado tantas vCPUs quanto o trabalho dele usa, não mais**: uma
vCPU parada custa pouco, mas um convidado com oito threads ocupadas num host de quatro processadores é
mais lento que o mesmo convidado com quatro. E **nunca dê a um convidado todos os processadores do
host**, a regra da aula 4, porque o host tem trabalho próprio, inclusive rodar os dispositivos do
convidado.
