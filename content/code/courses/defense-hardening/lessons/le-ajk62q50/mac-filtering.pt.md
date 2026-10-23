---
title: Uma lista de endereços de hardware
version: 1
---

**Toda placa de rede tem um endereço de hardware, o endereço MAC, e todo quadro que ela envia o traz
como origem.** O laboratório dá a cada máquina um endereço fixo que termina no último número do seu
endereço IP em hexadecimal: o `desk`, em `.20`, é `52:54:00:a8:3c:14`. O controle de porta mais
simples é uma lista: quadros destes endereços passam, todo o resto é descartado.

No `sw`, a lista da porta do `desk` aceita o próprio `desk` e a impressora da recepção, cujo endereço
é `52:54:00:a8:3c:63` (o laboratório não tem impressora; o endereço faz o papel de uma):

```
ana@sw:~$ cat nac/macfilter.nft
table netdev macfilter {
	chain desk_port {
		type filter hook ingress device "port-desk" priority filter; policy drop;
		ether saddr { 52:54:00:a8:3c:14, 52:54:00:a8:3c:63 } counter accept
		counter
	}
}
```

Uma tabela **netdev** fica presa a uma interface e vê os quadros quando chegam, antes da bridge e da
pilha IP. A chain se engancha no `ingress` da `port-desk` com `policy drop`, então um quadro é
descartado a não ser que uma regra o aceite, e a única regra aceita os dois endereços do conjunto.
Cada regra leva um `counter`, que o fim desta seção lê. Carregue, e o `desk` continua funcionando:

```
ana@sw:~$ sudo nft -f nac/macfilter.nft && echo loaded
loaded
ana@desk:~$ ping -c1 -W1 web | tail -2
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 0.418/0.418/0.418/0.000 ms
```

Depois ligue "outro dispositivo": no `desk`, mude o endereço da placa para um que a lista não tem e
tente de novo.

```
ana@desk:~$ sudo ip link set eth0 address 52:54:00:a8:3c:99; ping -c1 -W1 web | tail -2
1 packets transmitted, 0 received, 100% packet loss, time 0ms

ana@desk:~$ sudo ip link set eth0 address 52:54:00:a8:3c:63; ping -c1 -W1 web | tail -2
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 0.063/0.063/0.063/0.000 ms
ana@desk:~$ sudo ip link set eth0 address 52:54:00:a8:3c:14
```

O endereço terminado em `:99` é recusado, como deveria. O endereço terminado em `:63` passa, e esse é
o da impressora. De volta ao `sw`, os contadores concordam:

```
ana@sw:~$ sudo nft list chain netdev macfilter desk_port
table netdev macfilter {
	chain desk_port {
		type filter hook ingress device "port-desk" priority filter; policy drop;
		ether saddr { 52:54:00:a8:3c:14, 52:54:00:a8:3c:63 } counter packets 4 bytes 224 accept
		counter packets 2 bytes 56
	}
}
ana@sw:~$ sudo nft delete table netdev macfilter && echo removed
removed
```

Quatro quadros passaram pela lista, 224 bytes: dois pings de 84 bytes e os dois pedidos ARP de 28 que
acharam o `web` antes de cada um. Dois foram descartados, 56 bytes, que são dois pedidos ARP do
endereço desconhecido perguntando onde estava o `web`. Não tiveram resposta, então o ping dele nem
saiu da máquina. A tabela é removida no fim, porque as próximas seções a substituem.

## Para que a lista serve

Um filtro de MAC barra o engano honesto: o visitante que liga um notebook na tomada errada, o switch
que alguém conecta para fazer duas portas de uma. Cada um deles chega com um endereço que ninguém
listou, e é recusado. Também é barato: todo switch gerenciável tem isso, com nomes como **port
security** ou **sticky MAC**, que aprende o primeiro endereço que vê numa porta e recusa os outros. A
próxima seção trata do que ele não consegue fazer.
