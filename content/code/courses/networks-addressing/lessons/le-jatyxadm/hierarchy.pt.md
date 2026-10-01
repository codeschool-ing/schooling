---
title: Hierarquia, três camadas com uma função cada
version: 1
---

A aula 3 terminou numa híbrida: estrelas nas mesas, uma malha no meio. **Hierarquia** é o nome de
montar essa híbrida de propósito, em camadas, em que cada aparelho pertence a exatamente uma camada e
cada camada tem uma função. A imagem comum de "uma rede grande" é um grande switch plano com tudo
ligado nele. O plano é simples com vinte máquinas e ingovernável com duas mil, porque toda mudança e
toda falha atingem todo mundo de uma vez.

O projeto clássico tem três camadas:

- **Acesso** — onde as máquinas se ligam. Um switch por andar ou por sala, muitas portas, barato. A
  função dele é conectar pessoas, e mais nada.
- **Distribuição** — o gateway da LAN de cada switch de acesso, e o lugar onde as regras são aplicadas:
  quais LANs podem conversar, quais rotas são resumidas antes de subir (a seção de escalabilidade
  desta aula). Cada aparelho de distribuição atende um bloco do prédio.
- **Núcleo** — o meio, que leva o tráfego entre os blocos de distribuição o mais rápido que puder. **O
  núcleo carrega o tráfego de todo mundo, então não filtra nada nem faz trabalho esperto**; tudo o que
  poderia deixá-lo lento ou quebrá-lo fica uma camada abaixo.

## O campus do laboratório

O cenário desta aula, montado com `lab.sh up campus`, é esse projeto no menor tamanho possível: dois
roteadores de núcleo, dois roteadores de distribuição, cada roteador de distribuição ligado aos **dois**
núcleos, um switch de acesso embaixo de cada roteador de distribuição e um PC em cada um.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 384\" role=\"img\" aria-label=\"O cenário campus do laboratório em quatro camadas. Núcleo: c1 e c2, ligados por 10.20.0.0/30, c1 em .1 e c2 em .2. Distribuição: d1 e d2, cada um ligado aos dois núcleos; c1 a d1 com c1 em .5 e d1 em .6, c1 a d2 com .9 e .10, c2 a d1 com .13 e .14, c2 a d2 com .17 e .18, tudo em 10.20.0.0/24. Acesso: o switch a1 embaixo do d1, porta p24 subindo para o d1, e o a2 embaixo do d2. Hosts: o pc1 em 10.20.11.21 na porta p1 do a1, na LAN do d1, 10.20.11.0/24, com gateway 10.20.11.1; o pc2 em 10.20.12.22 no a2, na LAN do d2, 10.20.12.0/24, com gateway 10.20.12.1.\"><text x=\"20\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">núcleo</text><text x=\"20\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">distribuição</text><text x=\"20\" y=\"256\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">acesso</text><text x=\"20\" y=\"344\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">hosts</text><path d=\"M290.0 50.0 L450.0 50.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\"></path><text x=\"304.0\" y=\"41.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">.1</text><text x=\"436.0\" y=\"41.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">.2</text><path d=\"M240.0 70.0 L240.0 140.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\"></path><text x=\"254.0\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">.5</text><text x=\"254.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">.6</text><path d=\"M500.0 70.0 L500.0 140.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\"></path><text x=\"514.0\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">.17</text><text x=\"514.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">.18</text><path d=\"M287.3 70.0 L452.7 140.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\"></path><text x=\"303.2\" y=\"88.7\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">.9</text><text x=\"428.2\" y=\"141.6\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">.10</text><path d=\"M452.7 70.0 L287.3 140.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\"></path><text x=\"436.8\" y=\"88.7\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">.13</text><text x=\"311.8\" y=\"141.6\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">.14</text><path d=\"M240.0 180.0 L240.0 236.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\"></path><path d=\"M500.0 180.0 L500.0 236.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\"></path><path d=\"M240.0 276.0 L240.0 324.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\"></path><path d=\"M500.0 276.0 L500.0 324.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\"></path><text x=\"256.0\" y=\"227\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">p24</text><text x=\"254.0\" y=\"288\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">p1</text><text x=\"516.0\" y=\"227\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">p24</text><text x=\"514.0\" y=\"288\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">p1</text><rect x=\"190\" y=\"30\" width=\"100\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"240.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">c1</text><rect x=\"450\" y=\"30\" width=\"100\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"500.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">c2</text><rect x=\"190\" y=\"140\" width=\"100\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"240.0\" y=\"154\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">d1</text><text x=\"240.0\" y=\"169\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.20.11.1</text><rect x=\"450\" y=\"140\" width=\"100\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"500.0\" y=\"154\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">d2</text><text x=\"500.0\" y=\"169\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.20.12.1</text><rect x=\"190\" y=\"236\" width=\"100\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"240.0\" y=\"256.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">a1</text><rect x=\"450\" y=\"236\" width=\"100\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"500.0\" y=\"256.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">a2</text><rect x=\"190\" y=\"324\" width=\"100\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"240.0\" y=\"338\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pc1</text><text x=\"240.0\" y=\"353\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.20.11.21</text><rect x=\"450\" y=\"324\" width=\"100\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"500.0\" y=\"338\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pc2</text><text x=\"500.0\" y=\"353\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.20.12.22</text><text x=\"570\" y=\"256\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.20.12.0/24</text><text x=\"310\" y=\"256\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.20.11.0/24</text><text x=\"580\" y=\"84\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">links em 10.20.0.0/24,</text><text x=\"580\" y=\"100\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">uma /30 cada</text></svg>", "caption": "O campus da aula 6. Os números pequenos ao lado de cada cabo são o último byte do endereço naquela ponta, todos dentro de 10.20.0.0/24: 10.20.0.13 é a ponta do c2 no cabo até o d1, e 10.20.0.18 é a ponta do d2 no cabo até o c2.", "same": ["hosts"]}
```

Os roteadores trocam rotas com OSPF, que a aula 16 explica. Aqui ele serve por um comando que lista, em
cada roteador, com quais vizinhos ele está conversando. No roteador de núcleo c1:

```
root@c1:~# vtysh -c "show ip ospf neighbor"

