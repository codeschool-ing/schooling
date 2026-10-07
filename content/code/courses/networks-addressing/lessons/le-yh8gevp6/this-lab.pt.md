---
title: O laboratório deste curso
version: 2
---

O laboratório deste curso é a mesma ideia do Mininet, sem o Mininet. **O `netlab.sh`, o script que a
aula 1 pôs em `~/netlab`, monta cada rede com três peças do kernel do Linux:**

- um **namespace de rede** para cada dispositivo: interfaces, endereços, tabela de rotas e firewall
  próprios, isolados dos outros, embora todos rodem num computador só;
- um **par Ethernet virtual** para cada cabo: duas interfaces ligadas costas com costas, uma ponta
  movida para cada dispositivo, de modo que o que entra numa ponta sai na outra;
- uma **bridge do Linux** para cada switch, dentro do namespace do próprio switch, que aprende
  endereços MAC e inunda do jeito que a aula 18 descreve.

Roteadores são namespaces com o encaminhamento ligado, e os protocolos de roteamento das aulas 16 e 17
são o FRR, uma cópia dos daemons dele por roteador. A função que passa um cabo é curta o bastante para
ler inteira:

```bash
link() {  # link NODE1 IF1 NODE2 IF2 : one cable
  local tmp1="t$RANDOM$RANDOM" tmp2="u$RANDOM$RANDOM"
  ip link add "$tmp1" type veth peer "$tmp2"
  ip link set "$tmp1" netns "$1"; ip -n "$1" link set "$tmp1" name "$2"
  ip link set "$tmp2" netns "$3"; ip -n "$3" link set "$tmp2" name "$4"
  ip -n "$1" link set "$2" address "$(mac "$1" "$2")"
  ip -n "$3" link set "$4" address "$(mac "$3" "$4")"
  ip -n "$1" link set "$2" up
  ip -n "$3" link set "$4" up
}
```

Ela cria o par com nomes temporários, move uma ponta para cada dispositivo, renomeia as duas (`eth0` num
PC, `p1` num switch), dá a cada ponta um endereço MAC fixo e liga as duas. Com o escritório da aula 1
montado, o próprio computador lista os dispositivos:

```
ana@lab:~$ ip netns list
isp (id: 8)
r1 (id: 7)
web2 (id: 11)
web1 (id: 10)
lb (id: 9)
sw1 (id: 3)
srv (id: 6)
pc3 (id: 5)
pc2 (id: 4)
pc1 (id: 1)
```

Dez namespaces, dez dispositivos: três PCs e o srv, o switch, o roteador r1, o isp do provedor, o
balanceador de carga e os dois servidores web dele. A ordem e os números `id` são a contabilidade do
kernel e não dizem nada sobre a rede. Olhando dentro do switch:

```
ana@lab:~$ sudo ip -n sw1 -br link
lo               UNKNOWN        00:00:00:00:00:00 <LOOPBACK,UP,LOWER_UP> 
br0              UP             02:6a:dc:93:3b:8a <BROADCAST,MULTICAST,UP,LOWER_UP> 
p1@if413         UP             02:b7:0a:5d:30:6c <BROADCAST,MULTICAST,UP,LOWER_UP> 
p2@if415         UP             02:af:4f:ef:d8:f9 <BROADCAST,MULTICAST,UP,LOWER_UP> 
p3@if417         UP             02:ae:7e:a8:31:05 <BROADCAST,MULTICAST,UP,LOWER_UP> 
p4@if419         UP             02:11:c9:91:f3:9f <BROADCAST,MULTICAST,UP,LOWER_UP> 
p8@if421         UP             02:a0:79:0c:dd:24 <BROADCAST,MULTICAST,UP,LOWER_UP> 
```

`br0` é a bridge, o próprio switch. De `p1` a `p4` e `p8` são as portas dele, cada uma a ponta de um
cabo, e `@if413` diz que a outra ponta da p1 é a interface número 413, que mora em outro namespace.
Dentro do pc1:

```
ana@lab:~$ sudo ip netns exec pc1 ip -br addr
lo               UNKNOWN        127.0.0.1/8 ::1/128 
eth0@if412       UP             10.20.10.21/24 fe80::25:70ff:febc:29c6/64 
```

