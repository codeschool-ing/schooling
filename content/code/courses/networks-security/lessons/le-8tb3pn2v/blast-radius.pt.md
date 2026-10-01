---
title: O raio de impacto de um servidor comprometido
version: 1
---

A segmentação não serve para impedir o primeiro comprometimento. Algo exposto à internet vai ser
comprometido cedo ou tarde. Ela serve para limitar **o que o atacante alcança a partir dali**, o
raio de impacto (*blast radius*).

Suponha que `www` seja tomado por uma falha em algum software instalado nele. Quem o controla agora
inicia conexões **a partir de `www`**, então a pergunta é o que `www` pode alcançar:

```
ana@www:~$ probe app:8080 db:5432 app:22 laptop:22 admin:22 remote:80 remote:443
app:8080               open
db:5432                blocked
app:22                 blocked
laptop:22              blocked
admin:22               blocked
remote:80              blocked
remote:443             blocked
```

**Uma porta, a que o proxy precisa, e nada mais.** Nem o banco de dados, nem o SSH do servidor de
aplicação, nem a equipe, nem a máquina de gestão, nem a internet: `remote:80` e `remote:443` estão
bloqueados porque a matriz não dá à DMZ nenhuma linha rumo à internet. Software que toma um
servidor costuma chamar de volta para fora, para receber instruções ou enviar o que encontrou. Uma DMZ que não pode iniciar conexões de saída torna isso muito mais
difícil, e torna qualquer tentativa visível nos contadores do firewall.

```
root@fw:~# nft list ruleset | grep -c "iifname \"eth1\""
1
```

De todas as regras no `fw`, uma começa na DMZ. Essa contagem é o raio de impacto escrito como número,
e vale a pena acompanhá-la: toda regra adicionada com `iifname "eth1"` o aumenta.

**O que a DMZ não consegue proteger é o único caminho que ela permite.** `www` alcança `app` em 8080,
então uma falha na aplicação é alcançável a partir de um proxy comprometido. O firewall fez a parte
dele ao tornar isso a única coisa alcançável; as defesas da própria aplicação, e o WAF da aula 3, têm
de fazer o resto.

Um servidor que precisa mesmo chamar para fora, para buscar suas atualizações, por exemplo, ganha uma
regra para um destino, de preferência um proxy de atualizações dentro da empresa, e não para a
internet inteira.
