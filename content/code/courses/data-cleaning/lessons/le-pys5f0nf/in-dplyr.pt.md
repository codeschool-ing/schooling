---
title: Em dplyr
version: 1
---

O dplyr é a gramática de manipulação de dados do R: cada passo é um verbo, `filter`, `mutate`,
`group_by`, `summarise`, e o pipe `|>` passa a tabela de um para o outro. Ele se lê perto da
especificação:

```schooling-example
{
  "language": "r",
  "file": "task.R",
  "parts": [
    {
      "code": "suppressPackageStartupMessages(library(dplyr))\nlibrary(readr)\n\n",
      "note": "dplyr para os verbos, readr para a leitura."
    },
    {
      "code": "orders <- read_csv(\"raw/orders.csv\", col_types = cols(.default = col_character())) |>\n  distinct()\n\n",
      "note": "**Toda coluna como texto**, e linhas repetidas exatas removidas com `distinct()`."
    },
    {
      "code": "result <- orders |>\n  filter(status == \"delivered\") |>\n",
      "note": "Só pedidos entregues."
    },
    {
      "code": "  mutate(\n"
    },
    {
      "code": "    total = pmax(as.numeric(total), 0),\n",
      "note": "**Um total negativo vira zero**, linha a linha."
    },
    {
      "code": "    placed = if_else(\n      channel == \"site\",\n      format(as.POSIXct(ordered_at, format = \"%Y-%m-%dT%H:%M:%SZ\", tz = \"UTC\"),\n             tz = \"America/Sao_Paulo\", format = \"%Y-%m-%d %H:%M:%S\"),\n      ordered_at)\n  ) |>\n",
      "note": "**Os dois relógios**: o horário UTC do site formatado no fuso de São Paulo; o do aplicativo mantido como está."
    },
    {
      "code": "  group_by(channel) |>\n  summarise(orders = n(), revenue = sum(total),\n            december = sum(total[placed >= \"2025-12-01\"]))\n\n",
      "note": "Por canal: quantos pedidos, quanta receita, e a de dezembro. Os horários são comparados como texto, o que funciona porque estão escritos com o ano primeiro."
    },
    {
      "code": "print(as.data.frame(result), digits = 10)\n",
      "note": "Todos os dígitos, para a comparação com as outras ferramentas ser exata."
    }
  ]
}
```

```
ana@lab:~/clean$ Rscript task.R
  channel orders    revenue  december
1     app  11851 1065555.60 132925.45
2    site  14659 1436387.75 281616.15
```

A terceira ferramenta, os mesmos três números por canal. `col_types = cols(.default =
col_character())` é o jeito do readr de dizer o que `dtype=str` diz no pandas: ler tudo como texto e
não adivinhar nada. `distinct()` é o `SELECT DISTINCT *`, `pmax(..., 0)` é o `greatest`, e o fuso é
convertido formatando o horário UTC no fuso de São Paulo, com R básico e nenhum pacote extra.

Uma linha merece um segundo olhar. O `if_else` avalia **os dois** ramos em toda linha, então o
formato do site é aplicado também aos horários do aplicativo, onde falha e dá `NA`; a condição
escolhe então o outro ramo, e nada se perde. Isso é seguro aqui porque uma leitura que falha dá `NA`
em silêncio, e é exatamente o tipo de comportamento que vale conhecer antes de confiar num `if`
vetorizado.

**Três ferramentas, cada uma escrita a partir do mesmo parágrafo, concordam em todo
número.** É a mesma verificação da tabela tipada da aula 10 e do mapa de sobreviventes da aula 11,
em escala maior: quando duas implementações de uma especificação discordam, uma delas tem uma regra
que a outra não tem, e a especificação diz qual está errada.
