---
title: "Reservas: o mesmo endereço, ainda por DHCP"
version: 1
---

A impressora, prn, precisa de um endereço que as pessoas possam digitar numa janela de impressão, e
esse endereço não pode mudar. Um endereço estático digitado no menu da própria impressora
resolveria, e então o endereço moraria na impressora, onde ninguém olha. **Uma reserva mantém o
endereço no arquivo do servidor e o amarra ao endereço de hardware da impressora.** É o último bloco
da configuração do srv, impressa na seção sobre escopos: `host prn`, com `hardware ethernet
02:32:ed:ce:04:12` e `fixed-address 10.20.10.50`.

O endereço MAC no arquivo precisa ser o da própria impressora, e é daqui que ele vem:

```
ana@prn:~$ ip link show eth0 | grep ether
    link/ether 02:32:ed:ce:04:12 brd ff:ff:ff:ff:ff:ff link-netns sw1
```

Quando a impressora pede, as mesmas quatro mensagens voltam, com o endereço reservado nelas:

```
ana@prn:~$ sudo dhclient -v eth0 2>&1 | grep -E "DHCP|bound"
Internet Systems Consortium DHCP Client 4.4.3-P1
DHCPDISCOVER on eth0 to 255.255.255.255 port 67 interval 3 (xid=0xa06b9207)
DHCPOFFER of 10.20.10.50 from 10.20.10.10
DHCPREQUEST for 10.20.10.50 on eth0 to 255.255.255.255 port 67 (xid=0x7926ba0)
DHCPACK of 10.20.10.50 from 10.20.10.10 (xid=0xa06b9207)
bound to 10.20.10.50 -- renewal in 283 seconds.
ana@prn:~$ ip -br addr show eth0
eth0@if127       UP             10.20.10.50/24 fe80::32:edff:fece:412/64 
```

Nada na troca diz que era uma reserva. Do lado da impressora é o mesmo DORA do pc1; a diferença está
no servidor, que procurou o endereço MAC antes de escolher o que oferecer. **O 10.20.10.50 fica fora
do pool, .100 a .199, de propósito**: fora do pool, ele não tem como ser emprestado a um PC que por
acaso peça antes da impressora.

Reservas servem para tudo o que outras máquinas alcançam pelo endereço mas ninguém quer configurar à
mão. Uma impressora, um storage de rede, um ponto de acesso ou uma câmera que um sistema de gerência
consulta, o servidor de arquivos de um escritório pequeno. Uma regra de firewall que cita um
dispositivo pelo endereço é outro motivo: a regra só significa algo se o endereço não mudar.

Ela traz dois custos.

- **A reserva segue a placa de rede, não o dispositivo.** Troque a impressora, ou só a placa dela, e
  o novo endereço MAC recebe um endereço comum do pool até alguém editar o arquivo. As janelas de
  impressão continuam apontando para o .50, onde nada responde.
- Celulares e laptops agora apresentam um endereço MAC diferente e aleatório em cada rede Wi-Fi,
  para não serem seguidos de uma rede para a outra. Uma reserva por endereço MAC não se sustenta para
  um dispositivo que o troca.

E uma coisa que a reserva não muda: a impressora continua dependendo do servidor. **Se o srv cair, a
impressora fica com o 10.20.10.50 até o empréstimo vencer, e depois fica sem nada.** Um dispositivo
que precisa funcionar sem o servidor DHCP, como o roteador ou o próprio servidor DHCP, fica com
endereço estático. Quanto tempo é "até o empréstimo vencer", e o que o cliente faz antes disso, é a
próxima seção.
