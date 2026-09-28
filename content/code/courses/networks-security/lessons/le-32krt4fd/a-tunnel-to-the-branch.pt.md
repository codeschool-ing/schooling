---
title: As duas metades em ação, num túnel até a filial
version: 1
---

A filial fica no segmento da internet, atrás do seu próprio roteador, `branch`, e a equipe de lá
precisa da aplicação em `app`. Abrir `app` para a internet está fora de questão depois da aula 4. Uma
**VPN site a site** (*site-to-site VPN*) une as duas redes por um túnel cifrado: os pacotes entre a
filial e a matriz viajam dentro dele, e a internet no meio só vê o túnel.

O **WireGuard** é esta aula inteira num só protocolo. Cada ponta tem um par de chaves Curve25519:

```
root@fw:~# umask 077; wg genkey > wg.key; wg pubkey < wg.key > wg.pub; cat wg.pub
KZle1OHbaXxpMFIftlwMzvHqanoqRZ9xDlvDtzi6Oy8=
root@branch:~# umask 077; wg genkey > wg.key; wg pubkey < wg.key > wg.pub; cat wg.pub
RzVWXllEFMVGdig288pqtFqTXs//oftHmzj6v9yYtlU=
```

A configuração no `fw` nomeia a sua própria chave privada e, para o seu único par, a filial: a chave
pública dele, onde encontrá-lo e quais endereços podem chegar dele pelo túnel:

```
root@fw:~# sed "s/^PrivateKey = .*/PrivateKey = (the contents of wg.key)/" wg0.conf
[Interface]
ListenPort = 51820
PrivateKey = (the contents of wg.key)

[Peer]
# the branch office
PublicKey = RzVWXllEFMVGdig288pqtFqTXs//oftHmzj6v9yYtlU=
Endpoint = 203.0.113.70:51820
AllowedIPs = 10.99.0.2/32, 192.168.30.0/24
```

`AllowedIPs` é ao mesmo tempo uma tabela de rotas e um filtro: os pacotes que chegam pelo túnel vindos
desse par têm de vir desses endereços, ou são descartados. A interface é ativada em cada ponta, com uma
rota para a rede do outro lado passando por ela, e o `fw` ganha duas regras, uma que deixa entrar o UDP
do túnel e outra que deixa a filial usar a aplicação:

```
root@fw:~# wireguard-go wg0 2>/dev/null && wg setconf wg0 wg0.conf && ip addr add 10.99.0.1/24 dev wg0 && ip link set wg0 up && ip route add 192.168.30.0/24 dev wg0
root@branch:~# wireguard-go wg0 2>/dev/null && wg setconf wg0 wg0.conf && ip addr add 10.99.0.2/24 dev wg0 && ip link set wg0 up && ip route add 192.168.10.0/24 dev wg0 && ip route add 192.168.20.0/24 dev wg0
root@fw:~# nft list ruleset | grep -E "branch"
		iifname "wg0" oifname "eth3" ip daddr 192.168.20.10 tcp dport 8080 ct state new accept comment "the branch uses the application"
		iifname "eth0" udp dport 51820 accept comment "the branch tunnel"
```

Então um computador na filial pede a página de saúde da aplicação, e o `fw` mostra o túnel:

```
ana@branchpc:~$ curl -s -m5 http://192.168.20.10:8080/health
status: ok
root@fw:~# wg show wg0 | grep -vE "public key|private key"
interface: wg0
  listening port: 51820

peer: RzVWXllEFMVGdig288pqtFqTXs//oftHmzj6v9yYtlU=
  endpoint: 203.0.113.70:51820
  allowed ips: 10.99.0.2/32, 192.168.30.0/24
  latest handshake: 2 seconds ago
  transfer: 1.10 KiB received, 860 B sent
```

**Um handshake dois segundos atrás**, e tráfego nos dois sentidos. O que o segmento da internet
carregou enquanto isso, gravado na interface externa do `fw`:

```
root@fw:~# cut -d" " -f2- wire.txt
IP 203.0.113.70.51820 > 203.0.113.2.51820: UDP, length 148
IP 203.0.113.2.51820 > 203.0.113.70.51820: UDP, length 92
IP 203.0.113.70.51820 > 203.0.113.2.51820: UDP, length 32
IP 203.0.113.70.51820 > 203.0.113.2.51820: UDP, length 96
IP 203.0.113.70.51820 > 203.0.113.2.51820: UDP, length 96
IP 203.0.113.70.51820 > 203.0.113.2.51820: UDP, length 96
```

Só UDP entre os dois roteadores, na porta 51820. Os dois primeiros pacotes, **de 148 e 92 bytes, são o
handshake**: a metade assimétrica, em que as duas pontas combinam seus pares de chaves em chaves
simétricas novas. Tudo o que vem depois é a metade simétrica, ChaCha20-Poly1305: o pacote de 32 bytes é
um keepalive vazio, e os demais carregam o pedido da filial e a resposta. Quem está no caminho descobre
que os dois escritórios conversam, com que frequência e quanto, e nada do que foi dito.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"Um túnel entre sedes. branchpc, na filial, manda um pedido para app. O roteador da filial, branch, o coloca dentro de um pacote WireGuard endereçado ao fw, porta UDP 51820, pelo segmento da internet. O fw o tira do túnel e o passa pela chain forward até app na porta 8080. No segmento da internet só se veem os pacotes UDP externos entre 203.0.113.70 e 203.0.113.2.\"><defs><marker id=\"vp-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"60\" width=\"120\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">branchpc</text><text x=\"30\" y=\"93\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">192.168.30.20</text><rect x=\"170\" y=\"60\" width=\"120\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"180\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">branch</text><text x=\"180\" y=\"93\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">wg0</text><rect x=\"430\" y=\"60\" width=\"120\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"440\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">fw</text><text x=\"440\" y=\"93\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">wg0</text><rect x=\"580\" y=\"60\" width=\"120\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"590\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">app</text><text x=\"590\" y=\"93\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">:8080</text><path d=\"M140 83 L170 83\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#vp-ah-paper-dim)\"></path><path d=\"M550 83 L580 83\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#vp-ah-paper-dim)\"></path><rect x=\"290\" y=\"70\" width=\"140\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"83\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">UDP 51820</text><rect x=\"160\" y=\"20\" width=\"400\" height=\"110\" rx=\"3\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"168\" y=\"32\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">internet</text><text x=\"360\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">cifrado: ChaCha20-Poly1305</text><text x=\"20\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">dentro do túnel: GET /health de 192.168.30.20 para 192.168.20.10</text><text x=\"20\" y=\"180\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">no segmento da internet: UDP entre 203.0.113.70 e 203.0.113.2, tamanhos e horários</text></svg>", "caption": "O pedido viaja dentro do túnel; a internet vê dois roteadores trocando UDP.", "same": ["internet"]}
```

**O túnel não substitui o firewall.** Os pacotes que saem de `wg0` ainda atravessam a chain `forward`
do `fw`, e a regra escrita para eles concede à filial exatamente o que ela precisa, a aplicação na 8080.
Uma VPN decide quem pode entrar na rede; a matriz da aula 4 continua decidindo o que se pode alcançar
depois de entrar.
