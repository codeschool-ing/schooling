---
title: Signals num serviço, NgRx, ou o SignalStore do NgRx
version: 1
---

**Comece com um serviço de signals, e passe para uma biblioteca quando a aplicação, ou a equipe,
ficar maior do que uma pessoa consegue ter na cabeça.** O planner nunca vai ficar. Muitas aplicações de
empresa ficaram, anos atrás, e você vai encontrar o NgRx nelas.

| | um serviço de signals | NgRx Store | NgRx SignalStore |
|---|---|---|---|
| o estado | signals privados num serviço | um objeto para a aplicação inteira | signals, montados por uma função a partir de features |
| mudá-lo | um método | despachar uma action para um reducer | um método, declarado com `withMethods` |
| lê-lo | `computed` | seletores | `computed`, declarado com `withComputed` |
| o que acrescenta | nada para instalar | um registro de toda mudança, devtools, uma forma só para toda funcionalidade | convenções e features reutilizáveis, com menos cerimônia que o Store |
| o que custa | disciplina que a equipe mantém sozinha | actions, reducers e seletores para cada mudança, e um pacote | um pacote, e o jeito dele de fazer as coisas |

O **NgRx SignalStore**, no `@ngrx/signals`, é a mais nova das duas bibliotecas do NgRx: um store feito
de signals, montado por uma função a partir de partes como `withState` e `withMethods`, muito mais
perto do que o planner já faz. Código escrito desde a chegada dos signals muitas vezes o usa onde
código anterior usava o Store.

Seja qual for o usado, as perguntas da aula 11 decidem onde um pedaço de estado vai: é um fato que mais
de uma tela lê, ou assunto de uma tela só? Uma biblioteca muda como a resposta é escrita, não qual é a
resposta.

```
ana@dev:~/planner$ git status --short
 M src/app/course-sessions/course-sessions.ts
?? src/app/preferences.ts
```

```
ana@dev:~/planner$ git add -A && git commit -q -m "State: a preference store that lasts between visits"
```
