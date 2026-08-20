---
title: Propagação: por que a mudança demora
---

Alterou o DNS e o site velho continua aparecendo? Isso é o cache fazendo o trabalho dele. Cada registro tem um **TTL** — o tempo que os servidores do mundo podem guardar a resposta antes de perguntar de novo.

Nada "se espalha": o registro novo já está no ar desde o primeiro segundo. O que demora é os caches antigos expirarem, e o teto disso é o TTL que estava valendo **antes** da mudança.

Daí a manobra padrão de quem vai migrar: baixar o TTL para uns cinco minutos **um dia antes**, fazer a troca, conferir e só então voltar o TTL para horas. Baixar o TTL depois de mudar não adianta nada — os caches já pegaram o valor antigo.