O `eth0` do pc1 é essa outra ponta, e o `@if412` dele aponta de volta, pelo cabo, para a p1. Ela tem
`10.20.10.21/24`, o endereço que o cenário do escritório lhe dá. O `02:` no começo de cada MAC do switch
marca um endereço escolhido pelo laboratório e não por um fabricante, o que a aula 2 explica.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 258\" role=\"img\" aria-label=\"O cenário do escritório no laboratório deste curso. Dentro do escritório, 10.20.10.0/24: pc1 em 10.20.10.21, pc2 em 10.20.10.22, pc3 em 10.20.10.23 e srv em 10.20.10.10, nas portas p1 a p4 do switch sw1. A porta p8 vai ao roteador r1, que é 10.20.10.1 por dentro e 203.0.113.2 por fora. O r1 liga ao isp, em 203.0.113.1 e 192.0.2.1. Abaixo do isp está o lb, o balanceador de carga em 192.0.2.80, com dois servidores web atrás dele: web1 em 10.99.0.11 e web2 em 10.99.0.18.\"><rect x=\"10\" y=\"12\" width=\"300\" height=\"236\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"22\" y=\"28\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o escritório</text><text x=\"298\" y=\"28\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10.20.10.0/24</text><rect x=\"200\" y=\"96\" width=\"96\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"20\" y=\"42\" width=\"120\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"55\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pc1</text><text x=\"30\" y=\"71\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.20.10.21</text><path d=\"M140 62 L200 110\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"206\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">p1</text><rect x=\"20\" y=\"92\" width=\"120\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"105\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pc2</text><text x=\"30\" y=\"121\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.20.10.22</text><path d=\"M140 112 L200 124\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"206\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">p2</text><rect x=\"20\" y=\"142\" width=\"120\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"155\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pc3</text><text x=\"30\" y=\"171\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.20.10.23</text><path d=\"M140 162 L200 138\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"206\" y=\"138\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">p3</text><rect x=\"20\" y=\"192\" width=\"120\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"205\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">srv</text><text x=\"30\" y=\"221\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.20.10.10</text><path d=\"M140 212 L200 152\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"206\" y=\"152\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">p4</text><text x=\"248\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">sw1</text><text x=\"288\" y=\"110\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">p8</text><path d=\"M296 131 L330 131\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"330\" y=\"98\" width=\"120\" height=\"66\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"340\" y=\"112\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">r1</text><text x=\"340\" y=\"130\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.20.10.1</text><text x=\"340\" y=\"148\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">203.0.113.2</text><path d=\"M450 131 L478 131 L478 70 L490 70\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"490\" y=\"40\" width=\"112\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"500\" y=\"54\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">isp</text><text x=\"500\" y=\"71\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">203.0.113.1</text><text x=\"500\" y=\"87\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">192.0.2.1</text><path d=\"M546 100 L546 140\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"490\" y=\"140\" width=\"112\" height=\"66\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"500\" y=\"154\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">lb</text><text x=\"500\" y=\"171\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">192.0.2.80</text><text x=\"500\" y=\"189\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">balanceador</text><path d=\"M602 160 L622 148\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"622\" y=\"128\" width=\"92\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"631\" y=\"141\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">web1</text><text x=\"631\" y=\"157\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.99.0.11</text><path d=\"M602 188 L622 200\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"622\" y=\"180\" width=\"92\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"631\" y=\"193\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">web2</text><text x=\"631\" y=\"209\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.99.0.18</text></svg>", "caption": "Os dez namespaces do cenário do escritório. Cada caixa é um dispositivo com interfaces e rotas próprias; cada linha é um par Ethernet virtual."}
```

Você o usa desde a aula 1, e os comandos são poucos. O `up` desmonta o que estiver lá e monta uma rede
do zero, então toda aula começa do mesmo estado, e não do que a anterior deixou; o `on` roda um
comando, ou abre um shell, num dispositivo com um usuário, que é como as transcrições destas aulas
foram gravadas; o `down` desfaz tudo. **É o mesmo tipo de laboratório que o Mininet, então tem o mesmo
limite**: tudo nele é Linux, e quando uma aula fala da linha de comando de um fabricante, ela diz isso
e não mostra saída nenhuma.
