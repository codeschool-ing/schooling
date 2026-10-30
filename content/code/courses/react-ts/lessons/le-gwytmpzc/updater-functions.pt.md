---
title: Quando o próximo valor depende do anterior
version: 1
---

**Quando o valor novo é calculado a partir do antigo, passe uma função ao setter.** O React a chama
com o valor mais recente, inclusive qualquer mudança enfileirada antes no mesmo evento, e usa o que
ela devolve:

```
ana@dev:~/planner$ sed -i 's|setMonday(addDays(monday, 7))|setMonday((m) => addDays(m, 7))|' src/TwoWeeks.tsx
ana@dev:~/planner$ sed -n 12,16p src/TwoWeeks.tsx
    setMonday((m) => addDays(m, 7))
    setMonday((m) => addDays(m, 7))
    console.log('after both calls, monday is', monday)
  }
  return (
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'click button Two weeks on' | head -n 11
-- click button Two weeks on
after both calls, monday is 2026-10-19
- main:
  - heading "Study planner" [level=1]
  - navigation "Week":
    - button "Previous week"
    - button "Next week"
  - button "Two weeks on"
  - region "This week":
    - paragraph: Week of 2 Nov 2026
    - paragraph: 0 of 0 minutes done
ana@dev:~/planner$ sed -i '/TwoWeeks/d' src/App.tsx && rm src/TwoWeeks.tsx
```

A semana andou duas semanas, até 2 de novembro. O React enfileirou duas funções e as rodou em ordem:
a primeira recebeu o 19 e devolveu o 26, a segunda recebeu o 26 e devolveu 2 de novembro. O registro
ainda diz `2026-10-19`, e deveria: `monday` nesta renderização continua sendo o retrato de sempre. Só
a fila viu o valor intermediário.

Então há duas formas, e a regra para escolher é curta:

| você escreve | o React faz | use quando |
|---|---|---|
| `setMonday(addDays(monday, 7))` | substitui o valor pelo que você calculou a partir desta renderização | o valor novo não depende do antigo, ou esta é a única atualização do evento |
| `setMonday((m) => addDays(m, 7))` | enfileira a função e a roda sobre o valor mais recente | o valor novo é calculado a partir do antigo, e pode haver mais de uma atualização na fila |

A segunda forma nunca está errada onde a primeira está certa, e é o hábito mais seguro quando uma
atualização é calculada a partir do valor anterior. O `WeekNav` mantém a primeira forma porque chama
o setter uma vez por clique, a partir de um valor que o pai acabou de renderizar; o `toggleDone` do
planejador, na seção depois da próxima, usa a segunda.

O `TwoWeeks` sai, e o `App` volta a ser o da aula 3. O último comando da transcrição removeu os dois.
