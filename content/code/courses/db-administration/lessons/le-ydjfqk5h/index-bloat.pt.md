---
title: Bloat de índice, lido nas páginas folha
version: 1
---

Um índice incha por um motivo próprio. **Todo `UPDATE` não HOT acrescenta uma entrada nova a cada
índice da tabela**, apontando para a versão nova, e o VACUUM depois remove a entrada antiga. Uma
página de B-tree que perde entradas mantém o seu lugar na árvore pela metade, e uma página só é
reciclada quando fica totalmente vazia. Assim, um índice que um dia guardou duas entradas por linha
mantém as páginas que cresceu para guardá-las. (HOT, heap-only tuple, é o caso em que a versão nova
cabe na mesma página e nenhuma coluna indexada mudou; aí os índices nem são tocados. Atualizar todas
as linhas de uma tabela cheia não deixa espaço para isso.)

O `pgstatindex`, da mesma extensão, lê uma B-tree e informa sobre as páginas folha, o nível de baixo,
onde as entradas moram. Aqui estão os três índices da cópia ao lado dos três de `orders`, que
guardam o mesmo tipo de linha e nunca viram um `UPDATE`:

@@1@@

**`avg_leaf_density` é o quanto as páginas folha estão cheias, em média.** Um índice cujas chaves
chegam em ordem crescente enche cada folha até 90%, o fill factor padrão de um índice, e passa para
a próxima; `orders_pkey` cresceu assim enquanto o `shop.sql` inseria os ids de 1 a um milhão, e está
exatamente em 90. A chave primária da cópia está em 45%: o dobro de páginas para menos linhas, 43 MB
contra 21 MB. Os outros dois índices da cópia estão mais magros ainda.

Os outros dois índices de `orders` mostram por que uma meta fixa é a régua errada. As chaves deles
chegaram fora de ordem durante a carga, e uma inserção no meio de uma folha cheia a divide em duas
páginas meio cheias que depois voltam a encher, então eles se acomodam abaixo de 90 sem nenhuma
entrada morta: 87.53 e 78.11. **Compare um índice com o mesmo índice sem bloat**, como esta consulta
faz com os originais, e não com um número tirado de um livro.

`leaf_fragmentation` é a fração das páginas folha cuja próxima página na ordem da chave não é a
próxima página no arquivo. São essas divisões no meio das folhas que põem `orders_customer_id` perto
de 50 sem bloat nenhum. Isso importa para uma varredura de intervalo que lê muitas folhas num disco
giratório, e bem menos num SSD. **A densidade é o número que pede ação**; a fragmentação é detalhe.

Corrigir só um índice é `REINDEX`, e fazê-lo sem bloquear escritas é `REINDEX CONCURRENTLY`; os
dois são o assunto da lição 17. As duas correções da próxima seção reconstroem os índices como
efeito colateral de reconstruir a tabela.