Neighbor ID     Pri State           Up Time         Dead Time Address         Interface                        RXmtL RqstL DBsmL
10.255.0.2        1 Full/-          52.425s            3.844s 10.20.0.2       eth1:10.20.0.1                       0     0     0
10.255.0.11       1 Full/-          50.430s            3.457s 10.20.0.6       eth2:10.20.0.5                       0     0     0
10.255.0.12       1 Full/-          42.413s            3.819s 10.20.0.10      eth3:10.20.0.9                       0     0     0

```

**Três vizinhos**: `10.255.0.2` é o c2, o outro núcleo; `10.255.0.11` é o d1 e `10.255.0.12` é o d2, os
dois roteadores de distribuição. (Essas são as identidades OSPF dos roteadores, definidas no `lab.sh`; a
coluna `Address` é o endereço na outra ponta de cada cabo.) O `Up Time`, de 42.413s a 52.425s, é há
quanto tempo dura cada uma dessas conversas: o laboratório tinha menos de um minuto. No roteador de
distribuição d1:

```
root@d1:~# vtysh -c "show ip ospf neighbor"

Neighbor ID     Pri State           Up Time         Dead Time Address         Interface                        RXmtL RqstL DBsmL
10.255.0.1        1 Full/-          51.607s            3.407s 10.20.0.5       eth1:10.20.0.6                       0     0     0
10.255.0.2        1 Full/-          49.303s            3.671s 10.20.0.13      eth2:10.20.0.14                      0     0     0

```

**Dois vizinhos, os dois núcleos.** O d1 não tem cabo até o d2. Essa é a regra da hierarquia escrita em
cabos: um roteador de distribuição conversa para cima com o núcleo e para baixo com o switch de acesso,
e neste projeto não para o lado. O switch de acesso a1 não roda roteamento nenhum; ele é um switch.

Agora o pc1, embaixo de um lado, alcança o pc2, embaixo do outro:

```
ana@pc1:~$ traceroute -n 10.20.12.22
traceroute to 10.20.12.22 (10.20.12.22), 30 hops max, 60 byte packets
 1  10.20.11.1  2.701 ms  0.358 ms  0.245 ms
 2  10.20.0.13  0.557 ms  0.535 ms  0.230 ms
 3  10.20.0.18  0.485 ms  0.482 ms  0.249 ms
 4  10.20.12.22  1.336 ms  0.459 ms  0.369 ms
```

**Sobe, atravessa e desce**: `10.20.11.1` é o d1, o gateway do pc1; `10.20.0.13` é o c2, um roteador de
núcleo; `10.20.0.18` é o d2; depois o pc2. Os switches de acesso não aparecem, porque um switch não
responde a um traceroute — ele encaminha quadros sem ser um salto. Todo caminho entre dois blocos de
acesso tem essa forma e esse comprimento, seja qual for o bloco de partida. **Caminhos previsíveis são a
primeira coisa que a hierarquia compra**: qualquer um que conheça o projeto diz por onde um pacote vai
antes de rodar um comando.

## Quando três camadas são demais

Uma sede pequena não precisa de três camadas de equipamento. Um **núcleo colapsado** (*collapsed core*)
junta núcleo e distribuição num só par de aparelhos, que é o projeto normal para um prédio de algumas
centenas de pessoas. O cenário office da aula 1 é menor ainda: um switch, um roteador, hierarquia
nenhuma, e correto para o tamanho dele. As camadas são uma maneira de pensar — qual é a única função
deste aparelho? — antes de serem uma lista de compras.
