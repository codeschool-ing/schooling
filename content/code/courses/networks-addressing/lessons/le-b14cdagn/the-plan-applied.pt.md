---
title: O plano, montado
version: 1
---

Um plano no papel vira rede em poucas linhas: um endereço, com a sua máscara, em cada interface do
roteador. O laboratório desta aula é o plano montado. O r1 tem um cabo para cada uma das três LANs e
um para o r2, e atrás do r2 fica o hq1, um PC na matriz de onde parte cada teste desta aula:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 226\" role=\"img\" aria-label=\"O laboratório desta aula. Três PCs, cada um na sua LAN ligada ao roteador r1: sales1, 10.20.32.10, na /25 de vendas, alcançada pela eth1 do r1 com gateway .1; eng1, 10.20.32.140, na /26 de engenharia, pela eth2 com gateway .129; e ops1, 10.20.32.200, na /27 de operações, pela eth3 com gateway .193. O r1 se liga ao r2 pelo enlace 10.20.32.224/30, o r1 no .225 e o r2 no .226. O r2 tem uma rota, o /24, para tudo isso, e atrás do r2, em 10.20.99.0/24, fica o hq1 em 10.20.99.10.\"><rect x=\"20\" y=\"20\" width=\"180\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"35\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">sales1  10.20.32.10</text><text x=\"30\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">vendas, /25</text><line x1=\"200\" y1=\"42\" x2=\"330\" y2=\"42\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></line><text x=\"265\" y=\"33\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">eth1 .1</text><rect x=\"20\" y=\"90\" width=\"180\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"105\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">eng1  10.20.32.140</text><text x=\"30\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">engenharia, /26</text><line x1=\"200\" y1=\"112\" x2=\"330\" y2=\"112\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></line><text x=\"265\" y=\"103\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">eth2 .129</text><rect x=\"20\" y=\"160\" width=\"180\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"175\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">ops1  10.20.32.200</text><text x=\"30\" y=\"192\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">operações, /27</text><line x1=\"200\" y1=\"182\" x2=\"330\" y2=\"182\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></line><text x=\"265\" y=\"173\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">eth3 .193</text><rect x=\"330\" y=\"28\" width=\"120\" height=\"168\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"390\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">r1</text><text x=\"390\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">roteador</text><line x1=\"450\" y1=\"112\" x2=\"540\" y2=\"112\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></line><text x=\"456\" y=\"102\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">.225</text><text x=\"534\" y=\"102\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">.226</text><text x=\"495\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">10.20.32.224/30</text><rect x=\"540\" y=\"86\" width=\"110\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"595\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">r2</text><text x=\"595\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">uma rota: /24</text><line x1=\"595\" y1=\"138\" x2=\"595\" y2=\"168\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></line><text x=\"603\" y=\"153\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.20.99.0/24</text><rect x=\"540\" y=\"168\" width=\"110\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"550\" y=\"183\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">hq1</text><text x=\"550\" y=\"200\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10.20.99.10</text></svg>", "caption": "O plano montado: três LANs e um /30 nas quatro interfaces do r1, e o r2 alcançando todas por uma rota só."}
```

O gateway de cada LAN fica com o primeiro endereço de host da sua sub-rede, o que é um costume e não
uma regra, mas um que vale manter: o gateway é o endereço que as pessoas mais digitam, e .1, .129 e
.193 saem do plano sem precisar consultar nada.

| rede | sub-rede | interface do r1 | gateway | o PC no laboratório |
|---|---|---|---|---|
| vendas | 10.20.32.0/25 | eth1 | 10.20.32.1 | sales1, .10 |
| engenharia | 10.20.32.128/26 | eth2 | 10.20.32.129 | eng1, .140 |
| operações | 10.20.32.192/27 | eth3 | 10.20.32.193 | ops1, .200 |
| enlace com o r2 | 10.20.32.224/30 | eth0 | — | r2, .226 |

Aqui está o r1, como foi montado:

```
root@r1:~# ip -br addr
lo               UNKNOWN        127.0.0.1/8 ::1/128 
eth1@if194       UP             10.20.32.1/25 fe80::a6:80ff:fe20:1354/64 
eth2@if196       UP             10.20.32.129/26 fe80::26:62ff:fe13:4f3c/64 
eth3@if198       UP             10.20.32.193/27 fe80::e3:72ff:fe9b:b7c2/64 
eth0@if199       UP             10.20.32.225/30 fe80::1f:23ff:fee7:e9d5/64 
root@r1:~# ip route
default via 10.20.32.226 dev eth0 
10.20.32.0/25 dev eth1 proto kernel scope link src 10.20.32.1 
10.20.32.128/26 dev eth2 proto kernel scope link src 10.20.32.129 
10.20.32.192/27 dev eth3 proto kernel scope link src 10.20.32.193 
10.20.32.224/30 dev eth0 proto kernel scope link src 10.20.32.225 
```

**Ninguém digitou uma rota para nenhuma das quatro sub-redes.** Cada linha `proto kernel scope link`
apareceu quando o endereço foi configurado, porque um endereço com máscara diz qual rede está naquele
cabo. É também por isso que uma máscara errada custa tão caro: a rota vem da máscara, e a aula 12
mostrou um /24 digitado no lugar de um /25 fazendo um PC procurar as máquinas de outra sub-rede no
próprio cabo. A única rota que alguém digitou é a padrão, em direção ao r2 em 10.20.32.226, para tudo
o que não é uma das sub-redes do próprio r1.

O r2 fica acima, e esta é a tabela inteira dele:

```
root@r2:~# ip route
10.20.32.0/24 via 10.20.32.225 dev eth0 
10.20.32.224/30 dev eth0 proto kernel scope link src 10.20.32.226 
10.20.99.0/24 dev eth1 proto kernel scope link src 10.20.99.1 
```

Três LANs atrás do r1, e **o r2 alcança todas com uma linha**, `10.20.32.0/24 via 10.20.32.225`. O
r2 não sabe que a empresa tem um /25, um /26 e um /27; sabe que tudo em 10.20.32.0/24 é assunto do
r1, e o r1 resolve. Essa rota única é um resumo, e a próxima seção trata do que ela compra e do que
ela custa.

Agora o teste que importa, a partir do hq1, do outro lado dos dois roteadores:

```
ana@hq1:~$ ping -c 1 -q 10.20.32.10
PING 10.20.32.10 (10.20.32.10) 56(84) bytes of data.

