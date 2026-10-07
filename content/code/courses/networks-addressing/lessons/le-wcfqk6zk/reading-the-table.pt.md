---
title: Lendo uma tabela de rotas
version: 2
---

A imagem comum de um roteador é a de uma caixa que conhece a rede: ela enxerga onde as coisas estão e
acha um caminho até lá. Não é assim. **Um roteador conhece a sua tabela de rotas e mais nada.** Para
cada pacote ele lê o endereço de destino, procura na tabela as entradas que o contêm e manda o pacote
para onde a entrada vencedora diz: por uma interface e, em geral, para um próximo roteador. Se
nenhuma entrada contém o endereço, o pacote não vai a lugar nenhum, por mais perto que o destino
esteja.

O laboratório desta aula deixa isso visível. O r1 tem dois cabos de saída, um para o ra e um para o
rb, e os dois estão na rede distante, 10.30.0.0/16, onde moram o far1 e o far2. Nada é roteado
dinamicamente: cada rota da aula é digitada à mão, que é o assunto da aula 15, e a aula 16 passa o
trabalho para os protocolos.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"O laboratório desta aula. O pc1, 10.20.10.21, está ligado ao roteador r1, que é 10.20.10.1 na eth0. O r1 tem mais dois cabos: a eth1, 10.20.1.1, no enlace 10.20.1.0/30 até o roteador ra em 10.20.1.2; e a eth2, 10.20.2.1, no enlace 10.20.2.0/30 até o roteador rb em 10.20.2.2. O ra (10.30.0.1) e o rb (10.30.0.2) estão os dois na rede distante, 10.30.0.0/16, onde o far1 é 10.30.5.10 e o far2 é 10.30.7.10.\"><rect x=\"20\" y=\"100\" width=\"120\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"116\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pc1</text><text x=\"30\" y=\"134\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10.20.10.21</text><line x1=\"140\" y1=\"125\" x2=\"190\" y2=\"125\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></line><rect x=\"190\" y=\"72\" width=\"124\" height=\"106\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"200\" y=\"90\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">r1</text><text x=\"200\" y=\"108\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">roteador</text><text x=\"200\" y=\"130\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">eth0 10.20.10.1</text><text x=\"200\" y=\"146\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">eth1 10.20.1.1</text><text x=\"200\" y=\"162\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">eth2 10.20.2.1</text><line x1=\"314\" y1=\"106\" x2=\"440\" y2=\"55\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></line><line x1=\"314\" y1=\"144\" x2=\"440\" y2=\"195\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></line><text x=\"352\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.20.1.0/30</text><text x=\"352\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.20.2.0/30</text><rect x=\"440\" y=\"24\" width=\"96\" height=\"62\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"450\" y=\"39\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">ra</text><text x=\"450\" y=\"56\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.20.1.2</text><text x=\"450\" y=\"72\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.30.0.1</text><line x1=\"536\" y1=\"55\" x2=\"572\" y2=\"55\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></line><rect x=\"440\" y=\"164\" width=\"96\" height=\"62\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"450\" y=\"179\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">rb</text><text x=\"450\" y=\"196\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.20.2.2</text><text x=\"450\" y=\"212\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.30.0.2</text><line x1=\"536\" y1=\"195\" x2=\"572\" y2=\"195\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></line><rect x=\"572\" y=\"14\" width=\"138\" height=\"222\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"584\" y=\"34\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">a rede distante</text><text x=\"584\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10.30.0.0/16</text><rect x=\"584\" y=\"80\" width=\"112\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"594\" y=\"95\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">far1</text><text x=\"594\" y=\"111\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10.30.5.10</text><rect x=\"584\" y=\"132\" width=\"112\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"594\" y=\"147\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">far2</text><text x=\"594\" y=\"163\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10.30.7.10</text></svg>", "caption": "O laboratório desta aula: o r1 tem dois caminhos até a rede distante, pelo ra e pelo rb, e começa sem conhecer nenhum."}
```

Salve-o como `~/netlab/paths.sh` e monte com `sudo bash ~/netlab/netlab.sh up paths`:

```bash
# ~/netlab/paths.sh: a router with two ways out. r1 is cabled to ra and to rb,
# and both sit on the same far network, where far1 and far2 live. No routing
# protocol: FRR runs on r1 with nothing configured, so its table can be read
# beside the kernel's.
#
#                 +-- ra (10.20.1.0/30) --+
#   pc1 --- r1 ---+                       +--- 10.30.0.0/16: far1 .5.10, far2 .7.10
#   10.20.10.0/24 +-- rb (10.20.2.0/30) --+    (ra .0.1, rb .0.2)
local n
for n in pc1 sw9 far1 far2; do node $n; done
node r1 router; node ra router; node rb router
link pc1 eth0 r1 eth0; addr pc1 eth0 10.20.10.21/24; addr r1 eth0 10.20.10.1/24; gw pc1 10.20.10.1
link r1 eth1 ra eth0; addr r1 eth1 10.20.1.1/30; addr ra eth0 10.20.1.2/30
link r1 eth2 rb eth0; addr r1 eth2 10.20.2.1/30; addr rb eth0 10.20.2.2/30
link ra eth1 sw9 p1; link rb eth1 sw9 p2; link far1 eth0 sw9 p3; link far2 eth0 sw9 p4
switch sw9 "p1 p2 p3 p4"
addr ra eth1 10.30.0.1/16; addr rb eth1 10.30.0.2/16
addr far1 eth0 10.30.5.10/16; addr far2 eth0 10.30.7.10/16
gw far1 10.30.0.1; gw far2 10.30.0.1
ip -n ra route add 10.20.0.0/16 via 10.20.1.1
ip -n rb route add 10.20.0.0/16 via 10.20.2.1
echo "hostname r1" | frr r1
```

O ra e o rb ganham cada um uma rota de volta para o escritório no arquivo; o r1 não ganha nenhuma, e a
última linha sobe o FRR nele sem nada configurado, para que a visão dele da tabela possa ser lida ao
lado da do kernel na seção sobre distância administrativa.

Esta é a tabela do r1 antes de alguém digitar qualquer coisa, seguida do pc1 tentando alcançar o
far1:

```
root@r1:~# ip route
10.20.1.0/30 dev eth1 proto kernel scope link src 10.20.1.1 
10.20.2.0/30 dev eth2 proto kernel scope link src 10.20.2.1 
10.20.10.0/24 dev eth0 proto kernel scope link src 10.20.10.1 
ana@pc1:~$ ping -c 1 -W 1 10.30.5.10
PING 10.30.5.10 (10.30.5.10) 56(84) bytes of data.
From 10.20.10.1 icmp_seq=1 Destination Net Unreachable

