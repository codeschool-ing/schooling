---
title: O planner com o JavaScript desligado
version: 1
---

**Melhoria progressiva quer dizer construir a página para que ela funcione primeiro como HTML puro, e
depois deixar o JavaScript melhorá-la.** Um link que funciona sem JavaScript, um formulário que o
navegador consegue enviar sozinho, uma página que o servidor renderiza inteira: essa é a base.
Navegação no cliente, um formulário enviado sem recarregar, uma animação, são o que o JavaScript
acrescenta por cima. Se o script não chegar, num trem lento, atrás do proxy de uma empresa, num
navegador com uma extensão que o bloqueia, ou porque um deploy o quebrou, a base continua lá e a pessoa
ainda consegue fazer o que veio fazer.

A aula 13 levou o planner até a metade do caminho. O servidor renderiza cada página com os seus dados,
então com o JavaScript desligado ela pelo menos pode ser **lida**. O `look --no-js` abre uma página num
navegador com o JavaScript desligado:

```
ana@dev:~/planner$ look http://localhost:5173/courses/guitar --no-js --click 'Previous week'
-- click Previous week
at /courses/guitar
title: Guitar · Study planner
- main:
  - heading "Guitar" [level=1]
  - paragraph:
    - button "Previous week"
    - text: Week of 19 Oct 2026
    - button "Next week"
  - list:
    - listitem:
      - checkbox "20 Oct 2026, 45 min"
      - text: 20 Oct 2026, 45 min
  - paragraph: 45 minutes for Guitar this week (0 h 45 min)
  - text: Date
  - textbox "Date"
  - text: Minutes
  - spinbutton "Minutes": "30"
  - button "Add session"
```

**A semana não se mexeu.** O botão é um `<button>` com um `onclick`, e sem JavaScript ninguém está
escutando. Acrescentar uma sessão não vai melhor:

```
ana@dev:~/planner$ look http://localhost:5173/courses/guitar --no-js --fill 'Date=2026-10-21' --click 'Add session'
-- fill Date=2026-10-21
-- click Add session
at /courses/guitar
title: Guitar · Study planner
- main:
  - heading "Guitar" [level=1]
  - paragraph:
    - button "Previous week"
    - text: Week of 19 Oct 2026
    - button "Next week"
  - list:
    - listitem:
      - checkbox "20 Oct 2026, 45 min"
      - text: 20 Oct 2026, 45 min
  - paragraph: 45 minutes for Guitar this week (0 h 45 min)
  - text: Date
  - textbox "Date"
  - text: Minutes
  - spinbutton "Minutes": "30"
  - button "Add session"
```

Nenhuma sessão no dia 21. Sem script para chamar `preventDefault()`, o navegador fez o que um navegador
faz com um formulário: enviou, com `GET`, para o próprio endereço da página, com os campos numa query
depois de um `?`, e carregou a resposta. A query veio vazia, porque os inputs não têm `name` e um campo
sem nome não é enviado, e o servidor renderizou a página de novo a partir do mesmo arquivo. Nada mudou,
e nada avisou.

Tudo o que o planner faz quando algo é clicado acontece no navegador, na memória, e some no próximo
recarregamento. Esta aula leva essas mudanças para o servidor, onde elas são salvas, e faz isso com
formulários, para que funcionem **primeiro com o JavaScript desligado** e depois, com `use:enhance`, sem
recarregar a página quando o JavaScript está ligado. O nome que o SvelteKit dá à metade do servidor é
**form action**.
