---
title: Por quanto tempo lembrar um id
version: 1
---

**Uma tabela de ids processados cresce uma linha por evento, para sempre, a não ser que algo apague
dela, e apagar dela reabre a porta para as duplicatas que ela existia para barrar.** Então toda
deduplicação tem uma janela, escolhida ou não: o tempo pelo qual um id é lembrado. Uma duplicata que
chega dentro da janela é pega; uma que chega depois dela é aplicada de novo.

Depois da queda na segunda seção, a tabela tinha uma linha para cada venda já aplicada:

```
ubuntu@stream:~/work$ python -m sqlite3 stock.db "SELECT count(*) FROM processed"
(40,)
```

Quarenta linhas, uma por venda, depois de uma queda e de um reinício que pulou a única que já tinha
aplicado.

Quarenta linhas não são nada. Ponha números na Ponto Final: cinco lojas com, digamos, duas mil vendas
por dia cada são dez mil ids por dia, três milhões e meio por ano. Um id de venda tem dez caracteres;
com o custo próprio do SQLite e o índice que faz a chave primária funcionar, conte cinquenta bytes por
linha, então menos de 200 MB por ano. Isso cabe em qualquer disco e daria para guardar. Um sistema com
mil vezes esse tráfego guardaria 200 GB de ids e, pior, consultaria um a cada evento.

## De onde as duplicatas vêm de fato

A janela deveria ser tão longa quanto o maior atraso com que uma duplicata ainda pode chegar, e esse
atraso depende do que produz a duplicata:

| origem de uma duplicata | quão tarde ela pode chegar |
|---|---|
| uma nova tentativa do produtor depois de uma confirmação perdida | segundos, dentro de `message.timeout.ms` |
| uma queda do consumidor entre o efeito e o commit | o tempo que o consumidor ficar fora |
| um rebalanceamento que move uma partição no meio de um lote | segundos |
| uma releitura do tópico depois de corrigir um bug | até onde a releitura voltar, até a retenção |
| uma restauração do banco a partir de um backup | a idade do backup |

As três primeiras precisam de uma janela de horas, no máximo. As duas últimas precisam que a janela
cubra todo o histórico sendo reprocessado, que é o argumento honesto para guardar os ids **pelo
tempo que o tópico guardar os eventos**: nada mais antigo pode ser relido, porque o Kafka já apagou.

## Limitando

Uma janela é um delete com uma data dentro, então a tabela precisa saber quando cada id foi aplicado:

```sql
CREATE TABLE processed (sale TEXT PRIMARY KEY, applied_at TEXT NOT NULL);
DELETE FROM processed WHERE applied_at < datetime('now', '-7 days');
```

Rodado uma vez por dia, isso guarda uma semana. Guardada na memória em vez de numa tabela, a mesma
ideia é um conjunto com expiração, que é o que os processadores de stream fazem para a própria
deduplicação, e uma queda o esvazia a não ser que ele esteja num checkpoint, que a lição 13 mostra
como o Flink faz.

**A janela é um risco que você escolhe com números, não um detalhe.** Uma equipe que define sete dias
deveria saber dizer por que nenhuma duplicata pode chegar depois de sete dias, e o que acontece se um
backup mais antigo que isso for restaurado. Quando essa resposta é fraca, o desenho mais forte é o da
primeira seção, gravações que se repetem sem estrago e não precisam de memória nenhuma, ou o da seção
anterior, offsets no banco, que lembram um número por partição em vez de um por evento.
