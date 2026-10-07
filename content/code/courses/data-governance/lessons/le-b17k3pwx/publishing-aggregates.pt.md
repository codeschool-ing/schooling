---
title: Publicando contagens
version: 1
---

A maioria das divulgações de dado pessoal nem são linhas: são contagens. Vendas por cidade, receitas
por categoria, clientes por faixa etária. Uma contagem parece anônima por construção — é um número,
não uma pessoa — e uma contagem pequena é a exceção que faz dela outra coisa. "Um cliente de Belém
teve uma receita psiquiátrica este mês" é uma afirmação sobre uma pessoa, e numa cidade onde alguém
sabe quem compra na Ipê, é uma revelação.

A regra que trata disso é antiga e simples: **uma contagem abaixo de um limiar não é publicada como
número.** O relatório regional da Ipê, com limiar de dez:

```sql
-- Customers with a psychiatric prescription issued in June 2026, by city.
-- A count below 10 is published as "<10", never as the number.
SET ROLE ipe_owner;
SELECT c.city,
       CASE WHEN count(DISTINCT p.customer_id) < 10 THEN '<10'
            ELSE count(DISTINCT p.customer_id)::text END AS customers
FROM health.prescriptions p
JOIN sales.products pr USING (product_id)
JOIN sales.customers c USING (customer_id)
WHERE pr.category = 'psychiatric' AND p.issued_on >= DATE '2026-06-01'
GROUP BY c.city ORDER BY c.city;
```

```
ana@lab:~/gov$ psql -f report.sql
SET
      city      | customers 
----------------+-----------
 Belo Horizonte | 22
 Belém          | <10
 Brasília       | 16
 Campinas       | 20
 Curitiba       | 25
 Florianópolis  | <10
 Fortaleza      | <10
 Goiânia        | <10
 Manaus         | <10
 Natal          | <10
 Niterói        | 11
 Porto Alegre   | 19
 Recife         | 14
 Rio de Janeiro | 50
 Salvador       | 16
 Santos         | 13
 São Paulo      | 105
 Vitória        | 10
(18 rows)
```

Seis cidades aparecem como `<10`: quem lê fica sabendo que houve alguns, e não quantos, em Belém,
Manaus, Goiânia, Natal, Fortaleza e Florianópolis. Vitória, com exatamente 10, é publicada.

## Os detalhes que a desfazem

Supressão é fácil de escrever e fácil de derrotar, e três erros se repetem:

- **o total devolve a célula.** Se o relatório também imprimisse o total nacional, subtrair dele
  toda cidade publicada recuperaria a soma das suprimidas, e com uma célula suprimida, essa célula
  exatamente. Os totais são calculados sobre o que é publicado, ou a supressão é aplicada a uma
  segunda célula também.
- **dois relatórios diferem por uma pessoa.** Um relatório de junho e outro de "junho menos o último
  dia", ambos publicados, podem mostrar uma única receita na diferença. Os limiares valem para todo
  recorte que um leitor consegue fazer, inclusive o recorte entre duas divulgações.
- **o limiar é um número que alguém escolheu.** Dez é comum em estatísticas de saúde e não tem
  justificativa mais profunda que ser comum; um conjunto de dados sobre uma doença rara pode precisar
  de mais. Anote qual é o limiar e por quê, ao lado do relatório, para que a próxima pessoa o mude de
  propósito.

**Contagens são a forma mais segura de uma divulgação** quando são grossas o bastante e conferidas
assim — e é por isso que, quando um time recebe um pedido de "os dados", a primeira pergunta que vale
devolver é se as contagens bastariam.
