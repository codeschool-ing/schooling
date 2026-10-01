---
title: O que a operadora vê do túnel
version: 1
---

Uma VPN recebe a confiança de carregar tráfego pela rede de outra pessoa, então ela merece ser
conferida em vez de acreditada. A conferência é simples: **escute no cabo da operadora enquanto o túnel
está em uso**, depois escute dentro do túnel, e compare.

## No cabo da operadora

Na `isp`, o `tcpdump` ficou escutando na `eth0`, o cabo até a matriz, à espera de quatro pacotes.
Enquanto isso, o pc1 pingou o pc2 duas vezes; o ping terminou primeiro, então a saída dele aparece
primeiro, e a do tcpdump depois:

```
ana@pc1:~$ ping -c 2 10.30.10.22
PING 10.30.10.22 (10.30.10.22) 56(84) bytes of data.
64 bytes from 10.30.10.22: icmp_seq=1 ttl=62 time=31.6 ms
64 bytes from 10.30.10.22: icmp_seq=2 ttl=62 time=5.89 ms

--- 10.30.10.22 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1004ms
rtt min/avg/max/mdev = 5.885/18.728/31.571/12.843 ms
root@isp:~# timeout 6 tcpdump -n -c 4 -i eth0
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on eth0, link-type EN10MB (Ethernet), snapshot length 262144 bytes
15:21:22.930237 IP 203.0.113.2.51820 > 198.51.100.2.51820: UDP, length 128
15:21:22.941353 IP 198.51.100.2.51820 > 203.0.113.2.51820: UDP, length 128
15:21:23.916676 IP 203.0.113.2.51820 > 198.51.100.2.51820: UDP, length 128
15:21:23.918704 IP 198.51.100.2.51820 > 203.0.113.2.51820: UDP, length 128
4 packets captured
4 packets received by filter
0 packets dropped by kernel
```

Quatro pacotes para dois pings: dois echo requests e duas respostas. Isto é tudo o que a operadora ficou
sabendo sobre eles:

- **dois endereços públicos**, `203.0.113.2` e `198.51.100.2` — os roteadores dos dois escritórios;
- **uma porta**, 51820 nas duas pontas, e o protocolo, UDP;
- **um tamanho**, `length 128`, o mesmo para todo pacote;
- **os horários**, `15:21:22.930237` para o primeiro e `15:21:22.941353` para a resposta dele.

Fora da lista: o pc1, o pc2, os endereços privados deles, a palavra ICMP, ou qualquer byte do que o ping
carregava. A operadora não distingue um ping de uma transferência de arquivo, a não ser pelos tamanhos e
pelo ritmo.

## Dentro do túnel

A mesma escuta, agora na `wg0` do `rhq` — a ponta do túnel dentro da matriz — enquanto o pc1 pinga de
novo:

```
ana@pc1:~$ ping -c 2 10.30.10.22
PING 10.30.10.22 (10.30.10.22) 56(84) bytes of data.
64 bytes from 10.30.10.22: icmp_seq=1 ttl=62 time=5.08 ms
64 bytes from 10.30.10.22: icmp_seq=2 ttl=62 time=4.62 ms

--- 10.30.10.22 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1003ms
rtt min/avg/max/mdev = 4.622/4.850/5.079/0.228 ms
root@rhq:~# timeout 6 tcpdump -n -c 4 -i wg0
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on wg0, link-type RAW (Raw IP), snapshot length 262144 bytes
15:21:27.606623 IP 10.20.10.21 > 10.30.10.22: ICMP echo request, id 56, seq 1, length 64
15:21:27.610556 IP 10.30.10.22 > 10.20.10.21: ICMP echo reply, id 56, seq 1, length 64
15:21:28.608540 IP 10.20.10.21 > 10.30.10.22: ICMP echo request, id 56, seq 2, length 64
15:21:28.612236 IP 10.30.10.22 > 10.20.10.21: ICMP echo reply, id 56, seq 2, length 64
4 packets captured
4 packets received by filter
0 packets dropped by kernel
```

