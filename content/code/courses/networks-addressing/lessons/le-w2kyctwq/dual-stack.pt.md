---
title: Pilha dupla, dois protocolos no mesmo cabo
version: 1
---

Migrar para o IPv6 não quer dizer desligar o IPv4 num dia marcado. **O jeito como quase toda rede roda
IPv6 hoje é pilha dupla** (*dual stack*): os dois protocolos nas mesmas interfaces, lado a lado, cada um
com os seus endereços, as suas rotas e o seu gateway. Uma máquina com os dois fala IPv6 com o que tem
endereço IPv6 e IPv4 com o resto. Este escritório foi montado assim:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 292\" role=\"img\" aria-label=\"O laboratório desta aula, com as duas famílias de endereços em cada caixa. O pc1 tem 10.20.10.21 e 2001:db8:20:10:25:70ff:febc:29c6; o pc2 tem 10.20.10.22 e 2001:db8:20:10:fd:f2ff:fed2:63ba; o srv tem 10.20.10.10 e 2001:db8:20:10::10. Os três estão ligados ao switch sw1, e o sw1 ao roteador r1, cuja eth0 tem 10.20.10.1 e 2001:db8:20:10::1 e cuja eth1 tem 203.0.113.2 e 2001:db8:ffff::2. O r1 está ligado ao provedor isp, e o isp ao servidor web, em 192.0.2.80 e 2001:db8:99::80. As redes: LAN do escritório 10.20.10.0/24 e 2001:db8:20:10::/64; enlace do provedor 203.0.113.0/30 e 2001:db8:ffff::/64; servidor web 192.0.2.0/24 e 2001:db8:99::/64.\"><rect x=\"10\" y=\"20\" width=\"205\" height=\"58\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"20\" y=\"33\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pc1</text><text x=\"20\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.20.10.21</text><text x=\"20\" y=\"66\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2001:db8:20:10:25:70ff:febc:29c6</text><path d=\"M215 49 L240 124\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"10\" y=\"90\" width=\"205\" height=\"58\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"20\" y=\"103\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pc2</text><text x=\"20\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.20.10.22</text><text x=\"20\" y=\"136\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2001:db8:20:10:fd:f2ff:fed2:63ba</text><path d=\"M215 119 L240 124\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"10\" y=\"160\" width=\"205\" height=\"58\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"20\" y=\"173\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">srv</text><text x=\"20\" y=\"190\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.20.10.10</text><text x=\"20\" y=\"206\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2001:db8:20:10::10</text><path d=\"M215 189 L240 124\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"240\" y=\"106\" width=\"56\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"268\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">sw1</text><path d=\"M296 124 L318 124\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"318\" y=\"66\" width=\"158\" height=\"116\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"330\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">r1</text><text x=\"330\" y=\"100\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">eth0 10.20.10.1</text><text x=\"330\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">eth0 2001:db8:20:10::1</text><text x=\"330\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">eth1 203.0.113.2</text><text x=\"330\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">eth1 2001:db8:ffff::2</text><path d=\"M476 124 L500 124\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"500\" y=\"106\" width=\"56\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"528\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">isp</text><path d=\"M556 124 L576 124\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"576\" y=\"96\" width=\"134\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"588\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">web</text><text x=\"588\" y=\"127\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">192.0.2.80</text><text x=\"588\" y=\"143\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2001:db8:99::80</text><text x=\"10\" y=\"238\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">LAN do escritório</text><text x=\"10\" y=\"256\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10.20.10.0/24</text><text x=\"10\" y=\"272\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2001:db8:20:10::/64</text><text x=\"318\" y=\"238\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">enlace do provedor</text><text x=\"318\" y=\"256\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">203.0.113.0/30</text><text x=\"318\" y=\"272\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2001:db8:ffff::/64</text><text x=\"576\" y=\"238\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">servidor web</text><text x=\"576\" y=\"256\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">192.0.2.0/24</text><text x=\"576\" y=\"272\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2001:db8:99::/64</text></svg>", "caption": "Toda rede deste laboratório tem uma faixa IPv4 e um prefixo IPv6, e toda interface tem um endereço de cada. Os endereços link-local ficaram fora do desenho."}
```

A única interface do pc1, com tudo o que ela tem:

```
ana@pc1:~$ ip -br addr show eth0
eth0@if27        UP             10.20.10.21/24 2001:db8:20:10:25:70ff:febc:29c6/64 fe80::25:70ff:febc:29c6/64 
```

Três endereços na `eth0`. `10.20.10.21/24` é o endereço IPv4 que o lab.sh lhe deu, aquele com que a aula
8 trabalhou. `2001:db8:20:10:25:70ff:febc:29c6/64` é o endereço IPv6 global que ele montou por SLAAC, e
`fe80::25:70ff:febc:29c6/64` é o seu endereço link-local. **Os dois protocolos não dividem nada acima do
cabo**: o IPv4 sai por `10.20.10.1`, o IPv6 por `fe80::1f:23ff:fee7:e9d5`, e um problema num deles não diz
nada sobre o outro.

Qual dos dois um programa usa? Ele pergunta pelo nome e recebe uma lista:

```
ana@pc1:~$ getent ahosts web
2001:db8:99::80 STREAM web
2001:db8:99::80 DGRAM  
2001:db8:99::80 RAW    
192.0.2.80      STREAM 
192.0.2.80      DGRAM  
192.0.2.80      RAW    
```

`web` tem dois endereços, `2001:db8:99::80` e `192.0.2.80`, e **o IPv6 vem primeiro**. (`STREAM`,
`DGRAM` e `RAW` são os três tipos de socket para que cada endereço serviria; leia só os endereços.)
Neste laboratório os nomes vêm do `/etc/hosts` de cada máquina, que o lab.sh escreveu; na internet eles
vêm do DNS, onde um nome tem um registro **A** para IPv4 e um registro **AAAA** para IPv6, como o curso
de redes mostrou. A ordem é escolha do sistema, e numa máquina com endereço IPv6 global ele põe o IPv6
primeiro. Um programa que tenta os endereços na ordem, portanto, tenta o IPv6 primeiro.

O `curl` aceita usar um protocolo e não o outro, o que faz dele a ferramenta para testar cada caminho
separadamente:

```
ana@pc1:~$ curl -s -4 http://web/ -w "%{remote_ip}\n"
served by web
192.0.2.80
ana@pc1:~$ curl -s -6 http://web/ -w "%{remote_ip}\n"
served by web
2001:db8:99::80
```

Mesmo servidor, mesma página, dois caminhos diferentes: o `-4` se conectou a `192.0.2.80`, o `-6` a
`2001:db8:99::80`, e o `%{remote_ip}` imprimiu o endereço que cada um alcançou de fato.

Esse teste separado é a habilidade que esta seção ensina, porque **a falha clássica da pilha dupla é um
caminho IPv6 quebrado enquanto o IPv4 funciona**. O nome tem registro AAAA, a máquina prefere IPv6, a
conexão ao endereço IPv6 não chega a lugar nenhum, e o usuário vê um site lento ou que não abre,
enquanto todo teste em IPv4 passa. Os navegadores amenizam isso tentando os dois protocolos quase ao
mesmo tempo e ficando com o que responder primeiro, uma técnica chamada Happy Eyeballs; ferramentas
de linha de comando e programas mais antigos não fazem isso, e esperam. **Quando um site falha numa
máquina, teste `-4` e `-6` separadamente antes de qualquer outra coisa.**

Mais uma consequência, e ela é de segurança. Um firewall escrito para IPv4 não faz nada pelo IPv6, a
não ser que tenha sido escrito para os dois: no Linux, `iptables` e `ip6tables` são programas
separados, e uma tabela nftables da família `ip` só enxerga IPv4. Neste laboratório, o único conjunto de
regras do r1 é uma tabela de NAT IPv4, então o lado IPv6 dele encaminha tudo nos dois sentidos. Isso é
aceitável num laboratório sem internet de verdade e não é aceitável em nenhum outro lugar: **toda regra
que uma rede tem para IPv4 precisa de uma equivalente em IPv6**, escrita e testada no mesmo dia.
