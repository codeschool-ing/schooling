---
title: Uma regra no host
version: 1
---

As portas estão no host, então é lá que são fechadas: uma regra de firewall para o tráfego que chega **da
bridge do laboratório**, a `virbr2`, que a descrição da labnet nomeou de propósito. Ela é escrita para o
nftables, o firewall embutido no Linux, num arquivo próprio:

```
ana@host:~$ cat labguard.nft
table inet labguard {
  chain input {
    type filter hook input priority 0; policy accept;
    iifname "virbr2" ct state established,related accept
    iifname "virbr2" udp dport { 53, 67 } counter accept
    iifname "virbr2" tcp dport 53 counter accept
    iifname "virbr2" counter drop
  }
}
ana@host:~$ sudo nft -f labguard.nft && sudo nft list tables
table ip filter
table ip nat
table ip mangle
table ip6 filter
table ip6 nat
table ip6 mangle
table inet labguard
```

Lida de cima para baixo, e a primeira regra que combina decide:

- **`ct state established,related accept`**: respostas a conversas que o host começou. Sem ela, o próprio
  ssh do host para os convidados quebraria, porque as respostas voltam pela `virbr2`.
- **`udp dport { 53, 67 }`** e **`tcp dport 53`**: DHCP e DNS, de que a rede do libvirt precisa para dar
  endereço aos convidados.
- **`drop`**: tudo o mais que um convidado começa em direção ao host, em silêncio.

A `table inet labguard` é uma tabela própria, então pode ser removida com um comando sem mexer nas regras
que o libvirt guarda nas outras tabelas. Depois, a mesma conferência, do mesmo convidado:

```
ana@client:~$ bash check.sh 10.20.0.1
a route out of the lab: closed
the host's ssh: closed
the host's port 8000: closed
a shared folder: closed
a clipboard agent: closed
ana@client:~$ curl -sS -m 5 http://server/
lab server: ok
ana@client:~$ sudo networkctl renew enp1s0 && sleep 5 && ip -4 -br addr show enp1s0
enp1s0           UP             10.20.0.12/24 metric 100 
ana@host:~$ sudo nft list table inet labguard
table inet labguard {
        chain input {
                type filter hook input priority filter; policy accept;
                iifname "virbr2" ct state established,related accept
                iifname "virbr2" udp dport { 53, 67 } counter packets 81 bytes 5999 accept
                iifname "virbr2" tcp dport 53 counter packets 0 bytes 0 accept
                iifname "virbr2" counter packets 6 bytes 360 drop
        }
}
```

**As duas portas para dentro do host estão fechadas**, os convidados continuam se alcançando, e o client
pediu o endereço de novo e continua com ele, `10.20.0.12`. Toda linha `ana@client` depois da regra é também o
próprio ssh do host para dentro do convidado, ainda funcionando. Os contadores dizem o que aconteceu:
**81 pacotes de DHCP e DNS aceitos e 6 descartados**, as batidas nas portas 22 e 8000, mandadas
mais de uma vez cada porque o `nc` repete um pedido que não recebe resposta.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"O que um convidado do laboratório alcança depois que a regra entra. À esquerda, a rede do escritório, com a impressora em 10.0.0.50; o host a alcança pela lan0, 10.0.0.1, e os convidados não têm rota até ela. No meio, o host, com três serviços: ssh na porta 22, o servidor de notas na porta 8000, e DHCP e DNS. À direita, o client em 10.20.0.12 e o server, na labnet, onde o host é a virbr2, 10.20.0.1. Dos convidados, DHCP e DNS são aceitos, e ssh e porta 8000 são descartados pela labguard. Os convidados continuam se alcançando.\"><defs><marker id=\"dr-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"90\" width=\"170\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"114\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a rede do escritório</text><text x=\"32\" y=\"136\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">impressora</text><text x=\"180\" y=\"136\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10.0.0.50</text><rect x=\"250\" y=\"20\" width=\"230\" height=\"200\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"262\" y=\"42\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">host</text><rect x=\"262\" y=\"60\" width=\"206\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"274\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">ssh, porta 22</text><rect x=\"262\" y=\"104\" width=\"206\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"274\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">notas, porta 8000</text><rect x=\"262\" y=\"148\" width=\"206\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"274\" y=\"168\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">DHCP e DNS</text><text x=\"262\" y=\"208\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">lan0 10.0.0.1</text><text x=\"468\" y=\"208\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">virbr2 10.20.0.1</text><path d=\"M192 120 L248 120\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dr-ah)\" marker-start=\"url(#dr-ah)\"></path><rect x=\"560\" y=\"50\" width=\"140\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"572\" y=\"72\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">client</text><text x=\"572\" y=\"90\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10.20.0.12</text><rect x=\"560\" y=\"150\" width=\"140\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"572\" y=\"180\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">server</text><path d=\"M630 102 L630 148\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dr-ah)\" marker-start=\"url(#dr-ah)\"></path><path d=\"M558 70 L472 76\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dr-ah)\" stroke-dasharray=\"4 3\"></path><path d=\"M558 84 L472 120\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dr-ah)\" stroke-dasharray=\"4 3\"></path><path d=\"M558 170 L472 164\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dr-ah)\"></path><path d=\"M20 240 L56 240\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dr-ah)\" stroke-dasharray=\"4 3\"></path><text x=\"64\" y=\"244\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">descartado pela labguard</text><path d=\"M250 240 L286 240\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dr-ah)\"></path><text x=\"294\" y=\"244\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">aceito</text><text x=\"20\" y=\"172\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">sem rota a partir dos convidados</text></svg>", "caption": "A rede isolada fecha o caminho para fora; a regra fecha o caminho para dentro do host. Fica aberto o que o laboratório precisa: endereços, nomes, e os convidados se alcançando.", "same": ["client", "host", "server"]}
```
