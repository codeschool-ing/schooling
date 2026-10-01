---
title: Dois filtros, duas linguagens
version: 1
---

**O Wireshark tem dois filtros, eles falam linguagens diferentes e agem em momentos diferentes.** A
maior parte da confusão com captura vem de tratá-los como um só.

O filtro de captura age no fio, antes de qualquer coisa ser gravada. Ele é escrito em BPF, a
linguagem da biblioteca libpcap, que é também o que o `tcpdump` fala: `host 192.0.2.21`,
`tcp port 80`, `not arp`. Ele conhece endereços, portas, protocolos e posições de bytes, e nada sobre
o que HTTP ou DNS significam. **Um pacote que ele rejeita nunca é gravado**, e nada consegue
recuperá-lo depois.

O filtro de exibição age sobre pacotes já capturados, na memória ou num arquivo. É a linguagem do
próprio Wireshark, feita dos nomes dos campos que os dissectors decodificam: `ip.addr == 192.0.2.21`,
`tcp.port == 80`, `http.response.code >= 400`. **Ele esconde pacotes e não apaga nenhum**; limpe o
filtro e todos voltam.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 790 186\" role=\"img\" aria-label=\"Uma linha de montagem da esquerda para a direita: o fio, depois o filtro de captura, escrito em BPF como no tcpdump e passado com -f, depois o arquivo files.pcap, depois o filtro de exibição, escrito com nomes de campo do Wireshark e passado com -Y, depois a tela. O que o filtro de captura rejeita nunca é gravado; o que o filtro de exibição rejeita fica oculto e continua no arquivo.\"><defs><marker id=\"fl-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"60\" width=\"100\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"70.0\" y=\"85.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o fio</text><rect x=\"160\" y=\"60\" width=\"150\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"235.0\" y=\"78.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">filtro de captura</text><text x=\"235.0\" y=\"93.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">-f \"tcp port 80\"</text><rect x=\"350\" y=\"60\" width=\"110\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"405.0\" y=\"85.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">files.pcap</text><rect x=\"500\" y=\"60\" width=\"150\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"575.0\" y=\"78.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">filtro de exibição</text><text x=\"575.0\" y=\"93.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">-Y \"http.request\"</text><rect x=\"690\" y=\"60\" width=\"80\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"730.0\" y=\"85.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">tela</text><path d=\"M120 85 L160 85\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#fl-ah)\"></path><path d=\"M310 85 L350 85\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#fl-ah)\"></path><path d=\"M460 85 L500 85\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#fl-ah)\"></path><path d=\"M650 85 L690 85\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#fl-ah)\"></path><text x=\"235\" y=\"44\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">BPF, como no tcpdump</text><text x=\"575\" y=\"44\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">nomes de campo do Wireshark</text><path d=\"M235 110 L235 136\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#fl-ah)\"></path><text x=\"235\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">o que ele rejeita</text><text x=\"235\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">nunca é gravado</text><path d=\"M575 110 L575 136\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#fl-ah)\"></path><text x=\"575\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">o que ele rejeita fica oculto</text><text x=\"575\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">e continua no arquivo</text></svg>", "caption": "Os mesmos dois filtros existem na janela e no tshark, nos mesmos dois lugares. Só o primeiro pode perder um pacote de vez."}
```

| | filtro de captura | filtro de exibição |
|---|---|---|
| linguagem | BPF, como no `tcpdump` | nomes de campo do Wireshark |
| age | antes de gravar | depois, sobre o que foi gravado |
| o que ele descarta | some | fica oculto, ainda no arquivo |
| no `tshark` | `-f` | `-Y` |
| na janela | opções de captura, antes do Start | a barra acima da lista de pacotes |
| um host | `host 192.0.2.21` | `ip.addr == 192.0.2.21` |
| uma porta | `tcp port 80` | `tcp.port == 80` |
| entende HTTP | não | sim |

O arquivo da seção anterior, com seis perguntas:

```
ana@mon:~$ tshark -r files.pcap -Y dns
   11 0.008987287 192.168.10.10 → 192.0.2.53   DNS 98 Standard query 0x9ce1 A www.example.com OPT
   12 0.009225585   192.0.2.53 → 192.168.10.10 DNS 130 Standard query response 0x9ce1 A www.example.com A 192.0.2.80 OPT
   13 0.028355971 192.168.10.10 → 192.0.2.53   DNS 101 Standard query 0x7429 A nosuch.example.com OPT
   14 0.028578484   192.0.2.53 → 192.168.10.10 DNS 167 Standard query response 0x7429 No such name A nosuch.example.com SOA ns.example.com OPT
