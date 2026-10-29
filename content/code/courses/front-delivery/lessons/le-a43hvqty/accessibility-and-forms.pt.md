---
title: Acessibilidade e formulários
version: 1
---

**A árvore shadow está na árvore de acessibilidade como o resto da página, então um elemento feito de
elementos HTML de verdade sai quase todo acessível de graça.** O botão da linha é um `<button>`: tem o
papel de botão, é alcançado com Tab, Enter e Espaço o apertam, e um leitor de tela o anuncia como *Mark
done, botão*. Nada disso precisou de uma linha de código, e tudo teria de ser refeito à mão numa `<div>`
com um listener de clique.

O que a fronteira muda é a parte do HTML que funciona por referência.

## Referências não atravessam

`<label for="x">`, `aria-labelledby="x"` e `aria-describedby="x"` apontam todos para um id, e um id é
privado da sua árvore. Um rótulo na página não consegue nomear um input dentro de uma árvore shadow, e
uma descrição dentro da árvore não pode ser apontada a partir da página.

Há três respostas, em ordem de preferência:

1. **Mantenha a referência de um lado só.** Ponha o rótulo e o que ele rotula na mesma árvore. O botão do
   planner leva o próprio texto, então não precisa de referência nenhuma.
2. **Deixe o host levar o nome.** `aria-label` em `<planner-session>` nomeia o elemento host, e uma página
   pode escrevê-lo como qualquer atributo.
3. **Defina-o por dentro.** O elemento sabe o que mostra, então pode rotular os próprios pedaços.

O botão do planner mostra que o terceiro caso não é teórico. O botão de cada linha se chama *Mark done*,
então quem usa leitor de tela e percorre uma semana com Tab ouve o mesmo nome duas vezes, sem nada que
diferencie as linhas. O axe não aponta isso, já que todo botão tem nome. Uma correção dentro do `#render`
seria uma linha como ``button.setAttribute("aria-label", `Mark ${course} ${date} done`)``. O elemento
desta aula não tem essa linha; acrescentá-la, com um teste que peça o novo nome, é uma boa primeira mudança
a fazer nele.

## Foco

Um elemento host não recebe foco sozinho. Quando um elemento envolve um único input,
`attachShadow({ mode: "open", delegatesFocus: true })` faz com que focar o host, com um clique no padding
dele ou com `element.focus()`, leve o foco ao primeiro elemento focável lá dentro, e deixa a página
estilizar o host com `:focus-within`. A linha não tem nada antes do botão para onde delegar, então não usa
a opção.

## Formulários

**Um `<input>` dentro de uma árvore shadow não faz parte do `<form>` da página.** Enviar o formulário o
deixa de fora, e `form.reset()` não mexe nele. Um elemento que deve ser um campo de formulário diz isso, e
participa por meio de um objeto que o navegador lhe dá, o `ElementInternals`:

```typescript
class PlannerMinutes extends HTMLElement {
  static formAssociated = true;
  #internals = this.attachInternals();

  set value(minutes: number) {
    this.#internals.setFormValue(String(minutes));
    this.#internals.setValidity(minutes > 0 ? {} : { rangeUnderflow: true }, "Plan at least one minute");
  }
}
```

Com `formAssociated`, o elemento pode ser nomeado por um `<label for>` da página, envia o valor dado ao
`setFormValue` sob o atributo `name` dele, e `setValidity` faz o formulário se recusar a enviar e mostrar a
mensagem, como um campo nativo faria. Esta classe é uma ilustração e não está na biblioteca; o planner não
tem formulário desse tipo.
