---
title: Estático ou dinâmico: quem anota o endereço
version: 2
---

A aula 8 deu a cada máquina um endereço IPv4, e a aula 12 dá a ela uma máscara, mas nenhuma das duas
diz de onde esses números vêm. Há duas respostas. **Um endereço estático é digitado no próprio
dispositivo; um dinâmico é emprestado por um servidor que guarda a lista.** O protocolo que empresta
é o DHCP (*Dynamic Host Configuration Protocol*), e ele entrega mais do que um endereço: a máscara, o
gateway padrão e os servidores de nomes chegam na mesma resposta.

A imagem comum é que um endereço dinâmico muda o tempo todo e um estático não muda. Nenhuma das
metades se sustenta. Um servidor DHCP lembra quem tinha qual endereço: nesta aula o pc2 devolve o
10.20.10.101 e, na vez seguinte em que pede, recebe o 10.20.10.101 de novo. E um endereço estático
muda no momento em que alguém o digita outra vez. **A diferença é onde o endereço fica anotado: na
máquina, ou na configuração de um servidor.**

Este é o laboratório da aula:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 292\" role=\"img\" aria-label=\"O laboratório desta aula. Na LAN do escritório, 10.20.10.0/24, cinco máquinas estão ligadas ao switch sw1: pc1 na porta p1 e pc2 na porta p2, os dois clientes; a impressora prn na p3, MAC 02:32:ed:ce:04:12, com uma reserva para o .50; rogue na p5, um PC que depois vira um servidor DHCP intruso; e srv, 10.20.10.10, o servidor DHCP, na p4. A porta p8 vai para o roteador r1, que é 10.20.10.1 na eth0 e 10.20.20.1 na eth2 e faz o relay de DHCP. Atrás da eth2 fica o segundo andar, 10.20.20.0/24, com o cliente pc4.\"><rect x=\"10\" y=\"10\" width=\"404\" height=\"272\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><rect x=\"604\" y=\"10\" width=\"106\" height=\"272\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><line x1=\"262\" y1=\"40\" x2=\"322\" y2=\"140\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></line><rect x=\"22\" y=\"20\" width=\"240\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"33\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pc1</text><text x=\"32\" y=\"49\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">cliente: pede um endereço</text><text x=\"270\" y=\"32\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">p1</text><line x1=\"262\" y1=\"86\" x2=\"322\" y2=\"140\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></line><rect x=\"22\" y=\"66\" width=\"240\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"79\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pc2</text><text x=\"32\" y=\"95\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">cliente</text><text x=\"270\" y=\"78\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">p2</text><line x1=\"262\" y1=\"132\" x2=\"322\" y2=\"140\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></line><rect x=\"22\" y=\"112\" width=\"240\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"125\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">prn  02:32:ed:ce:04:12</text><text x=\"32\" y=\"141\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">impressora, reservada .50</text><text x=\"270\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">p3</text><line x1=\"262\" y1=\"178\" x2=\"322\" y2=\"140\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></line><rect x=\"22\" y=\"158\" width=\"240\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"171\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">rogue</text><text x=\"32\" y=\"187\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">um PC; depois, servidor intruso</text><text x=\"270\" y=\"190\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">p5</text><line x1=\"262\" y1=\"224\" x2=\"322\" y2=\"140\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></line><rect x=\"22\" y=\"204\" width=\"240\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"217\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">srv  10.20.10.10</text><text x=\"32\" y=\"233\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">servidor DHCP</text><text x=\"270\" y=\"236\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">p4</text><rect x=\"322\" y=\"108\" width=\"76\" height=\"64\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">sw1</text><text x=\"360\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">switch</text><line x1=\"398\" y1=\"140\" x2=\"452\" y2=\"140\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></line><text x=\"422\" y=\"131\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">p8</text><rect x=\"452\" y=\"96\" width=\"136\" height=\"88\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"462\" y=\"112\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">r1</text><text x=\"462\" y=\"130\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">roteador e relay</text><text x=\"462\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">eth0 10.20.10.1</text><text x=\"462\" y=\"168\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">eth2 10.20.20.1</text><line x1=\"588\" y1=\"140\" x2=\"614\" y2=\"140\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></line><rect x=\"614\" y=\"116\" width=\"88\" height=\"48\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"624\" y=\"132\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pc4</text><text x=\"624\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">cliente</text><text x=\"22\" y=\"254\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">LAN do escritório</text><text x=\"22\" y=\"270\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10.20.10.0/24</text><text x=\"614\" y=\"254\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">segundo andar</text><text x=\"614\" y=\"270\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10.20.20.0/24</text></svg>", "caption": "O laboratório desta aula: cinco máquinas num switch, um roteador que faz relay de DHCP e um segundo andar atrás dele.", "same": ["switch"]}
```

Salve-o como `~/netlab/dhcp.sh` e monte com `sudo bash ~/netlab/netlab.sh up dhcp`:

```bash
# ~/netlab/dhcp.sh: an office whose PCs get their addresses from a DHCP
# server. srv serves the office LAN and, through a relay on r1, a second floor
# on its own subnet. prn is a printer with a reservation; rogue is an
# ordinary PC, the one lesson 10 reads about.
#
#   pc1 pc2 prn rogue srv --- sw1 --- r1 --- pc4
#   10.20.10.0/24 (srv .10, r1 .1)       10.20.20.0/24 (r1 .1)
local n
for n in pc1 pc2 prn rogue srv sw1 pc4; do node $n; done
node r1 router
link pc1 eth0 sw1 p1; link pc2 eth0 sw1 p2; link prn eth0 sw1 p3; link rogue eth0 sw1 p5
link srv eth0 sw1 p4; link r1 eth0 sw1 p8
switch sw1 "p1 p2 p3 p4 p5 p8"
link r1 eth2 pc4 eth0
addr srv eth0 10.20.10.10/24; addr r1 eth0 10.20.10.1/24; addr r1 eth2 10.20.20.1/24
gw srv 10.20.10.1
cat > "$LAB/srv/dhcpd.conf" <<CONF
# the office's DHCP server
authoritative;
default-lease-time 600;
max-lease-time 7200;
option domain-name-servers 10.20.10.10;

