---
title: Um conjunto de regras que nega por padrão para o portal
version: 1
---

**O portal precisa de duas coisas da rede: HTTP de qualquer um e SSH dos administradores.** Os
administradores trabalham a partir do `admin`, em `.30`, e, depois da aula 15, pelo `jump`, em `.40`.
Todo o resto pode ser descartado. No `web`, escreva primeiro o conjunto de regras num arquivo no seu
home, para conferi-lo antes de ele tocar na máquina em execução:

```
ana@web:~$ cat nftables.conf
#!/usr/sbin/nft -f
# /etc/nftables.conf on web: the portal accepts what its job needs, and nothing else.
flush ruleset

table inet host {
	chain input {
		type filter hook input priority filter; policy drop;
		iif "lo" accept
		ct state established,related accept
		ct state invalid drop
		icmp type echo-request accept
		tcp dport 80 accept
		ip saddr { 192.168.60.30, 192.168.60.40 } tcp dport 22 accept
		counter
	}
}
```

Leia de cima para baixo, porque o nftables lê assim. Uma **tabela** da família `inet` trata IPv4 e
IPv6 juntos. A **chain** se engancha no caminho `input`, que vê os pacotes endereçados a esta máquina,
e a **policy** dela é `drop`: um pacote que nenhuma regra aceita é descartado. Depois as regras, em
ordem:

| regra | por quê |
|---|---|
| `iif "lo" accept` | a máquina falando consigo mesma, como o nginx com o portal em 127.0.0.1 |
| `ct state established,related accept` | respostas a conexões já permitidas, para cada permissão ser escrita uma vez |
| `ct state invalid drop` | pacotes que não pertencem a nenhuma conversa que o kernel conheça |
| `icmp type echo-request accept` | o ping, que o monitoramento e as pessoas usam para perguntar se a máquina está de pé |
| `tcp dport 80 accept` | o portal, para qualquer um |
| `ip saddr { … } tcp dport 22 accept` | SSH, só das duas máquinas administrativas |
| `counter` | conta o que chega ao fim, antes de a policy descartar |

O `flush ruleset` no topo esvazia todas as tabelas antes, então carregar o arquivo duas vezes dá o
mesmo resultado que carregá-lo uma vez.

## Conferir, depois carregar

`nft -c` interpreta o arquivo e monta as regras sem instalá-las. Só quando ele não diz nada de errado
o arquivo entra:

```
ana@web:~$ sudo nft -c -f nftables.conf && echo "syntax ok"
syntax ok
ana@web:~$ sudo nft -f nftables.conf && echo loaded
loaded
```

**Carregue um firewall numa máquina remota com uma segunda sessão já aberta**, e melhor ainda, a
partir de um console: um conjunto de regras que descarta o SSH de onde você está trabalhando tranca
você do lado de fora exatamente como a mudança de SSH da aula 1 poderia. No laboratório o console é
`sudo bash hostlab.sh root web`, que alcança a máquina sem passar pela rede.
