---
title: Bloquear a origem, e quanto isso vale
version: 1
---

Os logins da quinta vieram de `203.0.113.66`. Bloquear esse endereço no firewall é o movimento que todo mundo
faz primeiro, e vale ver exatamente o que ele compra. O `nc -z` só abre uma conexão e a fecha de novo; o `-s`
escolhe de qual dos endereços do `outside` ela sai:

```
root@soc:~# ip netns exec outside nc -z -w 3 -s 203.0.113.66 198.51.100.22 22; echo "exit $?"
Connection to 198.51.100.22 22 port [tcp/ssh] succeeded!
exit 0
root@soc:~# ip netns exec fw nft insert rule ip fw forward ip saddr 203.0.113.66 counter drop comment '"INC-2026-014 source"'
root@soc:~# ip netns exec outside nc -z -w 3 -s 203.0.113.66 198.51.100.22 22; echo "exit $?"
exit 1
root@soc:~# ip netns exec outside nc -z -w 3 -s 203.0.113.200 198.51.100.22 22; echo "exit $?"
Connection to 198.51.100.22 22 port [tcp/ssh] succeeded!
exit 0
```

Antes da regra, `203.0.113.66` alcança a porta SSH do `gw`. O `nft insert rule` coloca a regra nova no
**topo** da cadeia, não no fim, então ela é conferida antes de qualquer outra. Depois dela, a mesma conexão
falha (o `nc` sai com `1`). E então a última linha: **a mesma máquina, saindo de outro endereço, passa
direto.**

Essa é a pirâmide da dor da aula 9, vista do lado de quem defende. Um endereço IP fica perto da base: trocá-lo
não custa quase nada ao outro lado. Um bloqueio num endereço para a próxima tentativa mais preguiçosa e nada
além. **Ainda vale fazer**, porque custa quase nada e é rápido, mas não é o que contém o incidente da quinta. O
que o invasor tinha era **a senha do bruno, e depois uma chave no `gw`**. As duas funcionam de qualquer
endereço do mundo, e o firewall não sabe nada sobre elas.

Então o movimento que contém de verdade uma conta comprometida é a conta: bloquear, trocar a senha, e revogar
todas as chaves e sessões dela, em todos os hosts do escopo. A aula 14 é onde a chave que foi adicionada no
`gw` é achada e removida, com a evidência dela guardada; aqui a conta é bloqueada para que a chave, a senha e
qualquer sessão não possam ser usadas enquanto isso.

Toda regra adicionada numa resposta é temporária, e precisa sair de novo de propósito. O handle é como:

```
root@soc:~# ip netns exec fw nft -a list chain ip fw forward
table ip fw {
	chain forward { # handle 1
		type filter hook forward priority filter; policy accept;
		ip saddr 203.0.113.66 counter packets 9 bytes 420 drop comment "INC-2026-014 source" # handle 4
		ct state new log prefix "fw-new " group 1 # handle 2
		ip saddr 192.168.20.10 oifname "eth0" ip daddr != 203.0.113.150 counter packets 5 bytes 300 drop comment "INC-2026-014 files egress" # handle 3
	}
}
root@soc:~# ip netns exec fw nft delete rule ip fw forward handle 4
root@soc:~# ip netns exec outside nc -z -w 3 -s 203.0.113.66 198.51.100.22 22; echo "exit $?"
Connection to 198.51.100.22 22 port [tcp/ssh] succeeded!
exit 0
```

O insert colocou a regra nova no handle **4**, no topo da cadeia; o `nft delete rule ... handle 4` a remove, e a
conexão volta a funcionar. Apagar pelo handle remove exatamente aquela regra e nenhuma outra. **Toda regra
adicionada durante um incidente vai para o registro de decisões com o handle e o comentário**, para que
removê-la seja uma consulta e não um trabalho de arqueologia. Uma regra de emergência esquecida é como um
firewall acaba com trezentas linhas que ninguém tem coragem de mexer.
