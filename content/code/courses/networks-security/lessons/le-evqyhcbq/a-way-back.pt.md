---
title: Um caminho de volta, antes de se trancar do lado de fora
version: 1
---

O acidente clássico com firewall não é uma brecha. É o administrador, conectado por SSH, carregando
um conjunto de regras que descarta a própria sessão, e depois dirigindo até o prédio. Equipamentos de
rede feitos para isso têm um *commit confirmed*: a mudança se desfaz sozinha a menos que seja
confirmada dentro de alguns minutos. O `nft` não tem esse comando, e a mesma rede de proteção cabe
em uma linha.

Primeiro, salve o que funciona:

```
root@fw:~# nft list ruleset > known-good.nft; wc -l known-good.nft
21 known-good.nft
```

Depois agende o caminho de volta **antes** de fazer a mudança, e faça a mudança. O arquivo novo é uma
chain de entrada mais rígida que, por engano, não permite mais SSH a partir do segmento de gestão:

```conf
flush ruleset
table ip filter {
  chain input {
    type filter hook input priority filter; policy drop;
    ct state established,related accept
    iifname "lo" accept
  }
}
```

Salve-o no `fw` como `tighter.nft`, e então a única linha:

```
root@fw:~# (sleep 5; nft -f known-good.nft; echo "rolled back at $(date +%T)" > rollback.log) > /dev/null 2>&1 & nft -f tighter.nft; date +%T; nft list ruleset | grep -c accept
15:34:47
2
ana@admin:~$ probe fw:22
fw:22                  blocked
```

O `admin` ficou trancado do lado de fora, como a sessão SSH teria ficado. Cinco segundos depois, o job
em segundo plano restaura o conjunto de regras salvo, haja alguém conectado ou não. Se a mudança
tivesse funcionado, o administrador teria matado esse job, e isso é o *confirm*. No uso real o timer
é de alguns minutos, o bastante para testar de onde você está.

## O rollback que dobrou as regras

O rollback rodou, e a contagem de linhas `accept` voltou como **13**, não as 11 que foram salvas. A
chain de entrada mostra por quê:

```
root@fw:~# cat rollback.log; nft list ruleset | grep -c accept
rolled back at 15:34:52
13
root@fw:~# nft list chain ip filter input
table ip filter {
	chain input {
		type filter hook input priority filter; policy drop;
		ct state established,related accept
		iifname "lo" accept
		ct state established,related accept
		iifname "lo" accept
		iifname "eth4" ip saddr 192.168.99.0/24 tcp dport 22 ct state new accept comment "fw is administered from mgmt only"
	}
}
```

Cada regra do arquivo mais rígido aparece duas vezes. **O `nft list ruleset` imprime as regras, e não
uma instrução para limpar o que havia antes**, então carregar a saída dele soma ao que estiver
carregado agora: aqui, por cima das duas regras da chain mais rígida. Um conjunto de regras salvo
precisa começar com `flush ruleset` para substituir em vez de mesclar:

```
root@fw:~# nft -f baseline.nft; { echo "flush ruleset"; nft list ruleset; } > known-good.nft; head -3 known-good.nft
flush ruleset
table ip filter {
	chain forward {
root@fw:~# nft -f known-good.nft; nft list ruleset | grep -c accept
11
```

Com `flush ruleset` na primeira linha, o arquivo salvo devolve exatamente o que foi salvo: 11. Um plano
de rollback contém detalhes assim, e ninguém os testa até a noite em que são necessários. Teste o seu
numa tarde em que nada depende dele.
