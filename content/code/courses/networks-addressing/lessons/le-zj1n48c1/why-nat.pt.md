---
title: Privado por dentro, um endereço público por fora
version: 1
---

O IPv4 tem 2 elevado a 32 endereços, cerca de 4,3 bilhões, e há mais dispositivos que isso. **O NAT,
tradução de endereços de rede, deixa uma rede inteira usar endereços privados por dentro e dividir um
endereço público por fora.** As faixas privadas são reservadas pela RFC 1918 — `10.0.0.0/8`,
`172.16.0.0/12` e `192.168.0.0/16` — e a aula 8 trata delas: qualquer um pode usá-las, então o mesmo
endereço existe em milhares de escritórios ao mesmo tempo, e nenhum roteador da internet tem rota
para nenhum deles.

O laboratório do escritório é montado assim. O pc1 tem um endereço privado:

```
ana@pc1:~$ ip -br addr show eth0
eth0@if155       UP             10.20.10.21/24 fe80::25:70ff:febc:29c6/64 
```

e o r1, o roteador, tem um pé em cada mundo:

```
root@r1:~# ip -br addr
lo               UNKNOWN        127.0.0.1/8 ::1/128 
eth0@if163       UP             10.20.10.1/24 fe80::1f:23ff:fee7:e9d5/64 
eth1@if165       UP             203.0.113.2/30 fe80::a6:80ff:fe20:1354/64 
```

A `eth0`, voltada para o escritório, é `10.20.10.1/24`, o gateway do pc1. A `eth1`, voltada para o
provedor, é `203.0.113.2/30`, o único endereço público do escritório. (No laboratório ele vem de
203.0.113.0/24, um bloco reservado para documentação que faz o papel de um endereço público real.) O
que faz o compartilhamento funcionar é uma regra do nftables, o firewall do r1, numa tabela própria:

```
root@r1:~# nft list table ip nat
table ip nat {
	chain postrouting {
		type nat hook postrouting priority srcnat; policy accept;
		oifname "eth1" masquerade
	}
}
```

Leia a chain de fora para dentro. `type nat hook postrouting` a põe no último instante antes de um
pacote sair, depois que o r1 já decidiu para onde ele vai. `oifname "eth1"` casa com os pacotes que
saem pela interface voltada para a internet. `masquerade` troca o endereço de origem deles pelo
endereço que essa interface tem naquele momento, e por isso é a escolha comum quando o provedor pode
mudar o endereço; com um endereço fixo, `snat to 203.0.113.2` diz a mesma coisa com o endereço escrito.

A ideia errada mais comum é que o NAT é um recurso de segurança. **O NAT traduz endereços; decidir o
que pode passar é trabalho do firewall.** O r1 faz as duas coisas, e a tabela `inet filter` dele, a que
a aula 1 mostrou derrubando uma conexão vinda de fora, é o que recusa o tráfego que ninguém pediu. As
duas coisas se confundem fácil, porque um roteador com NAT e sem regra para uma conexão que chega não
tem para onde mandá-la mesmo — a seção sobre redirecionamento de portas mostra isso acontecendo. Mas
um roteador com NAT, uma regra de redirecionamento e nenhum firewall entregaria o que chegasse.
