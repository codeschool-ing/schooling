---
title: Uma view como interface
version: 1
---

Os analistas também querem idade. Não a data de nascimento — a análise de ninguém precisa do dia
em que alguém nasceu — mas se os clientes são jovens ou velhos, e como isso muda o que compram.
Conceder `birth_date` entregaria a data exata de 6.012 pessoas para responder a uma pergunta
sobre cinco faixas.

Uma **view** responde à pergunta e mantém a data na tabela:

```sql
-- What an analyst needs about a customer, computed where the data is.
-- The age band is derived here, so birth_date never leaves the table.
SET ROLE ipe_owner;
CREATE VIEW sales.customer_profile AS
SELECT customer_id,
       state,
       CASE WHEN age < 18 THEN 'under 18'
            WHEN age < 30 THEN '18-29'
            WHEN age < 50 THEN '30-49'
            WHEN age < 70 THEN '50-69'
            ELSE '70+' END AS age_band,
       created_at::date AS customer_since
FROM (SELECT c.*, extract(year FROM age(DATE '2026-07-01', birth_date))::int AS age
      FROM sales.customers c) c;
GRANT SELECT ON sales.customer_profile TO analyst;
```

```
ana@lab:~/gov$ psql -f view.sql
SET
CREATE VIEW
GRANT
ana@lab:~/gov$ psql service=bruno -c "SELECT age_band, count(*) FROM sales.customer_profile GROUP BY 1 ORDER BY 1"
 age_band | count 
----------+-------
 18-29    |  1153
 30-49    |  2283
 50-69    |  1617
 70+      |   939
 under 18 |    20
(5 rows)

ana@lab:~/gov$ psql service=bruno -c "SELECT birth_date FROM sales.customers LIMIT 1"
ERROR:  permission denied for table customers
```

A view calcula a faixa no servidor, e a data nunca chega ao Bruno: ele lê `customer_profile` e
continua sem conseguir ler `birth_date` da tabela. **A view é a interface que os analistas
recebem; a tabela é um detalhe de implementação em que eles nunca tocam.** O "hoje" do próprio
laboratório, 1º de julho de 2026, está escrito na view para que toda execução dê as mesmas
faixas.

As faixas mostram também algo que ninguém pediu: **vinte clientes têm menos de dezoito anos.** Os
termos de uso de uma farmácia podem dizer que os clientes são adultos; o dado diz outra coisa. A
aula 6 trata do que a LGPD exige para dado de crianças e adolescentes, e começa por essa linha.

## Por que uma view mostra o que quem a lê não pode ler

O Bruno não tem direito a `birth_date`, e a view lê `birth_date`. Funciona porque **uma view roda
com os privilégios do dono**, não de quem a lê. `ipe_owner` é dono da view e lê a tabela
inteira; o Bruno recebe a view, e a view lê a tabela em nome dele. É exatamente isso que torna uma
view útil como interface, e a seção 8 mostra o caso em que isso é exatamente o problema.

## O que faz de uma view uma boa interface

- **Ela expõe valores derivados, não brutos**: uma faixa etária, um mês, um estado — o que a
  pergunta precisa, na precisão de que precisa.
- **Ela tem o nome de quem a lê**, `customer_profile`, então uma concessão sobre ela se lê como
  uma decisão.
- **Ela é estável.** Quando a tabela ganha uma coluna, a view não ganha, até alguém decidir que os
  analistas devem tê-la. Privilégios de coluna não conseguem isso: uma coluna nova fica invisível
  até ser concedida, e um `SELECT` concedido na tabela a inclui no dia em que ela é criada.

Vale nomear um limite já. Uma view esconde as *colunas* de cada linha; não impede quem a lê de
filtrar até um grupo ter uma pessoa só. A aula 5 mede isso.
