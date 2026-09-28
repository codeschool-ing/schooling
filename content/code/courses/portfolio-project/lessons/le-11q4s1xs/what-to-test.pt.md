---
title: O que testar, e o que não
version: 1
---

Testes custam tempo para escrever e tempo para continuar funcionando conforme o código muda. Num projeto
de seis semanas, gaste esse tempo onde uma falha seria **errada**, e não só **visível**. Três lugares quase
sempre se qualificam:

- **As regras.** O que o sistema recusa e o que muda de estado sozinho. No loanbook: o segundo
  empréstimo, a devolução de um item que está na prateleira, a data em que um empréstimo atrasa.
- **O bug que você acabou de corrigir.** Um bug que aconteceu uma vez pode acontecer de novo, e um teste
  para ele é a única coisa que o impede de voltar sem ninguém notar.
- **A borda de uma regra.** *Atrasado no dia seguinte ao vencimento* tem uma borda: o próprio dia do
  vencimento. Um teste de cada lado dela vale mais que dez no meio.

E três lugares que num projeto pequeno em geral não valem a pena. **Getters e encanamento** só levam um valor
de um lugar a outro. **O framework ou a biblioteca** têm os próprios testes. E **o layout exato de uma
página** muda toda semana, e você vê as falhas dele de qualquer jeito.

A lista do loanbook é curta e segue o briefing da aula 4 quase linha a linha:

| teste | a linha do briefing |
|---|---|
| an item cannot be lent twice | *um segundo empréstimo de um item que está fora é recusado, dizendo com quem está* |
| a returned item can be lent again | *um item devolvido aparece como disponível na hora* |
| a loan is overdue the day after it is due | *um empréstimo fica atrasado no dia seguinte ao vencimento* |
| a borrower made of spaces is refused | o bug da aula 9 |
| a lent item shows who has it; an item that is in cannot come back; an unknown item is not found | o resto das regras |
