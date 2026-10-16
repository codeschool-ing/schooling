---
title: Trazendo a camada para dentro
version: 1
---

O Power BI lê dados pelo **Get data** (Obter dados), que oferece conectores para centenas de fontes,
entre elas o PostgreSQL. Numa empresa o banco estaria num servidor que o Power BI alcança, e você
escolheria esse conector, apontaria para o schema `semantic` com um papel só de leitura como o da
aula 3, e escolheria entre dois **modos de armazenamento**:

| modo | o que acontece | contrapartida |
|---|---|---|
| **Import** | o Power BI copia as linhas para o arquivo `.pbix` e responde da própria cópia compactada | rápido, e tão atual quanto a última atualização |
| **DirectQuery** | o Power BI manda uma consulta ao banco para cada visual, toda vez | sempre atual, e cada clique custa uma consulta ao banco |

O seu banco está dentro de uma máquina virtual que, de propósito, não deixa nada entrar pela porta
5432. Abri-la para o computador Windows é possível e não vale a pena num curso. **Arquivos são a
ponte mais simples**: exporte cada view da camada como CSV, copie os arquivos, e use o conector
**Text/CSV** do Get data, que é o modo Import com outra fonte.

Na máquina, crie um diretório, salve isto como `export.sql` dentro dele e rode com o `psql`:

```
\copy (SELECT * FROM semantic.orders) TO 'orders.csv' WITH (FORMAT csv, HEADER)
\copy (SELECT * FROM semantic.order_lines) TO 'order_lines.csv' WITH (FORMAT csv, HEADER)
\copy (SELECT * FROM semantic.customers) TO 'customers.csv' WITH (FORMAT csv, HEADER)
\copy (SELECT * FROM semantic.products) TO 'products.csv' WITH (FORMAT csv, HEADER)
\copy (SELECT * FROM semantic.calendar) TO 'calendar.csv' WITH (FORMAT csv, HEADER)
```

O `\copy` é um comando do próprio `psql`: roda a consulta no servidor e grava o resultado num
arquivo do lado do cliente, com uma linha de cabeçalho.

```
ana@vm:~$ cd powerbi
ana@vm:~/powerbi$ psql lantern -f export.sql
COPY 7098
COPY 11355
COPY 2649
COPY 12
COPY 546
```

```
ana@vm:~/powerbi$ wc -l *.csv
   547 calendar.csv
  2650 customers.csv
 11356 order_lines.csv
  7099 orders.csv
    13 products.csv
 21665 total
ana@vm:~/powerbi$ head -n 3 orders.csv
order_id,customer_id,order_date,status,gross,discount,net_revenue
2,660,2025-01-04,paid,32.90,0.00,32.90
3,325,2025-01-09,paid,77.70,0.00,77.70
```

Cada arquivo tem uma linha a mais que a contagem, pelo cabeçalho. Copie o diretório para o seu
computador Windows a partir de uma janela do PowerShell lá, com a mesma conexão SSH que a aula 1
montou (este comando não rodou para o curso, porque o curso não tem um computador Windows do outro
lado):

```
scp -P 2222 -r ana@localhost:powerbi .
```

## O Power Query, e a armadilha do idioma

Carregar um arquivo passa pelo **Power Query**, o editor entre a fonte e o modelo. Cada
transformação que você faz ali — renomear uma coluna, mudar um tipo, remover linhas — é gravada como
um passo, e os passos são repetidos a cada atualização. É a mesma ideia do `lantern.sql`: guarda-se a
receita, não o resultado.

Um passo precisa da sua atenção com estes arquivos. O CSV escreve `32.90` com ponto, e o Power Query
lê um número usando o **idioma** (*locale*) do arquivo ou das configurações do seu Windows. Num
computador em português (Brasil), onde o separador decimal é a vírgula, `32.90` pode ser lido como
`3290` — todo valor cem vezes maior, e nenhum erro em lugar nenhum. A aula 1 encontrou três linhas
assim nos dados da Lantern; isto deixaria todas assim. Ponha o idioma em inglês na carga (na janela
de importação, ou com *Alterar tipo → Usando localidade* nas colunas de dinheiro) e confira um valor
conhecido: o pedido 2 é R$ 32,90.

Essa conferência é a aula 1 de novo, numa ferramenta nova: **depois de qualquer carga, compare um
número que você já conhece.**
