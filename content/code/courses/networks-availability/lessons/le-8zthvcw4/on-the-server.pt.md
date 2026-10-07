---
title: tcpdump no servidor, uma linha de cada vez
version: 1
---

Um servidor num data center não tem tela, nem Wireshark, nem alguém para instalar um, e costuma ser a
máquina mais perto do problema. **O que ele tem, quase sempre, é o `tcpdump`**, do mesmo projeto que a
libpcap, a biblioteca por trás dos filtros de captura da aula 11, então ele fala o mesmo BPF. É a
ferramenta para capturar no próprio host, o terceiro lugar que a aula 11 citou.

A primeira tentativa em `web1` falha:

```
ana@web1:~$ tcpdump -i eth0
tcpdump: eth0: You don't have permission to perform this capture on that device
(socket: Operation not permitted)
```

**Abrir uma interface para ler todo pacote que passa nela exige root**, ou a capability que um grupo
`wireshark` concede, e `web1` não tem esse grupo. Então daqui em diante a captura passa por `sudo`, e as
próximas seções cuidam para que só a captura rode com esse privilégio.

## Lendo uma linha

O laptop buscou a página inicial, `curl -s http://192.0.2.21/` em `laptop`, enquanto o `tcpdump` em
`web1` imprimia os primeiros quatro pacotes que viu na porta 80, uma vez do jeito padrão e outra com
`-n`; comece a captura antes, depois busque a página, duas vezes:

```
ana@web1:~$ sudo tcpdump -i eth0 -c 4 tcp port 80
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on eth0, link-type EN10MB (Ethernet), snapshot length 262144 bytes
18:09:59.272963 IP 203.0.113.2.53572 > 192.0.2.21.http: Flags [S], seq 4253519600, win 64240, options [mss 1460,sackOK,TS val 2091423905 ecr 0,nop,wscale 10], length 0
18:09:59.272979 IP 192.0.2.21.http > 203.0.113.2.53572: Flags [S.], seq 1512749408, ack 4253519601, win 65160, options [mss 1460,sackOK,TS val 2178196906 ecr 2091423905,nop,wscale 10], length 0
18:09:59.273007 IP 203.0.113.2.53572 > 192.0.2.21.http: Flags [.], ack 1, win 63, options [nop,nop,TS val 2091423905 ecr 2178196906], length 0
18:09:59.273064 IP 203.0.113.2.53572 > 192.0.2.21.http: Flags [P.], seq 1:74, ack 1, win 63, options [nop,nop,TS val 2091423905 ecr 2178196906], length 73: HTTP: GET / HTTP/1.1
4 packets captured
10 packets received by filter
0 packets dropped by kernel
ana@web1:~$ sudo tcpdump -n -i eth0 -c 4 tcp port 80
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on eth0, link-type EN10MB (Ethernet), snapshot length 262144 bytes
18:10:01.354355 IP 203.0.113.2.53574 > 192.0.2.21.80: Flags [S], seq 3118618316, win 64240, options [mss 1460,sackOK,TS val 2627791292 ecr 0,nop,wscale 10], length 0
18:10:01.354371 IP 192.0.2.21.80 > 203.0.113.2.53574: Flags [S.], seq 2274837499, ack 3118618317, win 65160, options [mss 1460,sackOK,TS val 721148073 ecr 2627791292,nop,wscale 10], length 0
18:10:01.354397 IP 203.0.113.2.53574 > 192.0.2.21.80: Flags [.], ack 1, win 63, options [nop,nop,TS val 2627791292 ecr 721148073], length 0
18:10:01.354456 IP 203.0.113.2.53574 > 192.0.2.21.80: Flags [P.], seq 1:74, ack 1, win 63, options [nop,nop,TS val 2627791292 ecr 721148073], length 73: HTTP: GET / HTTP/1.1
4 packets captured
10 packets received by filter
0 packets dropped by kernel
```

**`-n` impede o `tcpdump` de transformar números em nomes.** Sem ele a porta saiu como `http`, e numa
rede com DNS reverso cada endereço seria consultado também, uma consulta por endereço novo, enviada
durante a captura. Com ele, `80` é `80`. Use `-n` sempre num servidor: um nome é mais lento, pode
estar errado, e uma porta chamada `http` esconde a pergunta de se ela é mesmo a 80.

A origem é `203.0.113.2`, e não o `192.168.10.20` do laptop. Esse é o endereço público de `hq`: o
roteador do escritório o traduziu, como a aula 11 de `networks-addressing` descreveu, e `web1` nunca
vê um endereço privado do escritório. `4 packets captured` contra `10 packets received by filter` quer
dizer que dez tinham passado pelo filtro quando o `tcpdump` parou, e ele imprimiu os quatro que o
`-c 4` pediu.

Desmontando a primeira linha com `-n`:

| pedaço | o que diz |
|---|---|
| `18:10:01.354355` | a hora, com microssegundos, no fuso da própria máquina |
| `203.0.113.2.53574 > 192.0.2.21.80` | endereço e porta de origem, depois o destino; a porta é o último número depois de um ponto |
| `Flags [S]` | as flags TCP: `S` SYN, `.` ACK, `P` push, `F` FIN, `R` reset |
| `seq 3118618316` | o número de sequência que o cliente escolheu |
| `win 64240` | a janela, como o campo a leva |
| `options [mss 1460,…,wscale 10]` | as opções TCP, aqui o tamanho máximo de segmento e a escala da janela |
| `length 0` | bytes de dados no segmento; um SYN não leva nenhum |

**`[S]`, `[S.]`, `[.]`, `[P.]` é a conexão abrindo e a primeira requisição**, o padrão a reconhecer
de relance. Depois do SYN, o `tcpdump` imprime números de sequência relativos ao início, então a
requisição é `seq 1:74`, 73 bytes. E `win 63` na terceira linha não é uma janela minúscula: o SYN disse
`wscale 10`, então a janela real é 63 × 1024 = 64512 bytes, que é o número que o `tshark` imprimiu como
`Win=64512` na aula 11. **O `tcpdump` imprime o campo; a escala está numa opção dois pacotes antes.**
