---
title: Mantendo verdadeiro
version: 1
---

Um dicionário completo em outubro está errado em dezembro, a menos que algo o mantenha em dia. O teste é esse algo.
Aqui chega uma coluna nova, do jeito que as colunas chegam, porque alguém precisa dela para um relatório:

```
ana@lab:~/wh$ duckdb wh.duckdb -c "ALTER TABLE fact_sales ADD COLUMN gift_wrap BOOLEAN DEFAULT false"
ana@lab:~/wh$ python3 check_docs.py; echo "exit status $?"
fact_sales.gift_wrap: no description
problems: 1
exit status 1
```

A coluna é acrescentada e o teste falha, nomeando-a. Num pipeline que roda o teste a cada mudança, a mudança que
acrescenta `gift_wrap` não chega ao warehouse enquanto não trouxer uma descrição e uma classificação. Assim,
**quem acrescenta a coluna escreve a descrição, na mesma mudança**, enquanto ainda sabe o que ela significa.

Essa é toda a disciplina, e ela tem três partes que só funcionam juntas:

- **As descrições moram com o código** que constrói as tabelas, no mesmo repositório e na mesma revisão.
- **O dicionário é gerado**, então ninguém edita uma cópia que pode se desviar.
- **Um teste falha numa lacuna**, no pipeline, então uma lacuna não consegue entrar.

Tire qualquer uma e o dicionário decai. Guardado numa wiki, ele se afasta do código. Escrito à mão, a cópia se afasta
da fonte. Sem o teste, lacunas entram em dias corridos, e todo warehouse tem dias corridos.

O que o teste não consegue conferir é se uma descrição é **verdadeira**. Um comentário dizendo "sem frete" numa coluna
que inclui frete passa em toda conferência desta lição. A revisão é a única defesa ali, e é por isso que as descrições
estão na mesma mudança que o SQL: quem revisa vê os dois de uma vez.
