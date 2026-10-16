---
title: Precisão e revocação
version: 1
---

Duas perguntas importam sobre os créditos, e cada uma é uma razão da matriz de confusão.

**Precisão: dos créditos enviados, quantos chegaram a quem ia sair?** Verdadeiros positivos sobre tudo o
que o modelo chamou de positivo, 348 sobre 348 + 363. No corte de equilíbrio ela é **0,489**: um pouco
menos da metade dos créditos cai em quem sai. A precisão é a métrica do orçamento da equipe de
retenção, porque todo falso positivo é R$ 40 gastos com ninguém.

**Revocação (*recall*): de quem ia sair, quantos receberam crédito?** Verdadeiros positivos sobre todos
os positivos de verdade, 348 sobre 348 + 1.136. No mesmo corte ela é **0,235**: o modelo alcança um
quarto de quem sai. A revocação é a métrica das pessoas que a empresa perde sem uma palavra, porque todo
falso negativo é alguém que saiu e nunca foi procurado. Ela também se chama **sensibilidade**, ou **taxa
de verdadeiros positivos**.

Nenhuma das duas inclui os verdadeiros negativos, e é por isso que as duas significam algo numa classe
rara.

## A troca entre elas

Leia juntas as colunas de precisão e revocação do `metrics.py`:

| corte | precisão | revocação |
|---|---|---|
| 0,5 | 0,603 | 0,079 |
| 0,4 | 0,589 | 0,131 |
| 0,278 | 0,489 | 0,235 |
| 0,2 | 0,417 | 0,328 |
| 0,1 | 0,283 | 0,493 |

**À medida que o corte cai, a revocação sobe e a precisão cai.** Um corte mais baixo manda mais
créditos, alcança mais gente que sai e gasta mais deles com quem ia ficar. Não há corte que vença as
duas, e qualquer relatório que cite só uma delas pode ficar bonito escolhendo o corte: uma revocação de
0,9 é fácil, num corte baixo o bastante para mandar crédito a todo mundo.

**Por isso as duas são sempre relatadas juntas, num corte declarado.** E a escolha do corte não é uma
pergunta que nenhuma delas responde. A tabela da aula 1 deu um preço a cada célula, e a aula 11
transforma esses preços num corte. Precisão e revocação dizem o que acontece num corte; o negócio diz
que corte ele pode pagar.
