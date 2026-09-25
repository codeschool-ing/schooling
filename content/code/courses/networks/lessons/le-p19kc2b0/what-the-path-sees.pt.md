---
title: O que o caminho consegue ver
version: 1
---

O roteador do escritório é onde começa a visão do provedor de internet, então é o lugar para testar a
promessa. Primeiro a lista de preços por HTTP puro, gravada num arquivo e depois procurada:

```
ana@router:~$ sudo timeout 3 tcpdump -n -i eth1 -w /tmp/http.pcap tcp port 80
tcpdump: listening on eth1, link-type EN10MB (Ethernet), snapshot length 262144 bytes
10 packets captured
10 packets received by filter
0 packets dropped by kernel
ana@router:~$ tcpdump -n -A -r /tmp/http.pcap 2>/dev/null | grep -E "GET|Host:|Location:"
13:57:47.491853 IP 203.0.113.2.45042 > 192.0.2.80.80: Flags [P.], seq 1:89, ack 1, win 63, options [nop,nop,TS val 2471684949 ecr 4226938385], length 88: HTTP: GET /prices.txt HTTP/1.1
.R.U....GET /prices.txt HTTP/1.1
Host: www.example.com
Location: https://www.example.com/prices.txt
```

O roteador leu **o pedido, `GET /prices.txt`, o site, `Host: www.example.com`, e o `Location:` da
resposta**. Se o servidor tivesse respondido com o arquivo, o arquivo estaria lá também. Agora a mesma
busca por HTTPS:

```
ana@router:~$ sudo timeout 3 tcpdump -n -i eth1 -w /tmp/https.pcap tcp port 443
tcpdump: listening on eth1, link-type EN10MB (Ethernet), snapshot length 262144 bytes
36 packets captured
36 packets received by filter
0 packets dropped by kernel
ana@router:~$ tcpdump -n -A -r /tmp/https.pcap 2>/dev/null | grep -c -E "GET|prices|line 1 of"
0
ana@router:~$ tcpdump -n -A -r /tmp/https.pcap 2>/dev/null | grep -o -m 1 "www.example.com"
www.example.com
```

36 pacotes, e **nenhum contém `GET`, `prices` ou a primeira linha do arquivo**. O que o roteador ainda
conseguia ler é o nome: `www.example.com` viaja às claras no Client hello, porque o servidor precisa
dele antes de qualquer chave existir.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"O que o roteador do escritório conseguia ler. Com HTTP puro: os endereços e as portas, sim; o nome, sim, no cabeçalho Host; o caminho, /prices.txt, sim; a própria página, sim; e ninguém saberia se ela tivesse sido alterada no caminho. Com HTTPS: os endereços e as portas, sim; o nome, sim, no ClientHello; o caminho, não; a página, não; e qualquer alteração no caminho quebraria a conexão.\"><defs><marker id=\"ob-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">o que o roteador viu</text><text x=\"330\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">http://</text><text x=\"520\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">https://</text><rect x=\"14\" y=\"38\" width=\"692\" height=\"28\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"20\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">os endereços e as portas</text><text x=\"330\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">sim</text><text x=\"520\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">sim</text><rect x=\"14\" y=\"74\" width=\"692\" height=\"28\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"20\" y=\"88\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o nome, www.example.com</text><text x=\"330\" y=\"88\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">sim, no Host:</text><text x=\"520\" y=\"88\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">sim, no ClientHello</text><rect x=\"14\" y=\"110\" width=\"692\" height=\"28\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"20\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o caminho, /prices.txt</text><text x=\"330\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">sim</text><text x=\"520\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">não</text><rect x=\"14\" y=\"146\" width=\"692\" height=\"28\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"20\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a própria página</text><text x=\"330\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">sim</text><text x=\"520\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">não</text><rect x=\"14\" y=\"182\" width=\"692\" height=\"28\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"20\" y=\"196\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">se foi alterada no caminho</text><text x=\"330\" y=\"196\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">não dá para saber</text><text x=\"520\" y=\"196\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">sim: ela quebraria</text></svg>", "caption": "O HTTPS esconde o que você pediu e o que voltou, e faz uma adulteração falhar de forma visível. Ele não esconde com quem você falou."}
```

Então o HTTPS protege o que você pediu e o que voltou, e faz uma adulteração quebrar a conexão em vez
de dar certo em silêncio. **Ele não esconde qual site você visitou**: os endereços, e na maioria das
conexões o nome, são visíveis para a rede do escritório, o provedor e qualquer um no meio. Um proxy de
empresa ou um filtro de escola que bloqueia sites pelo nome funciona exatamente a partir disso.
