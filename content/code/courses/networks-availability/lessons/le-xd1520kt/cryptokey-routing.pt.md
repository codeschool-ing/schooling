---
title: AllowedIPs: a rota e o filtro
version: 1
---

O nome sugere uma permissão, os endereços que um par tem permissão de alcançar, como se fosse uma linha
de firewall. **É uma lista dos endereços que ficam atrás de um par, e o WireGuard a lê nos dois
sentidos.** O projeto chama isso de cryptokey routing: cada faixa de endereços fica amarrada a
exatamente uma chave pública.

Na saída, um pacote que o kernel roteou para `wg0` é procurado pelo destino. O par cujo `AllowedIPs`
contém esse endereço é aquele para quem o pacote é criptografado, e ele vai para o endpoint desse par.
Na entrada, o pacote é decifrado com a chave de sessão de um par, e **o endereço de origem precisa estar
no `AllowedIPs` desse mesmo par, senão é descartado**.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 760 320\" role=\"img\" aria-label=\"Os dois pares de hq como uma tabela: a chave da filial n/CGaD63… com AllowedIPs 10.20.0.2/32 e 192.168.20.0/24 e endpoint 198.51.100.2:51820; a chave da Ana FYBqYy68… com 10.20.0.3/32 e nenhum endpoint ainda. Na saída, um pacote em wg0 para 192.168.20.30 é casado pelo destino com a linha que contém 192.168.20.0/24, cifrado para n/CGaD63… e enviado a 198.51.100.2:51820. Na entrada, um pacote decifrado com a chave de n/CGaD63… é conferido pela origem contra a mesma linha: se a origem está nela o pacote é entregue, se não é descartado e nada volta.\"><defs><marker id=\"ck-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"16\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">os pares de hq, do wg0.conf</text><text x=\"28\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">par (chave pública)</text><text x=\"234\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">AllowedIPs</text><text x=\"520\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Endpoint</text><rect x=\"20\" y=\"50\" width=\"200\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"28\" y=\"65\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">n/CGaD63…</text><rect x=\"226\" y=\"50\" width=\"280\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"234\" y=\"65\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">10.20.0.2/32, 192.168.20.0/24</text><rect x=\"512\" y=\"50\" width=\"228\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"520\" y=\"65\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">198.51.100.2:51820</text><rect x=\"20\" y=\"84\" width=\"200\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"28\" y=\"99\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">FYBqYy68…</text><rect x=\"226\" y=\"84\" width=\"280\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"234\" y=\"99\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">10.20.0.3/32</text><rect x=\"512\" y=\"84\" width=\"228\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"520\" y=\"99\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">nenhum ainda</text><text x=\"20\" y=\"144\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\" font-weight=\"600\">na saída: lido pelo destino</text><rect x=\"20\" y=\"160\" width=\"190\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"115.0\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">um pacote em wg0 para</text><text x=\"115.0\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">192.168.20.30</text><path d=\"M212 183 L236 183\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ck-ah)\"></path><rect x=\"240\" y=\"160\" width=\"230\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"355.0\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a linha que o contém</text><text x=\"355.0\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">192.168.20.0/24</text><path d=\"M472 183 L496 183\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ck-ah)\"></path><rect x=\"500\" y=\"160\" width=\"260\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"630.0\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">cifrado para n/CGaD63…, enviado a</text><text x=\"630.0\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">198.51.100.2:51820</text><text x=\"20\" y=\"244\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\" font-weight=\"600\">na entrada: lido pela origem</text><rect x=\"20\" y=\"260\" width=\"190\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"115.0\" y=\"276\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">decifrado com a chave de</text><text x=\"115.0\" y=\"292\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">n/CGaD63…</text><path d=\"M212 283 L236 283\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ck-ah)\"></path><rect x=\"240\" y=\"260\" width=\"230\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"355.0\" y=\"276\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a origem está nessa linha?</text><text x=\"355.0\" y=\"292\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">192.168.20.30</text><path d=\"M472 283 L496 283\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ck-ah)\"></path><rect x=\"500\" y=\"260\" width=\"260\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"630.0\" y=\"276\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">sim: entregue. Não: descartado,</text><text x=\"630.0\" y=\"292\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">e nada volta</text></svg>", "caption": "Uma lista, lida duas vezes. A coluna que escolhe a chave de um pacote que sai é a mesma que confere um pacote que entra."}
```

A tabela de rotas do kernel cuida só da primeira parte. Ela põe os pacotes em `wg0` e não faz ideia de
para qual par eles vão:

```
ana@hq:~$ ip route | grep wg0
10.20.0.0/24 dev wg0 proto kernel scope link src 10.20.0.1 
192.168.20.0/24 dev wg0 scope link 
```

O filtro é a metade que ninguém vê até ela morder. Para mostrá-lo, reduza a entrada de `hq` em `branch`
só ao endereço de túnel de `hq`. Em `branch`, com a chave pública de `hq` no lugar do marcador:
`sudo wg set wg0 peer HQ_PUBLIC_KEY allowed-ips 10.20.0.1/32`. Depois:

```
ana@branch:~$ sudo wg show wg0 allowed-ips
B6qH2hb1U5hsBki+4mN/m7AxAAKMeL7maFXl3uAeH2I=	10.20.0.1/32
ana@laptop:~$ ping -c 2 -W 1 192.168.20.30
PING 192.168.20.30 (192.168.20.30) 56(84) bytes of data.

