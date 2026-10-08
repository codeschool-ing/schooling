---
title: Oito grupos de dezesseis bits
version: 2
---

Um endereço IPv6 tem 128 bits, quatro vezes o tamanho de um endereço IPv4. Escrito em decimal com
pontos seriam dezesseis números, então ele é escrito **em hexadecimal: oito grupos de quatro dígitos
hexadecimais, separados por dois-pontos**. Cada dígito hexadecimal são quatro bits, então cada grupo
tem 16 bits, e oito grupos dão 128.

O escritório desta aula fala IPv4 e IPv6 ao mesmo tempo. Salve-o como `~/netlab/dualstack.sh`:

```bash
# ~/netlab/dualstack.sh: an office LAN that speaks IPv4 and IPv6 at once. r1
# announces the office's IPv6 prefix with radvd and the PCs build their own
# addresses from it; srv is given its IPv6 address by hand.
#
#   pc1 pc2 srv --- sw1 --- r1 === isp --- web
#   10.20.10.0/24           203.0.113.0/30        192.0.2.0/24
#   2001:db8:20:10::/64     2001:db8:ffff::/64    2001:db8:99::/64
local n
for n in pc1 pc2 srv sw1 web; do node $n; done
node r1 router; node isp router
link pc1 eth0 sw1 p1; link pc2 eth0 sw1 p2; link srv eth0 sw1 p4; link r1 eth0 sw1 p8
switch sw1 "p1 p2 p4 p8"
addr pc1 eth0 10.20.10.21/24; addr pc2 eth0 10.20.10.22/24; addr srv eth0 10.20.10.10/24
addr r1 eth0 10.20.10.1/24; addr r1 eth0 2001:db8:20:10::1/64
addr srv eth0 2001:db8:20:10::10/64
ip netns exec srv sysctl -qw net.ipv6.conf.eth0.autoconf=0   # its one address is the one it was given
for n in pc1 pc2 srv; do gw $n 10.20.10.1; done
ip -n srv -6 route add default via 2001:db8:20:10::1
link r1 eth1 isp eth0
addr r1 eth1 203.0.113.2/30; addr isp eth0 203.0.113.1/30; gw r1 203.0.113.1
addr r1 eth1 2001:db8:ffff::2/64; addr isp eth0 2001:db8:ffff::1/64
ip -n r1 -6 route add default via 2001:db8:ffff::1
ip -n isp -6 route add 2001:db8:20::/48 via 2001:db8:ffff::2
link isp eth1 web eth0
addr isp eth1 192.0.2.1/24; addr web eth0 192.0.2.80/24; gw web 192.0.2.1
addr isp eth1 2001:db8:99::1/64; addr web eth0 2001:db8:99::80/64
ip -n web -6 route add default via 2001:db8:99::1
ip netns exec r1 nft -f - <<'NFT'
table ip nat {
  chain postrouting {
    type nat hook postrouting priority srcnat;
    oifname "eth1" masquerade
  }
}
NFT
cat > "$LAB/r1/radvd.conf" <<'RA'
interface eth0 {
  AdvSendAdvert on;
  MinRtrAdvInterval 30;
  MaxRtrAdvInterval 100;
  prefix 2001:db8:20:10::/64 {
    AdvOnLink on;
    AdvAutonomous on;
  };
};
RA
daemon r1 radvd radvd -n -C "$LAB/r1/radvd.conf" -p "$LAB/r1/radvd.pidfile" -m stderr
web web '::'
for n in pc1 pc2 srv r1; do
  host $n 10.20.10.10 srv; host $n 2001:db8:20:10::10 srv
  host $n 192.0.2.80 web; host $n 2001:db8:99::80 web
done
```

O r1 roda o radvd, o programa que a seção sobre SLAAC lê, com a configuração escrita no diretório
dele, e os PCs montam seus endereços IPv6 a partir do que ele anuncia. Monte com
`sudo bash ~/netlab/netlab.sh up dualstack` e dê dez segundos, para que o primeiro anúncio chegue a
todos os PCs.

