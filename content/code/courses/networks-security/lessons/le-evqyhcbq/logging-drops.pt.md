---
title: Registrar o que a política descarta
version: 1
---

Uma política `drop` é silenciosa por projeto: quem enviou não recebe nada, e o administrador também
não. Uma regra colocada **por último na chain**, logo antes da política, pode registrar o que está
prestes a ser descartado. No `fw`, com a base carregada:

```sh
nft add rule ip filter forward limit rate 5/second log group 1 prefix \"fw-drop \" comment \"what the policy is about to drop\"
```

```
root@fw:~# nft list chain ip filter forward | tail -3
		limit rate 5/second burst 5 packets log prefix "fw-drop " group 1 comment "what the policy is about to drop"
	}
}
```

O `log group 1` entrega cada pacote ao grupo de log 1 do netfilter, onde qualquer programa pode lê-lo,
e o prefixo rotula as linhas. O `limit rate 5/second` importa tanto quanto o próprio log: sem ele,
qualquer um pode encher o disco enviando pacotes que o firewall descarta, e o log vira o ataque.

O `tcpdump` consegue ler esse grupo diretamente. Com ele escutando no `fw`, iniciado em segundo
plano com `setsid timeout 10 tcpdump -n -l -i nflog:1 -c 3 > /root/drops.txt 2>/dev/null </dev/null &`,
o `remote` tenta duas células que estão fechadas, e o `laptop` uma:

```
ana@remote:~$ probe db:5432 app:22
db:5432                blocked
app:22                 blocked
ana@laptop:~$ probe db:6379
db:6379                blocked
root@fw:~# cat drops.txt
15:35:01.265985 IP 203.0.113.50.46266 > 192.168.20.30.5432: Flags [S], seq 2762589466, win 64240, options [mss 1460,sackOK,TS val 1098298975 ecr 0,nop,wscale 10], length 0
15:35:01.266119 IP 203.0.113.50.37090 > 192.168.20.10.22: Flags [S], seq 656771972, win 64240, options [mss 1460,sackOK,TS val 1254501168 ecr 0,nop,wscale 10], length 0
15:35:03.286338 IP 192.168.10.20.58758 > 192.168.20.30.6379: Flags [S], seq 4277655433, win 64240, options [mss 1460,sackOK,TS val 4274771377 ecr 0,nop,wscale 10], length 0
```

Três tentativas de conexão descartadas, cada uma um `SYN` TCP com sua origem, destino e porta. **É
para isto que serve o log de descartes.** `203.0.113.50` tentando o banco de dados e o SSH é a
internet fazendo o que faz o dia inteiro. `192.168.10.20` tentando a porta 6379 é uma máquina da
LAN da equipe buscando um serviço que nunca recebeu. O segundo tipo é bem mais raro e bem mais
interessante, e muitas vezes é no log de descartes que alguém nota pela primeira vez um programa mal
configurado, ou um laptop comprometido.

Dois cuidados. O log de descartes de um firewall movimentado é quase todo ruído de fundo da internet,
então é lido filtrando, não a olho; a aula 23 decide o que vale a pena guardar. E uma regra de log em
qualquer lugar que não o último registra tráfego que regras posteriores teriam permitido, o que é
ruído de outro tipo.
