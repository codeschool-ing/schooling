---
title: A LAN, a rede que é sua
version: 1
---

Os cinco nomes do título desta aula não são cinco tamanhos numa mesma régua. A imagem comum é um
conjunto de círculos — pequeno para a LAN, maior para a MAN, o maior para a WAN — e ela erra a parte
mais útil. **O que separa uma LAN de uma WAN é de quem são os links**, e o tamanho vem disso.

Uma **LAN** (*local area network*, rede local) é a rede dentro de uma sede, feita de cabos, switches e
pontos de acesso que a empresa comprou, instalou e pode ir até lá ver. Por ser sua, ela é rápida e
barata: uma porta de switch custa o mesmo ocupada ou parada, e ninguém manda conta pelo tráfego. Uma
LAN também é, no caso comum, **um domínio de broadcast** — as máquinas nela se alcançam diretamente,
achando o MAC umas das outras com ARP, sem um roteador no meio.

O laboratório desta aula é uma empresa com duas sedes, montada com `lab.sh up sites`:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"O cenário sites do laboratório, da esquerda para a direita. A LAN da matriz, 10.20.10.0/24, tem o pc1 em 10.20.10.21 e o roteador rhq em 10.20.10.1, cujo outro lado é 203.0.113.2. A operadora, a WAN, tem a isp em 203.0.113.1 e 198.51.100.1, nos links 203.0.113.0/30 e 198.51.100.0/30. A LAN da filial, 10.30.10.0/24, tem o roteador rbr em 198.51.100.2 e 10.30.10.1, e o pc2 em 10.30.10.22. Acima deles, um túnel WireGuard liga o rhq, wg0 em 10.255.255.1, ao rbr, wg0 em 10.255.255.2, por cima da operadora.\"><rect x=\"8\" y=\"62\" width=\"228\" height=\"208\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"18\" y=\"78\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">LAN da matriz</text><text x=\"18\" y=\"94\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10.20.10.0/24</text><rect x=\"252\" y=\"62\" width=\"216\" height=\"208\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"262\" y=\"78\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">operadora: a WAN</text><rect x=\"484\" y=\"62\" width=\"228\" height=\"208\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"702\" y=\"78\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">LAN da filial</text><text x=\"702\" y=\"94\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10.30.10.0/24</text><rect x=\"20\" y=\"140\" width=\"92\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"155\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pc1</text><text x=\"30\" y=\"172\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.20.10.21</text><rect x=\"132\" y=\"140\" width=\"92\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"142\" y=\"155\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">rhq</text><text x=\"142\" y=\"172\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.20.10.1</text><text x=\"142\" y=\"186\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">203.0.113.2</text><rect x=\"310\" y=\"140\" width=\"100\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"320\" y=\"155\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">isp</text><text x=\"320\" y=\"172\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">203.0.113.1</text><text x=\"320\" y=\"186\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">198.51.100.1</text><rect x=\"496\" y=\"140\" width=\"92\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"506\" y=\"155\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">rbr</text><text x=\"506\" y=\"172\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">198.51.100.2</text><text x=\"506\" y=\"186\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.30.10.1</text><rect x=\"608\" y=\"140\" width=\"92\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"618\" y=\"155\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pc2</text><text x=\"618\" y=\"172\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.30.10.22</text><path d=\"M112 170.0 L132 170.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M224 170.0 L310 170.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M410 170.0 L496 170.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M588 170.0 L608 170.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.6\" fill=\"none\"></path><text x=\"360\" y=\"230\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">203.0.113.0/30</text><text x=\"360\" y=\"246\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">198.51.100.0/30</text><path d=\"M178.0 56 L178.0 30 L542.0 30 L542.0 56\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\" stroke-dasharray=\"6 4\"></path><path d=\"M178.0 62 L178.0 140\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"2 3\"></path><path d=\"M542.0 62 L542.0 140\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"2 3\"></path><text x=\"360\" y=\"16\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">túnel WireGuard, montado na seção da VPN</text><text x=\"186.0\" y=\"44\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">wg0 10.255.255.1</text><text x=\"534.0\" y=\"44\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.255.255.2 wg0</text></svg>", "caption": "O laboratório da aula 4: duas LANs que pertencem à empresa e uma WAN que pertence à operadora. O túnel no alto só existe depois que a seção da VPN o digita."}
```

O pc1 está na matriz. A visão que ele tem da rede diz exatamente onde a LAN dele termina:

```
ana@pc1:~$ ip -br addr show eth0
eth0@if199       UP             10.20.10.21/24 fe80::25:70ff:febc:29c6/64 
ana@pc1:~$ ip route
default via 10.20.10.1 dev eth0 
10.20.10.0/24 dev eth0 proto kernel scope link src 10.20.10.21 
```

Duas rotas, e elas são a ideia inteira de LAN. `10.20.10.0/24 dev eth0 ... scope link` quer dizer que
**todo endereço de 10.20.10.0 a 10.20.10.255 é alcançado diretamente no cabo**, perguntando o MAC
dele: essa faixa é a LAN do pc1. Todo o resto cai em `default via 10.20.10.1`, o roteador `rhq`, e sai
da LAN por ele. A borda de uma LAN é onde um pacote precisa ser entregue a um roteador; a aula 14 lê
tabelas de rotas como esta por inteiro.

O pc2 está na filial, em outra cidade:

```
ana@pc2:~$ ip -br addr show eth0
eth0@if201       UP             10.30.10.22/24 fe80::fd:f2ff:fed2:63ba/64 
```

`10.30.10.22/24` está numa faixa diferente, então o pc2 está numa LAN diferente, e nada na tabela do
pc1 o alcança diretamente. Duas LANs da mesma empresa, cada uma com seu roteador, cada uma rápida e
gratuita por dentro. A pergunta do resto da aula é o que liga as duas.

## O que uma LAN não é

- **Não é "tudo o que está atrás do meu roteador".** Um andar com cem PCs pode ser várias LANs,
  mantidas separadas de propósito; a seção de VLAN desta aula mostra o jeito usual.
- **Não é definida por uma distância.** Uma LAN que atravessa um campus de vários prédios, em fibra
  da própria empresa, continua sendo uma LAN. Um link até o prédio do outro lado da rua alugado de
  uma operadora não é.
- **Não é só cabo.** O Wi-Fi dos pontos de acesso da própria empresa faz parte da LAN; o ponto de
  acesso faz a ponte do rádio para a mesma Ethernet (aula 1).

Os endereços dentro das duas LANs, `10.20.10.0/24` e `10.30.10.0/24`, vêm das faixas privadas que a
aula 8 lista. Esse detalhe decide a seção de VPN desta aula: um endereço privado só significa alguma
coisa dentro da rede que o escolheu.
