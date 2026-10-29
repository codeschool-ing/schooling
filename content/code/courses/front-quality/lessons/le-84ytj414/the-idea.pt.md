---
title: Ache as coisas do jeito que uma pessoa acha
version: 1
---

**A Testing Library é um conjunto de funções para achar elementos numa página pelo que uma pessoa
percebe: o papel de um controle, o nome dele, o rótulo, o texto escrito nele.** Ela não roda testes;
quem faz isso continua sendo o Vitest. Ela troca o `querySelector(".tick")` da aula 2 por
`getByRole("button", { name: "Done" })`, e essa troca tem duas consequências.

A primeira é a que a aula 1 pediu. Uma classe é detalhe de implementação, e o nome de um botão não é:
renomeie `.tick` para `.done-button` e um teste que pede *o botão chamado Done* continua passando,
porque nada que uma pessoa vê mudou. **Um teste escrito com essas buscas quebra quando a experiência
quebra**, e sobrevive à refatoração.

A segunda é o motivo de este curso pôr a biblioteca aqui e não só num curso de testes. Cada busca lê a
página do jeito que a tecnologia assistiva a lê. O `getByRole` pergunta à **árvore de
acessibilidade**, a estrutura que um navegador monta para os leitores de tela a partir de elementos,
papéis e nomes, e o `getByLabelText` acha um campo do jeito que um leitor de tela o anuncia. **Se um
teste não acha um controle pelo nome, quem não enxerga a tela também não acha.** Os testes viram uma
primeira checagem de acessibilidade, de graça, e esta aula acha um defeito real no planner desse
jeito.

## Qual busca usar

A própria documentação da biblioteca as ordena, e vale a pena aprender a ordem como ela é:

| | busca | acha |
|---|---|---|
| 1 | `getByRole` | um elemento pelo papel e pelo nome acessível: `button` "Done", `link` "JavaScript", `heading` "Study planner" |
| 2 | `getByLabelText` | um campo de formulário pelo texto do `<label>` dele |
| 3 | `getByPlaceholderText` | um campo pelo placeholder, quando não há rótulo, o que já é um problema |
| 4 | `getByText` | um elemento pelo texto dentro dele, para o que não é interativo |
| 5 | `getByDisplayValue` | um campo pelo valor que ele tem agora |
| 6 | `getByAltText` | uma imagem pelo `alt` |
| 7 | `getByTitle` | um elemento pelo atributo `title` |
| 8 | `getByTestId` | um elemento por um `data-testid` escrito só para os testes |

Comece pelo topo e desça só quando a de cima não consegue dizer o que você quer. A última é uma saída
de emergência: uma pessoa nunca vê um test id, então um teste que precisa de um está testando algo que
ninguém consegue achar também.

## Três prefixos

Cada busca vem em três formas, e o prefixo diz o que acontece quando nada corresponde:

- **`getBy…`** devolve o elemento, e lança um erro se não houver nenhum ou houver mais de um. Use para
  o que precisa estar lá.
- **`queryBy…`** devolve `null` quando não há nenhum. Use para afirmar que algo **não** está lá, e só
  para isso.
- **`findBy…`** devolve uma promise que espera, tentando de novo, até o elemento aparecer, ou falha
  depois de um segundo. Use para o que chega depois, como dados de um servidor.

Cada uma também tem a forma `…All…`, `getAllByRole` e assim por diante, que devolve uma lista.
