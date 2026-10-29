---
title: Validação, à mão
version: 1
---

**Validação é um `computed`: os valores do formulário entram, sai uma mensagem por campo, e uma mensagem
vazia quer dizer que o campo está certo.** Nenhuma biblioteca é necessária para um formulário de três
campos, e escrever a validação à mão uma vez mostra o que toda biblioteca de validação faz por você:
decidir o que está errado, e decidir *quando* dizer.

O formulário do planner guarda os seus três campos num objeto `reactive`, o caso que a aula 2 deu para o
`reactive`: campos que sempre viajam juntos. As regras, do `SessionForm.vue`, que a última seção desta aula
mostra inteiro:

```javascript
const draft = reactive({ course: '', date: firstDate, minutes: 30 })
const tried = ref(false)

const errors = computed(() => ({
  course: draft.course ? '' : 'Choose a course.',
  date: draft.date ? '' : 'Choose a date.',
  minutes:
    Number.isInteger(draft.minutes) && draft.minutes >= 5 && draft.minutes <= 240
      ? ''
      : 'Between 5 and 240 whole minutes.',
}))
const valid = computed(() => Object.values(errors.value).every((e) => e === ''))
// Errors are shown only once the student has tried to submit.
const shown = computed(() => (tried.value ? errors.value : {}))
```

## O quê, e quando

**O `errors` responde "o que está errado", sempre**, e nunca fica velho, porque é calculado. **O `shown`
responde "o que dizer agora"**, e não diz nada até o aluno apertar o botão uma vez. Mostrar todos os erros
desde o primeiro momento, num formulário que o aluno ainda não tocou, o recebe com três mensagens
vermelhas para campos a que ele ainda não chegou. Mostrá-los só no envio, e depois ao vivo enquanto ele
corrige cada um, é o padrão que as próximas duas seções assumem.

Cada mensagem é uma frase que diz o que fazer, não o que deu errado nos termos do código: *Choose a
course*, e não *course is required*; *Between 5 and 240 whole minutes*, e não *invalid value*. A regra é
um fato sobre o planner, posto onde ficam as regras do planner: uma sessão de estudo de mais de quatro
horas provavelmente é um erro de digitação.

## As checagens do próprio navegador, desligadas

O formulário tem `novalidate`. Sem ele, o navegador checaria `min="5"` e `max="240"` sozinho no envio e
mostraria o seu próprio balão, com as suas palavras e no seu idioma, antes de o handler do Vue rodar. Os
atributos ficam no input, porque dizem ao campo numérico do navegador até onde as setas vão e dizem a um
leitor de tela qual é o intervalo; o `novalidate` só impede o navegador de bloquear o envio, para que um
único conjunto de mensagens, o do planner, seja mostrado, conectado para um leitor de tela como a próxima
seção descreve.

## A regra mora no formulário, e na store

O `errors` barra uma sessão ruim no formulário. Não é a única defesa: qualquer coisa que adicione uma
sessão sem o formulário, um teste, uma importação futura, passaria por cima dele. O `add` da store aceita
o que recebe, e um planner com servidor checaria de novo ali, porque um servidor nunca confia num
navegador. Para um planner cujos dados vivem no próprio navegador do aluno, a checagem do formulário basta.