--- 10.30.5.10 ping statistics ---
1 packets transmitted, 0 received, +1 errors, 100% packet loss, time 0ms

```

Três linhas, uma por interface com endereço. Desmonte a primeira:

| parte | o que diz |
|---|---|
| `10.20.1.0/30` | o destino, um prefixo: todo endereço cujos primeiros 30 bits batem |
| `dev eth1` | a interface pela qual um pacote que bate sai |
| `proto kernel` | quem pôs a rota ali: o kernel, no momento em que o endereço 10.20.1.1/30 foi configurado |
| `scope link` | o destino está no próprio cabo, então nenhum outro roteador é necessário |
| `src 10.20.1.1` | o endereço que o r1 usa como origem dos pacotes que ele mesmo manda para lá |

Essas são **rotas conectadas**, e são o único tipo que um roteador tem sem que ninguém lhe diga nada.
Elas não têm `via`: para alcançar 10.20.1.2, o r1 pergunta por ARP o endereço de hardware do próprio
10.20.1.2 e manda o quadro direto para ele. Uma rota que indica um próximo salto, com `via`, é o
outro tipo, e a próxima seção acrescenta a primeira.

Depois vem o ping do pc1. O pc1 tem uma rota padrão para o r1, então mandou o pacote; o r1 procurou
uma entrada que contivesse 10.30.5.10, não achou nenhuma e o descartou. **`From 10.20.10.1 ...
Destination Net Unreachable` é o r1 dizendo isso**, numa mensagem ICMP de volta ao pc1. O endereço no
começo da linha é o roteador que desistiu, e é a primeira coisa a ler ali: não é o far1, que nunca
viu o pacote, nem o pc1, que tinha uma rota e a usou. Um host sem rota própria imprime `Network is
unreachable` sem mandar nada, como o curso de redes mostrou; esta mensagem veio de um salto adiante.

O r1 está ligado aos dois roteadores que alcançariam o far1, a um metro de cabo da resposta, e ainda
assim não sabe nada sobre 10.30.0.0/16. **Estar ligado a um roteador que conhece o caminho não é
conhecer o caminho.** Toda rota além dos cabos do próprio roteador chega de um de dois jeitos: alguém
a digita, ou um protocolo de roteamento a aprende com um vizinho. De um jeito ou de outro ela vira uma
linha nesta tabela, e as próximas quatro seções tratam de qual linha vence quando mais de uma
poderia.