Essa forma é comprida, e duas regras a encurtam. O servidor do escritório desta aula recebeu o
endereço à mão, e a forma curta é o que o Linux imprime:

```
ana@srv:~$ ip -6 addr show eth0
32: eth0@if31: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000 link-netns sw1
    inet6 2001:db8:20:10::10/64 scope global 
       valid_lft forever preferred_lft forever
    inet6 fe80::9e:43ff:fe3e:caae/64 scope link 
       valid_lft forever preferred_lft forever
```

`2001:db8:20:10::10` é o endereço do srv e `/64` o seu prefixo. (A linha `fe80::` é um segundo
endereço que toda interface tem, e a próxima seção trata dele.) O `sipcalc` expande a forma curta:

```
ana@pc1:~$ sipcalc 2001:db8:20:10::10
-[ipv6 : 2001:db8:20:10::10] - 0

[IPV6 INFO]
Expanded Address	- 2001:0db8:0020:0010:0000:0000:0000:0010
Compressed address	- 2001:db8:20:10::10
Subnet prefix (masked)	- 2001:db8:20:10:0:0:0:10/128
Address ID (masked)	- 0:0:0:0:0:0:0:0/128
Prefix address		- ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff
Prefix length		- 128
Address type		- Aggregatable Global Unicast Addresses
Network range		- 2001:0db8:0020:0010:0000:0000:0000:0010 -
			  2001:0db8:0020:0010:0000:0000:0000:0010

-
ana@pc1:~$ ping -c 1 2001:0db8:0020:0010:0000:0000:0000:0010
PING 2001:0db8:0020:0010:0000:0000:0000:0010 (2001:db8:20:10::10) 56 data bytes
64 bytes from 2001:db8:20:10::10: icmp_seq=1 ttl=64 time=8.02 ms

--- 2001:0db8:0020:0010:0000:0000:0000:0010 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 8.019/8.019/8.019/0.000 ms
```

A linha `Expanded Address` é o endereço sem nada omitido:
`2001:0db8:0020:0010:0000:0000:0000:0010`. Duas regras o transformam na forma curta.

**Regra um: os zeros à esquerda de um grupo podem cair.** `0db8` vira `db8`, `0020` vira `20`, e `0000`
vira `0`. Só os zeros à esquerda: o zero final de `0010` faz parte do número, e tirá-lo daria `1`, outro
valor.

**Regra dois: uma sequência de grupos só de zeros pode ser trocada por `::`, uma vez por endereço.** Os
três grupos `0000` do meio viram `::`. Uma vez, porque dois seriam ambíguos: em `2001::5::1`, ninguém
sabe quantos grupos de zeros cada `::` esconde. Para expandir um endereço, conte os grupos escritos e
deixe o `::` ocupar o resto. Em `2001:db8:20:10::10` há cinco grupos escritos, então o `::` vale
8 − 5 = 3 grupos de zeros.

