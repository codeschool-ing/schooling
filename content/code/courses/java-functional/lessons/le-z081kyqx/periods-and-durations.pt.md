---
title: Períodos e durações
version: 1
---

**Há duas maneiras de dizer "quanto tempo", e elas discordam uma vez por ano.** Um `Period` conta unidades
do calendário, anos, meses e dias, e uma `Duration` conta segundos. Na maioria dos dias um dia tem 24 horas
e as duas concordam; no dia em que os relógios mudam, não:

```schooling-example
{
  "language": "java",
  "file": "Spans.java",
  "parts": [
    {
      "code": "// Spans.java: a Period counts calendar units, a Duration counts seconds\nimport java.time.Duration;\nimport java.time.LocalDate;\nimport java.time.LocalDateTime;\nimport java.time.Period;\nimport java.time.ZoneId;\nimport java.time.ZonedDateTime;\n\npublic class Spans {\n    public static void main(String[] args) {\n        LocalDate borrowed = LocalDate.of(2026, 1, 31);\n        System.out.println(\"a month after \" + borrowed + \": \" + borrowed.plusMonths(1));\n        System.out.println(\"30 days after \" + borrowed + \": \" + borrowed.plusDays(30));\n        System.out.println(\"between: \" + Period.between(LocalDate.of(2025, 11, 20), borrowed));\n",
      "note": "Um `LocalDate` não tem hora nem fuso, então a aritmética dele é aritmética de calendário. Um mês depois de 31 de janeiro é o último dia de fevereiro, já que não existe 31 de fevereiro."
    },
    {
      "code": "\n        ZoneId newYork = ZoneId.of(\"America/New_York\");\n        ZonedDateTime evening = ZonedDateTime.of(LocalDateTime.of(2026, 3, 7, 20, 0), newYork);\n        System.out.println(\"start:        \" + evening);\n        System.out.println(\"plus 1 day:   \" + evening.plusDays(1));\n        System.out.println(\"plus 24 hours \" + evening.plus(Duration.ofHours(24)));\n        System.out.println(\"hours apart:  \" + Duration.between(evening, evening.plusDays(1)).toHours());\n",
      "note": "Nova York adianta os relógios às 02:00 de 8 de março de 2026. Somar um dia mantém a hora do dia; somar 24 horas mantém a duração."
    },
    {
      "code": "\n        ZonedDateTime gap = ZonedDateTime.of(LocalDateTime.of(2026, 3, 8, 2, 30), newYork);\n        System.out.println(\"02:30 asked:  \" + gap);\n    }\n}\n",
      "note": "02:30 naquela madrugada nunca acontece em Nova York: os relógios pulam de 01:59 para 03:00."
    }
  ]
}
```

```
ana@vm:~/fp/time$ java Spans.java
a month after 2026-01-31: 2026-02-28
30 days after 2026-01-31: 2026-03-02
between: P2M11D
start:        2026-03-07T20:00-05:00[America/New_York]
plus 1 day:   2026-03-08T20:00-04:00[America/New_York]
plus 24 hours 2026-03-08T21:00-04:00[America/New_York]
hours apart:  23
02:30 asked:  2026-03-08T03:30-04:00[America/New_York]
```

## Tempo de calendário e tempo decorrido

O `plusMonths(1)` sobre 31 de janeiro deu 28 de fevereiro, **o último dia do mês em vez de um erro ou de 3
de março**, e o `plusDays(30)` deu 2 de março, que é outra resposta para uma pergunta que soa igual. Uma
biblioteca que empresta livros "por um mês" tem de escolher o que quer dizer, e deixar a escolha escrita.
O `Period.between` deu `P2M11D`: dois meses e onze dias, na notação ISO, com `P` de período.

Em Nova York os relógios foram adiantados uma hora na madrugada de 8 de março. **O `plusDays(1)` manteve a
hora do dia**, 20:00 de novo, e por isso o dia teve só 23 horas, como o `Duration.between` disse. **O
`plus` com 24 horas manteve a duração** e caiu às 21:00. Nenhum dos dois é um bug; respondem a perguntas
diferentes. Um lembrete para a mesma hora amanhã quer o primeiro, um timeout de um dia quer o segundo.

A última linha pediu 02:30 na madrugada em que os relógios pularam, uma hora que nunca existiu ali. O Java
não a recusou: ele empurrou a hora para a frente pelo tamanho do pulo, para 03:30, e mudou o deslocamento
de `-05:00` para `-04:00`. Um programa que monta horas a partir do que as pessoas digitam pode encontrar
isso, e no outono o contrário, uma hora que aconteceu duas vezes.

| tipo | conta | exemplo | o `plus` mantém |
|---|---|---|---|
| `Period` | anos, meses, dias | `P2M11D` | a hora do dia |
| `Duration` | segundos e nanossegundos | `PT24H` | a duração |

A `Duration` é também o que a aula 17 passou ao `Thread.sleep`: tempo decorrido, que não tem nada a ver
com calendários. Para medir quanto tempo um código leva, o `System.nanoTime` da aula 9 continua sendo a
ferramenta certa, já que o relógio da parede pode ser corrigido enquanto ele roda.
