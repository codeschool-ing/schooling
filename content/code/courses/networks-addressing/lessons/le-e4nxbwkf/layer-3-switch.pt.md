---
title: O switch de camada 3, e mudar um gateway de lugar
version: 1
---

Um **switch de camada 3** é um switch que também roteia entre as próprias VLANs. A descrição de
costume, "um switch e um roteador numa caixa", chega perto, e a parte que ela deixa de fora é a útil:
**o roteador de dentro não tem cabo nenhum até o switch**. Ele tem uma interface por VLAN, presa
direto às VLANs do switch, então um pacote roteado da VLAN 10 para a VLAN 20 nunca sai da caixa e
nunca cruza um tronco duas vezes. Essas interfaces se chamam **SVIs** (*switched virtual interfaces*,
interfaces virtuais comutadas), e um switch Cisco as escreve `interface Vlan10`.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 244\" role=\"img\" aria-label=\"Um switch de camada 3, desenhado como uma caixa, sw1. Dentro, no alto, o roteamento entre VLANs. Abaixo, duas interfaces virtuais comutadas: vlan10 com 10.20.10.1 e vlan20 com 10.20.20.1. As duas se ligam direto ao br0, o próprio switch, que leva as VLANs 10 e 20. Fora da caixa, pc1 em 10.20.10.21 e srv em 10.20.10.10 estão em portas da VLAN 10, e pc2 em 10.20.20.22 numa porta da VLAN 20. Nenhum cabo liga a parte de roteador à parte de switch.\"><defs><marker id=\"v22v-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"680\" height=\"158\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"32\" y=\"34\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">sw1, uma caixa</text><line x1=\"300\" y1=\"66\" x2=\"210\" y2=\"86\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></line><line x1=\"420\" y1=\"66\" x2=\"510\" y2=\"86\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></line><line x1=\"210\" y1=\"120\" x2=\"210\" y2=\"136\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></line><line x1=\"510\" y1=\"120\" x2=\"510\" y2=\"136\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></line><rect x=\"270\" y=\"34\" width=\"180\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">roteamento entre VLANs</text><rect x=\"120\" y=\"86\" width=\"180\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"210\" y=\"103\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">vlan10  10.20.10.1</text><rect x=\"420\" y=\"86\" width=\"180\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"510\" y=\"103\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">vlan20  10.20.20.1</text><rect x=\"40\" y=\"136\" width=\"640\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">br0: o switch, levando as VLANs 10 e 20</text><line x1=\"140\" y1=\"168\" x2=\"140\" y2=\"196\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></line><rect x=\"60\" y=\"196\" width=\"160\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"140\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">pc1  10.20.10.21</text><line x1=\"310\" y1=\"168\" x2=\"310\" y2=\"196\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></line><rect x=\"230\" y=\"196\" width=\"160\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"310\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">srv  10.20.10.10</text><line x1=\"580\" y1=\"168\" x2=\"580\" y2=\"196\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></line><rect x=\"500\" y=\"196\" width=\"160\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"580\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">pc2  10.20.20.22</text></svg>", "caption": "Um switch de camada 3. O roteador de dentro tem uma interface por VLAN, ligada direto às VLANs do próprio switch, então um pacote roteado nunca sai da caixa."}
```

Para que o switch fosse o único roteador do laboratório, a ponta do cabo do lado do r1 foi
desativada antes deste bloco, o que a aula não mostra. O ping do pc1 ao pc2 falha de novo, como deve
ser sem roteador nenhum:

```
ana@pc1:~$ ping -c 1 -W 1 -q 10.20.20.22
PING 10.20.20.22 (10.20.20.22) 56(84) bytes of data.

--- 10.20.20.22 ping statistics ---
1 packets transmitted, 0 received, 100% packet loss, time 0ms

