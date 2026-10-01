---
title: Uma regra escrita ao contrário
version: 1
---

O servidor de nomes na DMZ precisa buscar suas atualizações por HTTPS. A matriz não tem linha da DMZ
para a internet, então uma regra é acrescentada:

```
root@fw:~# nft add rule ip filter forward iifname eth0 oifname eth1 ip saddr 192.0.2.53 tcp dport 443 counter accept comment '"dns fetches its updates"'
```

Então o `dns` tenta:

```
ana@dns:~$ probe remote:443
remote:443             blocked
root@fw:~# nft list chain ip filter forward | grep "its updates" | sed "s/^\t*//"
iifname "eth0" oifname "eth1" ip saddr 192.0.2.53 tcp dport 443 counter packets 0 bytes 0 accept comment "dns fetches its updates"
```

**Bloqueado, e o contador da regra está em 0.** Leia devagar: `iifname eth0 oifname eth1` quer dizer
*chegando da internet e saindo para a DMZ*, enquanto `ip saddr 192.0.2.53` diz que o pacote vem de
`dns`, que mora na DMZ. Nenhum pacote consegue satisfazer as duas coisas, então a regra não está errada
de nenhum jeito de que o nftables pudesse reclamar; ela é simplesmente impossível. A regra pretendida é
`iifname eth1 oifname eth0`.

Regras impossíveis são fáceis de escrever porque uma regra tem duas pontas e cada uma é descrita duas
vezes, uma pela interface e outra pelo endereço. Também são fáceis de encontrar: **uma regra cujo
contador continua em zero depois que o tráfego para o qual ela foi escrita foi testado** está sombreada,
é impossível, ou descreve um tráfego que não existe.

| sintoma | causa comum |
|---|---|
| contador em 0, o tráfego ainda passa | sombreada por um accept acima dela |
| contador em 0, o tráfego ainda é descartado | sentido errado, interface errada, ou um erro de digitação em um endereço |
| contador subindo, mas no tráfego errado | uma máscara ou uma faixa de portas mais larga que o pretendido |
