---
title: Subindo o túnel, e um handshake de dois pacotes
version: 1
---

O `wg-quick` lê o arquivo e faz o resto: cria a interface, carrega as chaves, põe o endereço e
transforma cada faixa de `AllowedIPs` numa rota. Neste laboratório ele também mostra o que acontece
quando o kernel não tem WireGuard:

```
ana@hq:~$ sudo wg-quick up wg0
[#] ip link add wg0 type wireguard
Error: Unknown device type.
[!] Missing WireGuard kernel module. Falling back to slow userspace implementation.
[#] wireguard-go wg0
┌──────────────────────────────────────────────────────┐
│                                                      │
│   Running wireguard-go is not required because this  │
│   kernel has first class support for WireGuard. For  │
│   information on installing the kernel module,       │
│   please visit:                                      │
│         https://www.wireguard.com/install/           │
│                                                      │
└──────────────────────────────────────────────────────┘
[#] wg setconf wg0 /dev/fd/63
[#] ip -4 address add 10.20.0.1/24 dev wg0
[#] ip link set mtu 1420 up dev wg0
[#] ip -4 route add 192.168.20.0/24 dev wg0
```

O primeiro comando falha com `Unknown device type`, o jeito do kernel de dizer que não tem o módulo do
WireGuard, **então o `wg-quick` recorre ao `wireguard-go`**, o mesmo protocolo escrito como um programa
comum, pelo mesmo autor. Visto de fora ele se comporta igual, só que mais devagar.

**O aviso logo abaixo está errado sobre esta máquina.** Ele diz que o kernel tem suporte de primeira
classe ao WireGuard, uma linha depois de o kernel se recusar a criar o dispositivo. O WireGuard faz
parte do Linux desde a versão 5.6, e o aviso foi escrito para esse caso comum; o kernel deste
laboratório foi compilado sem ele. Num servidor normal o primeiro comando dá certo e nada do resto
aparece.

As últimas quatro linhas são o arquivo sendo aplicado. **`mtu 1420` é 1500 menos 80**, o espaço que o
WireGuard reserva para os próprios cabeçalhos quando o pacote externo é IPv6, o maior dos dois casos. E
`192.168.20.0/24 dev wg0` é a LAN da filial que estava em `AllowedIPs`, agora uma rota.

Nada atravessou a rede ainda. **O WireGuard não manda nada enquanto não houver o que mandar**, então o
handshake acontece quando o laptop pinga o caixa. O `tshark` foi iniciado antes, no enlace do provedor
em direção à filial, e imprimiu os quatro pacotes quando parou:

```
ana@laptop:~$ ping -c 2 192.168.20.30
PING 192.168.20.30 (192.168.20.30) 56(84) bytes of data.
64 bytes from 192.168.20.30: icmp_seq=1 ttl=62 time=2.85 ms
64 bytes from 192.168.20.30: icmp_seq=2 ttl=62 time=0.944 ms

--- 192.168.20.30 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1002ms
rtt min/avg/max/mdev = 0.944/1.898/2.853/0.954 ms
ana@isp:~$ tshark -n -i eth1 -c 4 -f "udp port 51820"
Capturing on 'eth1'
4 packets captured
    1 0.000000000  203.0.113.2 → 198.51.100.2 WireGuard 190 Handshake Initiation, sender=0x2881E370
    2 0.000755650 198.51.100.2 → 203.0.113.2  WireGuard 134 Handshake Response, sender=0x05725C3D, receiver=0x2881E370
    3 0.001210443  203.0.113.2 → 198.51.100.2 WireGuard 170 Transport Data, receiver=0x05725C3D, counter=0, datalen=96
    4 0.001769928 198.51.100.2 → 203.0.113.2  WireGuard 170 Transport Data, receiver=0x2881E370, counter=0, datalen=96
```

