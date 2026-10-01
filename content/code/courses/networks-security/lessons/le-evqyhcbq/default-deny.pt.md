---
title: Negar por padrão, porque ninguém conhece a lista inteira
version: 1
---

Há dois jeitos de escrever a política de um firewall. Uma **lista de bloqueio** (*blocklist*) permite
tudo e nomeia o que recusar. Uma **lista de permissão** (*allowlist*) recusa tudo e nomeia o que
permitir. As duas podem descrever a mesma rede no dia em que são escritas, e divergem a partir do dia
seguinte.

Uma lista de bloqueio, escrita por alguém que sabe quais portas são perigosas:

```
root@fw:~# cat blocklist.nft
flush ruleset
table ip filter {
  chain forward {
    type filter hook forward priority filter; policy accept;
    iifname "eth0" tcp dport { 23, 445, 3389 } drop comment "ports we know are dangerous"
    iifname "eth0" tcp dport 5432 drop comment "the database"
  }
}
root@fw:~# nft -f blocklist.nft
ana@remote:~$ probe db:5432 app:22 app:8080
db:5432                blocked
app:22                 open
app:8080               open
```

O banco de dados está `blocked`. O SSH no servidor de aplicação e a própria aplicação estão `open`
para a internet inteira, porque ninguém pensou em listá-los. Então um desenvolvedor instala um cache
no `db`, escutando na 6379, e não avisa ninguém:

```
ana@remote:~$ probe db:6379
db:6379                open
```

**O serviço novo ficou exposto no instante em que subiu**, sem nenhuma mudança no firewall. Uma lista
de bloqueio precisa conhecer todo serviço que um dia vai existir, e a lista é sempre escrita antes que
o próximo chegue.

A mesma rede sob a base da aula 4, cuja política é `drop`:

```
root@fw:~# nft -f baseline.nft
ana@remote:~$ probe db:5432 app:22 app:8080 db:6379 www:443
db:5432                blocked
app:22                 blocked
app:8080               blocked
db:6379                blocked
www:443                open
```

Tudo o que a matriz não nomeia está `blocked`, **inclusive o serviço de que ninguém falou ao
firewall**. A loja continua respondendo, porque está nomeada. O custo de uma lista de permissão é o
erro oposto: algo legítimo que ninguém listou é recusado, e alguém reclama. Essa falha é barulhenta e
é corrigida no mesmo dia. A falha da lista de bloqueio é silenciosa e é encontrada por quem estiver
varrendo a internet naquela semana.

**Negar por padrão** (*deny by default*) é essa escolha feita uma vez, para toda chain: a política é
`drop`, e cada `accept` é uma decisão para a qual alguém pode apontar. É também por isso que a aula 4
escreveu uma matriz cujas células vazias significam *negado*, em vez de uma lista de coisas a barrar.