--- 192.168.20.30 ping statistics ---
2 packets transmitted, 0 received, 100% packet loss, time 1004ms

```

Todo o resto estava intacto. `hq` continuava com a rota, o handshake continuava funcionando, e o ping
do laptop foi criptografado e entregue a `branch`. Lá `branch` o decifrou, viu que vinha de
`192.168.10.20`, que não está em `10.20.0.1/32`, e o descartou. **Nada imprimiu erro em nenhum dos
lados**: o laptop viu 100% de perda, como com a chave GRE errada da aula 1. Pôr a LAN do escritório de
volta na lista traz o caixa de volta:

```
ana@branch:~$ sudo wg set wg0 peer B6qH2hb1U5hsBki+4mN/m7AxAAKMeL7maFXl3uAeH2I= allowed-ips 10.20.0.1/32,192.168.10.0/24
ana@laptop:~$ ping -c 1 192.168.20.30
PING 192.168.20.30 (192.168.20.30) 56(84) bytes of data.
64 bytes from 192.168.20.30: icmp_seq=1 ttl=62 time=0.725 ms

--- 192.168.20.30 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 0.725/0.725/0.725/0.000 ms
```

Duas consequências valem mais que o mecanismo.

**O endereço de origem de um pacote que sai de `wg0` é prova de quem o mandou.** Um pacote de
`192.168.20.30` que saiu do túnel em `hq` foi decifrado com a chave de `branch`, porque nenhum outro par
pode usar esse endereço. Então uma regra de firewall em `hq` escrita para `192.168.20.0/24` é uma regra
sobre a filial. O laptop da Ana, com `10.20.0.3/32` e mais nada, não consegue mandar um pacote se
passando pelo caixa. É isso que o WireGuard tem no lugar de contas de usuário.

**Uma faixa pertence a um par de cada vez.** Dar `192.168.20.0/24` a um segundo par a tira do primeiro,
porque um pacote de saída precisa de uma única resposta para "qual chave?". Duas filiais numeradas com a
mesma LAN, portanto, não podem ficar as duas penduradas em `hq`, um problema que a aula 5 encontra pelo
outro lado.

A lista num laptop é o que faz um túnel ser dividido ou completo. `AllowedIPs = 192.168.10.0/24` manda
só o escritório pelo túnel; `AllowedIPs = 0.0.0.0/0` manda tudo, e a aula 5 captura os dois.
