---
title: Estilo através da fronteira
version: 1
---

**A página não consegue entrar numa árvore shadow com seletores, mas três coisas atravessam a fronteira de
propósito: propriedades herdadas, propriedades customizadas e as partes que o elemento nomeia.** Isso basta
para um design system, e é o motivo de os tokens da aula 5 serem propriedades customizadas, e não valores
escritos dentro de cada componente.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" aria-label=\"O que atravessa a fronteira do shadow. Da página, quatro coisas tentam chegar ao botão da linha. O seletor main button com fundo vermelho para na fronteira. Propriedades herdadas, como color e font, atravessam. Propriedades customizadas, como --accent, atravessam, e é assim que os tokens chegam ao botão. Uma regra em planner-session::part(button) atravessa, porque o elemento deu nome a essa parte.\"><text x=\"20\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">a página</text><text x=\"560\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">a árvore shadow</text><line x1=\"470\" y1=\"36\" x2=\"470\" y2=\"224\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></line><text x=\"470\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a fronteira</text><text x=\"20\" y=\"56\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">main button { background: red }</text><text x=\"20\" y=\"72\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">um seletor: barrado</text><line x1=\"260\" y1=\"60\" x2=\"462\" y2=\"60\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></line><line x1=\"458\" y1=\"54\" x2=\"466\" y2=\"66\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></line><line x1=\"458\" y1=\"66\" x2=\"466\" y2=\"54\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></line><text x=\"20\" y=\"100\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">color, font-family, line-height</text><text x=\"20\" y=\"116\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">herdadas: atravessam</text><line x1=\"260\" y1=\"104\" x2=\"556\" y2=\"130\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"556.0,130.0 548.4,132.5 548.9,126.3\" fill=\"var(--phosphor)\"></polygon><text x=\"20\" y=\"144\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">--accent: #2f6f4e</text><text x=\"20\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">propriedade customizada: atravessa</text><line x1=\"260\" y1=\"148\" x2=\"556\" y2=\"130\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"556.0,130.0 548.8,133.6 548.5,127.3\" fill=\"var(--phosphor)\"></polygon><text x=\"20\" y=\"188\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">planner-session::part(button)</text><text x=\"20\" y=\"204\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">uma parte com nome: atravessa</text><line x1=\"260\" y1=\"192\" x2=\"556\" y2=\"130\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"556.0,130.0 549.4,134.6 548.1,128.5\" fill=\"var(--phosphor)\"></polygon><rect x=\"560\" y=\"110\" width=\"140\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"630\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">&lt;button part=\"button\"&gt;</text></svg>", "caption": "Seletores param na raiz shadow; valores herdados, propriedades customizadas e partes com nome são os caminhos para dentro."}
```

## Propriedades herdadas, e propriedades customizadas

A árvore shadow herda do seu host do jeito que qualquer filho herda do pai. `color`, `font-family`,
`line-height` e toda outra propriedade herdada entram, então uma linha numa página com fonte serifada
aparece nessa fonte também. **Propriedades customizadas também são herdadas**, e cada token do
`tokens.css` é uma delas. É por isso que o botão do elemento pode dizer
`background: var(--accent, ButtonFace)` e ganhar o verde do planner: a página define `--accent` no `:root`,
o valor desce por herança até o host, e do host para dentro da árvore shadow. Uma troca de tema que muda
`--accent` muda o botão junto, e o elemento não precisa de código nenhum para isso.

O segundo valor de cada `var()` é uma **alternativa**, usada quando a propriedade não está definida, que é
o caso numa página que nunca carregou o `tokens.css`. `ButtonFace`, `ButtonText` e `GrayText` são cores do
sistema: o que o navegador e as configurações da pessoa usam para um botão comum e para texto apagado. Um
elemento com uma alternativa assim ainda parece um botão na página de outra pessoa.

`button` não herda a fonte por padrão, e é por isso que a folha de estilo diz `font: inherit`; sem isso, o
botão sairia na fonte pequena do próprio navegador, o que quer que a página tenha escolhido.

## `:host`, por dentro

Dentro da árvore shadow, `:host` é o próprio elemento. A folha de estilo o usa para fazer da linha um
contêiner flex com um espaço entre as partes. **Uma regra da página vence o `:host`**: se a página escreve
`planner-session { display: block }`, a linha vira um bloco. Essa ordem é proposital, para que a página
sempre possa posicionar e dimensionar o elemento que pôs ali, enquanto o elemento decide como ele é por
dentro.

## `::part`, para o que o elemento oferece

O botão tem `part="button"`. Uma parte é um pedaço com nome que o elemento deixa a página estilizar
diretamente:

```css
planner-session::part(button) {
  border-radius: 0;
}
```

O `main button { background: red }` da página não alcança esse botão, e esta regra alcança, porque o
elemento deu nome a ele. Uma parte é uma promessa, como uma função exportada: renomeie ou remova e uma
página que a estilizava quebra. Dê nome só aos pedaços que você pretende sustentar, e diga quais são na
documentação da biblioteca.

## O conteúdo light continua da página

*JavaScript*, o texto entre as tags, está no light DOM e só é mostrado no slot. Então são as regras da
própria página que o estilizam, exatamente como se ele estivesse em qualquer outro lugar dela; a folha de
estilo do elemento só o alcança por `::slotted()`, e apenas os elementos de primeiro nível que foram
encaixados, não o que está dentro deles. A próxima seção é sobre slots.
