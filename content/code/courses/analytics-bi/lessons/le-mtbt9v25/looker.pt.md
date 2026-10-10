---
title: Looker
version: 1
---

O **Looker** é a plataforma corporativa de BI do Google Cloud, e é a ferramenta mais construída em
torno da ideia da aula 3: nada é explorado sem que um modelador o tenha descrito antes.

A descrição é escrita em **LookML**, uma linguagem de arquivos de texto guardados no git. Uma **view**
descreve uma tabela: as dimensões e as medidas dela. Um **explore** diz quais views podem ser juntadas
a quais, e como. Um **model** agrupa explores e dá nome à conexão com o banco. Quem não é modelador
nunca escreve SQL: escolhe dimensões e medidas num explore, e o Looker escreve a consulta a partir do
LookML.

Os pedidos da Lantern, descritos como uma view em LookML, poderiam ficar assim. **Não rodou**: foi
escrito a partir da documentação do Looker para mostrar o formato, e um projeto de verdade seria
conferido pelo validador do próprio Looker.

```
view: orders {
  sql_table_name: semantic.orders ;;

  dimension: order_id {
    primary_key: yes
    type: number
    sql: ${TABLE}.order_id ;;
  }

  dimension_group: order {
    type: time
    datatype: date
    timeframes: [date, month, quarter, year]
    sql: ${TABLE}.order_date ;;
  }

  measure: net_revenue {
    type: sum
    sql: ${TABLE}.net_revenue ;;
    value_format_name: decimal_2
    description: "Gross minus discount for paid orders. Refunded orders count zero."
  }
}
```

Duas coisas nele são lições deste curso escritas como sintaxe. O `primary_key` diz ao Looker a
granularidade da view, que ele usa para detectar o fan-out da aula 3 e somar corretamente quando um
join repetiria linhas. E o `type: sum` da medida é escolhido uma vez, pelo modelador, então ninguém que
a explore escolhe uma média por acidente — o problema de medida implícita da aula 4, fechado pela
linguagem.

## Não confundir com o Looker Studio

O Google também tem o **Looker Studio**, antes Google Data Studio: uma ferramenta de painéis gratuita,
no navegador, sem LookML e sem modelo central, mais próxima em espírito de um gráfico de planilha. O
nome compartilhado manda muita gente para a errada. Se um anúncio de vaga pede LookML, ele quer dizer
Looker.