subnet 10.20.10.0 netmask 255.255.255.0 {
  range 10.20.10.100 10.20.10.199;
  option routers 10.20.10.1;
}

subnet 10.20.20.0 netmask 255.255.255.0 {
  range 10.20.20.100 10.20.20.199;
  option routers 10.20.20.1;
}

host prn {
  hardware ethernet $(mac prn eth0);
  fixed-address 10.20.10.50;
}
CONF
dhcpd_on srv eth0 "$LAB/srv/dhcpd.conf"
```

O bloco entre `<<CONF` e `CONF` é a configuração do servidor DHCP, escrita num arquivo do srv e lida
na seção sobre escopos; `dhcpd_on` sobe o servidor com ela. Nenhum PC recebe endereço IPv4: cada um
pede o seu nesta aula.

Os PCs começam sem nada. Este é o pc1 antes de pedir qualquer coisa a alguém:

```
ana@pc1:~$ ip -br addr show eth0
eth0@if123       UP             fe80::25:70ff:febc:29c6/64 
ana@pc1:~$ ip route
```

O único endereço dele é `fe80::25:70ff:febc:29c6/64`, o endereço IPv6 link-local que toda interface
dá a si mesma (aula 9). Não há endereço IPv4, e o `ip route` não imprimiu nada: nenhuma rota para a
própria sub-rede, nenhum gateway padrão. **Sem endereço, o pc1 não alcança nada por IPv4, nem o PC
ao lado**, e é nesse estado que todo laptop está no momento em que é conectado.

Recebe endereço estático tudo o que outras máquinas precisam encontrar pelo número, e tudo o que
precisa continuar funcionando quando o servidor DHCP não funciona. Neste laboratório são o r1 em
10.20.10.1, o gateway informado a todos os PCs, e o srv em 10.20.10.10, o próprio servidor DHCP — um
servidor não consegue emprestar um endereço a si mesmo antes de estar rodando. Servidores de nomes
entram no mesmo grupo. Cada um desses endereços está escrito no `dhcp.sh`, abaixo, numa linha `addr`.

Tudo o que vai e vem é dinâmico: laptops, celulares, desktops, o tablet de um visitante. Digitar os
endereços deles à mão custa mais do que os minutos que leva. Alguém erra a digitação e duas máquinas
dividem um endereço; uma máscara está errada e metade da sub-rede fica inalcançável, o que a aula 12
mostra acontecendo; e a planilha que registra quem tem o quê está desatualizada na sexta-feira. Com
DHCP o registro é o próprio arquivo do servidor, e mudar duzentos PCs para um novo servidor de nomes
é uma linha nele.

Impressoras são o terceiro caso clássico: um dispositivo que todo mundo alcança pelo endereço e que
ninguém quer configurar à mão. **Uma reserva é o meio-termo: o dispositivo pede por DHCP como
qualquer outro, e o servidor sempre lhe dá o mesmo endereço.** A seção sobre reservas faz isso para
a impressora, a prn.

Uma regra mantém os dois mundos separados. **Os endereços estáticos precisam ficar fora da faixa que
o servidor empresta**, ou cedo ou tarde o servidor oferece a alguém o endereço do roteador. Este
laboratório reserva de 10.20.10.1 a 10.20.10.99 para uso estático e empresta do .100 ao .199, e a
seção sobre escopos lê o arquivo que diz isso.
