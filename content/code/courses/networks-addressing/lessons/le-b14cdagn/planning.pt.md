---
title: O plano, do maior para o menor
version: 1
---

Um plano VLSM tem quatro passos, e a ordem dos dois últimos é o que o mantém arrumado.

1. Liste as redes e quantos hosts cada uma precisa, já com o crescimento que você espera.
2. Some dois a cada uma e arredonde para cima até uma potência de dois. Os dois são o endereço de
   rede e o de broadcast, que nenhum host pode usar. Vendas precisa de 100: 102, arredondado para
   128, que são 7 bits de host e um /25. Os 50 da engenharia viram 52 e depois 64, um /26. Os 20 de
   operações viram 22 e depois 32, um /27. Os 2 do enlace viram 4, que já é potência de dois: um /30.
3. Ordene do maior para o menor.
4. Dê a cada uma o próximo endereço livre.

O tamanho do prefixo é 32 menos o número de bits de host: 128 endereços são 2⁷, então 7 bits de host,
então /25. Arredondar é onde o plano mais erra. Uma rede de 62 hosts cabe exatamente num /26, e uma
rede de 63 precisa de 65 endereços e de um /25. **Conte os dois que ninguém pode usar antes de
arredondar, não depois.**

O passo 4 só funciona por causa do passo 3. Uma sub-rede precisa começar num múltiplo do seu próprio
tamanho, porque o endereço de rede dela é o que tem todos os bits de host em zero. Um /26 pode começar
no .0, no .64, no .128 ou no .192, e em nenhum outro lugar. Quando os tamanhos entram do maior para o
menor, cada um termina onde um menor tem permissão para começar, então **as sub-redes se encaixam
umas nas outras sem nenhum vão entre elas**. Aqui está o ipcalc fazendo exatamente isso: `-s` recebe
as quantidades de hosts e divide o bloco na ordem dada.

```
ana@hq1:~$ ipcalc 10.20.32.0/24 -s 100 50 20 2
Address:   10.20.32.0           00001010.00010100.00100000. 00000000
Netmask:   255.255.255.0 = 24   11111111.11111111.11111111. 00000000
Wildcard:  0.0.0.255            00000000.00000000.00000000. 11111111
=>
Network:   10.20.32.0/24        00001010.00010100.00100000. 00000000
HostMin:   10.20.32.1           00001010.00010100.00100000. 00000001
HostMax:   10.20.32.254         00001010.00010100.00100000. 11111110
Broadcast: 10.20.32.255         00001010.00010100.00100000. 11111111
Hosts/Net: 254                   Class A, Private Internet

1. Requested size: 100 hosts
Netmask:   255.255.255.128 = 25 11111111.11111111.11111111.1 0000000
Network:   10.20.32.0/25        00001010.00010100.00100000.0 0000000
HostMin:   10.20.32.1           00001010.00010100.00100000.0 0000001
HostMax:   10.20.32.126         00001010.00010100.00100000.0 1111110
Broadcast: 10.20.32.127         00001010.00010100.00100000.0 1111111
Hosts/Net: 126                   Class A, Private Internet

2. Requested size: 50 hosts
Netmask:   255.255.255.192 = 26 11111111.11111111.11111111.11 000000
Network:   10.20.32.128/26      00001010.00010100.00100000.10 000000
HostMin:   10.20.32.129         00001010.00010100.00100000.10 000001
HostMax:   10.20.32.190         00001010.00010100.00100000.10 111110
Broadcast: 10.20.32.191         00001010.00010100.00100000.10 111111
Hosts/Net: 62                    Class A, Private Internet

3. Requested size: 20 hosts
Netmask:   255.255.255.224 = 27 11111111.11111111.11111111.111 00000
Network:   10.20.32.192/27      00001010.00010100.00100000.110 00000
HostMin:   10.20.32.193         00001010.00010100.00100000.110 00001
HostMax:   10.20.32.222         00001010.00010100.00100000.110 11110
Broadcast: 10.20.32.223         00001010.00010100.00100000.110 11111
Hosts/Net: 30                    Class A, Private Internet

4. Requested size: 2 hosts
Netmask:   255.255.255.252 = 30 11111111.11111111.11111111.111111 00
Network:   10.20.32.224/30      00001010.00010100.00100000.111000 00
HostMin:   10.20.32.225         00001010.00010100.00100000.111000 01
HostMax:   10.20.32.226         00001010.00010100.00100000.111000 10
Broadcast: 10.20.32.227         00001010.00010100.00100000.111000 11
Hosts/Net: 2                     Class A, Private Internet

Needed size:  228 addresses.
Used network: 10.20.32.0/24
Unused:
10.20.32.228/30
10.20.32.232/29
10.20.32.240/28
```