```

Então o sw1 ganha uma interface em cada VLAN, os endereços que o r1 tinha, e permissão para
encaminhar:

```
root@sw1:~# ip link add link br0 name vlan10 type vlan id 10
root@sw1:~# ip link add link br0 name vlan20 type vlan id 20
root@sw1:~# bridge vlan add dev br0 vid 10 self && bridge vlan add dev br0 vid 20 self
root@sw1:~# ip addr add 10.20.10.1/24 dev vlan10 && ip addr add 10.20.20.1/24 dev vlan20
root@sw1:~# ip link set vlan10 up && ip link set vlan20 up && sysctl -w net.ipv4.ip_forward=1
net.ipv4.ip_forward = 1
root@sw1:~# ip route
10.20.10.0/24 dev vlan10 proto kernel scope link src 10.20.10.1 
10.20.20.0/24 dev vlan20 proto kernel scope link src 10.20.20.1 
```

`vlan10` e `vlan20` são interfaces de VLAN de novo, do mesmo tipo que o r1 usou, montadas desta vez
sobre o `br0`, o próprio switch. O terceiro comando importa e é fácil de não ver: **o `br0` também
tem de entrar nas VLANs 10 e 20** (`self` quer dizer a porta da própria bridge, e não um dos cabos
dela), porque nas listagens da aula 19 ele estava só na VLAN 1, e as interfaces do próprio switch só
ouvem as VLANs em que o switch entrou. `sysctl -w net.ipv4.ip_forward=1` é a linha que transforma um
host com dois endereços num roteador; o r1 já a tinha do laboratório, e o switch não. A tabela de
rotas tem as mesmas duas rotas conectadas que o r1 tinha, agora na `vlan10` e na `vlan20`.

Tudo no lugar, e o primeiro teste falha:

```
ana@pc1:~$ ping -c 2 -q 10.20.20.22
PING 10.20.20.22 (10.20.20.22) 56(84) bytes of data.

--- 10.20.20.22 ping statistics ---
2 packets transmitted, 0 received, 100% packet loss, time 1043ms

ana@pc1:~$ ip neigh show 10.20.10.1
10.20.10.1 dev eth0 lladdr 02:1f:23:e7:e9:d5 STALE 
root@sw1:~# ip -br link show vlan10
vlan10@br0       UP             02:6a:dc:93:3b:8a <BROADCAST,MULTICAST,UP,LOWER_UP> 
```

Dois enviados, nenhum recebido. **A tabela de vizinhos do pc1 ainda diz que 10.20.10.1 está em
`02:1f:23:e7:e9:d5`, que é o MAC do r1**, o mesmo que as duas últimas seções viram no tronco. A
`vlan10` do switch está em `02:6a:dc:93:3b:8a`. Então o pc1 faz exatamente o que a tabela manda:
manda os quadros do gateway para um MAC que nada no switch atende mais. O endereço mudou de máquina;
o cache de cada host da VLAN não mudou junto.

A entrada diz `STALE`, que quer dizer que o kernel vai conferi-la antes de confiar nela por muito
tempo, e um host deixado em paz se corrige quando a conferência com o MAC antigo falha. Uma rede não
precisa esperar por isso. **O novo dono de um endereço se anuncia com um ARP gratuito**: uma mensagem
ARP sobre o próprio endereço, mandada à VLAN inteira sem ninguém pedir, dizendo que MAC agora o tem.

```
root@sw1:~# arping -U -c 1 -I vlan10 10.20.10.1
ARPING 10.20.10.1 from 10.20.10.1 vlan10
Sent 1 probes (1 broadcast(s))
Received 0 response(s)
ana@pc1:~$ ip neigh show 10.20.10.1
10.20.10.1 dev eth0 lladdr 02:6a:dc:93:3b:8a STALE 
ana@pc1:~$ ping -c 2 -q 10.20.20.22
PING 10.20.20.22 (10.20.20.22) 56(84) bytes of data.

--- 10.20.20.22 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1004ms
rtt min/avg/max/mdev = 1.041/9.526/18.011/8.485 ms
ana@pc1:~$ traceroute -n 10.20.20.22
traceroute to 10.20.20.22 (10.20.20.22), 30 hops max, 60 byte packets
 1  10.20.10.1  4.508 ms  0.405 ms  0.212 ms
 2  10.20.20.22  1.100 ms  0.477 ms  0.208 ms
```

O `arping -U` manda esse anúncio não solicitado. `Received 0 response(s)` está certo, porque ninguém
responde a um anúncio. A tabela do pc1 agora tem `02:6a:dc:93:3b:8a`, ainda `STALE`: o Linux registra
um endereço que não pediu, mas só o marca como confirmado quando o usa. O próximo ping passa, e o
traceroute mostra os mesmos dois saltos de antes, com **10.20.10.1 agora respondendo de dentro do
switch**.

Qualquer mudança que leve um endereço de gateway para outro MAC, inclusive trocar um roteador com
defeito por um reserva, esbarra nos mesmos caches velhos. Os protocolos de redundância de primeiro
salto, como o VRRP, evitam o problema por construção: o endereço do gateway mantém um MAC virtual
qualquer que seja o roteador que o tem, então nenhum cache de host fica velho, e o roteador que
assume manda um ARP gratuito para que os switches aprendam atrás de que porta esse MAC vive agora.

O que o laboratório não mostra é velocidade. Um switch de camada 3 comercial roteia entre VLANs no
hardware de encaminhamento, perto da velocidade com que comuta; a bridge do Linux aqui roteia no
mesmo kernel que todo o resto, e os tempos das capturas não dizem nada sobre equipamento real.
