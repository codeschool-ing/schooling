---
title: Uma máscara mais larga do que parece
version: 1
---

Os administradores no segmento de gerência devem chegar aos servidores por SSH. A regra é digitada às
pressas:

```
root@fw:~# nft add rule ip filter forward ip saddr 192.168.99.0/16 oifname eth3 tcp dport 22 ct state new accept comment '"admins reach the servers over SSH"'
```

`192.168.99.0/16`. A intenção era `/24`: o segmento de gerência. Listar a regra de volta mostra o que o
nftables realmente guardou:

```
root@fw:~# nft list chain ip filter forward | grep "admins reach" | sed "s/^\t*//"
ip saddr 192.168.0.0/16 oifname "eth3" tcp dport 22 ct state new accept comment "admins reach the servers over SSH"
```

**`192.168.0.0/16`.** Um `/16` mantém só os dois primeiros bytes, então o nftables normalizou o endereço
para a rede que ele de fato descreve, que contém toda faixa do laboratório que começa com `192.168`: o
segmento de gerência, e também a LAN da equipe, os servidores e a filial. Da LAN da equipe:

```
ana@laptop:~$ probe app:22 db:22
app:22                 open
db:22                  open
```

O SSH nos dois servidores está aberto para o `laptop`. Nada falhou ao carregar e nenhuma regra parece
errada à primeira vista; a célula da matriz que diz *LAN da equipe para servidores: só a aplicação*
simplesmente deixou de ser verdade.

**Leia cada regra de volta depois de carregá-la.** O conjunto de regras no kernel é a verdade, e nem
sempre é o texto que foi digitado: o nftables reescreveu este endereço para a rede que ele descreve. Uma
olhada rápida na listagem pega exatamente essa classe de erro, em que o texto digitado e o significado
guardado divergem. As ACLs de roteador armam a mesma armadilha com as máscaras curinga (wildcard masks)
da aula 17, em que um byte errado alarga uma linha por um fator de 256.
