---
title: "Empréstimos: um endereço com data de devolução"
version: 1
---

**Um endereço de DHCP é emprestado, nunca dado.** Todo empréstimo, o *lease*, tem um início e um fim,
e o cliente precisa voltar antes do fim para mantê-lo. Os dois lados anotam o empréstimo, e o
registro do servidor é um arquivo de texto simples:

```
root@srv:~# cat /var/lib/dhcp/dhcpd.leases
# The format of this file is documented in the dhcpd.leases(5) manual page.
# This lease file was written by isc-dhcp-4.4.3-P1

# authoring-byte-order entry is generated, DO NOT DELETE
authoring-byte-order little-endian;

server-duid "\000\001\000\0012N[z\002\236C>\312\256";

lease 10.20.10.100 {
  starts 2 2026/09/29 11:20:32;
  ends 2 2026/09/29 11:30:32;
  cltt 2 2026/09/29 11:20:32;
  binding state active;
  next binding state free;
  rewind binding state free;
  hardware ethernet 02:25:70:bc:29:c6;
  client-hostname "pc1";
}
lease 10.20.10.101 {
  starts 2 2026/09/29 11:20:40;
  ends 2 2026/09/29 11:30:40;
  cltt 2 2026/09/29 11:20:40;
  binding state active;
  next binding state free;
  rewind binding state free;
  hardware ethernet 02:fd:f2:d2:63:ba;
  client-hostname "pc2";
}
```

Um bloco por endereço emprestado. O empréstimo do 10.20.10.100 ao pc1 `starts 2 2026/09/29
11:20:32` e `ends 2 2026/09/29 11:30:32`: dez minutos, o `default-lease-time 600` da configuração. O
`2` é o dia da semana, terça-feira. **Os horários deste arquivo estão em UTC**, enquanto o `tcpdump`
da seção sobre o DORA imprimiu o horário local do laboratório, `08:20` em São Paulo: o mesmo momento,
três horas de diferença na página, o que vale saber antes de comparar um empréstimo com um log.
`binding state active` é um empréstimo em uso, `next binding state free` é o que ele vira no fim, e
`client-hostname "pc1"` é o nome que o cliente mandou, o jeito mais rápido de descobrir de quem é um
empréstimo.

O pc1 guarda a sua própria cópia:

```
ana@pc1:~$ cat /var/lib/dhcp/dhclient.leases
lease {
  interface "eth0";
  fixed-address 10.20.10.100;
  option subnet-mask 255.255.255.0;
  option routers 10.20.10.1;
  option dhcp-lease-time 600;
  option dhcp-message-type 5;
  option domain-name-servers 10.20.10.10;
  option dhcp-server-identifier 10.20.10.10;
  renew 2 2026/09/29 11:25:24;
  rebind 2 2026/09/29 11:29:17;
  expire 2 2026/09/29 11:30:32;
}
```

As linhas `option` são o que o ACK trouxe; `dhcp-message-type 5` é o número do próprio ACK. As três
últimas linhas são o cronograma do cliente, medido a partir do início do empréstimo, às 11:20:32:

| | às | depois do início |
|---|---|---|
| renew (renovar) | 11:25:24 | 292 s, um pouco menos da metade de 600 |
| rebind (religar) | 11:29:17 | 525 s, sete oitavos de 600 |
| expire (vencer) | 11:30:32 | 600 s |

**No renew, o cliente pede ao servidor que lhe deu o endereço, diretamente e por unicast**, e um ACK
reinicia o relógio. Esse momento é o `renewal in 291 seconds` que o `dhclient` imprimiu quando
assumiu o endereço. Se aquele servidor não respondeu até o **rebind**, o cliente manda o pedido por
broadcast a qualquer servidor que escute. Se ninguém respondeu até o **expire**, o cliente para de
usar o endereço. Metade e sete oitavos são os padrões do protocolo, da RFC 2131; este cliente
antecipa o primeiro por um valor aleatório, e é por isso que cada `renewal in` desta aula é um número
diferente abaixo de 300 — 291 para o pc1, 283 para a impressora.

Um cliente que terminou de usar um endereço pode devolvê-lo antes:

```
ana@pc2:~$ sudo dhclient -r -v eth0 2>&1 | grep -E "DHCP"
Internet Systems Consortium DHCP Client 4.4.3-P1
DHCPRELEASE of 10.20.10.101 on eth0 to 10.20.10.10 port 67 (xid=0x64c27dc0)
ana@pc2:~$ ip -br addr show eth0
eth0@if125       UP             fe80::fd:f2ff:fed2:63ba/64 
```

O `dhclient -r` manda um **DHCPRELEASE**, por unicast ao servidor, `to 10.20.10.10`, e larga o
endereço: o pc2 volta a ter só o endereço IPv6 link-local. Um endereço devolvido volta ao pool na
hora. Um laptop simplesmente desconectado não manda nada, e o endereço dele continua emprestado até o
empréstimo vencer, e é por isso que a seção sobre escopos dimensionou o pool pelo prazo do
empréstimo.

Então a duração de um empréstimo é uma troca. Um empréstimo curto devolve depressa os endereços
abandonados, e uma mudança no escopo, como um novo servidor de nomes, chega a todos os clientes
dentro de um empréstimo. Custa uma renovação a cada poucos minutos de cada cliente, e o cliente
depende mais de perto do servidor estar no ar: com o srv parado, o pc1 perderia o endereço em até
dez minutos. Um empréstimo longo atravessa uma tarde com o servidor fora do ar. Dez minutos servem a
um laboratório em que você quer ver a renovação acontecer; um escritório empresta por horas ou dias.
