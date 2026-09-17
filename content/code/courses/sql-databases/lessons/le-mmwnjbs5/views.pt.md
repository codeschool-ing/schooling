---
title: Uma view é uma consulta com nome, não uma tabela
version: 1
---

```sql
CREATE VIEW active_customers AS
SELECT c.*
FROM   customers c
WHERE  c.deleted_at IS NULL
  AND  EXISTS (SELECT 1 FROM orders o
               WHERE o.customer_id = c.id AND o.placed_at > now() - INTERVAL '1 year');
```

```sql
SELECT count(*) FROM active_customers;
```

A segunda instrução parece ler uma tabela. Não lê: **a view não guarda linha nenhuma.** O banco
substitui a definição e a roda, toda vez, contra os dados como estão agora. Nada foi copiado e nada
pode ficar defasado.

Essa única frase responde à maioria das perguntas sobre views. O outro tipo — o que guarda linhas —
é a próxima seção, e manter os dois separados é a habilidade inteira aqui.

## Para que elas valem a pena

**Uma definição que para de ser discutida.** *"Cliente ativo"* é uma regra de negócio, e no instante
em que está escrita em quatro relatórios está escrita de quatro jeitos ligeiramente diferentes. Uma
view, uma definição, e uma mudança nela chega a todo mundo de uma vez. É a razão mais forte e não
tem nada a ver com o banco.

**Permissões.** Uma view pode expor algumas colunas de uma tabela e não outras:

```sql
CREATE VIEW staff_directory AS SELECT id, name, department FROM employees;
GRANT SELECT ON staff_directory TO reporting;
```

`reporting` lê o diretório e não tem permissão em `employees`, então salários ficam inalcançáveis. É
o jeito padrão de dar a alguém uma janela estreita para uma tabela larga.

**Uma renomeação que não quebra nada.** A aula 3 disse que renomear uma coluna é uma mudança de três
implantações porque duas versões da aplicação rodam ao mesmo tempo. Uma view é um jeito de comprar
esse tempo:

```sql
ALTER TABLE customers RENAME COLUMN nome TO name;
CREATE VIEW customers_old AS SELECT *, name AS nome FROM customers;
```

Código antigo lê a view, código novo lê a tabela, e a view é derrubada quando a última cópia antiga
sai do ar.

## As colunas ficam fixas quando ela é criada

A aula 4 alertou sobre `SELECT *` numa view e prometeu a demonstração aqui:

```sql
CREATE VIEW everything AS SELECT * FROM products;
ALTER TABLE products ADD COLUMN weight numeric;

SELECT * FROM everything;      -- a coluna nova não está lá
```

O `*` foi expandido numa lista de colunas na criação. A view tem as colunas que a tabela tinha
naquele dia, e as mantém até alguém recriá-la. Não há erro nem aviso — um relatório construído sobre
a view simplesmente nunca fica sabendo de `weight`.

`CREATE OR REPLACE VIEW` também não salva: ele acrescenta colunas no fim, e se recusa a remover,
renomear ou trocar a ordem. Para mudar o formato você derruba e recria, e tudo o que depende da view
precisa ser derrubado antes. **Escreva a lista de colunas.** Os três segundos que isso custa são os
mais baratos deste curso.

## Views em que você pode escrever

Uma view sobre uma tabela, sem agregação, sem `DISTINCT`, sem `GROUP BY` e sem janela, é
automaticamente atualizável — `INSERT`, `UPDATE` e `DELETE` nela alcançam a tabela de baixo.

Há uma quina afiada:

```sql
CREATE VIEW cheap_products AS SELECT * FROM products WHERE price < 100;
UPDATE cheap_products SET price = 500 WHERE id = 7;
```

Isso dá certo, e a linha desaparece da view — você atualizou uma linha para fora do conjunto que a
view define. Se isso não deve ser permitido, diga na criação:

```sql
CREATE VIEW cheap_products AS SELECT * FROM products WHERE price < 100
WITH CHECK OPTION;
```

Agora o `UPDATE` é rejeitado. Para uma view complicada demais para ser atualizável automaticamente,
o PostgreSQL permite escrever gatilhos `INSTEAD OF` e definir o que uma escrita quer dizer — vale
saber que existe, e vale um longo olhar antes de usar, porque uma tabela que não é tabela e uma
escrita que não é escrita são muita surpresa para um nome só.

## O que elas escondem

Uma view é uma consulta, então uma view sobre uma view sobre uma view é uma consulta grande, e o
planejador expande tudo antes de decidir qualquer coisa. Em geral isso é bom e o empurrão de filtro
da seção de tabelas derivadas se aplica sem mudança.

Ele deixa de ser bom no mesmo lugar: uma camada com `DISTINCT`, função de janela ou `GROUP BY` é um
muro que um filtro de fora não atravessa. Então `SELECT * FROM summary_view WHERE id = 7` lê como
uma busca indexada e pode ser uma agregação completa da tabela. **A view esconde o custo, não o
trabalho**, e este é o jeito mais comum de uma consulta que parece trivial levar nove segundos.

## E uma coisa que uma view simples não garante

Se você usa uma view para permissões, saiba que uma view comum não é um muro. Um usuário que possa
chamar uma função pode escrever:

```sql
SELECT * FROM staff_directory WHERE leak(salary_hint);
```

e o planejador pode avaliar a função barata antes das condições da própria view, então linhas que a
view deveria esconder chegam a ela. A resposta do PostgreSQL é `WITH (security_barrier = true)` na
view, ou segurança em nível de linha na própria tabela, que é a ferramenta mais forte. Se uma view
está segurando uma fronteira de segurança e não uma conveniência, essa distinção é a que você deve
pesquisar antes de confiar nela.
