---
title: Pelo relógio, e o ensaio
version: 1
---

Nem todo erro deixa um id de transação tão fácil de achar. O mais comum é alguém dizer "foi logo
depois das quatro", e o alvo é um horário. A mesma recuperação, pelo relógio, até o segundo em que o
`DELETE` foi confirmado:

```
ana@vm:~$ sudo pg_ctlcluster 16 restore stop
ana@vm:~$ sudo rm -rf /var/lib/postgresql/16/restore
ana@vm:~$ sudo -u postgres pgbackrest --stanza=main --pg1-path=/var/lib/postgresql/16/restore --archive-mode=off --type=time "--target=2026-10-10 16:36:08-03" --target-action=pause restore
ana@vm:~$ sudo pg_ctlcluster 16 restore start
shop=# SELECT count(*), min(placed_at) FROM orders;
 count |          min           
-------+------------------------
 50005 | 2026-01-01 09:07:00-03
(1 row)
```

O `recovery_target_time` para **antes da primeira transação confirmada depois do horário dado**. O
alvo era 16:36:08, o `DELETE` foi confirmado às 16:36:08.563, então não foi reaplicado, e a cópia de
novo tem 50005 pedidos. Duas coisas tornam um alvo por horário mais difícil do que parece:

- **O relógio de quem.** O horário de que alguém se lembra vem da própria tela, do log da aplicação
  ou de um gráfico de monitoramento, e nenhum desses é necessariamente o relógio do servidor de
  banco, no fuso horário do servidor de banco. Escreva o alvo com o offset, como aqui (`-03`), e
  confira os horários de commit no log, como o `pg_waldump` os mostrou, antes de confiar numa
  lembrança.
- **Cedo demais é seguro, tarde demais não é.** Um alvo um minuto adiantado perde um minuto de
  transações boas, que o reparo pode trazer de volta do servidor de produção. Um alvo um segundo
  atrasado reaplica o erro, e a cópia não serve para nada. Na dúvida, pause, olhe e vá mais cedo.

## O ensaio

Tudo nesta lição aconteceu numa máquina tranquila, com a resposta certa conhecida de antemão. No dia
em que for necessária, uma recuperação para um ponto no tempo é feita sob pressão, por quem estiver
de plantão, muitas vezes pela primeira vez naquele sistema. Os passos são poucos e cada um tem um
jeito de dar errado:

1. Pare as escritas que dificultam o reparo, se puder.
2. Ache o alvo: a transação ou o horário, a partir do log.
3. Garanta que o arquivo tem o segmento com o alvo.
4. Restaure num servidor separado, **com o arquivamento desligado**, e **pause** no alvo.
5. Olhe: o erro está ausente, e tudo antes dele está presente?
6. Promova, e escolha: substituir, ou reparar a partir da cópia.

Essa lista é um runbook em miniatura, e a lição 24 escreve um completo. A lição 7 faz disso um
hábito: rodar a lista com hora marcada, com cronômetro, antes que alguém precise dela.
