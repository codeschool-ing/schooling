---
title: Digitando uma rota, e vendo-a falhar
version: 1
---

O laboratório são três roteadores em linha, um PC em cada ponta, e um cabo reserva de r1 direto até r3
que esta seção ignora. **Cada roteador começa com suas rotas conectadas e mais nada**, e toda outra rota
da aula é digitada.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 215\" role=\"img\" aria-label=\"O laboratório desta aula, três roteadores em linha. pc1, 10.20.1.10, fica em 10.20.1.0/24 atrás de r1. r1 se liga a r2 por 10.20.12.0/30 (r1 é 10.20.12.1, r2 é 10.20.12.2), e r2 se liga a r3 por 10.20.23.0/30 (r2 é 10.20.23.1, r3 é 10.20.23.2). pc3, 10.20.3.10, fica em 10.20.3.0/24 atrás de r3. Um cabo reserva, 10.20.13.0/30, vai de r1 (10.20.13.1) direto a r3 (10.20.13.2).\"><defs><marker id=\"ch-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"10\" y=\"30\" width=\"100\" height=\"74\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"20\" y=\"44\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pc1</text><text x=\"20\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.20.1.10</text><rect x=\"150\" y=\"30\" width=\"118\" height=\"74\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"160\" y=\"44\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">r1</text><text x=\"160\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">eth0 10.20.1.1</text><text x=\"160\" y=\"77\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">eth1 10.20.12.1</text><text x=\"160\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">eth3 10.20.13.1</text><rect x=\"300\" y=\"30\" width=\"118\" height=\"74\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"310\" y=\"44\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">r2</text><text x=\"310\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">eth1 10.20.12.2</text><text x=\"310\" y=\"77\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">eth2 10.20.23.1</text><rect x=\"450\" y=\"30\" width=\"118\" height=\"74\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"460\" y=\"44\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">r3</text><text x=\"460\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">eth2 10.20.23.2</text><text x=\"460\" y=\"77\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">eth3 10.20.13.2</text><text x=\"460\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">eth0 10.20.3.1</text><rect x=\"610\" y=\"30\" width=\"100\" height=\"74\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"620\" y=\"44\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pc3</text><text x=\"620\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.20.3.10</text><path d=\"M110 67 L150 67\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M268 67 L300 67\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M418 67 L450 67\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M568 67 L610 67\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"130\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.20.1.0/24</text><text x=\"284\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.20.12.0/30</text><text x=\"434\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.20.23.0/30</text><text x=\"589\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.20.3.0/24</text><path d=\"M209 104 L209 170 L509 170 L509 104\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"359\" y=\"184\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.20.13.0/30</text><text x=\"359\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o cabo reserva</text></svg>", "caption": "O laboratório desta aula. Cada roteador começa só com suas redes conectadas; toda outra rota é digitada."}
```

r1 conhece as três redes que seus cabos tocam. pc1 pede a ele o pc3, e r1 não tem nenhuma linha que
case com `10.20.3.10`, então diz isso:

```
root@r1:~# ip route
10.20.1.0/24 dev eth0 proto kernel scope link src 10.20.1.1 
10.20.12.0/30 dev eth1 proto kernel scope link src 10.20.12.1 
10.20.13.0/30 dev eth3 proto kernel scope link src 10.20.13.1 
ana@pc1:~$ ping -c 1 -W 1 10.20.3.10
PING 10.20.3.10 (10.20.3.10) 56(84) bytes of data.
From 10.20.1.1 icmp_seq=1 Destination Net Unreachable

--- 10.20.3.10 ping statistics ---
1 packets transmitted, 0 received, +1 errors, 100% packet loss, time 0ms

```

`Destination Net Unreachable` vindo de `10.20.1.1` é r1 recusando, a mesma mensagem que a aula 14
encontrou. A correção parece óbvia: dizer a r1 onde fica `10.20.3.0/24`, e dizer a r2 também, já que r1
vai entregar o pacote a r2.

No Linux o comando é `ip route add REDE via PRÓXIMO-SALTO`. **O próximo salto tem de ser um endereço
numa rede à qual este roteador está conectado**, porque o roteador vai descobrir o MAC dele com ARP e
colocar o quadro naquele cabo. r1 alcança r2 em `10.20.12.2`, a outra ponta do `/30` que os dois
compartilham; r2 alcança r3 em `10.20.23.2`:

```
root@r1:~# ip route add 10.20.3.0/24 via 10.20.12.2
root@r2:~# ip route add 10.20.3.0/24 via 10.20.23.2
ana@pc1:~$ ping -c 1 -W 2 10.20.3.10
PING 10.20.3.10 (10.20.3.10) 56(84) bytes of data.

--- 10.20.3.10 ping statistics ---
1 packets transmitted, 0 received, 100% packet loss, time 1ms

```

Nenhum erro desta vez, e nenhuma resposta também: um pacote enviado, nenhum recebido, e **nada que
explique por quê**. Do ponto de vista de pc1, isso é indistinguível de pc3 desligado.

Enquanto isso, um `tcpdump` rodava em pc3, e imprimiu sua captura quando terminou:

```
root@pc3:~# timeout 6 tcpdump -n -i eth0 -c 3 icmp
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on eth0, link-type EN10MB (Ethernet), snapshot length 262144 bytes
08:35:23.124898 IP 10.20.1.10 > 10.20.3.10: ICMP echo request, id 37, seq 1, length 64
08:35:23.126700 IP 10.20.3.10 > 10.20.1.10: ICMP echo reply, id 37, seq 1, length 64
08:35:23.127054 IP 10.20.3.1 > 10.20.3.10: ICMP net 10.20.1.10 unreachable, length 92
3 packets captured
3 packets received by filter
0 packets dropped by kernel
```

Leia as três linhas em ordem. O pedido **chegou**, então as duas rotas funcionaram. pc3 **respondeu**,
então pc3 está bem. Depois `10.20.3.1`, que é r3, mandou a pc3 `ICMP net 10.20.1.10 unreachable`: r3
tinha uma resposta para `10.20.1.10` e nenhuma rota para `10.20.1.0/24`. **O erro foi para quem enviou o
pacote que r3 não conseguiu entregar, e quem enviou foi pc3**, então pc1 nunca soube.

Esse é o erro mais comum com rotas estáticas, e a captura mostra por que ele confunde tanto: o lado que
percebe a falha é o lado para o qual ninguém está olhando. Quando um ping entre duas redes falha em
silêncio, olhe a outra ponta antes de culpar o caminho de ida.

## A mesma rota em outros equipamentos

A ideia é a mesma em todo lugar, e só a grafia muda. Nenhuma destas foi executada neste laboratório:

| onde | a rota de que r1 precisa |
|---|---|
| Linux, como acima | `ip route add 10.20.3.0/24 via 10.20.12.2` |
| vtysh do FRR, `configure terminal` | `ip route 10.20.3.0/24 10.20.12.2` |
| Cisco IOS, `configure terminal` | `ip route 10.20.3.0 255.255.255.0 10.20.12.2` |

**Uma rota adicionada com `ip route add` dura até a máquina reiniciar.** Um roteador Linux de verdade
guarda suas rotas na configuração de rede, e um roteador com FRR ou IOS as guarda na configuração salva,
e é por isso que a segunda e a terceira linhas são as que você encontra nos equipamentos.
