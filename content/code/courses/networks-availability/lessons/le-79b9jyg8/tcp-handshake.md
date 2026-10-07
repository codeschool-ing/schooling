---
title: The TCP handshake, number by number
version: 1
---

Every TCP connection opens with three packets, and the usual summary stops at their names: SYN,
SYN-ACK, ACK. **The names are the easy half. The numbers inside them are what the rest of the
connection is counted against**, and reading them is how you tell a connection that worked from one
that only looked like it.

The laptop fetched `http://192.0.2.21/`, with `curl -s http://192.0.2.21/` in one shell on `laptop`,
while `tshark`, started first in another, printed six fields of each packet: the frame
number, the sender, the flags, the sequence number, the acknowledgement number and the bytes of
data.

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

`tcp.flags.str` draws the twelve flag bits as dots, with a letter where a bit is set: `S` SYN,
`A` ACK, `P` push, `F` FIN. Read the output down its columns.

**Frames 1 to 3 are the handshake.** The laptop sends a SYN with sequence 0. The server answers with
a SYN of its own, sequence 0, and acknowledges 1: "I have your byte 0, send me 1". The laptop
acknowledges the server's 0 with 1. A SYN carries no data and still uses up one sequence number,
which is why both sides start their real data at 1.

**Frames 4 to 7 are the page.** The request is 73 bytes starting at 1, so the server acknowledges 74,
the next byte it expects. The answer is 243 bytes starting at the server's 1, and the laptop
acknowledges 244. The acknowledgement is always the next byte wanted, never the last byte received.

**Frames 8 to 10 close it.** Each side sends a FIN, and a FIN, like a SYN, uses one number: the
laptop's FIN is at 74 and the server acknowledges 75; the server's is at 244 and the laptop
acknowledges 245.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 780 390\" role=\"img\" aria-label=\"A sequence diagram of the ten packets between laptop, 192.168.10.20, and web1, 192.0.2.21, with relative numbers. Opening: 1 SYN seq 0; 2 SYN, ACK seq 0 ack 1; 3 ACK seq 1 ack 1. The page: 4 GET of 73 bytes, seq 1 ack 1; 5 ACK ack 74; 6 200 OK of 243 bytes, seq 1 ack 74; 7 ACK ack 244. Closing: 8 FIN seq 74 ack 244; 9 FIN seq 244 ack 75; 10 ACK seq 75 ack 245.\"><defs><marker id=\"hs-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"120\" y=\"12\" width=\"140\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"190.0\" y=\"25.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">laptop</text><text x=\"190.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">192.168.10.20</text><rect x=\"520\" y=\"12\" width=\"140\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"590.0\" y=\"25.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">web1</text><text x=\"590.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">192.0.2.21</text><path d=\"M190 52 L190 380\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M590 52 L590 380\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M190 80 L590 92\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#hs-ah)\"></path><text x=\"390.0\" y=\"77\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">1  SYN  seq=0</text><path d=\"M590 110 L190 122\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#hs-ah)\"></path><text x=\"390.0\" y=\"107\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">2  SYN, ACK  seq=0 ack=1</text><path d=\"M190 140 L590 152\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#hs-ah)\"></path><text x=\"390.0\" y=\"137\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">3  ACK  seq=1 ack=1</text><path d=\"M190 170 L590 182\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#hs-ah)\"></path><text x=\"390.0\" y=\"167\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">4  GET, 73 bytes  seq=1 ack=1</text><path d=\"M590 200 L190 212\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#hs-ah)\"></path><text x=\"390.0\" y=\"197\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">5  ACK  ack=74</text><path d=\"M590 230 L190 242\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#hs-ah)\"></path><text x=\"390.0\" y=\"227\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">6  200 OK, 243 bytes  seq=1 ack=74</text><path d=\"M190 260 L590 272\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#hs-ah)\"></path><text x=\"390.0\" y=\"257\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">7  ACK  ack=244</text><path d=\"M190 290 L590 302\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#hs-ah)\"></path><text x=\"390.0\" y=\"287\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">8  FIN  seq=74 ack=244</text><path d=\"M590 320 L190 332\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#hs-ah)\"></path><text x=\"390.0\" y=\"317\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">9  FIN  seq=244 ack=75</text><path d=\"M190 350 L590 362\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#hs-ah)\"></path><text x=\"390.0\" y=\"347\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">10  ACK  seq=75 ack=245</text><path d=\"M20 74 L20 152\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"28\" y=\"116.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">opening</text><path d=\"M20 164 L20 272\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"28\" y=\"221.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the page</text><path d=\"M20 284 L20 362\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"28\" y=\"326.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">closing</text></svg>", "caption": "The capture of the first section, drawn. Every acknowledgement is the next byte wanted, and a SYN or a FIN uses one number although it carries no data."}
```

## Relative numbers are Wireshark's courtesy

A sequence number never really starts at 0. **Each side picks a random 32-bit starting number, and
Wireshark subtracts it for you.** The same request made again, the same way, printing the raw fields:

```
ana@laptop:~$ tshark -n -i eth0 -c 3 -f "host 192.0.2.21 and tcp port 80" -T fields -e frame.number -e tcp.flags.str -e tcp.seq_raw -e tcp.ack_raw
Capturing on 'eth0'
3 packets captured
1	··········S·	3237057867	0
2	·······A··S·	1721216027	3237057868
```

The laptop started at 3237057867 and the server at 1721216027, and the arithmetic is unchanged: the
server acknowledges 3237057868, one more than the laptop's start. The randomness is a defence. A
stranger who cannot see the packets would have to guess a number out of four billion to inject one
into the connection, where a counter that started at 0 would be guessed at the first try.
