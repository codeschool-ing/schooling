---
title: Datas ambíguas, e como provar qual é qual
version: 1
---

**`03/04/2025` é 3 de abril no Brasil e 4 de março nos Estados Unidos**, e nada no texto diz que país o
escreveu. Um leitor que chuta vai chutar do mesmo jeito para toda linha, e errar toda linha da outra
origem:

```
ana@lab:~/clean$ python -c "import pandas as pd; print(pd.to_datetime('03/04/2025'), pd.to_datetime('03/04/2025', dayfirst=True))"
2025-03-04 00:00:00 2025-04-03 00:00:00
```

O pandas lê com o mês primeiro, a menos que se diga outra coisa, e com o dia primeiro quando se diz.
As duas são datas válidas. **Uma leitura errada de uma data produz outra data válida**, e é por isso
que esse defeito sobrevive tanto tempo: nada falha, e todo gráfico por mês muda em silêncio um
duodécimo do ano para o mês errado.

A aula 1 achou três convenções em `signed_up`: ISO no site, dia primeiro nas lojas, mês primeiro no
aplicativo. Uma afirmação assim deve ser provada, não suposta, e o dado consegue prová-la: **um dia
pode passar de 12 e um mês não.** Contando, para cada origem, quantas vezes o primeiro e o segundo
número passam de 12:

```
ana@lab:~/clean$ psql -c "SELECT signup_channel, count(*) FILTER (WHERE split_part(signed_up, '/', 1)::int > 12) AS first_over_12, count(*) FILTER (WHERE split_part(signed_up, '/', 2)::int > 12) AS second_over_12 FROM raw.customers WHERE signed_up LIKE '%/%' GROUP BY 1"
 signup_channel | first_over_12 | second_over_12 
----------------+---------------+----------------
 app            |             0 |            438
 import-2023    |             3 |              8
 store          |           380 |              0
(3 rows)
```

As lojas têm 380 valores com o primeiro número acima de 12 e nenhum com o segundo: dia primeiro,
provado. O aplicativo tem o inverso, 438 e 0: mês primeiro, provado. Todo valor com um número acima de
12 é uma testemunha, e com centenas de testemunhas e nenhuma exceção a convenção não está em dúvida.

**A migração de 2023 tem testemunhas dos dois tipos**: 3 valores com o primeiro número acima de 12 e 8
com o segundo. Ela copiou registros dos três sistemas sem convertê-los, então a sua coluna mistura
convenções dentro de uma mesma origem. Isso muda como ela precisa ser lida, e a próxima seção mostra
como.

O mesmo teste resolve qualquer coluna de datas ambíguas: conte as testemunhas de cada lado. Se um lado
não tem nenhuma, a convenção está clara. Se os dois têm alguma, a coluna mistura convenções, e cada
valor precisa de outra coisa para ser decidido — a sua origem, os vizinhos, ou uma pessoa.
