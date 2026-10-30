---
title: Quando descrever não basta
version: 1
---

**Quase tudo no React é uma descrição**: você diz como a tela deve ficar, e o React muda o DOM para
combinar. Algumas coisas o navegador não deixa descrever. Ele só as faz quando alguém pede, num momento
específico, chamando um método num elemento específico:

| o que você quer | do que o navegador precisa | por que uma descrição não consegue dizer |
|---|---|---|
| mover o foco do teclado | `element.focus()` | o foco é um evento no tempo, não uma propriedade da página |
| abrir um diálogo como modal | `dialog.showModal()` | o atributo `open` o abre, mas não como modal |
| trazer algo para a vista | `element.scrollIntoView()` | rolar é uma ação |
| saber o tamanho com que algo saiu | `element.getBoundingClientRect()` | só o navegador sabe, depois do layout |
| entregar um nó a código que não é React | um mapa, um gráfico, um editor | esse código quer o próprio elemento |

Para cada um destes você precisa do elemento, e **um ref é como o React o entrega a você**. A aula 7
usou um para focar o título da tela do curso: o `useRef` cria a caixa, `ref={heading}` pede ao React
que ponha o `<h1>` nela, e um efeito chama `heading.current?.focus()`.

Três regras deixam isso seguro, e elas vêm de como o React funciona, não de gosto:

- **Use o elemento num efeito ou num handler de evento, nunca durante a renderização.** Na primeira
  renderização o elemento ainda não existe, então `ref.current` ainda é `null`; e uma renderização
  precisa ser pura, então não deve mudar nada no navegador, nem o foco.
- **Peça, não rearrume.** Chamar `focus()` ou `showModal()` pede ao navegador algo que é dele.
  Acrescentar ou remover filhos de um elemento que o React renderiza, ou mudar um texto que o React pôs
  lá, mexe no que o React acredita ser dele, e a próxima atualização pode sobrescrever a sua mudança ou
  falhar num nó que não está mais onde o React o deixou.
- **Prefira o elemento da própria plataforma** quando existe um. O navegador já sabe como um diálogo
  modal deve se comportar: para onde o foco vai, o que o Escape faz, o que um leitor de tela pode
  alcançar. Um código que reconstrói isso com `<div>`s precisa acertar cada um desses pontos à mão.

O planejador precisa da segunda linha dessa tabela. O formulário que acrescenta uma sessão fica no pé da
tela do curso, sempre visível, e vai para um diálogo que abre quando você pede.
