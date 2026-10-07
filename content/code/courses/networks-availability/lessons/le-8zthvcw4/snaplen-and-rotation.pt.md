---
title: Guardando menos, e continuando a guardar
version: 1
---

Uma captura num servidor movimentado cresce rápido, e duas flags a mantêm sob controle: uma pega menos
de cada pacote, a outra guarda só os últimos megabytes.

## Snap length

**O snap length é quantos bytes de cada pacote são guardados.** Por padrão o `tcpdump` guarda 262144,
o pacote inteiro de qualquer coisa que esta rede leva. Para uma pergunta sobre conexões e flags os
cabeçalhos bastam, e `-s 96` guarda os primeiros 96 bytes. O laptop fez as mesmas quatro requisições,
com a mesma linha da seção anterior:

```
ana@web1:~$ sudo tcpdump -n -i eth0 -s 96 -c 40 -Z ana -w short.pcap tcp port 80
tcpdump: listening on eth0, link-type EN10MB (Ethernet), snapshot length 96 bytes
40 packets captured
40 packets received by filter
0 packets dropped by kernel
ana@web1:~$ tcpdump -n -r short.pcap -v "tcp[tcpflags] & tcp-push != 0" | head -n 4
reading from file short.pcap, link-type EN10MB (Ethernet), snapshot length 96
18:10:05.723959 IP (tos 0x0, ttl 62, id 9618, offset 0, flags [DF], proto TCP (6), length 125)
    203.0.113.2.58030 > 192.0.2.21.80: Flags [P.], seq 3489478198:3489478271, ack 1958766029, win 63, options [nop,nop,TS val 2032094061 ecr 4037869552], length 73: HTTP, length: 73
	GET / HTTP/1.1 [|http]
18:10:05.724103 IP (tos 0x0, ttl 64, id 37345, offset 0, flags [DF], proto TCP (6), length 295)
ana@web1:~$ ls -l web1.pcap short.pcap
-rw-r--r-- 1 ana ana 3608 Sep 28 18:10 short.pcap
-rw-r--r-- 1 ana ana 4690 Sep 28 18:10 web1.pcap
```

`[|http]` é o `tcpdump` dizendo que o pacote acabou, no arquivo, no meio do HTTP. A linha da requisição
sobreviveu e o resto não. **96 bytes são 14 de Ethernet, 20 de IP e 32 de TCP com as opções, o que
deixa 30 da requisição**, o bastante para `GET / HTTP/1.1` e não para os cabeçalhos depois dela. O
`-v` acrescentou os detalhes do cabeçalho IP: `ttl 62` no pacote do laptop, que saiu com 64 e
atravessou dois roteadores, `hq` e o do provedor.

O arquivo tem 3608 bytes, contra 4690 para os mesmos quarenta pacotes guardados inteiros. A economia é
pequena aqui porque a maioria dos pacotes era confirmação sem dados para cortar. **Numa captura de transferências grandes o snap length tira a maior parte do arquivo**, e a maior parte do que um
estranho poderia ler nele. Guardar só os cabeçalhos é também a medida de privacidade mais simples que
existe.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 660 170\" role=\"img\" aria-label=\"A requisição do laptop desenhada como uma barra de 139 bytes: 14 de Ethernet, 20 de IP, 32 de TCP e 73 de HTTP. Um corte em 96 bytes, marcado -s 96, mantém os três cabeçalhos inteiros e os primeiros 30 bytes da requisição; os últimos 43 bytes nunca são gravados, o que o tcpdump marca como [|http].\"><rect x=\"20\" y=\"50\" width=\"61.60000000000001\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"50.800000000000004\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Ethernet</text><text x=\"50.800000000000004\" y=\"81\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">14</text><rect x=\"81.60000000000001\" y=\"50\" width=\"88.0\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"125.60000000000001\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">IP</text><text x=\"125.60000000000001\" y=\"81\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">20</text><rect x=\"169.60000000000002\" y=\"50\" width=\"140.8\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"240.00000000000003\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">TCP</text><text x=\"240.00000000000003\" y=\"81\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">32</text><rect x=\"310.40000000000003\" y=\"50\" width=\"132.0\" height=\"44\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"442.40000000000003\" y=\"50\" width=\"189.20000000000005\" height=\"44\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"376.40000000000003\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">HTTP</text><text x=\"376.40000000000003\" y=\"81\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">73</text><path d=\"M442.40000000000003 28 L442.40000000000003 46\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M442.40000000000003 98 L442.40000000000003 116\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"442.40000000000003\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">-s 96</text><text x=\"231.20000000000002\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">fica no arquivo: 96 bytes</text><text x=\"537.0\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">nunca gravado: 43</text><text x=\"231.20000000000002\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">cabeçalhos inteiros, 30 bytes da requisição</text><text x=\"537.0\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">o resto: [|http]</text></svg>", "caption": "A requisição da captura com snap length, em escala. Com -s 96 uma pergunta sobre conexões e flags ainda tem resposta, e o conteúdo da requisição quase todo não.", "same": ["Ethernet", "IP", "TCP", "HTTP"]}
```

## Um anel de arquivos

Uma falha que acontece uma vez por noite pede uma captura que rode a noite inteira sem encher o disco.
**`-C` começa um arquivo novo a cada tantos milhões de bytes, e `-W` guarda só essa quantidade de
arquivos**, sobrescrevendo o mais antigo. O laptop baixou um arquivo de 20 MB com isso rodando,
`curl -s -o /dev/null http://192.0.2.21/big.bin`, e quando o download terminou a captura foi parada com
`Ctrl+C`:

