---
title: Limitando o tamanho do segmento
version: 1
---

Há dois jeitos de consertar um buraco negro, e eles consertam coisas diferentes. O primeiro é deixar a
mensagem passar: remover a regra, ou estreitá-la para que o "fragmentation needed" de que a descoberta do
MTU do caminho precisa possa sair do roteador. Isso conserta o mecanismo para todos os protocolos. O
segundo, e o que foi rodado aqui, é **fazer o TCP nunca mandar um pacote grande demais para o túnel**, e
assim a mensagem nunca é necessária.

O tamanho máximo de segmento do TCP viaja no SYN, e **cada lado manda segmentos que não passam do que o
outro anunciou**. Um roteador pode reescrever essa opção quando o SYN passa por ele, o que se chama MSS
clamping, e quase todo roteador de VPN faz isso. Em `hq` são duas regras no hook de forward, uma para os
SYN que entram no túnel e outra para os que saem dele:

```
ana@hq:~$ sudo nft add table ip clamp && sudo nft add chain ip clamp syn "{ type filter hook forward priority mangle; }"
ana@hq:~$ sudo nft add rule ip clamp syn oifname wg0 tcp flags syn tcp option maxseg size set 1380 && sudo nft add rule ip clamp syn iifname wg0 tcp flags syn tcp option maxseg size set 1380
```

**1380 é o MTU do túnel menos 40 bytes**: 20 de cabeçalho IP e 20 de cabeçalho TCP, os dois que vão na
frente de todo segmento. Um segmento de até 1380 bytes de dados gera um pacote de até 1420, e isso cabe
no `wg0`. Depois, o mesmo download, com uma captura dos SYN no lado do escritório de `hq` enquanto ele
rodava:

```
ana@till:~$ curl -sS -m 30 -o /dev/null -w "%{http_code} %{size_download} bytes\n" http://192.168.10.10/big.bin
200 20000000 bytes
ana@hq:~$ sudo tcpdump -n -t -i eth0 -c 2 "tcp[tcpflags] & tcp-syn != 0"
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on eth0, link-type EN10MB (Ethernet), snapshot length 262144 bytes
IP 192.168.20.30.40598 > 192.168.10.10.80: Flags [S], seq 1928010537, win 64240, options [mss 1380,sackOK,TS val 2773923947 ecr 0,nop,wscale 10], length 0
IP 192.168.10.10.80 > 192.168.20.30.40598: Flags [S.], seq 1684711710, ack 1928010538, win 65160, options [mss 1460,sackOK,TS val 2944618766 ecr 2773923947,nop,wscale 10], length 0
2 packets captured
2 packets received by filter
0 packets dropped by kernel
```

**20000000 bytes, status 200**: o arquivo inteiro, onde oito segundos não tinham entregado nada. A
captura mostra como. O SYN do caixa saiu da filial anunciando 1460, como na captura da falha, e quando
chega à LAN do escritório diz **`mss 1380`**, porque `hq` o reescreveu ao sair do `wg0`. `files` agora
manda segmentos dimensionados para 1380, e eles cabem. O SYN-ACK da segunda linha ainda diz 1460, porque
esta captura é no lado do escritório e a resposta de `files` ainda não chegou à segunda regra; essa regra
a reescreve no caminho para dentro do túnel, onde a captura não olhou.

A correção foi conferida com **o mesmo teste que encontrou a falha**, o download de `big.bin`, e não com
um ping ou uma página pequena, que funcionaram o tempo todo e não provariam nada.

Dois limites mantêm o resultado honesto:

- **O clamping só ajuda o TCP.** O MSS é uma opção do TCP, então qualquer outra coisa que mande pacotes
  cheios com Don't Fragment ligado continua esbarrando na mensagem descartada no túnel.
- **A regra que causou tudo continua em `hq`**, descartando todo destination unreachable que o roteador
  enviaria, inclusive os que avisam um cliente de que um host ou uma porta não pode ser alcançado. Essas
  falhas agora chegam como timeouts em vez de erros.

Então a correção completa são as duas coisas: limitar o MSS e deixar o "fragmentation needed" sair. A
segunda metade não foi rodada neste laboratório. A aula 23 registra o caso inteiro como um registro de
incidente, com o sintoma, cada hipótese, o teste que a resolveu e a correção, inclusive a metade que
falta.
