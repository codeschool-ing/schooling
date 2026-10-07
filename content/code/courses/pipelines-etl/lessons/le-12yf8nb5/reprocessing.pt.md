---
title: Reprocessar uma janela, toda noite
version: 1
---

A lição 11 deixou o `fact_sales` trocando só o seu dia mais novo, e o teste de deriva da lição 12
falhou na maior parte dos dias novos desde então, porque a loja continua mudando vendas por semanas
depois que elas acontecem. Toda vez, o remédio foi uma recarga completa à mão. Mais dois dias, e o
mesmo:

```
ana@vm:~/etl$ sudo shop until 2026-03-18
ana@vm:~/etl$ python load_raw.py >/dev/null
ana@vm:~/etl/shop$ dbt build --quiet 2>&1 | grep -E "FAIL|Got"
08:51:47  13 of 14 FAIL 8 fact_sales_has_not_drifted ..................................... [FAIL 8 in 0.06s]
08:51:47    Got 8 results, configured to fail if != 0
ana@vm:~/etl$ cat shop/models/marts/fact_sales.sql
-- One row per order line sold. Each run replaces the last thirty days the table
-- already has, and every day after them: the shop changes a sale for weeks after
-- it was made, and a day outside the window is only put right by a full refresh.
{{ config(materialized='incremental',
          incremental_strategy='delete+insert',
          unique_key='order_date') }}
select order_date, order_id, line_no, shop_id, customer_id, book_id, quantity, line_cents
  from {{ ref('int_sales') }}
{% if is_incremental() %}
 where order_date >= (select max(order_date) - 30 from {{ this }})
{% endif %}
ana@vm:~/etl/shop$ dbt build -s fact_sales+ 2>&1 | grep -E " OK | PASS | FAIL |Done"
08:51:51  1 of 2 OK created sql incremental model dbt_marts.fact_sales ................... [INSERT 0 13475 in 0.21s]
08:51:51  2 of 2 PASS fact_sales_has_not_drifted ......................................... [PASS in 0.07s]
08:51:51  Done. PASS=2 WARN=0 ERROR=0 SKIP=0 NO-OP=0 REUSED=0 TOTAL=2
```

Oito dias derivaram. O `where` do modelo é o problema: uma execução incremental que troca só o dia
mais novo é idempotente — rodá-la duas vezes deixa a mesma tabela —, mas não é **completa**, porque os
dias para os quais ela não olha ainda podem mudar. A Ana alarga aquilo de que cada execução é
responsável para os últimos trinta dias, e diz por quê no modelo. É o resto da transcrição acima: o modelo novo, com `cat` depois da
edição, e a primeira execução dele. O `INSERT 0 13475` é um mês de
linhas apagado e escrito de novo, e o teste de deriva passa sem recarga completa. Três dias depois:

```
ana@vm:~/etl$ sudo shop until 2026-03-21
ana@vm:~/etl$ python load_raw.py >/dev/null
ana@vm:~/etl/shop$ dbt build -s fact_sales+ 2>&1 | grep -E " OK | PASS | FAIL |Done"
08:51:55  1 of 2 OK created sql incremental model dbt_marts.fact_sales ................... [INSERT 0 14895 in 0.21s]
08:51:55  2 of 2 PASS fact_sales_has_not_drifted ......................................... [PASS in 0.07s]
08:51:55  Done. PASS=2 WARN=0 ERROR=0 SKIP=0 NO-OP=0 REUSED=0 TOTAL=2
```

Continua passando. **Reprocessar uma janela é a forma apagar-e-inserir aplicada a mais de uma
fatia**: a execução é dona dos últimos trinta dias, apaga-os e escreve-os de novo, e consegue fazer
isso toda noite justamente porque a carga é idempotente. Sem isso, uma janela quereria dizer trinta
dias carregados trinta vezes.

A janela é uma troca, e os números nas transcrições mostram os dois lados. Cada execução agora escreve
umas catorze mil linhas em vez de algumas centenas, o que nos dados deste laboratório custa uma fração
de segundo e num warehouse grande pode custar dinheiro de verdade — a lição 19 trata disso. Em troca,
qualquer coisa que a loja mude dentro de um mês está certa na manhã seguinte. Uma mudança mais velha
que a janela ainda precisa da recarga completa, então o teste de deriva fica; ele só falha raramente o
bastante agora para que, quando falhar, queira dizer alguma coisa.

Quão larga fazê-la é uma pergunta que os dados respondem. As falhas do teste de deriva ao longo de
algumas semanas mostraram quão para trás as mudanças da loja chegavam; trinta dias cobre todas elas
aqui com folga. Em outro lugar poderiam ser sete dias ou noventa, e uma política de reembolso costuma
ser de onde vem o número.
