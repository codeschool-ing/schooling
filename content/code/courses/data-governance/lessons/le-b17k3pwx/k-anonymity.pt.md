---
title: k-anonimato, e o que ele não promete
version: 1
---

A seção anterior contou pessoas sozinhas no grupo. O **k-anonimato** transforma isso numa regra:
uma divulgação é *k*-anônima se toda combinação de quase-identificadores nela é dividida por pelo
menos *k* pessoas. Com *k* = 5, quem tenta destacar alguém cai numa multidão de pelo menos cinco.

A mais grossa das três divulgações, medida contra *k* = 5:

```sql
-- The smallest group, and how many groups are smaller than k = 5, for the
-- generalised release: decade of birth, sex and state.
SET ROLE ipe_owner;
SELECT min(n) AS smallest_group,
       count(*) FILTER (WHERE n < 5) AS groups_under_5,
       sum(n) FILTER (WHERE n < 5) AS customers_in_them,
       count(*) AS groups
FROM (SELECT count(*) AS n FROM sales.customers
      GROUP BY extract(decade FROM birth_date), sex, state) g;
```

```
ana@lab:~/gov$ psql -f kanon.sql
SET
 smallest_group | groups_under_5 | customers_in_them | groups 
----------------+----------------+-------------------+--------
              1 |             61 |               132 |    246
(1 row)
```

**246 grupos, e 61 deles têm menos de cinco pessoas** — 132 clientes em grupos pequenos demais. O
menor grupo tem uma. Então "década de nascimento, sexo e estado", que parecia segura com 22 pessoas
sozinhas, não é 5-anônima. Dois movimentos a levam até lá, e os dois perdem informação:

- **generalizar mais**: região em vez de estado, uma faixa etária mais larga — grupos menos
  numerosos e maiores;
- **suprimir**: deixar os 132 clientes de fora da divulgação, ou apagar os quase-identificadores
  deles, e dizer na divulgação que grupos pequenos foram suprimidos.

Qual está certo depende de para que a divulgação serve. Um estudo de diferenças regionais não pode
perder o estado; um estudo de efeitos da idade não pode perder a idade.

## O que o k-anonimato não promete

**Uma multidão de cinco que comprou o mesmo remédio revela esse remédio para os cinco.** Se todo
cliente do grupo "nascida nos anos 1970, mulher, Rio Grande do Norte" tem uma receita psiquiátrica,
saber que uma mulher do Rio Grande do Norte nascida nos anos 1970 está na divulgação lhe diz o
diagnóstico dela, embora você não saiba qual linha é a dela. Essa fraqueza é antiga e conhecida, e
os refinamentos com nome por causa dela — *l*-diversidade, *t*-proximidade — pedem que os valores
sensíveis dentro de cada grupo também variem.

**E ele não diz nada sobre combinar divulgações.** Duas divulgações, cada uma 5-anônima, podem
destacar uma pessoa quando juntadas, se generalizarem de jeitos diferentes. Um time que publica
mais de uma vez precisa medir o que as divulgações dizem juntas.

O uso defensável do *k*-anonimato é como **uma medida e um piso**, não como um certificado: uma
divulgação com grupos de um é com certeza insegura, e uma em que todo grupo tem cinco pessoas é mais
segura, por uma margem que a próxima seção transforma numa regra para contagens.
