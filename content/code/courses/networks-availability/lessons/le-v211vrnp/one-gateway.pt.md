---
title: Um gateway, e um jeito de ter dois
version: 1
---

O jeito óbvio de deixar redundante a saída de um escritório é ligar um segundo roteador. **Sozinho, um
segundo roteador não muda nada para os hosts.** Um host não conhece roteadores em geral; conhece um
endereço, o gateway padrão, e manda para lá tudo o que não está na própria rede. A tabela de rotas do
laptop diz isso em duas linhas:

```
ana@laptop:~$ ip route
default via 192.168.10.1 dev eth0 
192.168.10.0/24 dev eth0 proto kernel scope link src 192.168.10.20 
```

Quando o roteador em `192.168.10.1` morre, o laptop continua mandando para `192.168.10.1`, e ninguém
responde. Um segundo roteador no mesmo cabo, funcionando perfeitamente, nem é consultado. A aula 14 chamou
isso de redundância que os hosts não conseguem usar, e o gateway é onde os escritórios dão de cara com ela
primeiro.

Mudar todos os hosts não é a resposta. Podem ser centenas, alguns deles impressoras e telefones que pegam o
gateway do DHCP uma vez e nunca mais pensam nisso. **A solução é deixar os hosts em paz e fazer o endereço
mudar de lugar.** Dois roteadores combinam que um deles responde por `192.168.10.1` e o outro assume no
momento em que o primeiro parar. O endereço não pertence a nenhuma das duas máquinas. Pertence a um
**roteador virtual**, um grupo de roteadores reais, e os hosts não têm como saber qual roteador real está
por trás dele num dado dia.

Isso é o VRRP, Virtual Router Redundancy Protocol, um padrão da IETF: a versão 2 é a RFC 3768 e a versão
3, que acrescenta IPv6, é a RFC 5798. O grupo tem um número, o **VRID**, para que vários grupos possam
dividir uma LAN. Cada roteador do grupo tem uma **prioridade**, e o de maior prioridade que estiver vivo é
o **master**, que fica com o endereço. Os outros são **backups**, que escutam.

## Os dois roteadores

A matriz tem dois roteadores, `hq` e `hq2`, os dois na LAN e os dois com um enlace para o provedor. Para
esta aula `hq` muda de `192.168.10.1` para `192.168.10.2`, e `hq2` fica em `192.168.10.3`, o que libera o
`.1` para virar o endereço virtual. Uma rede de verdade faz a mesma coisa quando adota VRRP: **os hosts
ficam com o gateway que sempre tiveram**, e os roteadores saem do caminho dele. Em `hq`, com o endereço de
hardware que combina com o `.2`, para que um MAC numa captura continue dizendo de quem é:

```sh
sudo ip addr del 192.168.10.1/24 dev eth0
sudo ip link set eth0 address 52:54:00:a8:0a:02
sudo ip addr add 192.168.10.2/24 dev eth0
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 750 270\" role=\"img\" aria-label=\"O laptop em 192.168.10.20 tem um gateway, 192.168.10.1. Esse endereço pertence a um roteador virtual, VRID 10, desenhado como uma caixa tracejada em volta de dois roteadores reais: hq em 192.168.10.2 com MAC 52:54:00:a8:0a:02, master com prioridade 150, e hq2 em 192.168.10.3 com MAC 52:54:00:a8:0a:03, backup com prioridade 100. hq manda um anúncio para 224.0.0.18 a cada segundo, que hq2 ouve. Os dois roteadores chegam ao roteador do provedor em 203.0.113.1 pelo eth1.\"><defs><marker id=\"vr-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"106\" width=\"130\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"85.0\" y=\"123.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">laptop</text><text x=\"85.0\" y=\"138.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">192.168.10.20</text><text x=\"85\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">gateway:</text><text x=\"85\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">192.168.10.1</text><rect x=\"220\" y=\"22\" width=\"300\" height=\"236\" rx=\"4\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"232\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">roteador virtual, vrid 10</text><rect x=\"300\" y=\"52\" width=\"140\" height=\"26\" rx=\"13\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"370\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">192.168.10.1</text><path d=\"M150 130 L296 66\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#vr-ah)\"></path><rect x=\"250\" y=\"96\" width=\"240\" height=\"58\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"266\" y=\"113\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">hq</text><text x=\"474\" y=\"113\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">master, prioridade 150</text><text x=\"266\" y=\"136\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">192.168.10.2   52:54:00:a8:0a:02</text><rect x=\"250\" y=\"176\" width=\"240\" height=\"58\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"266\" y=\"193\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">hq2</text><text x=\"474\" y=\"193\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">backup, prioridade 100</text><text x=\"266\" y=\"216\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">192.168.10.3   52:54:00:a8:0a:03</text><path d=\"M 250 140 C 232 150, 232 176, 248 192\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\" marker-end=\"url(#vr-ah)\"></path><text x=\"370\" y=\"250\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">hq para 224.0.0.18, a cada 1 s</text><rect x=\"600\" y=\"136\" width=\"130\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"665.0\" y=\"153.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">isp</text><text x=\"665.0\" y=\"168.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">203.0.113.1</text><path d=\"M490 125 L600 152\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M490 205 L600 168\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"545\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">eth1</text><text x=\"545\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">eth1</text></svg>", "caption": "O laptop conhece um endereço, e o endereço pertence a quem, dos dois roteadores, for master. Cada roteador mantém o próprio endereço e o próprio endereço de hardware; só 192.168.10.1 muda de lugar.", "same": ["gateway:"]}
```

O daemon de VRRP nos dois é o keepalived, que também roda os health checks da aula 16. Esta é a
configuração dele em `hq`, `/etc/keepalived/keepalived.conf`, para escrever com `sudo nano`:

```schooling-example
{"language": "conf", "file": "keepalived.conf", "parts": [{"code": "vrrp_instance office {\n    state BACKUP\n    interface eth0", "note": "Uma instância VRRP, chamada `office`. Os dois roteadores começam como backup e deixam a eleição decidir, e `eth0` é o lado da LAN, por onde os anúncios saem e chegam."}, {"code": "    virtual_router_id 10\n    priority 150\n    advert_int 1", "note": "O número do grupo nesta LAN, a prioridade deste roteador e o intervalo dos anúncios em segundos. `hq2` tem o mesmo arquivo com prioridade 100, então `hq` ganha enquanto está saudável."}, {"code": "    virtual_ipaddress {\n        192.168.10.1/24\n    }", "note": "O endereço que muda de lugar: o gateway padrão dos hosts. Pertence a quem for master, e a nenhum dos dois fora isso."}, {"code": "    track_interface {\n        eth1\n    }\n}", "note": "`eth1` é o enlace com o provedor. Se ele cair, este roteador abre mão do endereço, mesmo com o lado da LAN funcionando."}]}
```

`hq2` recebe o mesmo arquivo com uma mudança, `priority 100` em vez de `priority 150`. Com os dois roteadores no mesmo VRID e com o mesmo
endereço virtual, só falta decidir quem vai primeiro, e isso é uma eleição.
