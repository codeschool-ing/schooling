---
title: Um pacote, desmontado
version: 1
---

Cada camada embrulha o que recebe da camada de cima num cabeçalho seu, e a camada de baixo trata o
conjunto todo como dados. Isso é **encapsulamento**, e um pacote mostra. O laptop buscou
`http://www.example.com/` enquanto o `tcpdump -XX` imprimia o quadro que levava o pedido, byte a
byte:

```
ana@laptop:~$ sudo tcpdump -n -e -XX -c 1 "tcp dst port 80 and tcp[tcpflags] & tcp-push != 0"
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on eth0, link-type EN10MB (Ethernet), snapshot length 262144 bytes
13:05:57.717708 52:54:00:a8:0a:14 > 52:54:00:a8:0a:01, ethertype IPv4 (0x0800), length 144: 192.168.10.20.49864 > 192.0.2.80.80: Flags [P.], seq 365871663:365871741, ack 1424285085, win 63, options [nop,nop,TS val 915910785 ecr 3747846154], length 78: HTTP: GET / HTTP/1.1
        0x0000:  5254 00a8 0a01 5254 00a8 0a14 0800 4500  RT....RT......E.
        0x0010:  0082 9b9e 4000 4006 11cb c0a8 0a14 c000  ....@.@.........
        0x0020:  0250 c2c8 0050 15ce c22f 54e4 dd9d 8018  .P...P.../T.....
        0x0030:  003f 8d81 0000 0101 080a 3697 b081 df63  .?........6....c
        0x0040:  980a 4745 5420 2f20 4854 5450 2f31 2e31  ..GET./.HTTP/1.1
        0x0050:  0d0a 486f 7374 3a20 7777 772e 6578 616d  ..Host:.www.exam
        0x0060:  706c 652e 636f 6d0d 0a55 7365 722d 4167  ple.com..User-Ag
        0x0070:  656e 743a 2063 7572 6c2f 382e 352e 300d  ent:.curl/8.5.0.
        0x0080:  0a41 6363 6570 743a 202a 2f2a 0d0a 0d0a  .Accept:.*/*....
1 packet captured
1 packet received by filter
0 packets dropped by kernel
```

A primeira linha é o resumo do `tcpdump`, e o bloco abaixo dela é o próprio quadro: 144 bytes em
hexadecimal, 16 por linha, com os caracteres imprimíveis à direita. Cortado nas fronteiras das
camadas, fica assim:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"O quadro de 144 bytes capturado no laptop, cortado em camadas. Os primeiros 14 bytes são o cabeçalho Ethernet: do MAC do laptop, 52:54:00:a8:0a:14, para 52:54:00:a8:0a:01, que é o do roteador, não o do servidor web. Os 20 bytes seguintes são o cabeçalho IP: de 192.168.10.20 para 192.0.2.80, TTL 64, levando TCP. Os 32 bytes seguintes são o cabeçalho TCP: da porta 49864 para a porta 80, flags P e ACK. Os últimos 78 bytes são o pedido HTTP: GET / HTTP/1.1 com Host: www.example.com.\"><defs><marker id=\"fr-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"30\" width=\"66.11111111111111\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"53.05555555555556\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Ethernet</text><rect x=\"86.11111111111111\" y=\"30\" width=\"94.44444444444444\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"133.33333333333334\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">IP</text><rect x=\"180.55555555555554\" y=\"30\" width=\"151.11111111111111\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"256.1111111111111\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">TCP</text><rect x=\"331.66666666666663\" y=\"30\" width=\"368.3333333333333\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"515.8333333333333\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">HTTP</text><text x=\"20\" y=\"88\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">144 bytes no fio</text><rect x=\"20\" y=\"112\" width=\"12\" height=\"12\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"42\" y=\"118\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Cabeçalho Ethernet, 14 bytes</text><text x=\"236\" y=\"118\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">52:54:00:a8:0a:14 → 52:54:00:a8:0a:01</text><text x=\"473.7\" y=\"118\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">para o roteador</text><rect x=\"20\" y=\"144\" width=\"12\" height=\"12\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"42\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Cabeçalho IP, 20 bytes</text><text x=\"236\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">192.168.10.20 → 192.0.2.80</text><text x=\"406.6\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">TTL 64, levando TCP</text><rect x=\"20\" y=\"176\" width=\"12\" height=\"12\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"42\" y=\"182\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Cabeçalho TCP, 32 bytes</text><text x=\"236\" y=\"182\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">49864 → 80</text><text x=\"309.0\" y=\"182\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">portas, flags P e ACK</text><rect x=\"20\" y=\"208\" width=\"12\" height=\"12\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"42\" y=\"214\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">HTTP, 78 bytes</text><text x=\"236\" y=\"214\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\" xml:space=\"preserve\">GET / HTTP/1.1  Host: www.example.com</text></svg>", "caption": "Um quadro, quatro camadas, cada uma embrulhada na de baixo. O pedido em si são os últimos 78 bytes; tudo antes dele é endereçamento.", "same": ["Ethernet", "HTTP", "HTTP, 78 bytes", "IP", "TCP"]}
```

Três coisas se leem direto dos bytes:

- O quadro começa com **`5254 00a8 0a01`, o MAC de destino, e ele é do roteador**, não do servidor
  web. O laptop manda tudo o que está fora do escritório para o gateway, a rota padrão da seção 04
  funcionando. O
  destino IP, `c000 0250`, é `192.0.2.80`, o servidor web. A camada 2 diz o próximo salto; a camada 3
  diz o destino final.
- O `0800` depois dos dois MACs diz "vem IPv4". O `45` abre o cabeçalho IP: versão 4, cabeçalho de 5
  palavras de 4 bytes. O `4006` alguns bytes depois é o TTL, `0x40` ou 64, e o protocolo, 6 para TCP.
- O pedido é legível a partir do `GET`, porque HTTP na porta 80 não é criptografado. Por HTTPS, os
  mesmos 78 bytes seriam ruído, que é o ponto da aula 5.
