---
title: A política escrita como matriz, depois como regras
version: 1
---

Antes de escrever uma regra, anote **qual zona pode iniciar uma conversa com qual, e em quê**. Uma
tabela de zonas contra zonas, em que cada célula nomeia o que é permitido e toda célula vazia
significa negado, é curta o bastante para revisar e completa o bastante para servir de referência:

| de ↓ para → | internet | DMZ | LAN da equipe | servidores | gestão |
|---|---|---|---|---|---|
| **internet** | · | `www` em 80 e 443; `dns` em UDP 53 | — | — | — |
| **DMZ** | — | · | — | `www` para `app` em 8080 | — |
| **LAN da equipe** | web, 80 e 443 | web, 80 e 443; DNS | · | `app` em 8080 | — |
| **servidores** | — | — | — | · | — |
| **gestão** | — | SSH | — | SSH | · |

Leia uma linha para ver o que uma zona pode fazer e uma coluna para ver o que pode alcançá-la. A
**linha dos servidores está vazia**: nada no segmento de servidores inicia uma conversa com outra
zona. A aplicação responde; ela nunca chama para fora. A linha da DMZ tem uma entrada, e é um host
para um host em uma porta.

O `fw` já guarda esta matriz como regras, em `baseline.nft`, escritas para o laboratório e
carregadas agora:

```
root@fw:~# cat baseline.nft
flush ruleset
table ip filter {
  chain forward {
    type filter hook forward priority filter; policy drop;
    ct state established,related accept
    ct state invalid drop
    iifname "eth2" oifname { "eth0", "eth1" } tcp dport { 80, 443 } ct state new accept comment "staff browse"
    iifname "eth2" oifname "eth1" ip daddr 192.0.2.53 meta l4proto { tcp, udp } th dport 53 ct state new accept comment "staff resolve names"
    iifname "eth2" oifname "eth3" ip daddr 192.168.20.10 tcp dport 8080 ct state new accept comment "staff use the application"
    iifname "eth0" oifname "eth1" ip daddr 192.0.2.80 tcp dport { 80, 443 } ct state new accept comment "the world reaches the shop"
    iifname "eth0" oifname "eth1" ip daddr 192.0.2.53 udp dport 53 ct state new accept comment "the world asks our names"
    iifname "eth1" oifname "eth3" ip saddr 192.0.2.80 ip daddr 192.168.20.10 tcp dport 8080 ct state new accept comment "the proxy reaches the application"
    iifname "eth4" oifname { "eth1", "eth3" } tcp dport 22 ct state new accept comment "administration over SSH"
  }
  chain input {
    type filter hook input priority filter; policy drop;
    ct state established,related accept
    iifname "lo" accept
    iifname "eth4" ip saddr 192.168.99.0/24 tcp dport 22 ct state new accept comment "fw is administered from mgmt only"
  }
}
root@fw:~# nft -f baseline.nft
```

Cada linha `accept` cumpre uma parte da matriz, e **cada uma traz um comentário dizendo o que permite**. A chain
de entrada protege o próprio `fw`: ele só pode ser administrado a partir do segmento de gestão. A
política `drop` nas duas chains é toda célula vazia de uma vez.

Dois detalhes nas regras merecem uma segunda olhada. A célula de DNS da equipe diz `meta l4proto {
tcp, udp } th dport 53`, os dois transportes em uma linha, porque o DNS recorre ao TCP para respostas
grandes. A célula de DNS da internet é **só UDP**, o que o teste da próxima seção torna visível. E
toda regra que sai da DMZ nomeia **um endereço de origem além do de destino**: `ip saddr 192.0.2.80`
significa que, de todas as máquinas da DMZ, só o proxy pode alcançar a aplicação.
