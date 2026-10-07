---
title: Uma cópia para desenvolvedores
version: 1
---

Desenvolvedores precisam de dados. Um plano de consulta, uma migração, um bug que só aparece com um
cliente que tem sessenta pedidos — tudo fica mais fácil com dado realista, e o dado realista mais
fácil é uma cópia da produção. **Essa cópia é o lugar mais comum em que dado pessoal vai parar onde
ninguém queria**: um notebook, um banco de teste com senha fraca, o cache de um sistema de CI, uma
captura de tela num relato de bug.

**Mascaramento estático** torna a cópia segura antes de ela sair: a mesma forma e as mesmas
distribuições, sem ninguém dentro.

```sql
-- A copy of the customers for the developers' database: the same shape and
-- the same distributions, and nobody in it.
SET ROLE ipe_owner;
COPY (
  SELECT customer_id,
         'Customer ' || customer_id                     AS full_name,
         'customer' || customer_id || '@example.com'    AS email,
         make_date(extract(year FROM birth_date)::int, 1, 1) AS birth_date,
         sex, left(cep, 2) || '000-000'                  AS cep,
         city, state, created_at, marketing_opt_in
  FROM sales.customers ORDER BY customer_id
) TO STDOUT WITH (FORMAT csv, HEADER true);
```

```
ana@lab:~/gov$ psql -X -q -f dev.sql > dev_customers.csv && head -n 3 dev_customers.csv && wc -l dev_customers.csv
customer_id,full_name,email,birth_date,sex,cep,city,state,created_at,marketing_opt_in
1,Customer 1,customer1@example.com,1998-01-01,F,01000-000,São Paulo,SP,2025-01-07 12:04:18-03,t
2,Customer 2,customer2@example.com,1985-01-01,F,90000-000,Porto Alegre,RS,2020-07-16 12:14:56-03,f
6013 dev_customers.csv
```

Cada coluna foi decidida:

- **o id é mantido**, para que pedidos, itens e chamados copiados do mesmo jeito ainda se liguem ao
  cliente certo — um desenvolvedor depurando "o cliente de sessenta pedidos" ainda o acha;
- **o nome e o e-mail são trocados**, de forma determinística, por valores que dizem o que são;
- **a data de nascimento mantém o ano** e perde o dia, o que deixa testável toda funcionalidade
  baseada em idade;
- **o CEP mantém a região** (os dois primeiros dígitos) e perde a rua;
- **o CPF nem é exportado** — e, depois das seções seguintes desta aula, não sobra CPF em claro para
  exportar.

6.013 linhas: um cabeçalho e todos os clientes.

## Mascarado não é anônimo

Este arquivo é muito mais seguro que a tabela e **continua sendo dado pessoal**. Os ids de cliente
se ligam à produção; cidade, sexo, ano de nascimento e momento do cadastro juntos destacam muita
gente, como a seção 9 mede. Uma cópia mascarada pertence a um ambiente com controle de acesso, não a
um repositório público nem à demonstração de um fornecedor.

A alternativa é aquela em que este curso foi construído: **gerar o dado**. O `generate.py` da aula 1
escreve 6.012 clientes com sementes fixas, todo CPF falhando no dígito verificador e todo e-mail num
domínio reservado para exemplos. Ninguém ali existe, então ninguém pode ser exposto por ele, e um
teste que precisa de "um cliente menor de dezoito" ou de "um cadastro duplicado" o recebe porque
alguém o escreveu no gerador. Para a maior parte do trabalho de desenvolvimento, um gerador sai mais
barato que uma cópia bem mascarada e é mais seguro que qualquer cópia.
