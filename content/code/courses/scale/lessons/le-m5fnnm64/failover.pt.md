---
title: Quando o primário se perde
version: 1
---

O segundo motivo para rodar uma réplica é que ela pode assumir. Aqui o primário é parado, como se
a máquina dele tivesse morrido, e a bilheteria é chamada a vender e a ler:

```
ana@lab:~/tickets$ docker compose stop db
 Container tickets-db-1 Stopping 
 Container tickets-db-1 Stopped 
ana@lab:~/tickets$ curl -s -o /dev/null -w "%{http_code}\n" -X POST localhost:8080/events/1/tickets
502
ana@lab:~/tickets$ curl -s localhost:8080/events/1; echo
{"name": "Show 1", "left": 1000000, "host": "ea1537135dcf"}
ana@lab:~/tickets$ docker compose exec replica psql -U tickets -c 'SELECT pg_promote()'
 pg_promote 
------------
 t
(1 row)

ana@lab:~/tickets$ docker compose exec replica psql -U tickets -c "UPDATE events SET sold = sold + 1 WHERE id = 1 RETURNING sold"
 sold 
------
    1
(1 row)

UPDATE 1
```

**A venda falha**, com o 502 do nginx, porque a conexão da bilheteria com o primário se foi. **A
leitura funciona**: vai para a réplica, que ainda tem toda linha que tinha aplicado. Uma bilheteria
que lê de réplicas continua mostrando os shows enquanto não consegue vendê-los, o que é uma falha
muito melhor que uma página em branco, e a aula 11 transforma isso num desenho deliberado.

Depois a réplica é **promovida**: `pg_promote()` manda ela parar de seguir e virar um primário. Ela
responde `t`, e daí em diante aceita escritas, como o `UPDATE` mostra.

## O que uma promoção não faz

Isso levou dois comandos, e em produção é a operação mais perigosa deste curso. Três motivos:

- **O programa ainda aponta para o primário antigo.** `DATABASE_URL` diz `db`, e o `db` está morto.
  Alguma coisa precisa redirecionar as escritas: uma mudança de configuração, um nome no DNS
  movido para o novo servidor, ou um proxy na frente dos bancos que sabe qual é o primário.
  Ferramentas como o Patroni existem para fazer a sequência inteira, detectar, promover e
  redirecionar, com um consenso entre várias máquinas sobre quem decide.
- **A réplica estava atrasada.** Com replicação assíncrona, as transações que o primário tinha
  confirmado e ainda não enviado estão numa máquina morta. Um comprador que ouviu "seu ingresso
  está vendido" pode ter comprado um ingresso que não existe mais. Quanto se pode perder é o atraso
  no momento da falha; a aula 3 trata de deixar isso em zero, e de quanto custa.
- **O primário antigo pode voltar.** Se voltar e ainda achar que é o primário, dois servidores
  aceitam escritas nas mesmas linhas, e as histórias deles discordam daquele momento em diante.
  Isso é o **cérebro dividido** (*split brain*), e a defesa é garantir, antes de promover, que o
  primário antigo não consiga mais aceitar escritas; isso se chama **isolamento** (*fencing*).

**Uma réplica torna um failover possível; não o torna seguro.** Ensaie no laboratório, onde perder
dados não custa nada, e reponha a pilha depois com `docker compose down` e `docker compose up -d`.
