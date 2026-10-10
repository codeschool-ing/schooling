---
title: Ler o resíduo
version: 1
---

**O resíduo é o relatório da própria decomposição sobre o que ela não conseguiu explicar**, e é a
parte que as pessoas pulam. A aula 1 disse que ruído com padrão não é ruído. Os quatro maiores
resíduos da seção anterior são um padrão:

| semana que termina em | resíduo | o que aconteceu |
|---|---|---|
| 16 fev 2025 | 1,082 | sem Carnaval; em 2024 a segunda e a terça de Carnaval caíram nesta semana do ano |
| 10 mar 2024 | 1,078 | sem Carnaval; em 2025 ele caiu nesta semana do ano |
| 18 fev 2024 | 0,930 | a segunda e a terça de Carnaval |
| 26 nov 2023 | 1,067 | Black Friday, que em 2024 caiu uma semana do ano depois |

Três deles são o **Carnaval**, que caiu em 21 de fevereiro de 2023, 13 de fevereiro de 2024 e 4 de
março de 2025. Um índice sazonal é uma média sobre a mesma semana em anos diferentes. O Carnaval
ficou numa semana de fevereiro em 2024 e numa semana de março em 2025, então a média pôs **meio
Carnaval em cada uma dessas semanas**. A semana que teve Carnaval saiu mais baixa do que o índice de
meio Carnaval esperava, e as semanas que não tiveram saíram mais altas. Um resíduo de 0,930 é uma
semana sete por cento abaixo do que tendência e sazonalidade previam; 1,082 é oito por cento acima.

O quarto é a **Black Friday**. A data dela segue uma regra, a sexta depois da quarta quinta-feira
de novembro, e a regra a põe numa semana do ano diferente de um ano para o outro. O índice esperava
meia Black Friday em duas semanas, e recebeu uma inteira numa delas.

Essa é a lição geral: **um feriado que muda de lugar não pode ser aprendido de um período fixo**.
Uma decomposição o espalha por todas as posições que ele já ocupou, e deixa para trás um par de
resíduos, um alto e um baixo, onde a verdade era uma queda só. A aula 6 trata feriados móveis como
o que eles são, um efeito de calendário modelado à parte.

## O que procurar

Leia uma série de resíduos com três perguntas, nesta ordem.

1. **Onde estão os maiores valores, e eles têm nome?** Um feriado, uma promoção, uma queda do site,
   uma mudança de preço. Um resíduo grande sem nome é uma pergunta para quem conhece o negócio.
2. **Ele tem ritmo?** Uma ondulação semanal quer dizer que uma sazonalidade semanal escapou; uma
   anual quer dizer que a sazonalidade ficou rígida demais. Nenhuma das duas deveria sobreviver a
   uma boa decomposição.
3. **Ele deriva?** Resíduos que ficam acima de 1 por meses e depois abaixo de 1 por meses querem
   dizer que a tendência ficou suave demais para acompanhar uma mudança real.

Um resíduo limpo não prova que a decomposição está certa. Um resíduo sujo prova que algo está
errado, e costuma dizer o quê.