Leia pedaço por pedaço: vendas é 10.20.32.0/25, hosts do .1 ao .126; engenharia é 10.20.32.128/26,
hosts do .129 ao .190; operações é 10.20.32.192/27, hosts do .193 ao .222; o enlace é
10.20.32.224/30, hosts .225 e .226. A coluna em binário mostra cada máscara andando mais um bit para
a direita, e cada rede começando onde a anterior terminou. No fim, `Needed size: 228 addresses`, a
soma 128 + 64 + 32 + 4, e os 28 endereços que sobram aparecem como os três blocos em que caem: um
/30, um /29 e um /28.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 236\" role=\"img\" aria-label=\"O bloco 10.20.32.0/24, 256 endereços, desenhado como uma barra do .0 ao .255 com o plano por cima. Vendas, 10.20.32.0/25, ocupa a primeira metade, do .0 ao .127, com 126 hosts. Engenharia, 10.20.32.128/26, ocupa do .128 ao .191, com 62 hosts. Operações, 10.20.32.192/27, ocupa do .192 ao .223, com 30 hosts. Os últimos 32 endereços, do .224 ao .255, aparecem de novo mais largos embaixo: o enlace entre r1 e r2, 10.20.32.224/30, e depois três blocos livres, 10.20.32.228/30, 10.20.32.232/29 e 10.20.32.240/28, o último com espaço para 14 hosts. 228 endereços estão planejados e 28 estão livres.\"><text x=\"20\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">10.20.32.0/24</text><text x=\"130\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">256 endereços: 228 planejados, 28 livres</text><rect x=\"20.0\" y=\"36\" width=\"340.0\" height=\"52\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"190.0\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">10.20.32.0/25</text><text x=\"190.0\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">vendas, 126 hosts</text><rect x=\"360.0\" y=\"36\" width=\"170.0\" height=\"52\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"445.0\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">10.20.32.128/26</text><text x=\"445.0\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">engenharia, 62 hosts</text><rect x=\"530.0\" y=\"36\" width=\"85.0\" height=\"52\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"572.5\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">.192/27</text><text x=\"572.5\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">30 hosts</text><rect x=\"615.0\" y=\"36\" width=\"10.62\" height=\"52\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"625.62\" y=\"36\" width=\"74.38\" height=\"52\" rx=\"1\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"3 3\"></rect><text x=\"20.0\" y=\"100\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">.0</text><text x=\"360.0\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">.128</text><text x=\"530.0\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">.192</text><text x=\"615.0\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">.224</text><text x=\"700.0\" y=\"100\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">.255</text><line x1=\"615.0\" y1=\"108\" x2=\"300\" y2=\"146\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line><line x1=\"700\" y1=\"108\" x2=\"700\" y2=\"146\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line><rect x=\"300.0\" y=\"150\" width=\"50.0\" height=\"52\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"325.0\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">/30</text><text x=\"325.0\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">enlace</text><rect x=\"350.0\" y=\"150\" width=\"50.0\" height=\"52\" rx=\"1\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"3 3\"></rect><text x=\"375.0\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">/30</text><text x=\"375.0\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">livre</text><rect x=\"400.0\" y=\"150\" width=\"100.0\" height=\"52\" rx=\"1\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"3 3\"></rect><text x=\"450.0\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">.232/29</text><text x=\"450.0\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">livre</text><rect x=\"500.0\" y=\"150\" width=\"200.0\" height=\"52\" rx=\"1\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"3 3\"></rect><text x=\"600.0\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">.240/28</text><text x=\"600.0\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">livre, 14 hosts</text><text x=\"300.0\" y=\"214\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">.224</text><text x=\"350.0\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">.228</text><text x=\"400.0\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">.232</text><text x=\"500.0\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">.240</text><text x=\"700.0\" y=\"214\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">.255</text><text x=\"20\" y=\"168\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">os últimos 32 endereços,</text><text x=\"20\" y=\"184\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">desenhados mais largos</text></svg>", "caption": "O plano sobre o seu /24: do maior para o menor, cada sub-rede começando onde a anterior terminou, e os 28 endereços livres juntos no fim.", "same": ["30 hosts"]}
```

A ordem não é enfeite. Posicione as mesmas sub-redes sem cuidado e um bloco que tem espaço pode não
conseguir guardá-las. Suponha que alguém coloque primeiro o enlace em 10.20.32.64/30 e operações em
10.20.32.192/27, porque esses números pareciam arrumados. Ainda há 220 endereços livres, e vendas só
precisa de 128 deles, mas **um /25 só pode começar no .0 ou no .128**, e cada uma dessas metades agora
tem uma sub-rede pequena dentro. Vendas não cabe mais em lugar nenhum do bloco. Do maior para o menor
nunca se encurrala assim, e o espaço livre que sobra fica no fim, em pedaços alinhados que uma rede
futura pode ocupar inteiros.

Duas coisas que um plano escrito também deve dizer. Arredondar para cima já deu a cada rede alguma
folga: vendas tem 126 endereços de host para 100 hosts, engenharia 62 para 50, operações 30 para 20.
Se uma rede vai crescer além disso, planeje para o tamanho que ela vai ter, porque **redimensionar
uma sub-rede depois quer dizer renumerar cada máquina dentro dela**. E o espaço livre faz parte do
plano: 10.20.32.240/28 tem espaço para 14 hosts, e anotar isso agora é o que impede alguém de
recortá-lo do meio da engenharia no ano que vem.
