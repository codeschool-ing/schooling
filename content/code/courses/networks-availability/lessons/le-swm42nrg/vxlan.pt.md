---
title: Uma VPN de camada 2 com VXLAN
version: 1
---

Todo túnel até aqui uniu duas redes: uma sub-rede em cada ponta e um roteador entre elas, então um pacote
do laptop para o caixa perdia um salto de TTL a cada roteador. **Uma VPN de camada 2 une as duas pontas
num único segmento Ethernet**: uma sub-rede, um domínio de broadcast, máquinas nas duas pontas que se
alcançam pelo endereço MAC como se dividissem um switch.

O VXLAN, Virtual eXtensible LAN, faz isso levando quadros Ethernet inteiros dentro de UDP, porta 4789,
com um cabeçalho de 8 bytes cujo campo principal é um identificador de rede de 24 bits, o **VNI**.
Enquanto uma tag de VLAN, vista em `networks-addressing`, tem 12 bits e uns quatro mil valores, um VNI
tem uns dezesseis milhões. Diferente do GRE, o kernel em que estas transcrições foram gravadas o tem,
então o túnel é o do próprio kernel, como no seu. Em `hq`:

```
ana@hq:~$ sudo ip link add vx0 type vxlan id 100 local 203.0.113.2 remote 198.51.100.2 dstport 4789 dev eth1
ana@hq:~$ sudo ip addr add 172.16.0.1/24 dev vx0 && sudo ip link set vx0 up
ana@hq:~$ ip link show vx0
4: vx0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1450 qdisc noqueue state UNKNOWN mode DEFAULT group default qlen 1000
    link/ether ca:2e:ce:6e:53:49 brd ff:ff:ff:ff:ff:ff
```

`vx0` é uma interface Ethernet, com endereço MAC próprio e `BROADCAST` entre as flags, coisa que nenhum
túnel das aulas anteriores tinha. `branch` recebe a imagem espelhada, com `172.16.0.2`, no shell dele:

```sh
sudo ip link add vx0 type vxlan id 100 local 198.51.100.2 remote 203.0.113.2 dstport 4789 dev eth1
sudo ip addr add 172.16.0.2/24 dev vx0 && sudo ip link set vx0 up
```

**O MTU de `vx0` é 1450, e a figura abaixo diz para onde vão os outros 50 bytes.** Depois `hq`
pingou a outra ponta, e o roteador do provedor capturou o túnel com `-e`, que imprime os endereços
Ethernet:

```
ana@hq:~$ ping -c 1 172.16.0.2
PING 172.16.0.2 (172.16.0.2) 56(84) bytes of data.
64 bytes from 172.16.0.2: icmp_seq=1 ttl=64 time=1.27 ms

--- 172.16.0.2 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 1.266/1.266/1.266/0.000 ms
ana@isp:~$ sudo tcpdump -n -t -e -i eth0 -c 4 udp port 4789
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on eth0, link-type EN10MB (Ethernet), snapshot length 262144 bytes
52:54:00:00:71:02 > 52:54:00:00:71:01, ethertype IPv4 (0x0800), length 92: 203.0.113.2.57530 > 198.51.100.2.4789: VXLAN, flags [I] (0x08), vni 100
ca:2e:ce:6e:53:49 > ff:ff:ff:ff:ff:ff, ethertype ARP (0x0806), length 42: Request who-has 172.16.0.2 tell 172.16.0.1, length 28
52:54:00:00:71:01 > 52:54:00:00:71:02, ethertype IPv4 (0x0800), length 92: 198.51.100.2.57530 > 203.0.113.2.4789: VXLAN, flags [I] (0x08), vni 100
96:6b:a3:79:75:aa > ca:2e:ce:6e:53:49, ethertype ARP (0x0806), length 42: Reply 172.16.0.2 is-at 96:6b:a3:79:75:aa, length 28
52:54:00:00:71:02 > 52:54:00:00:71:01, ethertype IPv4 (0x0800), length 148: 203.0.113.2.47755 > 198.51.100.2.4789: VXLAN, flags [I] (0x08), vni 100
ca:2e:ce:6e:53:49 > 96:6b:a3:79:75:aa, ethertype IPv4 (0x0800), length 98: 172.16.0.1 > 172.16.0.2: ICMP echo request, id 26447, seq 1, length 64
52:54:00:00:71:01 > 52:54:00:00:71:02, ethertype IPv4 (0x0800), length 148: 198.51.100.2.47755 > 203.0.113.2.4789: VXLAN, flags [I] (0x08), vni 100
96:6b:a3:79:75:aa > ca:2e:ce:6e:53:49, ethertype IPv4 (0x0800), length 98: 172.16.0.2 > 172.16.0.1: ICMP echo reply, id 26447, seq 1, length 64
4 packets captured
4 packets received by filter
0 packets dropped by kernel
```

