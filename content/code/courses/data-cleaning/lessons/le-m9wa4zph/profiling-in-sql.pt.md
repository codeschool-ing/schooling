---
title: O mesmo perfil em SQL, e o perfil por escrito
version: 1
---

**Tudo nesta aula pode ser feito onde o dado já está.** Quando uma tabela tem milhões de linhas,
puxá-la para o pandas para contar valores distintos é o caminho longo; o banco os conta onde eles
estão. As medidas são as mesmas e os achados também.

O perfil de uma coluna é uma consulta:

```
ana@lab:~/clean$ psql -c "SELECT count(*) AS rows, count(cep) AS filled, count(DISTINCT cep) AS distinct_values, min(length(cep)) AS shortest, max(length(cep)) AS longest FROM raw.customers"
 rows | filled | distinct_values | shortest | longest 
------+--------+-----------------+----------+---------
 2413 |   2413 |            2360 |        7 |       9
(1 row)
```

`count(cep)` conta os valores não nulos e `count(*)` conta linhas, então a diferença são as células
vazias, exatamente como `filled` e `empty` no pandas. `count(DISTINCT …)`, `min(length(…))` e
`max(length(…))` são o resto.

O perfil de padrões são duas chamadas aninhadas de `regexp_replace`, primeiro os dígitos e depois as
letras:

```
ana@lab:~/clean$ psql -c "SELECT regexp_replace(regexp_replace(cep, '[0-9]', '9', 'g'), '[[:alpha:]]', 'a', 'g') AS pattern, count(*) FROM raw.customers GROUP BY 1 ORDER BY 2 DESC"
  pattern  | count 
-----------+-------
 99999-999 |  1322
 99999999  |   803
 9999999   |   288
(3 rows)
```

As mesmas três formas, com as mesmas contagens, numa ferramenta diferente. `[[:alpha:]]` é a classe
do PostgreSQL para uma letra de qualquer alfabeto, fazendo o papel de `[^\W\d_]` no Python, e a
opção `'g'` troca todas as ocorrências em vez da primeira.

Padrões funcionam em qualquer texto, inclusive no dinheiro que o caixa das lojas escreve:

```
ana@lab:~/clean$ psql -c "SELECT regexp_replace(total, '[0-9]', '9', 'g') AS pattern, count(*) FROM raw.store_sales GROUP BY 1 ORDER BY 2 DESC"
  pattern  | count 
-----------+-------
 R$ 99,99  | 19308
 R$ 999,99 |  3395
 R$ 9,99   |   891
(3 rows)
```

Todo total das lojas tem a forma `R$ 9,99`, com um, dois ou três dígitos antes da vírgula. **Isso é
boa notícia e um aviso.** Boa, porque só há um formato a converter: tirar o `R$ `, trocar a vírgula
por ponto. Um aviso, porque nenhuma venda chegou a R$ 1.000 em 2025, então o separador de milhar do
caixa — um ponto, como em `R$ 1.234,56` — nunca aparece, e uma conversão escrita e testada com os
dados deste ano estragaria a primeira venda grande do ano que vem. A aula 7 escreve a conversão de
um jeito que dá conta dos dois.

## O perfil, por escrito

Um perfil na tela some quando o terminal fecha. **O que Ana guarda é um documento curto**, uma linha
por achado, cada uma com o seu número, a sua origem e quem pode responder por ela:

| achado | quantos | de onde vem | quem responde |
|---|---|---|---|
| `store_sales.csv` em Latin-1 com `;` | um arquivo | o caixa das lojas | ninguém precisa: leia direito |
| códigos de produto sem zeros à esquerda | algumas linhas | o aplicativo | o time do aplicativo |
| ids de cliente repetidos | 37 linhas a mais | a exportação do CRM | o time do CRM |
| ano de nascimento 1900 | 348 | o formulário das lojas | a gerência das lojas |
| CEPs de sete dígitos | 288 | o aplicativo | o time do aplicativo |
| datas com dia primeiro e com mês primeiro | 1.369 linhas | as lojas e o aplicativo | o time do aplicativo |
| vazio e `0` querem dizer sem desconto | 13.883 e 11.233 | o site e o aplicativo | ninguém precisa: mesmo significado |
| totais negativos | 137 | os cupons do site | pagamentos |
| consentimento de marketing escrito de 10 jeitos | 2.352 preenchidos | os três sistemas | o time do CRM |

**A última coluna é o motivo de escrever.** Alguns achados se limpam e se esquecem; outros são
perguntas que só outro time responde, e a melhor correção para um CEP de sete dígitos é um aplicativo
que o guarde como texto. A aula 17 guarda este documento junto do código de limpeza, para que a
próxima pessoa saiba distinguir uma decisão de um acidente.
