---
title: Quem pode pedir
version: 1
---

O ping marcado da seção anterior saiu do laptop, e ninguém deu permissão ao laptop. `ana` digitou
`-Q 0xb8` como usuária comum e o ping dela furou a fila. **Qualquer programa em qualquer máquina pode
escrever o DSCP que quiser nos próprios pacotes**, então um roteador que acredita na marcação entregou a
fila de prioridade a quem pedir primeiro. Um job de backup marcado como EF tomaria a classe de voz, e as
ligações voltariam a esperar.

A correção é uma **fronteira de confiança** (trust boundary): o primeiro equipamento que o dono da rede
controla reescreve a marcação de tudo o que passa por ele, e só então põe EF de volta no que ele sabe que é
voz. Aqui esse equipamento é `hq`, e a reescrita são duas regras de `nftables` nos pacotes que chegam da LAN
do escritório, `eth0`:

```
ana@hq:~$ sudo nft add table ip qos && sudo nft add chain ip qos edge "{ type filter hook prerouting priority mangle; }"
ana@hq:~$ sudo nft add rule ip qos edge iifname eth0 ip dscp set cs0 && sudo nft add rule ip qos edge iifname eth0 ip saddr 192.168.10.10 udp dport 5004 ip dscp set ef
ana@hq:~$ sudo nft list table ip qos
table ip qos {
	chain edge {
		type filter hook prerouting priority mangle; policy accept;
		iifname "eth0" ip dscp set cs0
		iifname "eth0" ip saddr 192.168.10.10 udp dport 5004 ip dscp set ef
	}
}
```

A chain se prende ao `prerouting` com `priority mangle`, então roda quando o pacote chega, antes do
roteamento e bem antes de o classificador da `eth1` ler o byte na saída. A primeira regra põe todo pacote
da LAN em `cs0`, melhor esforço. A segunda marca como EF um tipo de tráfego: UDP para a porta 5004 vindo de
`files`, `192.168.10.10`, que faz o papel do gateway de voz do escritório. **A ordem é a política**: limpar
tudo e depois conceder as exceções, o mesmo formato de um firewall que nega por padrão.

O laptop tenta de novo, com o mesmo upload rodando:

```
ana@laptop:~$ ping -c 5 -q -Q 0xb8 192.0.2.21 | tail -n 1
rtt min/avg/max/mdev = 24.483/26.292/27.973/1.185 ms
```

**26 ms em média: o ping do laptop voltou para a fila do upload.** O laptop continua marcando o ping como
EF; `hq` é que não acredita mais. E `files` envia um datagrama para a porta 5004, com `echo voice | nc -u
-w1 192.0.2.21 5004`, um comando sem opção nenhuma de marcação, rodado fora da tela. O provedor o vê
chegar:

```
ana@isp:~$ sudo tcpdump -n -v -i eth0 -c 1 udp port 5004
tcpdump: listening on eth0, link-type EN10MB (Ethernet), snapshot length 262144 bytes
18:13:25.380855 IP (tos 0xb8, ttl 63, id 57798, offset 0, flags [DF], proto UDP (17), length 34)
    203.0.113.2.50848 > 192.0.2.21.5004: UDP, length 6
1 packet captured
1 packet received by filter
0 packets dropped by kernel
```

`tos 0xb8`, EF, num pacote cujo remetente não marcou nada. `length 6` é a palavra `voice` e uma quebra de
linha. **A marcação foi decidida pela rede, a partir do endereço e da porta do pacote, e não pelo programa
que o enviou**, que é o único tipo de marcação sobre o qual um roteador pode se dar ao luxo de agir.

Num escritório de verdade a fronteira fica no switch de acesso, a primeira coisa em que um telefone ou um
laptop é ligado. Os switches confiam na marcação numa porta onde há um telefone IP, muitas vezes numa VLAN
de voz própria, a ideia da aula 19 de `networks-addressing`, e a zeram em todas as outras portas. Um
roteador mais para dentro passa então a ter marcações em que pode acreditar sem perguntar quem as escreveu.