**Aqui tudo está às claras**: `10.20.10.21 > 10.30.10.22: ICMP echo request`, números de sequência,
tamanhos. `link-type RAW (Raw IP)` diz que não há nem cabeçalho Ethernet: a `wg0` leva pacotes IP puros,
porque um túnel não tem endereços MAC para pôr num.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 262\" role=\"img\" aria-label=\"Duas fileiras de caixas, desenhadas em escala de bytes. A fileira de cima é um pacote como a isp o vê: um cabeçalho IP de 20 bytes de 203.0.113.2 para 198.51.100.2, um cabeçalho UDP de 8 bytes da porta 51820 para a porta 51820, e depois os 128 bytes que o UDP carrega: um cabeçalho WireGuard de 16 bytes, 96 bytes cifrados e uma tag de autenticação de 16 bytes. A fileira de baixo é o mesmo pacote como a wg0 do rhq o vê, embaixo da parte cifrada: um cabeçalho IP de 20 bytes de 10.20.10.21 para 10.30.10.22, um cabeçalho ICMP de 8 bytes e 56 bytes de dados, 84 ao todo, mais 12 bytes de enchimento que fazem 96.\"><text x=\"24\" y=\"14\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">O que o tcpdump na isp imprimiu para um pacote:</text><text x=\"24\" y=\"32\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">IP 203.0.113.2.51820 &gt; 198.51.100.2.51820: UDP, length 128</text><rect x=\"24.0\" y=\"74\" width=\"86.0\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"67.0\" y=\"89\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">IP</text><text x=\"67.0\" y=\"105\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">20</text><rect x=\"110.0\" y=\"74\" width=\"34.4\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"127.2\" y=\"89\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">UDP</text><text x=\"127.2\" y=\"105\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">8</text><rect x=\"144.4\" y=\"74\" width=\"68.8\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"178.8\" y=\"89\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">cabeçalho</text><text x=\"178.8\" y=\"105\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">16</text><rect x=\"213.2\" y=\"74\" width=\"412.8\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"419.6\" y=\"89\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">cifrado: o pacote de baixo, completado</text><text x=\"419.6\" y=\"105\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">96</text><rect x=\"626.0\" y=\"74\" width=\"68.8\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"660.4\" y=\"89\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">tag</text><text x=\"660.4\" y=\"105\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">16</text><path d=\"M144.4 62 L144.4 56 L694.8 56 L694.8 62\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"419.6\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">length 128: o que o UDP carrega</text><path d=\"M213.2 118 L213.2 164\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\"></path><path d=\"M626.0 118 L626.0 164\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\"></path><rect x=\"213.2\" y=\"164\" width=\"86.0\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"256.2\" y=\"179\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">IP</text><text x=\"256.2\" y=\"195\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">20</text><rect x=\"299.2\" y=\"164\" width=\"34.4\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"316.4\" y=\"179\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">ICMP</text><text x=\"316.4\" y=\"195\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">8</text><rect x=\"333.6\" y=\"164\" width=\"240.8\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"454.0\" y=\"179\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">dados</text><text x=\"454.0\" y=\"195\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">56</text><rect x=\"574.4\" y=\"164\" width=\"51.6\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"600.2\" y=\"179\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">+12</text><text x=\"213.2\" y=\"226\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">O que o tcpdump na wg0 do rhq imprimiu para o mesmo pacote:</text><text x=\"213.2\" y=\"244\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">IP 10.20.10.21 &gt; 10.30.10.22: ICMP echo request</text></svg>", "caption": "Um ping, duas vezes. O pacote de 84 bytes que o pc1 enviou é completado até 96 bytes e cifrado; o WireGuard põe 16 bytes na frente e uma tag de 16 bytes atrás, que são os 128 que o tcpdump imprimiu na isp. Só os dois cabeçalhos de fora podem ser lidos no caminho.", "same": ["tag"]}
```

Os 128 bytes não são um mistério. O pacote que o pc1 enviou tem 84 bytes: um cabeçalho IP de 20 bytes,
um cabeçalho ICMP de 8 bytes e os 56 bytes de dados que o `56(84)` anunciou na primeira linha do ping.
O WireGuard o completa até 96 e o cifra, põe na frente um cabeçalho próprio de 16 bytes e atrás uma tag
de autenticação de 16 bytes: 16 + 96 + 16 = 128. Um pacote maior produz um datagrama maior, então **o
tamanho é uma das coisas que uma VPN não esconde**.

## O que a cifra protege, e de quem

**O túnel protege o tráfego do caminho, não das pontas.** A operadora, e qualquer um escutando em
qualquer cabo entre os dois roteadores, vê a primeira captura. Quem controla o `rhq`, o `rbr`, o pc1 ou
o pc2 vê a segunda. Então uma VPN é a resposta certa para "a rede da operadora não é nossa", e resposta
nenhuma para "alguém tem um shell no nosso roteador".

O que o caminho ainda descobre vale ser dito com todas as letras, porque é a parte que as pessoas
esquecem: **quais duas sedes conversam, quando, e quanto**. Isso se chama metadado, e num link entre uma
matriz e uma filial ele é quase inofensivo. Numa VPN de acesso remoto, ele conta à rede que a carrega onde
uma pessoa estava e quando trabalhou.

Dois hábitos decorrem disso para quem faz suporte:

- **Teste um túnel por fora além de por dentro.** Um ping que funciona mostra que o túnel leva tráfego.
  Uma captura na interface de fora mostra que ele leva *só* tráfego cifrado — e uma captura que mostrasse
  ICMP entre endereços privados do lado da operadora queria dizer que o tráfego estava contornando o
  túnel, não passando por ele.
- **Proteja as pontas.** As chaves moram nos roteadores, e a aula 6 acrescenta o resto: um roteador cuja
  configuração ninguém anotou é um roteador que ninguém consegue reconstruir.
