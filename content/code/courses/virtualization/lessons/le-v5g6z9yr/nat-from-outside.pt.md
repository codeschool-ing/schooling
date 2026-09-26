---
title: NAT, visto do escritório
version: 1
---

O convidado na rede default, e o que o escritório vê dele:

```
ana@vmn:~$ ip -br addr show enp1s0; ip route | head -1
enp1s0           UP             192.168.122.232/24 metric 100 fe80::5054:ff:fe55:d409/64 
default via 192.168.122.1 dev enp1s0 proto dhcp src 192.168.122.232 metric 100 
ana@vmn:~$ curl -sS http://10.0.0.50/
office printer: ready
ana@host:~$ tail -1 /var/log/office-http.log
10.0.0.1 - - [25/Sep/2026 21:14:27] "GET / HTTP/1.1" 200 -
ana@host:~$ sudo ip netns exec printer curl -sS -m 5 http://$(getent hosts vmn | cut -d" " -f1)/
curl: (7) Failed to connect to 192.168.122.232 port 80 after 0 ms: Couldn't connect to server
```

A vmn tem `192.168.122.232`, do libvirt, e o caminho dela para fora é `192.168.122.1`, o host. Ela alcançou a
impressora. Mas o log da impressora diz que o visitante foi **`10.0.0.1`**, o host: o escritório nunca
viu o endereço da vmn. E quando a impressora tentou alcançar a vmn, nem conseguiu começar:
`192.168.122.0/24` não quer dizer nada na rede do escritório, e ninguém lá tem rota para ele.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 170\" role=\"img\" aria-label=\"NAT, passo a passo. A vmn manda um pedido do próprio endereço, 192.168.122.232. O host reescreve o remetente para o próprio endereço no escritório, 10.0.0.1, e guarda a conexão. O log da impressora registra 10.0.0.1. A resposta vai para 10.0.0.1, e o host a repassa para a vmn.\"><defs><marker id=\"nt-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"40\" width=\"140\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">vmn</text><rect x=\"290\" y=\"40\" width=\"170\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"304\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">o host reescreve o remetente</text><rect x=\"580\" y=\"40\" width=\"120\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"594\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">o log da impressora</text><text x=\"594\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">10.0.0.1</text><path d=\"M162 58 L288 58\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#nt-ah)\"></path><text x=\"170\" y=\"32\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">de 192.168.122.232</text><path d=\"M462 58 L578 58\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#nt-ah)\"></path><text x=\"470\" y=\"32\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">de 10.0.0.1</text><path d=\"M 640 92 L 640 106 L 90 106 L 90 94\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#nt-ah)\" stroke-dasharray=\"4 3\"></path><text x=\"20\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">as respostas vão para 10.0.0.1, e o host as repassa</text></svg>", "caption": "A rede do escritório nunca vê o endereço do convidado, só o do host. É por isso que um convidado em NAT alcança tudo o que o host alcança, e nada consegue começar uma conversa com ele."}
```

Esse é o caráter todo do NAT. **Um convidado em NAT alcança tudo o que o host alcança, e nada o
alcança.** É o padrão mais seguro para um convidado que só precisa navegar e se atualizar, e o errado
para um convidado que precisa ser servidor para alguém além do host.

A exceção é o **redirecionamento de portas** (port forwarding): uma regra no host que manda uma porta
dele para uma do convidado, como a porta 8080 do host para a 80 do convidado. O VirtualBox tem isso no
botão *Redirecionamento de Portas* da placa em NAT; o libvirt precisa de uma regra de firewall sua. Cada
porta redirecionada é um furo pequeno na proteção do NAT, feito de propósito.
