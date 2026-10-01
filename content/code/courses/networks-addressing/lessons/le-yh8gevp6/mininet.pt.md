---
title: Mininet: uma rede montada com o kernel
version: 1
---

O Mininet não segue nenhum dos dois caminhos. **Ele monta a rede com o próprio kernel do Linux**: cada
host é um processo no seu namespace de rede, cada cabo é um par de interfaces Ethernet virtuais, e cada
switch é um switch de software no kernel. Ele nasceu em Stanford para pesquisa em redes definidas por
software, por isso os switches dele são, por padrão, Open vSwitch comandados por um controlador
OpenFlow. Para esta aula ele rodou na forma mais simples, com bridges comuns do Linux como switches
(`--switch lxbr`) e nenhum controlador (`--controller none`), para não precisar de nada além do kernel.
A versão é o Mininet 2.3.0, do pacote do próprio Ubuntu.

Um comando monta a rede, testa e desmonta de novo. `--topo linear,3` pede três switches em linha com um
host em cada, e `--test pingall` faz cada host pingar todos os outros:

```
ana@lab:~$ sudo mn --switch lxbr --controller none --topo linear,3 --test pingall
*** Creating network
*** Adding controller
*** Adding hosts:
h1 h2 h3 
*** Adding switches:
s1 s2 s3 
*** Adding links:
(h1, s1) (h2, s2) (h3, s3) (s2, s1) (s3, s2) 
*** Configuring hosts
h1 h2 h3 
*** Starting controller

*** Starting 3 switches
s1 s2 s3 
*** Waiting for switches to connect
s1 s2 s3 
*** Ping: testing ping reachability
h1 -> h2 h3 
h2 -> h1 h3 
h3 -> h1 h2 
*** Results: 0% dropped (6/6 received)
*** Stopping 0 controllers

*** Stopping 5 links
.....
*** Stopping 3 switches
s1 s2 s3 
*** Stopping 3 hosts
h1 h2 h3 
*** Done
completed in 9.602 seconds
```

Leia de cima para baixo. O Mininet criou três hosts, três switches e cinco links: três ligando cada
host ao seu switch e dois ligando os switches em linha. Ele imprimiu `*** Adding controller` e, no fim,
`Stopping 0 controllers`, porque a etapa roda o que foi pedido e aqui não foi pedido nada. Cada host
pingou então os outros dois — `h1 -> h2 h3` quer dizer que o h1 alcançou os dois — e o resultado é
`0% dropped (6/6 received)`: três hosts, dois pings cada. A rede foi montada, testada e desmontada em
9.602 segundos na máquina virtual deste laboratório.

Sem o `--test`, o Mininet abre um prompt próprio, `mininet>`, onde um comando digitado depois do nome
de um host roda dentro daquele host. Numa segunda execução, com a mesma topologia, três comandos foram
digitados ali:

- `net` listou cada nó e a que cada interface dele está ligada. A linha do switch do meio foi
  `s2 lo:  s2-eth1:h2-eth0 s2-eth2:s1-eth2 s2-eth3:s3-eth2`: porta 1 para o h2, porta 2 para o s1,
  porta 3 para o s3. O desenho abaixo são essas linhas, desenhadas;
- `h1 ip -br addr` mostrou a interface `h1-eth0` do h1 com `10.0.0.1/8`. Se ninguém disser outra
  coisa, o Mininet numera os hosts a partir de 10.0.0.1 dentro de 10.0.0.0/8;
- `h1 ping -c 2 h3` atravessou os três switches: 2 pacotes transmitidos, 2 recebidos, a primeira
  resposta em 3.89 ms e a segunda em 0.824 ms.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 206\" role=\"img\" aria-label=\"A topologia linear,3 do Mininet, como o comando net a listou. Três hosts, h1, h2 e h3, cada um ligado ao seu switch: h1-eth0 a s1-eth1, h2-eth0 a s2-eth1, h3-eth0 a s3-eth1. Os switches formam uma linha: s1-eth2 a s2-eth2, e s2-eth3 a s3-eth2. Cinco links ao todo.\"><text x=\"20\" y=\"46\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">hosts</text><text x=\"20\" y=\"156\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">switches</text><rect x=\"125\" y=\"28\" width=\"90\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"170\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">h1</text><rect x=\"125\" y=\"138\" width=\"90\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"170\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">s1</text><path d=\"M170 64 L170 138\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"176\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">h1-eth0</text><text x=\"176\" y=\"126\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">s1-eth1</text><rect x=\"335\" y=\"28\" width=\"90\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"380\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">h2</text><rect x=\"335\" y=\"138\" width=\"90\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"380\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">s2</text><path d=\"M380 64 L380 138\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"386\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">h2-eth0</text><text x=\"386\" y=\"126\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">s2-eth1</text><rect x=\"545\" y=\"28\" width=\"90\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"590\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">h3</text><rect x=\"545\" y=\"138\" width=\"90\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"590\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">s3</text><path d=\"M590 64 L590 138\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"596\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">h3-eth0</text><text x=\"596\" y=\"126\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">s3-eth1</text><path d=\"M215 156 L335 156\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M425 156 L545 156\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"219\" y=\"190\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">s1-eth2</text><text x=\"331\" y=\"190\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">s2-eth2</text><text x=\"429\" y=\"190\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">s2-eth3</text><text x=\"541\" y=\"190\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">s3-eth2</text></svg>", "caption": "O que o --topo linear,3 montou: três switches em linha, um host em cada, cinco links. Um ping do h1 para o h3 atravessa os três switches.", "same": ["hosts", "switches"]}
```

Duas coisas fazem do Mininet uma boa ferramenta para aprender. **É rede de verdade**: `ip`, `ping`,
`tcpdump` e `ss` rodam dentro de um host do Mininet exatamente como num servidor Linux, porque é isso
que o host é, um canto da pilha de rede de uma máquina Linux. E ele é uma biblioteca Python além de um
comando, então uma topologia pode ser escrita como um programa curto e remontada idêntica toda vez. O
que ele não dá é dispositivo de fabricante: os hosts e switches dele são Linux, e um laboratório que
precisa de IOS precisa de uma das ferramentas das duas seções anteriores.