O ping acima mostra que as duas formas são o mesmo endereço. Ele recebeu a forma longa, imprimiu a
curta entre parênteses, e o srv respondeu: **a máquina compara 128 bits, não texto**. Já pessoas e
programas comparam texto. Uma busca por `2001:0db8:0020:0010` não acha nada num log que escreveu
`2001:db8:20:10::10`. A RFC 5952 fixou um jeito de escrever cada endereço: minúsculas, zeros à esquerda
omitidos e `::` na maior sequência de zeros. O Linux segue essa regra, então busque por essa forma.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 236\" role=\"img\" aria-label=\"O endereço IPv6 do srv escrito por extenso como oito grupos de quatro dígitos hexadecimais, cada grupo com 16 bits: 2001, 0db8, 0020, 0010, 0000, 0000, 0000, 0010. Os quatro primeiros grupos são o prefixo, 64 bits, a rede 2001:db8:20:10::/64. Os quatro últimos são o identificador de interface, 64 bits, aqui ::10, escrito à mão. Os grupos cinco a sete, só zeros, estão destacados. Na forma curta, o endereço é 2001:db8:20:10::10: os zeros à esquerda caem em cada grupo, e os dois-pontos duplos ficam no lugar dos três grupos de zeros.\"><rect x=\"18\" y=\"30\" width=\"82\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"59\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" fill=\"var(--paper)\">2001</text><text x=\"59\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">16 bits</text><text x=\"102\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper-dim)\">:</text><rect x=\"104\" y=\"30\" width=\"82\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"145\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" fill=\"var(--paper)\">0db8</text><text x=\"145\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">16 bits</text><text x=\"188\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper-dim)\">:</text><rect x=\"190\" y=\"30\" width=\"82\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"231\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" fill=\"var(--paper)\">0020</text><text x=\"231\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">16 bits</text><text x=\"274\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper-dim)\">:</text><rect x=\"276\" y=\"30\" width=\"82\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"317\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" fill=\"var(--paper)\">0010</text><text x=\"317\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">16 bits</text><text x=\"360\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper-dim)\">:</text><rect x=\"362\" y=\"30\" width=\"82\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"403\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" fill=\"var(--paper-dim)\">0000</text><text x=\"403\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">16 bits</text><text x=\"446\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper-dim)\">:</text><rect x=\"448\" y=\"30\" width=\"82\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"489\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" fill=\"var(--paper-dim)\">0000</text><text x=\"489\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">16 bits</text><text x=\"532\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper-dim)\">:</text><rect x=\"534\" y=\"30\" width=\"82\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"575\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" fill=\"var(--paper-dim)\">0000</text><text x=\"575\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">16 bits</text><text x=\"618\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper-dim)\">:</text><rect x=\"620\" y=\"30\" width=\"82\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"661\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" fill=\"var(--paper)\">0010</text><text x=\"661\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">16 bits</text><path d=\"M18 104 L358 104\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"188\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">prefixo, 64 bits: a rede</text><text x=\"188\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">2001:db8:20:10::/64</text><path d=\"M362 104 L702 104\" stroke=\"var(--wire)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"532\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">identificador de interface, 64 bits</text><text x=\"532\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">aqui ::10, escrito à mão</text><text x=\"18\" y=\"178\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">na forma curta</text><text x=\"140\" y=\"178\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" fill=\"var(--paper)\">2001:db8:20:10::10</text><text x=\"18\" y=\"210\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">zeros à esquerda caem em cada grupo; \"::\" está no lugar dos três grupos de zeros destacados</text></svg>", "caption": "Um endereço, 128 bits, na forma em que o sipcalc o expande. O prefixo /64 identifica a rede e a outra metade identifica a interface nela.", "same": ["16 bits"]}
```

O prefixo se escreve como no IPv4, com uma barra. **`/64` quer dizer que os primeiros 64 bits
identificam a rede, `2001:db8:20:10::/64`, e os últimos 64 bits identificam a interface nela.** No
IPv4 a parte de host era o que a máscara deixasse; no IPv6 uma LAN é um `/64` quase sempre, então a
parte de host tem 64 bits: cabem tantas interfaces quanto a internet IPv4 inteira ao quadrado. O identificador de interface
do srv, `::10`, foi escolhido à mão para ser fácil de lembrar. Os PCs escolhem o seu, e esse é o
assunto das próximas duas seções.

Mais duas leituras da saída. `2001:db8::/32` é o bloco que a RFC 3849 reserva para documentação, o
equivalente IPv6 do `203.0.113.0/24` que a aula 8 mostrou, e por isso o laboratório pode imprimi-lo.
`Aggregatable Global Unicast Addresses` é o nome que o sipcalc dá aos endereços globais, os que são
roteados na internet; sem prefixo, o sipcalc tratou o endereço como um `/128`, uma interface só, do
jeito que o ipcalc supunha um `/24`.
