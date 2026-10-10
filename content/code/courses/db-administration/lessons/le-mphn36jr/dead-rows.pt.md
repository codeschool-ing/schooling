---
title: Um UPDATE deixa a linha antiga para trás
version: 1
---

A imagem que a maioria das pessoas tem é a de um `UPDATE` que encontra a linha e a altera onde ela
está. **O PostgreSQL nunca faz isso.** Ele escreve uma versão nova e completa da linha em outro
lugar e deixa a antiga onde estava, marcada com a transação que a substituiu. A lição 8 de
sql-databases mostrou o motivo do lado de quem lê: uma transação em `REPEATABLE READ` continua
vendo os dados como estavam quando ela começou, e a única forma de mostrar a alguém o valor antigo é
ainda tê-lo. Esta seção olha a mesma coisa do lado do armazenamento.

Tudo nesta lição acontece numa cópia de `orders`, para que `shop` fique como a lição 4 deixou e as
lições seguintes comecem das mesmas tabelas que você tem. A cópia ganha uma chave primária e um
`VACUUM ANALYZE` para começar arrumada. `pageinspect` é uma extensão que vem com o PostgreSQL e lê
as páginas de uma tabela em estado bruto; a última seção a remove de novo.

@@1@@

Três colunas escondidas contam a história, e toda tabela as tem. **`ctid` é onde uma versão mora**:
página 0, item 7, no começo. **`xmin` é a transação que escreveu a versão**, aqui a que carregou a
cópia, e **`xmax` é a transação que a apagou ou substituiu**, 0 enquanto ninguém fez isso.

Depois do `UPDATE`, a linha 7 responde de `(8333,41)`, a última página da tabela, escrita pela
transação 786. A página 0 estava cheia, então a versão nova foi para onde havia espaço. O
`heap_page_items` mostra o que ainda está na página 0: o item 7 é a versão antiga, intacta, com
`t_xmax` igual a 786 e `t_ctid` apontando para a nova. Qualquer transação que começou antes de a
786 fazer commit ainda lê `paid` nela.

Quando a 786 faz commit e nenhuma transação em andamento é antiga o bastante para precisar da versão
antiga, **ela está morta**: ocupa o mesmo espaço de uma linha viva e nada nunca mais vai lê-la. Um
`DELETE` deixa uma versão morta do mesmo jeito, sem uma nova ao lado. Um `ROLLBACK` também deixa
uma, ao contrário: a versão nova que ele escreveu é a que ninguém vai ver.

@@2@@

**`n_dead_tup` é a contagem que o servidor faz das versões mortas**, guardada por tabela em
`pg_stat_user_tables`: uma do `UPDATE` da linha 7, que fez commit, e uma do `UPDATE` que sofreu
rollback. Uma sessão envia suas contagens quando fica ociosa por um momento, então uma consulta
digitada logo depois de uma alteração pode mostrar o número de antes dela.

Duas versões mortas num milhão de linhas não custam nada. Uma aplicação que atualiza o status de
cada pedido três vezes no caminho até `shipped` deixa três versões mortas por pedido, e **uma tabela
cujas linhas mudam muito guarda tanto espaço morto quanto dados vivos**, a menos que alguma coisa
venha recuperá-lo. Essa coisa é o `VACUUM`.
