---
title: Túnel dividido e túnel completo
version: 1
---

Uma decisão define o dia de quem usa acesso remoto mais do que qualquer outra: **só o tráfego da empresa
passa pelo túnel, ou tudo?** O primeiro é um túnel dividido (split tunnel) e o segundo um túnel completo
(full tunnel). No WireGuard é uma linha, o `AllowedIPs` do laptop, que a aula 4 mostrou ser também a
tabela de rotas dele.

Primeiro o laptop da Ana, dividido, como a aula 4 escreveu o arquivo dela. Ela sobe o túnel com
`sudo wg-quick up wg0` em `remote`:

```
ana@remote:~$ sudo grep AllowedIPs /etc/wireguard/wg0.conf
AllowedIPs = 10.20.0.0/24, 192.168.10.0/24
ana@remote:~$ ip route get 192.168.10.10; ip route get 192.0.2.21
192.168.10.10 dev wg0 src 10.20.0.3 uid 1001 
    cache 
192.0.2.21 via 192.168.1.1 dev eth0 src 192.168.1.50 uid 1001 
    cache 
ana@remote:~$ traceroute -n -q 1 192.0.2.21
traceroute to 192.0.2.21 (192.0.2.21), 30 hops max, 60 byte packets
 1  192.168.1.1  0.848 ms
 2  198.51.100.1  0.623 ms
 3  192.0.2.21  0.567 ms
ana@remote:~$ curl -s http://192.0.2.21/
served by web1
```

O `AllowedIPs` lista a rede do túnel e a LAN da matriz, e mais nada. O `ip route get` pergunta ao kernel
por onde um pacote iria, sem mandar nenhum. Para o `files`, pelo `wg0`, com o endereço de túnel dela,
`10.20.0.3`; para o `web1`, pela `eth0`, via o roteador de casa, `192.168.1.1`. O traceroute concorda:
roteador de casa, provedor, `web1`. **A empresa nunca vê o tráfego web dela.**

Depois o arquivo dela muda para `AllowedIPs = 0.0.0.0/0`, com o túnel derrubado antes. Em `remote`:

```sh
sudo wg-quick down wg0
sudo sed -i 's|^AllowedIPs = .*|AllowedIPs = 0.0.0.0/0|' /etc/wireguard/wg0.conf
```

E ela o sobe de novo:

```
ana@remote:~$ sudo wg-quick up wg0
[#] ip link add wg0 type wireguard
Error: Unknown device type.
[!] Missing WireGuard kernel module. Falling back to slow userspace implementation.
[#] wireguard-go wg0
┌──────────────────────────────────────────────────────┐
│                                                      │
│   Running wireguard-go is not required because this  │
│   kernel has first class support for WireGuard. For  │
│   information on installing the kernel module,       │
│   please visit:                                      │
│         https://www.wireguard.com/install/           │
│                                                      │
└──────────────────────────────────────────────────────┘
[#] wg setconf wg0 /dev/fd/63
[#] ip -4 address add 10.20.0.3/24 dev wg0
[#] ip link set mtu 1420 up dev wg0
[#] wg set wg0 fwmark 51820
[#] ip -4 rule add not fwmark 51820 table 51820
[#] ip -4 rule add table main suppress_prefixlength 0
[#] ip -4 route add 0.0.0.0/0 dev wg0 table 51820
[#] sysctl -q net.ipv4.conf.all.src_valid_mark=1
[#] nft -f /dev/fd/63
```

Este `wg-quick` faz mais do que fez na aula 4, porque uma rota padrão pelo túnel tem uma armadilha. Os
próprios pacotes do túnel, o UDP criptografado para `hq`, também seriam roteados para dentro do túnel e
ficariam dando voltas. As linhas depois de `mtu 1420` são como ele evita isso. O WireGuard marca os
próprios pacotes de saída com `fwmark 51820`. **Todo pacote sem a marca é procurado numa tabela
separada, a 51820, cuja única rota é uma padrão pelo `wg0`**, enquanto os marcados usam a tabela comum
e saem pela `eth0`. O `suppress_prefixlength 0` deixa a tabela comum ainda decidir tudo o que for mais
específico que uma rota padrão, o que mantém a LAN de casa alcançável. A linha do `nft` carrega regras
de firewall que o `wg-quick` não imprime.

```
ana@remote:~$ ip route get 192.0.2.21
192.0.2.21 dev wg0 table 51820 src 10.20.0.3 uid 1001 
    cache 
ana@remote:~$ traceroute -n -q 1 192.0.2.21
traceroute to 192.0.2.21 (192.0.2.21), 30 hops max, 60 byte packets
 1  10.20.0.1  1.048 ms
 2  203.0.113.1  1.267 ms
 3  192.0.2.21  1.278 ms
ana@remote:~$ curl -s http://192.0.2.21/
served by web1
ana@web1:~$ tail -n 2 /lab/web1/www/logs/access.log | cut -d" " -f1-7
198.51.100.77 - - [28/Sep/2026:18:09:20 -0300] "GET /
203.0.113.2 - - [28/Sep/2026:18:09:20 -0300] "GET /
```

