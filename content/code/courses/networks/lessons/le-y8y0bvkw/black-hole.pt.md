---
title: Páginas pequenas carregam, grandes travam
version: 1
---

A descoberta do MTU do caminho depende de uma mensagem ICMP conseguir voltar. Muitos firewalls
descartam ICMP por costume, com a teoria de que `ping` é só coisa de atacante. Aqui o roteador do
provedor ganha esse costume, e os caches de rota são limpos para ninguém lembrar do MTU menor:

```
ana@laptop:~$ curl -sS -m 5 -o /dev/null -w '%{http_code} %{size_download} bytes\n' https://www.example.com/
200 173 bytes
ana@laptop:~$ curl -sS -m 5 -o /dev/null -w '%{http_code} %{size_download} bytes\n' https://www.example.com/prices.txt
curl: (28) Operation timed out after 5002 milliseconds with 0 out of 186893 bytes received
200 0 bytes
```

**A página inicial carrega e a lista de preços não.** A página inicial tem 173 bytes, e todo pacote
daquela conexão era pequeno. A lista de preços tem 186893 bytes, e o servidor a manda em pacotes
cheios, de 1500 bytes. Cada um chega ao roteador do provedor, não cabe na linha de 1492 bytes e é
descartado; o ICMP que avisaria também é descartado. O curl recebeu os cabeçalhos, que eram pequenos, e
por isso sabia o tamanho do que vinha, e depois esperou cinco segundos por bytes que nunca chegaram:
`0 out of 186893 bytes received`.

Isso é um **buraco negro de PMTU**, e é uma das falhas mais confusas que o suporte encontra. Nada está
fora do ar. O `ping` funciona. Sites pequenos funcionam. E-mail com anexo pequeno funciona e com anexo
grande trava. Uma VPN, que acrescenta um cabeçalho seu e encolhe o MTU de novo, piora a situação.

O conserto que os roteadores usam é o **MSS clamping**. No handshake do TCP, cada lado anuncia o seu
**MSS**, *maximum segment size*, o máximo de dados que aceita num segmento:

```
ana@laptop:~$ sudo tcpdump -n -c 2 -i eth0 "tcp[tcpflags] & tcp-syn != 0"
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on eth0, link-type EN10MB (Ethernet), snapshot length 262144 bytes
13:16:11.376614 IP 192.168.10.20.46916 > 192.0.2.80.443: Flags [S], seq 2699027394, win 64240, options [mss 1460,sackOK,TS val 3790312328 ecr 0,nop,wscale 10], length 0
13:16:11.376962 IP 192.0.2.80.443 > 192.168.10.20.46916: Flags [S.], seq 1567898401, ack 2699027395, win 65160, options [mss 1460,sackOK,TS val 2150135722 ecr 3790312328,nop,wscale 10], length 0
2 packets captured
2 packets received by filter
0 packets dropped by kernel
```

`mss 1460` nos dois sentidos: 1500 menos 20 bytes de cabeçalho IP e 20 de cabeçalho TCP. O roteador
pode reescrever esse número quando o handshake passa por ele, e então nenhum dos lados manda um
segmento grande demais para o enlace mais estreito:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 170\" role=\"img\" aria-label=\"O que cabe num pacote. Numa LAN Ethernet com MTU de 1500 bytes, 20 vão para o cabeçalho IP e 20 para o cabeçalho TCP, e sobra um MSS de 1460 bytes de dados. Numa linha DSL com PPPoE, o MTU é 1492, e os mesmos dois cabeçalhos deixam um MSS de 1452.\"><defs><marker id=\"bg-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">LAN Ethernet, MTU 1500</text><rect x=\"20\" y=\"30\" width=\"58\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"49\" y=\"45\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">IP 20</text><rect x=\"78\" y=\"30\" width=\"58\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"107\" y=\"45\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">TCP 20</text><rect x=\"136\" y=\"30\" width=\"506.1333333333333\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"148\" y=\"45\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">dados: MSS 1460</text><text x=\"20\" y=\"88\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">DSL com PPPoE, MTU 1492</text><rect x=\"20\" y=\"96\" width=\"58\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"49\" y=\"111\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">IP 20</text><rect x=\"78\" y=\"96\" width=\"58\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"107\" y=\"111\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">TCP 20</text><rect x=\"136\" y=\"96\" width=\"503.36\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"148\" y=\"111\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">dados: MSS 1452</text></svg>", "caption": "O MSS é o MTU menos os dois cabeçalhos. O clamping reescreve o MSS que cada lado anuncia, e nenhum dos dois manda um segmento que o enlace mais estreito não carrega.", "same": ["IP 20", "TCP 20"]}
```

```
ana@router:~$ sudo nft add table inet mangle
ana@router:~$ sudo nft add chain inet mangle forward '{ type filter hook forward priority mangle; }'
ana@router:~$ sudo nft add rule inet mangle forward tcp flags syn tcp option maxseg size set rt mtu
ana@router:~$ sudo nft list table inet mangle
table inet mangle {
        chain forward {
                type filter hook forward priority mangle; policy accept;
                tcp flags syn tcp option maxseg size set rt mtu
        }
}
ana@laptop:~$ curl -sS -m 5 -o /dev/null -w '%{http_code} %{size_download} bytes\n' https://www.example.com/prices.txt
200 186893 bytes
```

`set rt mtu` quer dizer: reduza o MSS para caber no MTU da rota que este pacote segue. A lista de preços
agora chega inteira, os 186893 bytes, e o handshake do jeito que o servidor web recebeu mostra por
quê:

```
ana@www:~$ sudo tcpdump -n -c 1 -i eth0 "tcp[tcpflags] == tcp-syn"
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on eth0, link-type EN10MB (Ethernet), snapshot length 262144 bytes
13:16:22.132563 IP 203.0.113.2.48122 > 192.0.2.80.443: Flags [S], seq 2712839801, win 64240, options [mss 1452,sackOK,TS val 1201598779 ecr 0,nop,wscale 10], length 0
1 packet captured
1 packet received by filter
0 packets dropped by kernel
```

**`mss 1452`**, que é 1492 menos 40. A maioria dos roteadores de casa e de escritório faz isso sozinha
em linhas PPPoE. Quando uma falha se parece com esta e eles não fazem, esta é a opção a procurar, que
nos menus dos roteadores costuma se chamar *MSS clamping* ou *TCP MSS adjust*.
