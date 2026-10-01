---
title: Um segundo servidor que ninguém pediu
version: 1
---

O DHCP não tem noção de servidor oficial. **Um cliente aceita a primeira oferta que chega, de quem
quer que a tenha mandado**, e qualquer máquina da sub-rede pode responder a um broadcast. Um segundo
servidor DHCP numa LAN é quase sempre um acidente: um roteador doméstico ligado por uma das portas LAN para ganhar mais
algumas tomadas. De vez em quando é um ataque, porque quem responde decide o gateway e o servidor de
nomes do cliente. De um jeito ou de outro, os clientes que o escutam ficam
isolados ou são mandados para outro lugar.

No laboratório, o PC chamado rogue virou um segundo servidor, que empresta do 10.20.10.200 para cima
e indica a si mesmo, 10.20.10.66, como gateway. Como ele foi iniciado não faz parte desta aula; o que
ele faz com a rede, sim. O pc2 pede um endereço, com um `tcpdump` rodando no pc2 num segundo terminal,
que imprime depois:

```
ana@pc2:~$ sudo dhclient -v eth0 2>&1 | grep -E "DHCPOFFER|DHCPACK|bound"
DHCPOFFER of 10.20.10.101 from 10.20.10.10
DHCPACK of 10.20.10.101 from 10.20.10.10 (xid=0x25a4e4f)
bound to 10.20.10.101 -- renewal in 251 seconds.
root@pc2:~# timeout 12 tcpdump -n -i eth0 udp src port 67
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on eth0, link-type EN10MB (Ethernet), snapshot length 262144 bytes
08:21:27.072890 IP 10.20.10.10.67 > 10.20.10.101.68: BOOTP/DHCP, Reply, length 300
08:21:27.083101 IP 10.20.10.10.67 > 10.20.10.101.68: BOOTP/DHCP, Reply, length 300
08:21:28.091759 IP 10.20.10.66.67 > 10.20.10.200.68: BOOTP/DHCP, Reply, length 300

3 packets captured
3 packets received by filter
0 packets dropped by kernel
```

O pc2 aceitou a oferta do servidor verdadeiro, 10.20.10.101 vindo de 10.20.10.10. A captura mostra
que foi uma corrida. Duas respostas de 10.20.10.10, a oferta e o ACK, e depois **uma terceira
resposta, de 10.20.10.66, oferecendo 10.20.10.200**, um segundo mais tarde. O servidor verdadeiro foi
mais rápido desta vez, e nada garante que sempre será.

Para ver o outro desfecho, o servidor verdadeiro é pausado: `kill -STOP` congela o processo sem
encerrá-lo, do jeito que um servidor sobrecarregado ficaria parado sem responder. Então o pc2 pede de
novo:

```
root@srv:~# kill -STOP $(cat /run/lab/srv/dhcpd.pidfile)
ana@pc2:~$ sudo dhclient -r eth0; sudo dhclient -v eth0 2>&1 | grep -E "DHCPOFFER|DHCPACK|bound"
Killed old client process
DHCPOFFER of 10.20.10.200 from 10.20.10.66
DHCPACK of 10.20.10.200 from 10.20.10.66 (xid=0xae5dac3e)
bound to 10.20.10.200 -- renewal in 272 seconds.
ana@pc2:~$ ip route
default via 10.20.10.66 dev eth0 
10.20.10.0/24 dev eth0 proto kernel scope link src 10.20.10.200 
ana@pc2:~$ ping -c 2 -W 1 10.20.20.1
PING 10.20.20.1 (10.20.20.1) 56(84) bytes of data.

--- 10.20.20.1 ping statistics ---
2 packets transmitted, 0 received, 100% packet loss, time 1040ms

```

(`Killed old client process` é o `dhclient -r` encerrando o cliente anterior.) A única oferta veio de
10.20.10.66, e o pc2 a aceitou. A rota padrão dele agora aponta para o rogue, e um ping para
10.20.20.1, o endereço do r1 no outro andar, perde os dois pacotes. O rogue não é roteador, então **o
pc2 tem um endereço que funciona e nenhuma saída**. Um intruso que encaminhasse o tráfego seria pior,
porque nada pareceria quebrado enquanto cada pacote passasse pela máquina de outra pessoa. Depois o
servidor verdadeiro é liberado:

