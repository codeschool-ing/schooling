---
title: Quando nenhuma busca serve
version: 1
---

**Às vezes o elemento que você quer não tem papel, nem rótulo, nem texto próprio, e a biblioteca
oferece três saídas, na ordem de quanto cada uma abre mão.** Precisar da terceira é sinal de que quem
precisa mudar é a página, e não o teste.

## Estreite a busca: `within`

A página inicial tem uma lista de cursos, cada item com um link e uma frase. "Os minutos do item de
JavaScript" não é uma busca, mas são duas: ache o item, depois procure dentro dele.

```typescript
const item = screen.getByRole("link", { name: "JavaScript" }).closest("li")!;
expect(within(item).getByText("90 min this week")).toBeInTheDocument();
```

O `closest("li")` sobe até o item, e o `within(item)` limita a segunda busca a ele. Cada passo continua
sendo algo que uma pessoa consegue ver.

## Veja o que a biblioteca vê: `screen.debug`

Quando uma busca falha e você não entende por quê, o `screen.debug()` mostra a página como a
biblioteca a tem, o mesmo despejo que o teste vermelho mostrou mais acima nesta aula. O
`logRoles(document.body)`, da `@testing-library/dom`, mostra cada elemento pelo papel e pelo nome que as
buscas achariam, e é a resposta mais rápida para "por que o `getByRole("button", { name: "Done" })` não
acha o meu botão".

## O último recurso: `data-testid`

Um `data-testid="week-total"` no parágrafo faria o `getByTestId("week-total")` funcionar, e funcionaria
para sempre, porque nada além do teste o lê. Esse é o problema. O total da semana do planner é achado
pelo texto, `getByText("This week: 105 min")`, o que também confere que a frase diz o que deve dizer.
**Use um test id para o que realmente não tem uma alça perceptível**, como um canvas que um teste
precisa localizar, e trate cada um como uma pergunta sobre se uma pessoa conseguiria achar aquela
coisa.

## O que deixar de lado

- **O `container` e o `querySelector`.** Eles continuam lá, e a aula 2 mostra até onde eles levam. Todo
  seletor é um fato sobre o código, e não sobre a página.
- **Testes de snapshot da página inteira.** O `expect(document.body.innerHTML).toMatchSnapshot()`
  registra a marcação e falha em qualquer mudança, inclusive na correção dos rótulos desta aula, então
  falha numa refatoração e não tem nada a dizer sobre se a mudança estava certa. Um snapshot que
  ninguém revisa é um teste de que a página não mudou, que raramente é a pergunta.
