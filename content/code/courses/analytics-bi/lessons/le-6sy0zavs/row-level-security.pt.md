---
title: Segurança em nível de linha, e a mesma ideia em SQL
version: 1
---

O gerente de vendas da Lantern para o Sul deve ver os números do Sul e de mais ninguém, no mesmo
relatório que todo mundo usa. Montar um relatório separado por região é a resposta que não escala.
A **segurança em nível de linha** (*row-level security*) é a que escala: o próprio modelo filtra as
linhas conforme quem está olhando.

No Power BI ela é um **papel**, definido no Desktop em *Gerenciar funções*, com um filtro DAX numa
tabela:

```
customers[region] = "South"
```

(Não rodou.) Quem for atribuído a esse papel no serviço vê o relatório como se um filtro de região
estivesse fixo no Sul e escondido. Como o filtro está em `customers`, ele anda até `orders` pelo
relacionamento como qualquer outro filtro, e toda medida o respeita. O *Exibir como* do Desktop deixa
o autor conferir o que um papel vê antes de publicar — o passo que as pessoas pulam, e então publicam
um relatório em que o papel não vê nada, ou vê tudo.

## A mesma ideia no PostgreSQL

O banco também sabe fazer isso, e fazer uma vez em SQL torna o mecanismo visível. Uma tabela diz quem
pode ver qual região, e uma view faz o join com ela usando `current_user`, que dentro de uma view é o
papel que roda a consulta, e não o dono da view:

```sql
CREATE TABLE semantic.region_access (role_name text, region text);
INSERT INTO semantic.region_access VALUES ('south_manager', 'South');
CREATE VIEW semantic.my_orders AS
SELECT o.*, c.region
FROM semantic.orders o
JOIN semantic.customers c USING (customer_id)
JOIN semantic.region_access a ON a.region = c.region AND a.role_name = current_user;
```

Depois, um papel para o gerente, que pode ler essa view e mais nada:

```sql
CREATE ROLE south_manager LOGIN PASSWORD 'another-password-to-choose';
GRANT USAGE ON SCHEMA semantic TO south_manager;
GRANT SELECT ON semantic.my_orders TO south_manager;
```

```
lantern=# CREATE TABLE semantic.region_access (role_name text, region text);
CREATE TABLE

lantern=# INSERT INTO semantic.region_access VALUES ('south_manager', 'South');
INSERT 0 1

lantern=# CREATE VIEW semantic.my_orders AS
lantern-# SELECT o.*, c.region
lantern-# FROM semantic.orders o
lantern-# JOIN semantic.customers c USING (customer_id)
lantern-# JOIN semantic.region_access a ON a.region = c.region AND a.role_name = current_user;
CREATE VIEW

lantern=# CREATE ROLE south_manager LOGIN PASSWORD 'another-password-to-choose';
CREATE ROLE

lantern=# GRANT USAGE ON SCHEMA semantic TO south_manager;
GRANT

lantern=# GRANT SELECT ON semantic.my_orders TO south_manager;
GRANT
```

Conectado como o gerente, pedindo todas as regiões:

```
ana@vm:~$ PGPASSWORD=another-password-to-choose psql -h localhost -U south_manager lantern -c 'SELECT region, count(*) FROM semantic.my_orders GROUP BY region'
 region | count 
--------+-------
 South  |  1126
(1 row)
```

Só chegam os 1.126 pedidos do Sul. O gerente não escreveu filtro e não consegue tirar um: a view o
aplica, e o papel não lê as tabelas de baixo.

Dois avisos valem para as duas versões. **Um filtro desse tipo é tão bom quanto a tabela de
mapeamento**: um gerente que muda de região e continua na tabela segue vendo a antiga. E **quem
constrói o modelo vê tudo**, por desenho, então a segurança em nível de linha protege os leitores de
um relatório uns dos outros, e não dos autores dele.
