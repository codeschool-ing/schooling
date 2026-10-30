---
title: Do que um componente é feito
version: 1
---

**Um componente é uma classe, um template, e um decorator que junta os dois e diz onde eles vão.** A
classe guarda os dados e o comportamento; o template é o HTML que os desenha; o decorator diz ao
Angular o nome do componente num template e o que mais o template dele pode usar. Todo o resto deste
curso é feito de componentes, então esta seção lê um deles campo a campo.

O que o `ng generate` escreveu na aula 2 tem um template vazio. Dê a ele algo para dizer, e um estilo
próprio:

```html
<!-- src/app/week-summary/week-summary.html -->
<p>This week: nothing planned yet.</p>
```

```css
/* src/app/week-summary/week-summary.css */
p {
  font-weight: 600;
}
```

A classe é a que a CLI escreveu, sem mudança:

```schooling-example
{"language": "typescript", "file": "src/app/week-summary/week-summary.ts", "parts": [
 {"code": "import { Component } from '@angular/core';", "note": "`Component` é o decorator, importado do framework como qualquer outra função."},
 {"code": "@Component({\n  selector: 'app-week-summary',", "note": "O **seletor** é a tag que põe este componente numa página. Todo template que escreve `<app-week-summary />` ganha um."},
 {"code": "  imports: [],", "note": "O que *este* template pode usar além de HTML puro: outros componentes, diretivas e pipes. A próxima seção é sobre esta lista."},
 {"code": "  templateUrl: './week-summary.html',\n  styleUrl: './week-summary.css',\n})", "note": "O template e os estilos, cada um num arquivo ao lado da classe. `template: '<p>…</p>'` e `styles: 'p { … }'` os põem no próprio arquivo, o que serve a um componente de poucas linhas."},
 {"code": "export class WeekSummary {}", "note": "A classe. Vazia por enquanto: um template sem `{{ }}` não lê nada dela. A aula 4 dá campos a ela."}
]}
```

## Standalone é o padrão

Todo componente que você escreve neste curso é **standalone**: ele lista no próprio `imports` o que o
template dele usa, e mais ninguém precisa saber dele. Esse é o padrão desde o Angular 19, por isso o
decorator não diz nada. Código escrito antes disso diz `standalone: true` em todo componente, e código
que não é standalone diz `standalone: false`, que é o assunto da seção desta aula sobre código com
NgModule.

## Os estilos ficam dentro do componente

A regra `p { font-weight: 600 }` do `week-summary.css` não deixa todo parágrafo da página em negrito.
O Angular reescreve os estilos do componente para que valham só no template dele, o que se chama
**view encapsulation** (encapsulamento de view). A próxima seção põe o `WeekSummary` na página, e,
uma vez lá, o `look --html` mostra como isso funciona: com `--raw`, ele mantém os atributos que o
Angular acrescenta.

```
ana@dev:~/planner$ look http://localhost:4200/ --html app-week-summary --raw
[vite] connecting...
[vite] connected.
Angular is running in development mode.
<app-week-summary _nghost-ng-c935675244=""><p _ngcontent-ng-c935675244="">This week: nothing planned yet.</p></app-week-summary>
```

Todo elemento do componente tem o mesmo atributo inventado, `_ngcontent-` e um código. A regra da
folha de estilo do componente é reescrita para combinar com ele, o que o `look --styles` mostra ao
imprimir toda regra que o navegador guarda:

```
ana@dev:~/planner$ look http://localhost:4200/ --styles
[vite] connecting...
[vite] connected.
Angular is running in development mode.
p[_ngcontent-ng-c935675244] { font-weight: 600; }
```

`p` virou `p[_ngcontent-ng-c935675244]`. Um `<p>` em qualquer outro lugar não tem o atributo e mantém
o peso normal. O próprio elemento hospedeiro, `<app-week-summary>`, ganha `_nghost-` no lugar, que é o
que permite a uma folha de estilo estilizar a caixa do próprio componente com `:host`.

Você raramente vai precisar pensar nisso. Importa no dia em que um estilo se recusa a chegar num
elemento, e a resposta quase sempre é que o elemento pertence a outro componente.