--- 10.20.32.10 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 1ms
rtt min/avg/max/mdev = 10.249/10.249/10.249/0.000 ms
ana@hq1:~$ ping -c 1 -q 10.20.32.140
PING 10.20.32.140 (10.20.32.140) 56(84) bytes of data.

--- 10.20.32.140 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 1ms
rtt min/avg/max/mdev = 2.809/2.809/2.809/0.000 ms
ana@hq1:~$ ping -c 1 -q 10.20.32.200
PING 10.20.32.200 (10.20.32.200) 56(84) bytes of data.

--- 10.20.32.200 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 1ms
rtt min/avg/max/mdev = 2.080/2.080/2.080/0.000 ms
ana@hq1:~$ traceroute -n 10.20.32.200
traceroute to 10.20.32.200 (10.20.32.200), 30 hops max, 60 byte packets
 1  10.20.99.1  4.096 ms  0.420 ms  0.190 ms
 2  10.20.32.225  0.557 ms  0.215 ms  0.223 ms
 3  10.20.32.200  0.889 ms  0.304 ms  0.451 ms
```

Um pacote para cada LAN, e um de volta de cada. O traceroute mostra o caminho em três saltos: o r2,
que responde do seu endereço do lado do hq1, 10.20.99.1; depois o r1, da sua ponta do enlace,
10.20.32.225; depois o próprio ops1. Os tempos de ida e volta são o computador único deste laboratório
falando consigo mesmo, e não dizem nada sobre uma rede.

**Cada endereço daquele traceroute foi decidido pelo plano**, até qual ponta do /30 é do r1. Escrever
a tabela acima antes de digitar um único comando é o que deixou a montagem com poucas linhas, e é o
documento de que alguém vai precisar no dia em que uma dessas sub-redes tiver de crescer.
