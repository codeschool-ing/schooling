---
title: Faixas em SQL
version: 1
---

O SQL tem dois jeitos de pôr um número em faixas. O geral é um `CASE`, um ramo por faixa, que é o
que você escreve quando as bordas são irregulares ou têm nome:

```sql
CASE WHEN age < 25 THEN '18-24'
     WHEN age < 35 THEN '25-34'
     ELSE '35+' END
```

Cada `WHEN` é testado em ordem, então escrever as faixas de baixo para cima com `<` dá as mesmas
faixas fechadas à esquerda do `right=False` do pandas. Escrever com `<=` dá as faixas padrão do
`pd.cut`, com o 25 na primeira. **Escolha uma convenção e use nas duas ferramentas**, senão o mesmo
cliente cai em faixas diferentes no painel e no notebook.

O outro é o `width_bucket`, para faixas de largura igual. Ele recebe o valor, as bordas de baixo e
de cima, e quantos baldes cortar entre elas, e faz uma coisa que o `pd.cut` não faz: numera o que
fica de fora.

```
ana@lab:~/clean$ psql -c "SELECT width_bucket(total::numeric, 0, 200, 4) AS bucket, min(total::numeric), max(total::numeric), count(*) FROM (SELECT DISTINCT * FROM raw.orders) o GROUP BY 1 ORDER BY 1"
 bucket |  min   |   max    | count 
--------+--------+----------+-------
      0 | -17.05 |    -0.10 |   137
      1 |   0.25 |    49.95 | 12176
      2 |  50.00 |    99.95 |  8469
      3 | 100.00 |   149.95 |  3085
      4 | 150.00 |   199.95 |  1597
      5 | 200.00 | 26928.50 |  3062
(6 rows)
```

Os baldes 1 a 4 têm R$ 50 de largura, de 0 a 200, cada um fechado à esquerda. **O balde 0 guarda
tudo o que está abaixo da borda de baixo** e o balde 5 tudo o que está na borda de cima ou acima,
então nenhum valor some. Aqui o balde 0 são os 137 pedidos com total negativo, os cupons maiores
que a cesta que a aula 9 decidiu ler como nada cobrado, e o balde 5 são 3.062 pedidos de R$ 200 ou
mais, até os R$ 26.928,50 da clínica.

Esse comportamento de transbordo é a parte útil. Uma divisão em faixas que diz quanto caiu de cada
ponta é uma divisão que confere as próprias bordas, o mesmo trabalho que o `if` do `bands.py` faz à
mão.