ana@mon:~$ tshark -r files.pcap -Y "http.request"
    4 0.000137514 192.168.10.10 → 192.0.2.21   HTTP 139 GET / HTTP/1.1 
   39 1.105093152 192.168.10.10 → 192.0.2.23   HTTP 151 GET /nothing-here HTTP/1.1 
ana@mon:~$ tshark -r files.pcap -Y "http.response.code >= 400"
   41 1.105425089   192.0.2.23 → 192.168.10.10 HTTP 360 HTTP/1.1 404 Not Found  (text/html)
ana@mon:~$ tshark -r files.pcap -Y "tcp.flags.syn == 1 && tcp.flags.ack == 0"
    1 0.000000000 192.168.10.10 → 192.0.2.21   TCP 74 59928 → 80 [SYN] Seq=0 Win=64240 Len=0 MSS=1460 SACK_PERM TSval=3641093702 TSecr=0 WS=1024
   19 1.068646331 192.168.10.10 → 192.0.2.21   TCP 74 51132 → 443 [SYN] Seq=0 Win=64240 Len=0 MSS=1460 SACK_PERM TSval=1132118576 TSecr=0 WS=1024
   36 1.104894905 192.168.10.10 → 192.0.2.23   TCP 74 47586 → 80 [SYN] Seq=0 Win=64240 Len=0 MSS=1460 SACK_PERM TSval=327870121 TSecr=0 WS=1024
ana@mon:~$ tshark -r files.pcap -Y "icmp && ip.dst == 192.0.2.22"
   15 0.041952556 192.168.10.10 → 192.0.2.22   ICMP 98 Echo (ping) request  id=0x0ccf, seq=1/256, ttl=64
   17 1.062237869 192.168.10.10 → 192.0.2.22   ICMP 98 Echo (ping) request  id=0x0ccf, seq=2/512, ttl=64
ana@mon:~$ tshark -r files.pcap -Y "tls.handshake.type == 1" -T fields -e ip.dst -e tls.handshake.extensions_server_name
192.0.2.21	www.example.com
```

Cada uma delas é algo que um filtro de captura não conseguiria perguntar. `dns` achou os quatro
pacotes das consultas, e o quadro 14 já diz `No such name` para `nosuch.example.com`. `http.request`
achou as duas requisições pelo que elas são, e `http.response.code >= 400` achou a que falhou, um 404
de `web3`; para o BPF cada uma delas era só um segmento TCP com bytes dentro. Um SYN sem ACK é uma
conexão sendo aberta, e foram três: `web1` na 80 e na 443, e `web3` na 80.

A última imprime dois campos em vez de uma linha de resumo. **O nome do site HTTPS, `www.example.com`, atravessou o fio em texto claro**, no Client Hello,
embora tudo depois dele seja criptografado. A aula 13 abre esse handshake.

**A regra de trabalho é capturar largo e exibir estreito.** Dê à captura um filtro simples, que só tire o que você tem certeza de que não vai precisar: o `not arp` acima, ou `not port 22` para não
gravar a sua própria sessão SSH. Depois filtre a exibição quantas vezes a pergunta mudar. Um filtro de
captura estreito demais custa uma segunda captura, e a falha pode não se repetir enquanto você espera.
