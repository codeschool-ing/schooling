---
title: Regras depois do fim
version: 1
---

Alguns conjuntos de regras terminam com uma regra final explícita que pega tudo (catch-all), uma regra
sem condições que descarta e conta tudo o que sobrou, para que o veredito final fique escrito na cadeia
em vez de implícito na política:

```
root@fw:~# nft add rule ip filter forward counter drop comment '"drop everything else, and count it"'
```

Um hábito sensato. Então, semanas depois, o financeiro precisa que sua ferramenta de relatórios na LAN da
equipe leia o banco de dados, e a regra nova é acrescentada ao fim do jeito de sempre:

```
root@fw:~# nft add rule ip filter forward iifname eth2 oifname eth3 ip daddr 192.168.20.30 tcp dport 5432 counter accept comment '"finance reporting reads the database"'
```

Da LAN da equipe, o banco de dados:

```
ana@laptop:~$ probe db:5432
db:5432                blocked
```

Bloqueado, e a listagem mostra a regra nova **abaixo da regra que pega tudo**, que já descartou a
tentativa:

```
root@fw:~# nft list chain ip filter forward | tail -4 | head -2 | sed "s/^\t*//"
counter packets 1 bytes 60 drop comment "drop everything else, and count it"
iifname "eth2" oifname "eth3" ip daddr 192.168.20.30 tcp dport 5432 counter packets 0 bytes 0 accept comment "finance reporting reads the database"
```

A regra que pega tudo contou **1 pacote**; a regra do financeiro contou **0**, e nada nunca vai chegar a
ela. Toda regra depois de um veredito incondicional é inalcançável. É a mesma regra da primeira
correspondência que a quarentena sombreada, na sua forma mais escancarada, e é comum porque acrescentar
ao fim é o padrão em toda ferramenta: `nft add`, `iptables -A`, o botão *nova regra* de uma interface web.

**Duas defesas, as duas baratas.** Mantenha o conjunto de regras em um arquivo, onde a regra que pega
tudo é visivelmente a última linha e uma regra nova é escrita acima dela, em vez de editar a cadeia em
execução. E deixe o veredito final para a política, com uma regra que só conta e não tem veredito
próprio, como fez a aula 1; uma regra que só conta não consegue esconder nada abaixo dela.
