---
title: Um laço não tem saída
version: 2
---

O instinto é bom e o resultado não é. Um segundo cabo entre dois switches parece um seguro: se um
cabo falhar, o outro continua ali. **Numa rede comutada, um segundo caminho sem nada que o
administre é uma falha que derruba o segmento inteiro em segundos**, com todos os cabos ligados e
todas as luzes verdes.

Dois fatos de lições anteriores bastam para explicar. Um switch inunda um broadcast por todas as
portas menos aquela por onde ele chegou (lição 18), e faz o mesmo com qualquer quadro para um
endereço MAC que ainda não aprendeu. E **um quadro Ethernet não carrega contador de saltos**. Um
pacote IP tem um TTL que cada roteador diminui em um, o campo com que o `traceroute` brinca no curso
de redes, então um pacote preso num laço de roteamento morre depois de no máximo 255 saltos. Um
switch não reescreve nada no quadro que encaminha, então um quadro dando voltas num anel de
switches nunca envelhece.

## O laboratório: três switches em triângulo

O laboratório desta lição são três switches, `sw1`, `sw2` e `sw3`, cada um uma bridge do Linux,
ligados entre si em triângulo, com um PC na porta `p10` de cada um. O spanning tree está desligado,
e o laboratório começa com o cabo entre `sw3` e `sw1` desconectado:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 320\" role=\"img\" aria-label=\"Três switches ligados em triângulo com o spanning tree desligado: sw1 em cima, com o pc1 na porta p10; sw2 embaixo à esquerda e sw3 embaixo à direita, com pc2 e pc3 nas portas p10. A p2 do sw1 vai à p1 do sw2, a p3 do sw2 à p2 do sw3, e a p1 do sw3 à p3 do sw1, o cabo ligado por três segundos. Duas cópias de um broadcast dão a volta no triângulo, uma no sentido horário e outra no contrário, e nenhuma para nunca. Nesses três segundos a p2 do sw1 recebeu 201.975 quadros.\"><defs><marker id=\"stl-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"stl-p\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><path d=\"M360 40 L360 70\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M170 254 L170 282\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M550 254 L550 282\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M320 114 L210 210\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M400 114 L510 210\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\"></path><path d=\"M230 232 L490 232\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"298\" y=\"126\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">p2</text><text x=\"422\" y=\"126\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">p3</text><text x=\"214\" y=\"194\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">p1</text><text x=\"506\" y=\"194\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">p1</text><text x=\"238\" y=\"221\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">p3</text><text x=\"482\" y=\"221\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">p2</text><text x=\"368\" y=\"55\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">p10</text><text x=\"178\" y=\"268\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">p10</text><text x=\"558\" y=\"268\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">p10</text><rect x=\"320\" y=\"10\" width=\"80\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"25.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pc1</text><rect x=\"130\" y=\"282\" width=\"80\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"170.0\" y=\"297.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pc2</text><rect x=\"510\" y=\"282\" width=\"80\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"550.0\" y=\"297.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pc3</text><rect x=\"300\" y=\"70\" width=\"120\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">sw1</text><rect x=\"110\" y=\"210\" width=\"120\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"170.0\" y=\"232.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">sw2</text><rect x=\"490\" y=\"210\" width=\"120\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"550.0\" y=\"232.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">sw3</text><path d=\"M425.1 151.8 L469.1 190.2\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\" marker-end=\"url(#stl-a)\"></path><path d=\"M412.0 220.0 L308.0 220.0\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\" marker-end=\"url(#stl-a)\"></path><path d=\"M250.9 190.2 L294.9 151.8\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\" marker-end=\"url(#stl-a)\"></path><path d=\"M484.9 172.2 L440.9 133.8\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\" marker-end=\"url(#stl-p)\"></path><path d=\"M308.0 244.0 L412.0 244.0\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\" marker-end=\"url(#stl-p)\"></path><path d=\"M279.1 133.8 L235.1 172.2\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\" marker-end=\"url(#stl-p)\"></path><path d=\"M14 22 L44 22\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\" marker-end=\"url(#stl-a)\"></path><text x=\"52\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">uma cópia, inundada no sentido horário</text><path d=\"M14 44 L44 44\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\" marker-end=\"url(#stl-p)\"></path><text x=\"52\" y=\"44\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">outra cópia, no sentido contrário</text><text x=\"486\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">ligado por três segundos</text><text x=\"706\" y=\"22\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">a p2 do sw1 recebeu</text><text x=\"706\" y=\"40\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">201.975 quadros nesses segundos</text></svg>", "caption": "O laço que o laboratório fechou por três segundos. Um switch inunda um broadcast por todas as portas menos aquela por onde ele entrou, então cada cópia segue dando a volta no triângulo, nos dois sentidos, e nada num quadro Ethernet se esgota."}
```

Salve-o como `~/netlab/stp.sh` e monte com `sudo bash ~/netlab/netlab.sh up stp`:

```bash
# ~/netlab/stp.sh: three switches cabled in a triangle, a PC on each, and
# spanning tree off. The cable from sw3 to sw1 starts unplugged (its sw3 end
# down), because with spanning tree off a triangle is a loop.
#
#          pc1
#           | p10
#          sw1
#     p2  /    \  p3
#     p1 /      \ p1   (unplugged)
#      sw2 ---- sw3
#       | p3  p2 |
#      pc2      pc3   (both on p10)
local n
for n in sw1 sw2 sw3 pc1 pc2 pc3; do node $n; done
link sw1 p2 sw2 p1; link sw2 p3 sw3 p2; link sw3 p1 sw1 p3
link pc1 eth0 sw1 p10; link pc2 eth0 sw2 p10; link pc3 eth0 sw3 p10
ip -n sw3 link set p1 down
switch sw1 "p2 p3 p10"; switch sw2 "p1 p3 p10"; switch sw3 "p1 p2 p10"
addr pc1 eth0 10.20.10.21/24; addr pc2 eth0 10.20.10.22/24; addr pc3 eth0 10.20.10.23/24
```

A linha `ip -n sw3 link set p1 down` é o cabo desconectado. Num prompt de root no sw3,
`ip link set p1 up` o conecta e `ip link set p1 down` o desconecta de novo. Com o spanning tree
desligado, conectá-lo cria o laço de que esta seção trata. Neste laboratório isso custa alguns segundos
de uma máquina virtual ocupada; numa rede de verdade é uma queda, então é um experimento só de
laboratório.

No `sw1`, esse cabo é o da `p3`:

```
root@sw1:~# bridge link show
462: p2@if461: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 master br0 state forwarding priority 32 cost 2 
465: p3@if466: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 master br0 state disabled priority 32 cost 2 
467: p10@if468: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 master br0 state forwarding priority 32 cost 2 
root@sw1:~# ip -s link show p2 | sed -n "3,6p"
    RX:  bytes packets errors dropped  missed   mcast           
          1766      21      0       0       0       0 
    TX:  bytes packets errors dropped carrier collsns           
          1188      14      0       0       0       0 
