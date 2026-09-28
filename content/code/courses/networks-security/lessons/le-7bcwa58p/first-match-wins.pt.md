---
title: A primeira correspondência vence, então posição é significado
version: 1
---

Uma cadeia (chain) é lida de cima para baixo, e **a primeira regra cujas condições casam todas é a que
decide**. Nenhuma regra abaixo dela é consultada para aquele pacote. Esse único fato explica a maior
parte dos bugs em conjuntos de regras: uma regra pode estar perfeitamente escrita e não fazer nada,
porque algo acima dela já decidiu.

O `laptop` precisa ser isolado enquanto alguém o investiga. O administrador acrescenta uma regra à
configuração de base:

```
root@fw:~# nft add rule ip filter forward ip saddr 192.168.10.20 counter drop comment '"laptop quarantined, ticket 5120"'
```

O `nft add` acrescenta ao fim: a regra vai para **o final** da cadeia. Então o `laptop` tenta os serviços
de sempre:

```
ana@laptop:~$ probe app:8080 www:443
app:8080               open
www:443                open
```

**Os dois continuam abertos.** A quarentena não fez nada, e a listagem das regras diz por quê:

```
root@fw:~# nft -a list chain ip filter forward | grep -E "staff use|quarantined" | sed "s/^\t*//"
iifname "eth2" oifname "eth3" ip daddr 192.168.20.10 tcp dport 8080 ct state new accept comment "staff use the application" # handle 10
ip saddr 192.168.10.20 counter packets 0 bytes 0 drop comment "laptop quarantined, ticket 5120" # handle 20
```

A regra da equipe, handle 10, fica acima da quarentena, handle 20, e aceita a conexão do `laptop` para a
aplicação antes que o descarte seja sequer lido; a regra da web faz o mesmo para `www`. O contador do
descarte está em **0 pacotes**. Uma regra **sombreada** (shadowed), inteiramente coberta por regras
acima dela, parece exatamente uma regra que funciona no arquivo, e só o contador a denuncia.

A correção é a posição. Os handles mostram onde cada coisa está:

```
root@fw:~# nft -a list chain ip filter forward | sed -n "3,4p;/quarantined/p" | sed "s/^\t*//"
type filter hook forward priority filter; policy drop;
ct state established,related accept # handle 3
ip saddr 192.168.10.20 counter packets 0 bytes 0 drop comment "laptop quarantined, ticket 5120" # handle 20
root@fw:~# nft delete rule ip filter forward handle 20
root@fw:~# nft insert rule ip filter forward position 4 ip saddr 192.168.10.20 counter drop comment '"laptop quarantined, ticket 5120"'
```

`insert … position 4` põe a regra antes do handle 4, logo depois da regra do tráfego estabelecido, então
toda conexão nova do `laptop` a encontra antes de qualquer `accept`:

```
root@fw:~# nft list chain ip filter forward | sed -n "3,6p" | sed "s/^\t*//"
type filter hook forward priority filter; policy drop;
ct state established,related accept
ip saddr 192.168.10.20 counter packets 0 bytes 0 drop comment "laptop quarantined, ticket 5120"
ct state invalid drop
ana@laptop:~$ probe app:8080 www:443
app:8080               blocked
www:443                blocked
root@fw:~# nft list chain ip filter forward | grep quarantined | sed "s/^\t*//"
ip saddr 192.168.10.20 counter packets 2 bytes 120 drop comment "laptop quarantined, ticket 5120"
```

Bloqueado, e o contador mostra as duas tentativas. A quarentena da aula 9 usou `insert` sem posição, o
que põe a regra bem no topo, acima até do tráfego estabelecido, e corta conexões que já estavam abertas.
Qual das duas se quer é uma decisão; **`add` quase nunca é o que uma quarentena quer.**

A ordem também custa tempo. Todo pacote percorre a cadeia até algo casar, então as regras que casam com
a maior parte do tráfego ficam perto do topo, e é por isso que a aula 1 pôs `established,related`
primeiro; e listas longas de endereços ficam em um set, que o nftables consulta em um único passo em vez
de regra por regra.