Quatro pacotes, e **os dois primeiros são o handshake inteiro**. `hq` manda um Handshake Initiation de
190 bytes, `branch` responde com um Handshake Response de 134, e a partir daí os dois têm chaves de
sessão. Os pacotes 3 e 4 são o ping e a resposta, como `Transport Data`.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 760 330\" role=\"img\" aria-label=\"Uma sequência entre hq em 203.0.113.2 e branch em 198.51.100.2, tirada da captura do tshark. Em 0,000000000 segundo hq manda um Handshake Initiation de 190 bytes; em 0,000755650 branch manda um Handshake Response de 134 bytes. Daí em diante os dois têm chaves de sessão. Em 0,001210443 hq manda Transport Data de 170 bytes, o ping, e em 0,001769928 branch manda Transport Data de 170 bytes, a resposta.\"><defs><marker id=\"hs-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"180\" y=\"14\" width=\"140\" height=\"42\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"250.0\" y=\"28.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">hq</text><text x=\"250.0\" y=\"43.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">203.0.113.2</text><rect x=\"520\" y=\"14\" width=\"140\" height=\"42\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"590.0\" y=\"28.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">branch</text><text x=\"590.0\" y=\"43.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">198.51.100.2</text><path d=\"M250 56 L250 318\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M590 56 L590 318\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"3 4\"></path><text x=\"20\" y=\"34\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">tempo (s)</text><text x=\"20\" y=\"100\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.000000000</text><path d=\"M254 100 L586 100\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#hs-ah)\"></path><text x=\"420.0\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1  Handshake Initiation</text><text x=\"420.0\" y=\"91\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">190 bytes</text><text x=\"20\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.000755650</text><path d=\"M586 160 L254 160\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#hs-ah)\"></path><text x=\"420.0\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">2  Handshake Response</text><text x=\"420.0\" y=\"151\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">134 bytes</text><text x=\"20\" y=\"240\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.001210443</text><path d=\"M254 240 L586 240\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#hs-ah)\"></path><text x=\"420.0\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">3  Transport Data</text><text x=\"420.0\" y=\"231\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">170 bytes</text><text x=\"238\" y=\"240\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">o ping</text><text x=\"20\" y=\"296\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.001769928</text><path d=\"M586 296 L254 296\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#hs-ah)\"></path><text x=\"420.0\" y=\"274\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">4  Transport Data</text><text x=\"420.0\" y=\"287\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">170 bytes</text><text x=\"238\" y=\"296\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">a resposta</text><path d=\"M190 200 L650 200\" stroke=\"var(--scan)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"660\" y=\"130\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">handshake</text><text x=\"660\" y=\"194\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">chaves de sessão</text><text x=\"660\" y=\"207\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">existem daqui</text><text x=\"660\" y=\"220\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">em diante</text><text x=\"660\" y=\"268\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">dados</text></svg>", "caption": "Os quatro pacotes da captura do tshark, em ordem. Dois pacotes combinam as chaves, e o terceiro já leva o ping do laptop.", "same": ["handshake"]}
```

Cada lado escolheu um índice aleatório para a sessão, `sender=0x2881E370` para `hq` e
`sender=0x05725C3D` para `branch`, e todo pacote de dados leva o índice de quem recebe. O receptor
encontra a sessão por esse número, não pelo endereço de onde o pacote veio, e a seção sobre roaming
mostra por que isso importa. `counter=0` marca o primeiro pacote de dados em cada sentido. O contador
sobe um por pacote e o receptor recusa um número que já viu, então um pacote gravado não pode ser
reenviado depois.

Os tamanhos fecham. Um pacote de dados tem 170 bytes no fio para um ping de 84: 14 de Ethernet, 20 de IP
externo, 8 de UDP, 16 de cabeçalho do WireGuard, o ping completado até 96 bytes, que é o `datalen=96`,
e 16 de tag de autenticação. A primeira resposta levou 2,85 ms e a segunda 0,944 ms, porque a primeira
esperou o handshake; sem atraso em nenhum enlace, os dois tempos são um computador falando consigo
mesmo. **O primeiro ping não se perdeu**: o WireGuard segura o pacote enquanto a sessão é combinada.

O `wg show` é o estado da interface:

```
ana@hq:~$ sudo wg show
interface: wg0
  public key: B6qH2hb1U5hsBki+4mN/m7AxAAKMeL7maFXl3uAeH2I=
  private key: (hidden)
  listening port: 51820

peer: n/CGaD63Wk0H9pfG6sbwBbJdh+XswYcDf0wmiU4zFT8=
  endpoint: 198.51.100.2:51820
  allowed ips: 10.20.0.2/32, 192.168.20.0/24
  latest handshake: 1 second ago
  transfer: 348 B received, 404 B sent

peer: FYBqYy68QPdITaZcZGko576tjvRUt5cUWsMsdGzbgkE=
  allowed ips: 10.20.0.3/32
```

O par da filial tem endpoint, um handshake de um segundo atrás e contadores de bytes que batem com a
captura: **404 B enviados são 148 + 128 + 128**, a carga UDP da iniciação e dois pacotes de dados, e 348
B recebidos são 92 + 128 + 128. O par de casa só tem os IPs permitidos. Ele nunca mandou nada, então
`hq` não tem endpoint nem handshake para ele.

Esse é o estado normal de um par que ninguém está usando. **Não existe conexão para estar de pé ou
caída, só um handshake recente ou não**, e enquanto há tráfego um novo é feito a cada dois minutos, com
chaves novas.