Quatro pacotes, cada um impresso em duas linhas: o quadro externo, da interface real de `hq` para o
roteador do provedor, e o quadro dentro dele. **O primeiro levava um broadcast ARP**,
`ff:ff:ff:ff:ff:ff`, perguntando quem tem `172.16.0.2`; `branch` respondeu, e o ping e a resposta vieram
em seguida. Um broadcast atravessando um provedor é justamente o que nenhum túnel anterior conseguia
fazer, e é o que faz das duas pontas um só segmento. O `ttl=64` da resposta diz o mesmo: nenhum roteador
ficou entre as duas pontas, até onde o pacote interno consegue saber.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 198\" role=\"img\" aria-label=\"Um quadro desenhado como uma fileira de cabeçalhos, o ping capturado de 148 bytes: um cabeçalho Ethernet externo de 14 bytes, um IP externo de 20, UDP para a porta 4789 de 8, um cabeçalho VXLAN de 8, depois o próprio quadro de hq de 98 bytes intacto, um cabeçalho Ethernet interno de 14 e o pacote IP com a mensagem ICMP de 84. O pacote IP externo, do cabeçalho IP externo até o fim, tem 134 bytes, e é o que o MTU de 1500 do enlace conta. Os cabeçalhos IP externo, UDP, VXLAN e Ethernet interno somam 50 bytes na frente do pacote IP interno, então o pacote interno pode ter no máximo 1500 menos 50, 1450 bytes.\"><text x=\"20\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">O ping capturado pelo vx0: um quadro de 148 bytes no fio</text><rect x=\"20\" y=\"64\" width=\"104\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"72.0\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Ethernet externo</text><text x=\"72.0\" y=\"93\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">14 bytes</text><rect x=\"128\" y=\"64\" width=\"84\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"170.0\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">IP externo</text><text x=\"170.0\" y=\"93\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">20 bytes</text><rect x=\"216\" y=\"64\" width=\"80\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"256.0\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">UDP 4789</text><text x=\"256.0\" y=\"93\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">8 bytes</text><rect x=\"300\" y=\"64\" width=\"70\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"335.0\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">VXLAN</text><text x=\"335.0\" y=\"93\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">8 bytes</text><rect x=\"374\" y=\"64\" width=\"104\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"426.0\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Ethernet interno</text><text x=\"426.0\" y=\"93\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">14 bytes</text><rect x=\"482\" y=\"64\" width=\"180\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"572.0\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">IP + ICMP</text><text x=\"572.0\" y=\"93\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">84 bytes</text><path d=\"M374 61 L374 56 L662 56 L662 61\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"518.0\" y=\"47\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o quadro do próprio hq, 98 bytes, intacto</text><path d=\"M128 111 L128 116 L662 116 L662 111\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"395.0\" y=\"127\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o pacote IP externo, 134 bytes: o que o MTU de 1500 do enlace conta</text><path d=\"M128 143 L128 148 L478 148 L478 143\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"303.0\" y=\"159\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">50 bytes na frente do pacote IP interno: 1500 − 50 = 1450</text><rect x=\"20\" y=\"177\" width=\"14\" height=\"10\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"40\" y=\"182\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">posto pelo VXLAN</text><rect x=\"190\" y=\"177\" width=\"14\" height=\"10\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"210\" y=\"182\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o quadro que o vx0 enviou</text></svg>", "caption": "O custo é de 50 bytes seja qual for a conta: 148 − 98 no fio, 134 − 84 em IP. O cabeçalho Ethernet interno é o motivo de o MTU do vx0 ser 1450, e não 1464.", "same": ["VXLAN", "IP + ICMP"]}
```

O último comando mostra como o `vx0` sabe para onde mandar um quadro:

```
ana@hq:~$ ip neigh show dev vx0; bridge fdb show dev vx0
172.16.0.2 lladdr 96:6b:a3:79:75:aa REACHABLE 
96:6b:a3:79:75:aa dst 198.51.100.2 self 
00:00:00:00:00:00 dst 198.51.100.2 via eth1 self permanent
```

A tabela de encaminhamento é a tabela MAC de um switch, vista em `networks-addressing`, com uma
diferença: **cada entrada aponta não para uma porta, e sim para o endereço público da outra ponta.**
`96:6b:a3:79:75:aa` foi aprendido da resposta e mora atrás de `198.51.100.2`. A entrada de zeros é a
lista de inundação, para onde vai um broadcast ou um destino desconhecido. Com mais sites haveria uma
linha dessas por site, e um broadcast seria copiado para cada um.

**Nada disso vai cifrado.** O provedor leu o pedido ARP e o ping tão facilmente quanto leu o GRE da aula
1. O VXLAN foi feito para data centers, sobre enlaces que o operador controla; atravessando uma rede que
você não controla, ele vai dentro de IPsec ou de outro túnel cifrado, e paga os dois custos.
