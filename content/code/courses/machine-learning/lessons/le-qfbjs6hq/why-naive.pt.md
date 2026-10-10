---
title: O que há de ingênuo nele, e por que funciona mesmo assim
version: 1
---

O naive Bayes multiplica a evidência de cada palavra como se as palavras fossem **independentes umas
das outras, dada a classe**: como se saber que uma reclamação diz *bruised* não dissesse nada sobre
ela também dizer *bananas*. Isso é falso em quase todo texto. Palavras andam em expressões; *arrived*
e *late* vêm juntas; uma avaliação que fala em *refund* provavelmente fala de algo que deu errado. A
suposição é a parte ingênua, e o modelo a faz sabendo, porque ela transforma um cálculo impossível em
multiplicar algumas contagens.

A surpresa é o quão pouco isso atrapalha a **ordenação**. Para decidir se uma avaliação é reclamação,
o modelo só precisa pôr as reclamações acima das não reclamações; ele não precisa acertar a
probabilidade exata. Palavras correlacionadas fazem ele contar a mesma evidência duas vezes, o que
empurra toda nota ainda mais para a ponta para onde ela já ia, e a ordem das avaliações quase sempre
sobrevive.

O que ela atrapalha são as **próprias probabilidades**. A última linha do `bayes.py` diz isso: **56,8%
das avaliações de teste ganharam nota abaixo de 1% ou acima de 99%.** Cada palavra correlacionada
soma sua evidência de novo, e o modelo termina certo onde não tem direito de estar. Uma avaliação com
99,9% não está mil vezes mais segura que uma com 99%; as duas são, no fundo, *muito provavelmente uma
reclamação*.

Isso importa assim que o número é usado como probabilidade e não como ordem. A aula 11 define um
limiar a partir de custos, e um limiar calculado a partir de custos supõe que 0,3 quer dizer três em
dez. **As probabilidades do naive Bayes precisam ser calibradas antes de serem usadas assim**, o que a
aula 11 faz para qualquer modelo cujas notas não merecem confiança como saem.

## Onde ele cabe

O naive Bayes é o primeiro modelo certo para texto, pelo mesmo motivo que a regressão linear é o
primeiro modelo certo para números: é rápido, não precisa de ajuste fino, é legível e é uma linha de
base forte. Filtros de spam rodaram nele por anos. Os limites dele são a suposição de independência e
as notas confiantes demais; nos dados de churn, onde as colunas são poucas, numéricas e
correlacionadas, ele não tem vantagem nenhuma, e este curso não o usa ali.
