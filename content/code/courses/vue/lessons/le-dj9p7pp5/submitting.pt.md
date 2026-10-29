---
title: Enviando, e o que acontece depois
version: 1
---

**Um handler de envio faz quatro coisas, em ordem: impede o envio do próprio navegador, checa, age e
reseta o formulário para a próxima entrada.** Cada passo tem um jeito de dar errado que o aluno nota na
hora, o que faz valer a pena escrevê-los na mesma ordem toda vez.

O handler do planner:

```javascript
function submit() {
  tried.value = true
  if (!valid.value) {
    saved.value = ''
    return
  }
  planner.add({ ...draft })
  saved.value = `Added ${draft.minutes} minutes of ${planner.titles[draft.course]} on ${formatDay(draft.date)}.`
  Object.assign(draft, { course: '', minutes: 30 })
  tried.value = false
  courseField.value.focus()
}
```

e o formulário que o chama, `<form novalidate @submit.prevent="submit">`. Em ordem:

1. **`.prevent`** impede o navegador de mandar o formulário para um endereço e recarregar a página, o que
   a aula 5 mostrou que perderia todos os refs.
2. **`tried.value = true`** liga as mensagens, e um formulário inválido para ali, com a linha de status
   esvaziada para que um "Added…" antigo não fique sobre uma nova falha.
3. **`planner.add({ ...draft })`** entrega à store uma *cópia*. O `addSession` da aula 3 já monta um objeto
   novo a partir dos três campos, então hoje a cópia não muda nada; ela está ali para que o formulário não
   dependa do que a store faz com o que recebe. Uma store que guardasse o próprio objeto estaria segurando
   o rascunho reativo do formulário, e a próxima tecla mudaria uma sessão que já está na lista: a prop de
   objeto da aula 6, num lugar novo.
4. **Reset**: o curso é limpo e os minutos voltam a 30, mas **a data fica**, porque a próxima sessão
   muitas vezes é no mesmo dia; o `tried` volta a false, para que o campo de curso limpo não apareça como
   erro; e o foco volta ao primeiro campo.

A nova action da store é uma linha ao lado do `toggle`, pela regra da aula 3, que esperava desde então
para ser usada:

```javascript
function add(session) {
  sessions.value = addSession(sessions.value, session)
}
```

com `addSession` adicionado ao import de `../planner.js`, e `add` ao que a store retorna.

## Preencha e envie

Escolha guitar, o dia 24, 25 minutos, e adicione:

```
ana@dev:~/vue/planner$ look http://localhost:5173/ --clock 2026-10-21T10:00 --do 'select select guitar' --do 'fill input[type=date] 2026-10-24' --do 'fill input[type=number] 25' --do 'click text=Add the session' --text main
[vite] connecting...
[vite] connected.
-- select select guitar
-- fill input[type=date] 2026-10-24
-- fill input[type=number] 25
-- click text=Add the session
== the text of main
This week
Courses
Statistics

45 of 105 minutes done, goal 180

 25% of the weekly goal

Spanish

30 of 70 minutes done, goal 120

 25% of the weekly goal

Guitar

0 of 45 minutes done, goal 90

 0% of the weekly goal

Week of 19 October 2026
Previous weekNext week
 19 October 2026, Statistics, 45 minutes
 19 October 2026, Spanish, 30 minutes
 21 October 2026, Statistics, 60 minutes (today)
 22 October 2026, Guitar, 20 minutes
 23 October 2026, Spanish, 40 minutes
 24 October 2026, Guitar, 25 minutes
75 of 220 minutes done
Add a session
Course
Choose…
Statistics
Spanish
Guitar
Date
Minutes
Add the session

Added 25 minutes of Guitar on 24 October 2026.
```

**A sessão está na lista da semana, no dia 24, e o total planejado foi de 195 para 220.** A linha de status
diz o que foi adicionado, e o formulário está pronto para a próxima. `select` é uma ação que o `look` tem
para um `<select>`, escolhendo a opção pelo valor; o seu próprio navegador escolhe com o mouse, ou com as
setas depois que o campo tem o foco.

## Envios assíncronos

O planner salva no navegador na hora. Um formulário que envia para um servidor espera, e a espera precisa
de mais duas coisas: **desabilitar o botão enquanto envia**, `:disabled="sending"`, para que um clique
duplo não crie duas sessões; e **dizer o que aconteceu quando falha**, na mesma linha de status, sem
limpar o formulário, para que o aluno tente de novo sem digitar tudo duas vezes.
