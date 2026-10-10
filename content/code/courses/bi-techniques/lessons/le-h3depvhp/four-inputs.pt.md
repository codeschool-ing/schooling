---
title: Quatro números decidem o tamanho
version: 1
---

Um teste é uma aposta contra o acaso: com poucos visitantes, os dois grupos diferem só por sorte, e
um efeito real menor que essa sorte não aparece. **O tamanho de amostra é o número de visitantes em
que o efeito que importa se destaca da sorte**, e é definido por quatro números, todos escolhidos
antes do teste.

| entrada | o valor da Panela | o que quer dizer | se você diminuí-la |
|---|---|---|---|
| **taxa de base** | 4,2% | quantos visitantes convertem hoje | taxas perto de 0 ou de 100% pedem mais visitantes para a mesma alta |
| **efeito mínimo detectável**, MDE | +0,6 ponto | a menor alta que vale achar, da hipótese da aula 7 | muito mais visitantes: a próxima seção mede quanto |
| **nível de significância**, α | 5%, bilateral | a chance de um alarme falso quando nada mudou | mais visitantes |
| **poder**, 1 − β | 80% | a chance de detectar o efeito se ele de fato existir | menos visitantes, e mais efeitos reais perdidos |

Dois deles vêm da aula 15 de `statistics`. **O α é a taxa de erro tipo I**: declarar um vencedor que
não é. **O β é a taxa de erro tipo II**: perder um vencedor que é, e o poder é o complemento dele. As
convenções, 5 por cento e 80 por cento, querem dizer que um teste é montado para aceitar quatro vezes
mais risco de perder um efeito do que de inventar um, o que reflete que lançar uma mudança que não
faz nada costuma custar mais que não lançar uma que ajuda.

**A taxa de base vem do dado, não da esperança.** Os 4,2 por cento da Panela são a conversão que o
plano espera no grupo de controle. Se a taxa real vier diferente, o poder do teste muda junto, o que
a aula 10 confere.

**O MDE vem do negócio, não da estatística.** É o menor efeito que pagaria a mudança. Um erro comum
é defini-lo pelo que o time espera ver; um teste dimensionado para uma expectativa otimista é
pequeno demais para detectar uma realista.