Agora a rota para o `web1` é `dev wg0 table 51820`, e o traceroute passa primeiro por `hq`,
`10.20.0.1`, e depois sai para o provedor a partir da matriz. A página é a mesma. As duas últimas linhas
do log de acesso do `web1`, que o `netlab.sh` guarda em `/lab/web1`, são os dois pedidos, feitos no mesmo segundo: **o mesmo laptop e a mesma
página, e o `web1` viu dois clientes diferentes.** Dividido, o pedido veio de `198.51.100.77`, o
roteador da casa da Ana. Completo, veio de `203.0.113.2`, porque `hq` encaminhou o tráfego dela para a
internet e o traduziu para o próprio endereço (NAT, aula 11 de `networks-addressing`).

```schooling-figure
{"svg": "<svg viewBox=\"0 0 760 245\" role=\"img\" aria-label=\"Cinco máquinas: remote em 192.168.1.50, homegw em 198.51.100.77, o roteador do provedor em 203.0.113.1, web1 em 192.0.2.21, e hq em 203.0.113.2 acima do provedor. O caminho dividido vai de remote a homegw, ao provedor e ao web1, e o web1 registra 198.51.100.77. O caminho completo vai de remote por um túnel tracejado até hq, e de hq de volta pelo provedor até o web1, e o web1 registra 203.0.113.2.\"><defs><marker id=\"pa-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"150\" width=\"130\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"85.0\" y=\"163.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">remote</text><text x=\"85.0\" y=\"178.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">192.168.1.50</text><rect x=\"180\" y=\"150\" width=\"130\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"245.0\" y=\"163.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">homegw</text><text x=\"245.0\" y=\"178.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">198.51.100.77</text><rect x=\"370\" y=\"150\" width=\"130\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"435.0\" y=\"163.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">isp</text><text x=\"435.0\" y=\"178.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">203.0.113.1</text><rect x=\"600\" y=\"150\" width=\"130\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"665.0\" y=\"163.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">web1</text><text x=\"665.0\" y=\"178.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">192.0.2.21</text><rect x=\"370\" y=\"40\" width=\"130\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"435.0\" y=\"53.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">hq</text><text x=\"435.0\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">203.0.113.2</text><path d=\"M150 170 L180 170\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M310 170 L370 170\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M500 170 L600 170\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M435 80 L435 150\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M85 196 L 85 214 L 665 214 L 665 196\" stroke=\"var(--phosphor)\" stroke-width=\"1.8\" fill=\"none\" marker-end=\"url(#pa-ah)\"></path><text x=\"375\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">dividido: o web1 registra 198.51.100.77</text><path d=\"M85 150 C 85 60, 250 60, 366 60\" stroke=\"var(--amber)\" stroke-width=\"1.8\" fill=\"none\" stroke-dasharray=\"6 4\" marker-end=\"url(#pa-ah)\"></path><text x=\"150\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">túnel</text><path d=\"M455 80 L 455 146\" stroke=\"var(--amber)\" stroke-width=\"1.8\" fill=\"none\" marker-end=\"url(#pa-ah)\"></path><path d=\"M500 162 L 596 162\" stroke=\"var(--amber)\" stroke-width=\"1.8\" fill=\"none\" marker-end=\"url(#pa-ah)\"></path><text x=\"470\" y=\"112\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">completo: o web1 registra 203.0.113.2</text></svg>", "caption": "O mesmo pedido ao web1, dividido e completo. Os pacotes do túnel completo ainda atravessam homegw e o provedor, criptografados dentro do túnel, e depois atravessam o provedor uma segunda vez ao sair de hq."}
```

Esse segundo endereço é quase todo o argumento a favor do túnel completo. O firewall, os filtros e os
logs da empresa se aplicam a tudo o que ela faz. Um serviço que só aceita o endereço do escritório
funciona da cozinha dela. No Wi-Fi de um café, o tráfego dela atravessa a rede do café criptografado,
desde que o DNS dela vá pelo mesmo caminho, e a próxima seção mostra que isso não é automático. O custo
é o caminho da figura: **toda chamada de vídeo e todo download atravessam duas vezes o
link de internet da matriz**, entrando e saindo. Quando esse link cai, ela perde a internet além do
escritório.

Um túnel dividido é a troca oposta. A matriz leva só o próprio tráfego e as chamadas dela saem direto,
mas todo o resto que ela faz fica fora da vista da empresa, assim como o resto da rede em que o laptop
está. Muitas empresas dividem, e põem na lista uma relação curta de destinos sensíveis que devem passar pelo
túnel.
