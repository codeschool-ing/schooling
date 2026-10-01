---
title: Privado dentro, público fora
version: 1
---

Muita gente acredita que todo computador na internet tem um endereço próprio, que o resto da
internet enxerga. O endereço do pc1 é `10.20.10.21`, e nenhuma máquina fora deste escritório vai
vê-lo num pacote. Milhares de outros escritórios usam neste momento exatamente o mesmo endereço numa
máquina deles, e nenhum conflita com o pc1.

Isso funciona por causa de três blocos que a RFC 1918 (1996) separou para uso **privado**:

| bloco | faixa | tamanho |
|---|---|---|
| `10.0.0.0/8` | 10.0.0.0 a 10.255.255.255 | 16.777.216 endereços |
| `172.16.0.0/12` | 172.16.0.0 a 172.31.255.255 | 1.048.576 endereços |
| `192.168.0.0/16` | 192.168.0.0 a 192.168.255.255 | 65.536 endereços |

Qualquer um pode usá-los sem pedir a ninguém, e **nenhum provedor os roteia pela internet**: um pacote
endereçado a 10.20.10.21 vindo de fora não tem para onde ir. Um endereço privado só é único dentro da
própria rede, e é tudo de que um escritório precisa para as suas máquinas. O bloco do meio é o que as
pessoas lembram errado: ele vai de `172.16` a `172.31`, então `172.32.0.1` é um endereço público
comum.

O pc1 e o roteador, lado a lado:

```
ana@pc1:~$ ip -br addr show eth0
eth0@if430       UP             10.20.10.21/24 fe80::25:70ff:febc:29c6/64 
root@r1:~# ip -br addr
lo               UNKNOWN        127.0.0.1/8 ::1/128 
eth0@if438       UP             10.20.10.1/24 fe80::1f:23ff:fee7:e9d5/64 
eth1@if440       UP             203.0.113.2/30 fe80::a6:80ff:fe20:1354/64 
```

O pc1 tem um endereço, privado. O r1 tem um de cada lado: `10.20.10.1/24` na `eth0`, o gateway do
escritório, e `203.0.113.2/30` na `eth1`, virada para o provedor. (Os endereços `fe80::` ao lado são
IPv6, que a aula 9 explica; o `lo` é a próxima seção.) O roteador é onde o mundo privado acaba:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 262\" role=\"img\" aria-label=\"O escritório do laboratório desta aula. Do lado de dentro, com endereços privados em 10.20.10.0/24: pc1 em 10.20.10.21, pc2 em 10.20.10.22, pc3 em 10.20.10.23 e srv em 10.20.10.10, todos ligados ao switch sw1, que está ligado ao roteador r1, cuja eth0 é 10.20.10.1. A eth1 do r1, 203.0.113.2, fica do lado de fora, ligada ao provedor isp em 203.0.113.1. Todo pacote do escritório sai de 203.0.113.2, o que a aula 11 explica.\"><text x=\"20\" y=\"16\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">dentro: endereços privados, 10.20.10.0/24</text><text x=\"500\" y=\"16\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">fora: endereços públicos</text><path d=\"M480 6 L480 256\" stroke=\"var(--wire)\" stroke-width=\"1.5\" fill=\"none\" stroke-dasharray=\"4 4\"></path><rect x=\"20\" y=\"34\" width=\"130\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"48\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pc1</text><text x=\"32\" y=\"65\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10.20.10.21</text><path d=\"M150 56 L210 140\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"20\" y=\"90\" width=\"130\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"104\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pc2</text><text x=\"32\" y=\"121\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10.20.10.22</text><path d=\"M150 112 L210 140\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"20\" y=\"146\" width=\"130\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pc3</text><text x=\"32\" y=\"177\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10.20.10.23</text><path d=\"M150 168 L210 140\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"20\" y=\"202\" width=\"130\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"216\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">srv</text><text x=\"32\" y=\"233\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10.20.10.10</text><path d=\"M150 224 L210 140\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"210\" y=\"122\" width=\"70\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"245\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">sw1</text><path d=\"M280 140 L320 140\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"320\" y=\"104\" width=\"140\" height=\"72\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"332\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">r1</text><text x=\"332\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">eth0 10.20.10.1</text><text x=\"332\" y=\"158\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">eth1 203.0.113.2</text><path d=\"M460 158 L570 158\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"570\" y=\"122\" width=\"130\" height=\"54\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"582\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">isp</text><text x=\"582\" y=\"158\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">203.0.113.1</text><text x=\"500\" y=\"206\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">todo pacote do escritório sai</text><text x=\"500\" y=\"224\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">de 203.0.113.2 (aula 11)</text></svg>", "caption": "Quatro endereços privados dentro e um endereço público na interface de fora do roteador. A linha tracejada é a borda da rede do escritório."}
```

**Todo pacote que o escritório manda para a internet sai com o endereço público do r1 como origem.** O
roteador troca a origem privada na saída e a devolve nas respostas, o que é NAT, assunto da aula 11.
Para o resto da internet, o escritório inteiro é um endereço só.

Agora pergunte ao ipcalc pelos dois endereços que não são privados:

```
ana@pc1:~$ ipcalc -b 203.0.113.2
Address:   203.0.113.2          
Netmask:   255.255.255.0 = 24   
Wildcard:  0.0.0.255            
=>
Network:   203.0.113.0/24       
HostMin:   203.0.113.1          
HostMax:   203.0.113.254        
Broadcast: 203.0.113.255        
Hosts/Net: 254                   Class C

ana@pc1:~$ ipcalc -b 100.64.1.1
Address:   100.64.1.1           
Netmask:   255.255.255.0 = 24   
Wildcard:  0.0.0.255            
=>
Network:   100.64.1.0/24        
HostMin:   100.64.1.1           
HostMax:   100.64.1.254         
Broadcast: 100.64.1.255         
Hosts/Net: 254                   Class A

```

`203.0.113.2` recebe `Class C` e mais nada, como receberia um endereço público. Mas ele não é um
endereço público comum. **`203.0.113.0/24` é um dos três blocos que a RFC 5737 reserva para
documentação**, junto com `192.0.2.0/24` e `198.51.100.0/24`, para que um livro, um manual ou um
laboratório possam imprimir um endereço que não é de ninguém. Este laboratório os usa no papel da
internet pública, e é por isso que as suas transcrições podem ser publicadas. Este ipcalc não conhece
esses blocos, e não avisa.

`100.64.1.1` recebe `Class A` e mais nada, e isso também está incompleto. **`100.64.0.0/10` é espaço
de endereços compartilhado (RFC 6598, 2012)**: endereços que um provedor usa entre os roteadores dos
clientes e o seu próprio NAT, quando tem endereços públicos de menos para dar um a cada cliente. Esse
arranjo se chama NAT de operadora (*carrier-grade NAT*), e a aula 11 volta a ele. Se a interface de
fora de um roteador doméstico mostra um endereço entre `100.64.0.1` e `100.127.255.254`, o cliente
está atrás de um segundo NAT, do provedor, e ninguém na internet consegue abrir uma conexão direto
para aquela casa.

Duas coisas para guardar desta saída. Uma calculadora conhece as faixas que o autor lhe ensinou, e
esta parou na RFC 1918. **Se um endereço é privado, de documentação ou compartilhado é um fato que
você mesmo confere na tabela**, e a última seção desta aula tem a tabela completa.
