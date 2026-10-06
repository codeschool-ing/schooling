---
title: Escrevendo as descrições
version: 1
---

As descrições do modelo inteiro são um arquivo SQL, executado depois que as tabelas são construídas. Ele começa assim:

```
-- What every table and column of the model means, kept in the database
-- beside the data, where the dictionary is generated from.

COMMENT ON TABLE fact_sales IS 'One row per line of an order that was not cancelled, in a shop or online.';
COMMENT ON COLUMN fact_sales.date_key IS 'Day the order was placed, São Paulo time. Key of dim_date.';
COMMENT ON COLUMN fact_sales.shop_key IS 'Shop the order was placed in; the website is the shop Online. Key of dim_shop.';
COMMENT ON COLUMN fact_sales.book_key IS 'Book sold on this line. Key of dim_book.';
COMMENT ON COLUMN fact_sales.customer_key IS 'Customer as they were when ordering; 0 for a sale nobody identified. Key of dim_customer.';
COMMENT ON COLUMN fact_sales.promotion_key IS 'Promotion applied to the line; 0 when there was none. Key of dim_promotion.';
```

```
ana@lab:~/wh$ grep -c "^COMMENT ON" comments.sql
104
ana@lab:~/wh$ duckdb wh.duckdb < comments.sql
ana@lab:~/wh$ python3 check_docs.py; echo "exit status $?"
problems: 0
exit status 0
```

Cento e quatro comandos, um para cada uma das 12 tabelas e das 92 colunas, incluído o que foi escrito na seção 4, e o
teste passa. Escrevê-los levou mais tempo do que qualquer consulta deste curso, e a maior parte do tempo foi gasta
decidindo, não digitando: o que exatamente `days_to_ship` conta, e o que ele é antes de um pedido ser enviado?

Alguns hábitos fazem as descrições valerem a leitura:

- **Diga o que quem lê não consegue ver.** "Número do pedido" não acrescenta nada a `order_id`. "Número do pedido no
  sistema da loja. Com line_no, identifica a linha" diz a quem lê como contar pedidos direito.
- **Nomeie os valores especiais.** Chave 0, "Not yet", 9999-12-31: cada um foi escolhido numa lição anterior e cada um é
  uma armadilha para quem não estava lá.
- **Dê a unidade e a aritmética.** `on_hand` diz com todas as letras que é semiaditivo: some entre lojas e livros,
  nunca entre datas.
- **Use as palavras do glossário.** `net_cents` diz "Net sales"; `amount_cents` diz "Receipts". Os dois nomes que a lição
  11 deu às suas duas medidas agora estão escritos nas colunas que as guardam.
- **Prefira uma frase simples a três espertas.** Uma descrição é lida por alguém no meio de outra coisa.

Uma descrição que precisa de um parágrafo costuma ser sinal de que a coluna faz coisas demais. Se explicá-la exige três
cláusulas de "exceto quando", o modelo talvez queira uma segunda coluna.
