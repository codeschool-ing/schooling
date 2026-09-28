---
title: O handshake TCP, número a número
version: 1
---

Toda conexão TCP abre com três pacotes, e o resumo de sempre para nos nomes deles: SYN, SYN-ACK, ACK.
**Os nomes são a metade fácil. Os números dentro deles são a base contra a qual o resto da conexão é
contado**, e lê-los é como se distingue uma conexão que funcionou de uma que só pareceu funcionar.

O laptop buscou `http://192.0.2.21/` enquanto o `tshark` imprimia seis campos de cada pacote: o número
do quadro, quem mandou, as flags, o número de sequência, o número de confirmação e os bytes de dados.

```
ana@laptop:~$ tshark -n -i eth0 -c 10 -f "host 192.0.2.21 and tcp port 80" -T fields -e frame.number -e ip.src -e tcp.flags.str -e tcp.seq -e tcp.ack -e tcp.len
Capturing on 'eth0'
10 packets captured
1	192.168.10.20	··········S·	0	0	0
2	192.0.2.21	·······A··S·	0	1	0
3	192.168.10.20	·······A····	1	1	0
4	192.168.10.20	·······AP···	1	1	73
5	192.0.2.21	·······A····	1	74	0
6	192.0.2.21	·······AP···	1	74	243
7	192.168.10.20	·······A····	74	244	0
8	192.168.10.20	·······A···F	74	244	0
9	192.0.2.21	·······A···F	244	75	0
10	192.168.10.20	·······A····	75	245	0
```

`tcp.flags.str` desenha os doze bits de flag como pontos, com uma letra onde o bit está ligado: `S`
SYN, `A` ACK, `P` push, `F` FIN. Leia as colunas de cima para baixo e a conexão conta a própria
história.

**Os quadros 1 a 3 são o handshake.** O laptop manda um SYN com sequência 0. O servidor responde com um
SYN próprio, sequência 0, e confirma 1: "recebi o seu byte 0, mande o 1". O laptop confirma o 0 do
servidor com 1. Um SYN não leva dados e mesmo assim gasta um número de sequência, e é por isso que os
dois lados começam os dados de verdade em 1.

**Os quadros 4 a 7 são a página.** A requisição tem 73 bytes a partir de 1, então o servidor confirma
74, o próximo byte que espera. A resposta tem 243 bytes a partir do 1 do servidor, e o laptop confirma
244. A confirmação é sempre o próximo byte desejado, nunca o último byte recebido.

**Os quadros 8 a 10 fecham a conexão.** Cada lado manda um FIN, e um FIN, como um SYN, gasta um
número: o FIN do laptop está em 74 e o servidor confirma 75; o do servidor está em 244 e o laptop
confirma 245.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 780 390\" role=\"img\" aria-label=\"Um diagrama de sequência dos dez pacotes entre laptop, 192.168.10.20, e web1, 192.0.2.21, com números relativos. Abertura: 1 SYN seq 0; 2 SYN, ACK seq 0 ack 1; 3 ACK seq 1 ack 1. A página: 4 GET de 73 bytes, seq 1 ack 1; 5 ACK ack 74; 6 200 OK de 243 bytes, seq 1 ack 74; 7 ACK ack 244. Fechamento: 8 FIN seq 74 ack 244; 9 FIN seq 244 ack 75; 10 ACK seq 75 ack 245.\"><defs><marker id=\"hs-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"120\" y=\"12\" width=\"140\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"190.0\" y=\"25.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">laptop</text><text x=\"190.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">192.168.10.20</text><rect x=\"520\" y=\"12\" width=\"140\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"590.0\" y=\"25.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">web1</text><text x=\"590.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">192.0.2.21</text><path d=\"M190 52 L190 380\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M590 52 L590 380\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M190 80 L590 92\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#hs-ah)\"></path><text x=\"390.0\" y=\"77\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">1  SYN  seq=0</text><path d=\"M590 110 L190 122\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#hs-ah)\"></path><text x=\"390.0\" y=\"107\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">2  SYN, ACK  seq=0 ack=1</text><path d=\"M190 140 L590 152\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#hs-ah)\"></path><text x=\"390.0\" y=\"137\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">3  ACK  seq=1 ack=1</text><path d=\"M190 170 L590 182\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#hs-ah)\"></path><text x=\"390.0\" y=\"167\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">4  GET, 73 bytes  seq=1 ack=1</text><path d=\"M590 200 L190 212\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#hs-ah)\"></path><text x=\"390.0\" y=\"197\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">5  ACK  ack=74</text><path d=\"M590 230 L190 242\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#hs-ah)\"></path><text x=\"390.0\" y=\"227\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">6  200 OK, 243 bytes  seq=1 ack=74</text><path d=\"M190 260 L590 272\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#hs-ah)\"></path><text x=\"390.0\" y=\"257\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">7  ACK  ack=244</text><path d=\"M190 290 L590 302\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#hs-ah)\"></path><text x=\"390.0\" y=\"287\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">8  FIN  seq=74 ack=244</text><path d=\"M590 320 L190 332\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#hs-ah)\"></path><text x=\"390.0\" y=\"317\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">9  FIN  seq=244 ack=75</text><path d=\"M190 350 L590 362\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#hs-ah)\"></path><text x=\"390.0\" y=\"347\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">10  ACK  seq=75 ack=245</text><path d=\"M20 74 L20 152\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"28\" y=\"116.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">abertura</text><path d=\"M20 164 L20 272\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"28\" y=\"221.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a página</text><path d=\"M20 284 L20 362\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"28\" y=\"326.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">fechamento</text></svg>", "caption": "A captura da primeira seção, desenhada. Toda confirmação é o próximo byte desejado, e um SYN ou um FIN gasta um número embora não leve dados."}
```

## Números relativos são uma gentileza do Wireshark

Um número de sequência nunca começa de verdade em 0. **Cada lado escolhe um número inicial aleatório
de 32 bits, e o Wireshark o subtrai para você.** A mesma requisição feita de novo, imprimindo os
campos brutos:

```
ana@laptop:~$ tshark -n -i eth0 -c 3 -f "host 192.0.2.21 and tcp port 80" -T fields -e frame.number -e tcp.flags.str -e tcp.seq_raw -e tcp.ack_raw
Capturing on 'eth0'
3 packets captured
1	··········S·	3237057867	0
2	·······A··S·	1721216027	3237057868
```

O laptop começou em 3237057867 e o servidor em 1721216027, e a aritmética é a mesma: o servidor
confirma 3237057868, um a mais que o início do laptop. A aleatoriedade é uma defesa. Um estranho que
não enxerga os pacotes teria de adivinhar um número entre quatro bilhões para injetar um na conexão,
onde um contador que começasse em 0 seria adivinhado na primeira tentativa.
