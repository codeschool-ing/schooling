---
title: Quem pode se conectar
version: 1
---

Todo controle deste curso até aqui confiou em uma coisa sem dizer: que o que estiver conectado à LAN
do escritório tem direito de estar ali. A aula 7 mostrou o que uma máquina no segmento pode fazer com as
vizinhas, e a aula 21 isolou os servidores uns dos outros. Nenhuma das duas faz a pergunta que está por
baixo: **quem decidiu que esta máquina podia entrar na rede?**

Na maioria das redes de escritório, ninguém decidiu. Uma tomada de rede na sala de reunião é uma porta
ativa de um switch, e um laptop ligado nela recebe um endereço, uma rota e a LAN inteira, seja de quem
for. **Controle de acesso à rede (NAC, *network access control*)** é o nome de transformar isso em uma
decisão. O **IEEE 802.1X** é a forma padrão de tomá-la numa porta de switch ou numa rede Wi-Fi.

O 802.1X nomeia três participantes:

| participante | nesta aula | sua função |
|---|---|---|
| **suplicante** (*supplicant*) | `newpc` e `visitor` | a máquina que pede para entrar, e o software nela que prova quem ela é |
| **autenticador** (*authenticator*) | `sw`, o switch de acesso | mantém a porta fechada, repassa a troca e abre a porta quando mandam |
| **servidor de autenticação** | o próprio servidor EAP do hostapd, dentro do `sw` | confere as credenciais e diz sim ou não; numa rede real, é um servidor **RADIUS** |

O autenticador nunca julga as credenciais por conta própria. Ele leva mensagens **EAP** entre os outros
dois, embrulhadas em quadros EAPOL (EAP over LAN) no cabo e em RADIUS no caminho até o servidor. É
essa divisão que permite a um único servidor de políticas decidir por centenas de switches e pontos de
acesso.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" aria-label=\"O 802.1X no switch de acesso do laboratório. newpc, na porta p1, é o suplicante e fala EAPOL com o switch, o autenticador. O switch repassa a troca ao servidor de autenticação, RADIUS numa rede real, e só abre p1 para a LAN do escritório depois do sucesso. visitor, na porta p2, oferece um certificado que ele mesmo assinou; o servidor recusa e p2 continua fechada para tudo menos EAPOL.\"><defs><marker id=\"dx-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"dx-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"dx-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"40\" width=\"150\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"56\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">newpc</text><text x=\"30\" y=\"73\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">suplicante</text><rect x=\"20\" y=\"150\" width=\"150\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"166\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">visitor</text><text x=\"30\" y=\"183\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">certificado próprio</text><rect x=\"280\" y=\"30\" width=\"170\" height=\"180\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"290\" y=\"46\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">sw</text><text x=\"290\" y=\"63\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">autenticador</text><rect x=\"280\" y=\"72\" width=\"40\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"300\" y=\"85\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">p1</text><rect x=\"280\" y=\"160\" width=\"40\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"300\" y=\"173\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">p2</text><path d=\"M170 72 L280 82\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#dx-ah-phosphor)\" marker-start=\"url(#dx-ah-phosphor)\"></path><text x=\"225\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">EAPOL</text><path d=\"M170 176 L280 173\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#dx-ah-amber)\" marker-start=\"url(#dx-ah-amber)\" stroke-dasharray=\"4 3\"></path><text x=\"225\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">recusado</text><rect x=\"540\" y=\"30\" width=\"160\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"550\" y=\"46\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">servidor EAP</text><text x=\"550\" y=\"63\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">RADIUS numa rede real</text><path d=\"M450 55 L540 55\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#dx-ah-paper-dim)\" marker-start=\"url(#dx-ah-paper-dim)\"></path><text x=\"495\" y=\"45\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">RADIUS</text><rect x=\"540\" y=\"140\" width=\"160\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"550\" y=\"156\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">192.168.10.0/24</text><text x=\"550\" y=\"173\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">LAN do escritório</text><path d=\"M450 160 L540 160\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#dx-ah-phosphor)\"></path><text x=\"495\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">depois do sucesso</text></svg>", "caption": "Três partes, e uma porta que fica fechada até a terceira dizer sim.", "same": ["EAPOL", "RADIUS"]}
```

O laboratório acrescenta um switch de acesso, o `sw`, à LAN do escritório. Na porta `p1` dele está um
laptop da empresa, o `newpc`, e na `p2` está o `visitor`, a máquina pessoal de alguém. Antes de qualquer
autenticação, o filtro do switch é este:

```
root@sw:~# nft list table netdev ports
table netdev ports {
	set authorised {
		type ifname . ether_addr
	}

	chain p1 {
		type filter hook ingress device "p1" priority filter; policy drop;
		ether type 0x888e accept
		iifname . ether saddr @authorised accept
	}

	chain p2 {
		type filter hook ingress device "p2" priority filter; policy drop;
		ether type 0x888e accept
		iifname . ether saddr @authorised accept
	}
}
```

A chain de entrada de cada porta descarta por padrão. A única coisa que ela aceita é o EtherType
`0x888e`, que é o EAPOL, porque a máquina precisa de algum jeito de pedir. Todo o resto espera que a sua
porta e o seu endereço apareçam no conjunto `authorised`, que está vazio.

Então o `newpc` tem um endereço e um cabo, e nenhum lugar para ir:

```
ana@newpc:~$ ip -br address show eth0
eth0@if1856      UP             192.168.10.30/24 
ana@newpc:~$ ping -c 2 -W 1 192.168.10.1
PING 192.168.10.1 (192.168.10.1) 56(84) bytes of data.

--- 192.168.10.1 ping statistics ---
2 packets transmitted, 0 received, 100% packet loss, time 1025ms
```

**O endereço não é o acesso.** Ele configurou `192.168.10.30` na própria interface, mas nenhum quadro
além do EAPOL chega à LAN ainda, nem o ARP.
