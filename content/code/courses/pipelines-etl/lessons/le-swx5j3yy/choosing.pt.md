---
title: Completa ou incremental, tabela por tabela
version: 1
---

**A escolha é feita por tabela, não por pipeline.** A extração noturna da Ponto Final acaba com os
dois tipos lado a lado, porque as tabelas dela não são parecidas:

| tabela | tamanho e crescimento | exclusões? | extração |
|---|---|---|---|
| `shops` | 7 linhas, fixa | não | completa |
| `books` | 1.200 linhas, lenta | não | completa |
| `customers` | 5.000 linhas, +20 por dia | sim, pedidos de apagamento | completa |
| `orders` | 17.000 linhas, +300 por dia | não | incremental, com retrocesso |
| `order_lines` | 26.000 linhas, +450 por dia | não | incremental, pelo `updated_at` do pedido |
| `payments` | 17.000 linhas, +300 por dia | não | incremental |

`order_lines` não tem `updated_at` próprio. Uma linha nunca é alterada depois de escrita, então a
extração pega as linhas de cada pedido que mudou, e um estorno relê as linhas desse pedido também —
umas poucas linhas a mais, que a view da versão mais recente junta.

Três perguntas decidem cada linha de uma tabela como essa:

1. **Ela é pequena, e vai continuar pequena?** Então recarregue inteira e pare de pensar nela.
2. **A origem sabe dizer o que mudou?** Um `updated_at` confiável, com índice, preenchido por toda
   escrita. Se não, uma carga completa ou o log do banco.
3. **A origem apaga linhas, e isso importa?** Se apaga, uma carga incremental precisa de algo ao lado
   — uma carga completa das chaves, ou o log.

**E escreva a resposta ao lado da tabela**, com o motivo. A próxima pessoa a olhar para um job
noturno que recarrega `customers` inteira vai querer torná-lo incremental, e o motivo de não ser —
os pedidos de apagamento — não aparece no código.