```
root@srv:~# kill -CONT $(cat /run/lab/srv/dhcpd.pidfile)
```

A defesa mora no switch, porque só o switch sabe por qual porta cada quadro entrou. **O DHCP snooping
marca a porta voltada para o servidor verdadeiro como confiável e todas as outras como não
confiáveis, e descarta mensagens de servidor que chegam por uma porta não confiável.** Ofertas e ACKs
são reconhecíveis pela origem, a porta UDP 67. Um switch gerenciável tem o snooping como recurso a
ligar por VLAN; o switch deste laboratório é uma bridge Linux, e uma regra do nftables faz o mesmo
trabalho. O srv está ligado na porta p4:

```
root@sw1:~# nft add table bridge snoop
root@sw1:~# nft add chain bridge snoop forward "{ type filter hook forward priority 0; }"
root@sw1:~# nft add rule bridge snoop forward iifname != "p4" udp sport 67 counter drop
```

Leia a regra da esquerda para a direita: no caminho de encaminhamento da bridge, um quadro que entrou
por qualquer porta que não seja a `p4` e carrega UDP da porta de origem 67 é contado e descartado. O
pc2 pede de novo, com o mesmo `tcpdump` ao lado:

```
ana@pc2:~$ sudo dhclient -v eth0 2>&1 | grep -E "DHCPOFFER|DHCPACK|bound"
DHCPOFFER of 10.20.10.101 from 10.20.10.10
DHCPACK of 10.20.10.101 from 10.20.10.10 (xid=0xa3cfec6e)
bound to 10.20.10.101 -- renewal in 298 seconds.
root@pc2:~# timeout 12 tcpdump -n -i eth0 udp src port 67
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on eth0, link-type EN10MB (Ethernet), snapshot length 262144 bytes
08:21:57.406295 IP 10.20.10.10.67 > 10.20.10.101.68: BOOTP/DHCP, Reply, length 300
08:21:57.418782 IP 10.20.10.10.67 > 10.20.10.101.68: BOOTP/DHCP, Reply, length 300

2 packets captured
2 packets received by filter
0 packets dropped by kernel
ana@pc2:~$ ip route
default via 10.20.10.1 dev eth0 
10.20.10.0/24 dev eth0 proto kernel scope link src 10.20.10.101 
```

Duas respostas chegam ao pc2 agora, as duas de 10.20.10.10, e a rota padrão volta a ser o r1. O
contador diz o que aconteceu com a oferta do intruso:

```
root@sw1:~# nft list table bridge snoop
table bridge snoop {
	chain forward {
		type filter hook forward priority 0; policy accept;
		iifname != "p4" udp sport 67 counter packets 1 bytes 328 drop
	}
}
```

**`counter packets 1 bytes 328 drop`: uma mensagem de servidor chegou por uma porta que não tinha
motivo para mandar uma, e o switch a jogou fora.** Esse contador também é o alarme. Um número que não
para de subir quer dizer que um servidor está respondendo de uma porta onde não deveria haver nenhum,
e a porta diz até qual mesa você precisa ir. O recurso de snooping de um switch também mantém uma
tabela de qual endereço ele viu ser emprestado a qual MAC em qual porta, e outras proteções são
construídas sobre essa tabela; a Cisco chama duas delas de Dynamic ARP Inspection e IP Source Guard.

A regra deste laboratório é mais grosseira que o recurso de um switch. Ela descarta tudo o que vem da
porta UDP 67, e os pedidos que o relay encaminha também saem do r1 pela porta 67 — a captura da seção
sobre relay mostra `10.20.10.1.67`. Com o relay e esta regra rodando juntos, a p8, a porta voltada
para o r1, também teria de ser confiável, ou o segundo andar perderia o DHCP para a sua própria
proteção.
