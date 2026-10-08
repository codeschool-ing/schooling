---
title: Cortando a saída, no laboratório
version: 1
---

O servidor de arquivos tem um único destino legítimo fora da empresa: o provedor de backup. Todo o resto que
ele manda para a internet é, por enquanto, suspeito. Então o primeiro movimento é uma regra de firewall no
`fw` que deixa o `files` alcançar o backup e nada mais do lado da internet, e não mexe no lado de dentro da
empresa.

O laboratório precisa de duas coisas para isso ficar visível. O provedor de backup ganha um endereço no
`outside`, `203.0.113.150`, e o `outside` roda um servidor web pequeno, o do próprio Python, para haver algo a
alcançar:

```
root@soc:~# ip -n outside addr add 203.0.113.150/24 dev eth0
root@soc:~# ip netns exec outside python3 -m http.server 8080 >/dev/null 2>&1 &
```

O `&` deixa o servidor rodando em segundo plano. Antes da regra, o `files` alcança os dois endereços, e o
`curl` imprime o status HTTP que recebeu, `200` nos dois:

```
root@soc:~# ip netns exec files curl -s -o /dev/null -w "%{http_code}\n" http://203.0.113.200:8080/
200
root@soc:~# ip netns exec files curl -s -o /dev/null -w "%{http_code}\n" http://203.0.113.150:8080/
200
```

Agora a regra. O `nft add rule` a coloca no fim da cadeia `forward` do `fw`, aquela por onde passa todo pacote
que atravessa o firewall. Leia da esquerda para a direita: pacotes **de** `192.168.20.10`, **saindo** por
`eth0`, o lado da internet, **para qualquer destino menos** `203.0.113.150`, são contados e descartados. O
comentário leva o identificador do incidente, para quem achar a regra daqui a um ano saber por que ela está
lá:

```
root@soc:~# ip netns exec fw nft add rule ip fw forward ip saddr 192.168.20.10 oifname eth0 ip daddr != 203.0.113.150 counter drop comment '"INC-2026-014 files egress"'
root@soc:~# ip netns exec fw nft -a list chain ip fw forward
table ip fw {
	chain forward { # handle 1
		type filter hook forward priority filter; policy accept;
		ct state new log prefix "fw-new " group 1 # handle 2
		ip saddr 192.168.20.10 oifname "eth0" ip daddr != 203.0.113.150 counter packets 0 bytes 0 drop comment "INC-2026-014 files egress" # handle 3
	}
}
```

O `nft -a` mostra o **handle** de cada regra, o número que a nomeia para apagar depois. A regra de log da aula
1 continua em primeiro lugar, então uma tentativa bloqueada ainda é escrita no `fw.log`: a regra para o
tráfego sem escondê-lo. Agora as mesmas verificações, e mais algumas:

```
root@soc:~# ip netns exec files curl -s -m 5 -o /dev/null -w "%{http_code}\n" http://203.0.113.200:8080/; echo "exit $?"
000
exit 28
root@soc:~# ip netns exec files curl -s -m 5 -o /dev/null -w "%{http_code}\n" http://203.0.113.150:8080/
200
root@soc:~# ip netns exec files nc -z -w 3 198.51.100.22 22; echo "exit $?"
Connection to 198.51.100.22 22 port [tcp/ssh] succeeded!
exit 0
root@soc:~# ip netns exec fw nft list chain ip fw forward | grep files
		ip saddr 192.168.20.10 oifname "eth0" ip daddr != 203.0.113.150 counter packets 5 bytes 300 drop comment "INC-2026-014 files egress"
root@soc:~# grep 'DST=203.0.113.200' /var/log/soclab/fw.log | tail -1
Oct  7 20:39:29 fw fw-new  IN=eth2 OUT=eth0 MAC=fe:8e:86:0d:bc:51:5e:1b:63:92:fa:05:08:00 SRC=192.168.20.10 DST=203.0.113.200 LEN=60 TOS=00 PREC=0x00 TTL=63 ID=824 DF PROTO=TCP SPT=55372 DPT=8080 SEQ=160397314 ACK=0 WINDOW=64240 SYN URGP=0 MARK=0x0 
```

Leia na ordem. Para `203.0.113.200`, o `curl` desistiu depois de cinco segundos (`-m 5`) com status `000` e
código de saída `28`, que é o código do curl para tempo esgotado: nada voltou. Para o backup, `200`, como
antes. Para o `gw`, dentro da empresa, o `nc -z` ainda conecta, porque esse tráfego sai por `eth1` e a regra só
olha para `eth0`. (O `nc` vem numa instalação padrão do Ubuntu; se faltar, `sudo apt install
netcat-openbsd`.) O contador diz que a regra descartou **5 pacotes, 300 bytes**: a primeira tentativa e as
retransmissões de uma conexão que nunca teve resposta. E a linha do log mostra que a tentativa foi registrada
a caminho do descarte.

**Verificar faz parte da ação, não é um extra.** Uma regra escrita na interface errada ou com um endereço
digitado errado é aceita pelo `nft` sem reclamação e não faz nada, e uma contenção que nunca foi verificada é
uma afirmação no registro do incidente que ninguém consegue sustentar. Cada verificação aqui responde a uma
pergunta diferente: o caminho ruim fechou, o caminho bom está aberto, o lado de dentro não foi afetado, e
tudo continua sendo registrado.
