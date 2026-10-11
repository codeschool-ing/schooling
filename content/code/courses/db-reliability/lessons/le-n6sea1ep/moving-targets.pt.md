---
title: O ensaio que falha por motivos próprios
version: 1
---

O script compara o banco em produção, lido logo depois do ponto de restauração, com uma cópia
restaurada até o ponto de restauração. Num banco tranquilo, os dois são o mesmo momento. Rode-o
enquanto alguma coisa escreve:

```
ana@vm:~$ (for i in $(seq 1 600); do psql -q bigshop -c "INSERT INTO orders (customer_id, total_cents, placed_at) VALUES (1, 900, now())"; done) &
ana@vm:~$ ./restore-drill.sh
2c2
< orders|3000005|77a66ec5301cb1082a6322c490cf710f
---
> orders|3000001|bcb0f27f7cde0fa846ef5b667234b468
2026-10-10 16:50:34,20261010-164946F,3.2,2.5,6.7,17.9,DIFFERENT
ana@vm:~$ echo $?
1
ana@vm:~$ wait
```

**`DIFFERENT`, e status de saída 1.** O `diff` mostra por quê: o relatório em produção contou 3000005
pedidos no `bigshop`, a cópia restaurada 3000001. Quatro pedidos foram inseridos no instante entre
o ponto de restauração e o relatório em produção ler a tabela. O backup está perfeito, e o ensaio
falhou.

Isso é pior do que parece. Um ensaio que falha de vez em quando por motivos que não têm nada a ver
com o backup ensina todo mundo que o lê a ignorar as falhas dele, e um dia a falha ignorada é real.
**Um ensaio tem que ser construído para que um resultado vermelho sempre queira dizer alguma
coisa.**

## Fazendo dos dois lados um só momento

A falha vem de ler o lado em produção num instante diferente do que foi restaurado. Há três jeitos
de fechar essa diferença, do grosseiro ao exato:

- **Rodar o ensaio quando nada escreve.** Uma janela de manutenção, ou um banco que fica parado à
  noite. Simples, e depende de o banco colaborar.
- **Comparar só o que não pode mudar.** Contagens e impressões digitais de tabelas que nunca são
  escritas depois do fechamento do dia, ou linhas mais antigas que o ponto de restauração. Mais
  fraco, e continua funcionando num sistema movimentado.
- **Ler o lado em produção dentro de um único snapshot, e restaurar exatamente até o horário desse
  snapshot.** Abra uma transação `REPEATABLE READ`, pergunte o `now()` (que no PostgreSQL é o
  momento em que a transação começou), rode o relatório inteiro dentro dela, e restaure com
  `--type=time` até esse momento. Cada comando do relatório vê o banco como estava num único
  instante, e a restauração para nesse mesmo instante. É isso que faz o ensaio que a plataforma
  roda.

O terceiro tem uma borda que vale conhecer, e o ensaio da plataforma a cita na própria saída em vez
de escondê-la: uma linha confirmada no mesmo instante do snapshot pode cair num lado só, então uma
diferença de uma ou duas linhas numa tabela movimentada, uma vez, não é defeito. **Um defeito de
verdade se repete.**

O ensaio do laboratório fica com o primeiro jeito, porque nada escreve no seu shop a não ser que
você faça escrever, e porque a versão acima tem algumas linhas a mais do que esta lição precisa.
Seja qual for o seu, anote qual é, no script, onde a próxima pessoa vai ler.