```

`NO-CARRIER` e `state disabled` são o cabo desconectado. Os contadores da `p2`, o cabo para o `sw2`,
dizem que desde que o laboratório subiu essa porta recebeu 21 quadros e enviou 14. Uma rede calma.

Então o cabo que faltava foi ligado, e três segundos depois foi desligado de novo. Ninguém digitou
nada no meio. Os mesmos contadores depois:

```
root@sw1:~# ip -s link show p2 | sed -n "3,6p"
    RX:  bytes packets errors dropped  missed   mcast           
      15019266  201975      0       0       0       0 
    TX:  bytes packets errors dropped carrier collsns           
      16857698  219701      0       0       0       0 
```

**De 21 quadros recebidos para 201.975, e de 14 enviados para 219.701, em uns três segundos, numa
porta só.** Nenhum programa mandou esses quadros. O quadro de broadcast ou multicast que estava no
fio quando o triângulo fechou foi inundado por cada switch para os outros dois, que o inundaram
adiante, e ele voltou ao switch de onde saiu, que o inundou de novo. Ele dá a volta nos dois
sentidos ao mesmo tempo, porque uma inundação sai por todas as portas, e cada volta acrescenta
cópias.

## O que um laço faz com uma rede

Isso é uma **tempestade de broadcast** (*broadcast storm*), e neste laboratório ela parou só porque
o cabo foi puxado. Em switches de verdade ela enche cada enlace do laço até a velocidade máxima e o
mantém assim, e cada dispositivo do segmento tem de receber cada broadcast da tempestade. Os PCs
ficam lentos, os switches gastam o processador inundando, e a interface de gerência que você usaria
para resolver deixa de responder.

A tempestade também destrói a tabela MAC. Um switch aprende um endereço MAC pela porta por onde um
quadro chega (lição 18). Quando cópias do mesmo quadro chegam pela `p2` e depois pela `p3`, o `sw1`
muda o endereço do remetente de uma porta para a outra, sem parar. Isso se chama **oscilação de
MAC** (*MAC flapping*), e os quadros para aquele endereço saem pela porta que ganhou por último, que
bem pode ser a errada.

E nada disso acaba sozinho: nenhum campo do quadro se esgota. A solução tem de ser um protocolo que
deixe os switches descobrirem o laço e desligarem só as portas necessárias para quebrá-lo. Esse
protocolo é o resto desta lição.
