---
title: Escolhas: radio, checkbox, select e textarea
version: 1
---

Nem toda resposta é digitada. Quando as respostas possíveis são conhecidas de antemão, o formulário as oferece, e o HTML tem um elemento para cada formato de escolha.

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>Order · Andorinha Books</title>
  </head>
  <body>
    <main>
      <h1>Order a book</h1>
      <form action="order" method="get">
        <fieldset>
          <legend>Format</legend>
          <label><input type="radio" name="format" value="paperback" checked> Paperback</label>
          <label><input type="radio" name="format" value="hardback"> Hardback</label>
        </fieldset>
        <fieldset>
          <legend>Extras</legend>
          <label><input type="checkbox" name="extra" value="wrap"> Gift wrap</label>
          <label><input type="checkbox" name="extra" value="card"> A card</label>
          <label><input type="checkbox" name="extra" value="bag"> A cloth bag</label>
        </fieldset>
        <label for="shop">Collect from</label>
        <select id="shop" name="shop">
          <option value="pinheiros">Pinheiros</option>
          <option value="centro" selected>Centro</option>
        </select>
        <label for="notes">Notes</label>
        <textarea id="notes" name="notes" rows="3"></textarea>
        <button>Order</button>
      </form>
    </main>
  </body>
</html>
```

**Botões de rádio são uma escolha entre várias.** O que os torna um grupo é o `name` compartilhado: os dois são `name="format"`, então marcar um desmarca o outro. Cada um leva o `value` que é enviado quando é o marcado. `checked` marca a escolha inicial; sem ele, um grupo pode ser enviado sem nada escolhido.

**Checkboxes são qualquer número de respostas sim-ou-não independentes.** Estes três também compartilham `name="extra"`, mas compartilhar um nome não os amarra: cada um é marcado por conta própria.

**`<select>` é uma escolha numa lista**, desenhada como menu suspenso. Cada `<option>` tem o `value` enviado e o texto mostrado, e `selected` escolhe a inicial. **`<textarea>` é texto livre em várias linhas**, e é um dos elementos da aula 1 que leem o conteúdo como texto, então sempre precisa da tag de fechamento.

**`<fieldset>` e `<legend>` agrupam controles relacionados sob uma legenda.** Sem eles, um leitor de tela no botão de rádio ouve *Paperback, botão de rádio* e tem de adivinhar a pergunta. Com eles:

```
ana@laptop:~/site$ probe choices.html tree
- main:
  - heading "Order a book" [level=1]
  - group "Format":
    - text: Format
    - radio "Paperback" [checked]
    - text: Paperback
    - radio "Hardback"
    - text: Hardback
  - group "Extras":
    - text: Extras
    - checkbox "Gift wrap"
    - text: Gift wrap
    - checkbox "A card"
    - text: A card
    - checkbox "A cloth bag"
    - text: A cloth bag
  - text: Collect from
  - combobox "Collect from":
    - option "Pinheiros"
    - option "Centro" [selected]
  - text: Notes
  - textbox "Notes"
  - button "Order"
```

Cada grupo é um **group** nomeado pela legenda, então quem escuta ouve *Format, grupo* antes das opções, e o select é um **combobox** nomeado pelo rótulo.

## O que as escolhas enviam

Enviado sem mexer em nada, e depois com um formato, dois extras e uma nota escolhidos:

```
ana@laptop:~/site$ probe choices.html send button
GET /order?format=paperback&shop=centro&notes=
ana@laptop:~/site$ probe choices.html check 'input[value=hardback]' check 'input[value=wrap]' check 'input[value=bag]' fill '#notes' 'Gift for Ana, 8 Oct' send button
GET /order?format=hardback&extra=wrap&extra=bag&shop=centro&notes=Gift+for+Ana%2C+8+Oct
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"Os sete controles do formulário de encomenda à esquerda, e a requisição que o navegador monta com eles à direita. O radio marcado format=hardback, as caixas marcadas extra=wrap e extra=bag, o select shop=centro e o notes= vazio são enviados. O radio não marcado e a caixa não marcada não são. A requisição diz GET /order?format=hardback&amp;extra=wrap&amp;extra=bag&amp;shop=centro&amp;notes=.\"><defs><marker id=\"ah3\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"18\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">o que há no formulário</text><rect x=\"20\" y=\"34\" width=\"330\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"48\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">format=hardback</text><text x=\"340\" y=\"48\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">radio, marcado</text><rect x=\"20\" y=\"68\" width=\"330\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"30\" y=\"82\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper-dim)\">format=paperback</text><text x=\"340\" y=\"82\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">radio, não marcado</text><rect x=\"20\" y=\"102\" width=\"330\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"116\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">extra=wrap</text><text x=\"340\" y=\"116\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">checkbox, marcado</text><rect x=\"20\" y=\"136\" width=\"330\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"30\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper-dim)\">extra=card</text><text x=\"340\" y=\"150\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">checkbox, não marcado</text><rect x=\"20\" y=\"170\" width=\"330\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"184\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">extra=bag</text><text x=\"340\" y=\"184\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">checkbox, marcado</text><rect x=\"20\" y=\"204\" width=\"330\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"218\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">shop=centro</text><text x=\"340\" y=\"218\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">select, opção escolhida</text><rect x=\"20\" y=\"238\" width=\"330\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"252\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">notes=</text><text x=\"340\" y=\"252\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">textarea, vazio</text><text x=\"380\" y=\"18\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">o que o navegador envia</text><rect x=\"380\" y=\"34\" width=\"320\" height=\"96\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"394\" y=\"54\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--phosphor)\">GET /order?</text><text x=\"394\" y=\"75\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">format=hardback</text><text x=\"394\" y=\"96\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">&amp;extra=wrap&amp;extra=bag</text><text x=\"394\" y=\"117\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">&amp;shop=centro&amp;notes=</text><path d=\"M352 120 C 366 120, 366 90, 378 90\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#ah3)\"></path><text x=\"380\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">Todo campo com nome e valor vai,</text><text x=\"380\" y=\"179\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">na ordem da página. Uma caixa</text><text x=\"380\" y=\"198\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">que ninguém marcou não vai;</text><text x=\"380\" y=\"217\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">um campo de texto vazio vai</text><text x=\"380\" y=\"236\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">sem nada depois do =.</text></svg>", "caption": "Um formulário é uma lista de pares nome=valor. As linhas tracejadas são controles que existem na página e não enviam nada."}
```

A primeira requisição não tem `extra` nenhum. **Uma checkbox desmarcada não envia nada**, nem `extra=` nem `extra=off`. O servidor só sabe que ninguém quis embrulho para presente pela ausência, então precisa tratar um nome que falta como *não*. A segunda requisição tem `extra` duas vezes, uma por caixa marcada, e o servidor lê o nome como lista. E `notes=` é enviado mesmo vazio, porque um campo de texto sempre tem valor, ainda que vazio.
