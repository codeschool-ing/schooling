---
title: Um conjunto de regras que outras pessoas conseguem ler
version: 1
---

O conjunto de regras de um firewall vive mais do que a pessoa que o escreveu. Quatro hábitos o mantêm
legível, e o nftables dá suporte direto a cada um.

**Uma família para os dois protocolos.** As tabelas do laboratório são `ip`, só IPv4:

```
root@fw:~# nft list tables
table ip filter
```

Numa rede com IPv6, uma `table ip` deixa todo pacote IPv6 sem filtro, o que é uma segunda política
`accept`, invisível. A família `inet` trata os dois com um único conjunto de regras. A base, com
só a linha `table` alterada por
`sed "s/^table ip filter/table inet filter/" baseline.nft > baseline-inet.nft`, passa limpa na
verificação:

```
root@fw:~# nft -c -f baseline-inet.nft && echo "inet rule set: ok"
inet rule set: ok
```

**Conjuntos em vez de regras repetidas.** Um grupo de endereços ou portas usado em vários lugares
pertence a um conjunto (*set*) com nome, definido uma vez:

```
root@fw:~# cat sets.nft
table ip filter {
  set admins {
    type ipv4_addr
    elements = { 192.168.99.10 }
    comment "machines allowed to administer servers"
  }
  set admin_ports {
    type inet_service
    elements = { 22, 9100 }
  }
}
root@fw:~# nft -f sets.nft && nft insert rule ip filter forward index 2 ip saddr @admins oifname "eth3" tcp dport @admin_ports ct state new accept comment \"administration, by set\"
root@fw:~# nft list chain ip filter forward | grep "@admins"
		ip saddr @admins oifname "eth3" tcp dport @admin_ports ct state new accept comment "administration, by set"
```

A regra se lê *de um admin, para os servidores, numa porta de administração*. Acrescentar uma máquina
aos admins é uma mudança no conjunto, não em regra alguma, e vale em todo lugar onde o conjunto é
usado:

```
root@fw:~# nft add element ip filter admins { 192.168.99.11 } && nft list set ip filter admins | grep elements
		elements = { 192.168.99.10, 192.168.99.11 }
```

**Um comentário em cada accept**, nomeando a decisão que ele registra, como a base faz: `"the proxy
reaches the application"` diz por que a regra existe, coisa que a própria regra não consegue dizer.

**O arquivo é a fonte, e ele vive no controle de versão.** O conjunto de regras em execução é uma
cópia de um arquivo que alguém revisou, nunca o contrário. Uma mudança é um commit com um motivo, uma
revisão e um histórico, que é também o primeiro lugar onde alguém olha quando uma célula da matriz se
revela aberta sem dever estar. A aula 18 reúne os erros que a revisão existe para pegar.