```
ana@web1:~$ sudo tcpdump -n -i eth0 -C 1 -W 3 -Z ana -w ring.pcap tcp port 80
tcpdump: listening on eth0, link-type EN10MB (Ethernet), snapshot length 262144 bytes
15316 packets captured
15316 packets received by filter
0 packets dropped by kernel
ana@web1:~$ ls -l ring.pcap*
-rw-r--r-- 1 ana ana  237648 Sep 28 18:10 ring.pcap0
-rw-r--r-- 1 ana ana 1001402 Sep 28 18:10 ring.pcap1
-rw-r--r-- 1 ana ana 1000412 Sep 28 18:10 ring.pcap2
```

Passaram 15316 pacotes, e o que sobrou são três arquivos de cerca de um megabyte. `ring.pcap0` é o
menor porque estava sendo gravado quando a captura parou: **é o arquivo mais novo, não o mais
antigo**. O `tcpdump` gravou 0, 1 e 2, depois voltou ao 0 e começou a sobrescrevê-lo, então os pacotes
mais antigos ainda guardados estão no começo de `ring.pcap1`. O handshake e o `GET` que iniciaram o
download estavam em arquivos que não existem mais.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 710 172\" role=\"img\" aria-label=\"Três arquivos em fila, ring.pcap0 com 237648 bytes, ring.pcap1 com 1001402 bytes e ring.pcap2 com 1000412 bytes, com setas de cada um para o seguinte e uma seta tracejada de ring.pcap2 de volta a ring.pcap0: quando o terceiro enche, o tcpdump sobrescreve o primeiro. ring.pcap0 estava em gravação quando a captura parou, então é o mais novo; os pacotes mais antigos ainda guardados estão em ring.pcap1.\"><defs><marker id=\"rg-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"40\" y=\"50\" width=\"170\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"125.0\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ring.pcap0</text><text x=\"125.0\" y=\"83.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">237648 bytes</text><rect x=\"270\" y=\"50\" width=\"170\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"355.0\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ring.pcap1</text><text x=\"355.0\" y=\"83.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">1001402 bytes</text><rect x=\"500\" y=\"50\" width=\"170\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"585.0\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ring.pcap2</text><text x=\"585.0\" y=\"83.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">1000412 bytes</text><path d=\"M210 75 L270 75\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rg-ah)\"></path><path d=\"M440 75 L500 75\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rg-ah)\"></path><path d=\"M585 100 C 585 160, 125 160, 125 104\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#rg-ah)\"></path><text x=\"355\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">cheio: volta a ring.pcap0, sobrescrevendo</text><text x=\"125\" y=\"32\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">em gravação ao parar: o mais novo</text><text x=\"355\" y=\"32\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">pacotes mais antigos ainda guardados</text><text x=\"585\" y=\"32\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">cheio com um milhão de bytes</text></svg>", "caption": "O anel de -C 1 -W 3, com os tamanhos que o ls imprimiu. A numeração diz a ordem em que os arquivos foram criados, e nada sobre qual guarda os pacotes mais novos."}
```

Essa é a troca: um anel guarda os minutos antes de você pará-lo, que é o que se quer quando ele é
parado no momento em que a falha aparece. A próxima seção pergunta o que acontece com os arquivos
depois disso.
