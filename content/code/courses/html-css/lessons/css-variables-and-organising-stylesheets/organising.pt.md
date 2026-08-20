---
title: Organizar sem virar arqueologia
---

Um CSS que cresce sem ordem vira um arquivo em que ninguém ousa apagar nada. Três hábitos seguram isso:

- **Ordem previsível no arquivo**: reset, variáveis, base, componentes, utilitários, media queries. Regra nova tem um lugar óbvio para entrar.
- **Especificidade baixa e plana**: classe simples, quase sem aninhar. Seletor com quatro níveis obriga o próximo a ter cinco.
- **Nome pelo que a coisa é, não pelo que ela parece**: `.aviso` sobrevive à decisão de deixar o aviso azul; `.texto-vermelho` não.

Se um `!important` apareceu, quase sempre a causa foi um seletor específico demais lá atrás. O conserto é baixar a especificidade daquele, não subir a deste.
