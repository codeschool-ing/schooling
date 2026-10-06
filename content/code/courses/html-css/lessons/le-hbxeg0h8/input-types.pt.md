---
title: Tipos de campo
version: 1
---

`<input>` é um elemento só com muitos comportamentos, escolhidos pelo `type`. O padrão é `text`, uma linha de qualquer coisa. Os outros mudam três coisas: **o que o navegador aceita**, **o que ele oferece para ajudar** e, no celular, **que teclado aparece**.

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>Types · Andorinha Books</title>
  </head>
  <body>
    <main>
      <h1>Field types</h1>
      <form>
        <label for="t-email">Email</label> <input id="t-email" type="email">
        <label for="t-tel">Phone</label> <input id="t-tel" type="tel">
        <label for="t-qty">Copies</label> <input id="t-qty" type="number">
        <label for="t-date">Pick-up date</label> <input id="t-date" type="date">
        <label for="t-pw">Password</label> <input id="t-pw" type="password">
        <label for="t-q">Search</label> <input id="t-q" type="search">
      </form>
    </main>
  </body>
</html>
```

```
ana@laptop:~/site$ probe types.html tree
- main:
  - heading "Field types" [level=1]
  - text: Email
  - textbox "Email"
  - text: Phone
  - textbox "Phone"
  - text: Copies
  - spinbutton "Copies"
  - text: Pick-up date
  - textbox "Pick-up date"
  - text: Password
  - textbox "Password"
  - text: Search
  - searchbox "Search"
```

Leia os papéis: a maioria é **textbox**, mas o número virou um **spinbutton**, que um leitor de tela anuncia com o valor e deixa o usuário aumentar e diminuir, e o campo de busca virou um **searchbox**. O tipo é informação que o navegador repassa.

O que cada tipo muda:

| tipo | aceita | no celular |
| --- | --- | --- |
| `email` | algo com cara de endereço, conferido quando o formulário é enviado | um teclado com `@` e `.` |
| `tel` | qualquer coisa: números de telefone variam demais entre países para conferir | o teclado numérico |
| `number` | números, com `min`, `max` e `step` | dígitos, às vezes com sinal |
| `date` | uma data, escolhida num calendário que o navegador desenha | um seletor de data |
| `password` | qualquer coisa, desenhada como pontos | um teclado que não sugere palavras |
| `search` | qualquer coisa; alguns navegadores acrescentam um botão para limpar | um teclado cujo Enter diz Ir ou Buscar |
| `url` | um endereço completo começando com um esquema, como `https://` | um teclado com `/` e `.com` |

## Duas armadilhas

**`number` é para quantidades, não para qualquer coisa feita de dígitos.** Um CEP, um número de cartão ou um telefone é uma sequência de dígitos, não um valor: ninguém soma dois CEPs. Como `type="number"` um CEP não consegue guardar o hífen, um servidor que o lê como número perde o zero inicial de `05422`, e a roda do mouse sobre o campo pode mudá-lo em um. Use `type="text"` com `inputmode="numeric"`, que pede ao celular o teclado numérico sem transformar o valor em número.

**`date` devolve um formato fixo, seja o que for que o leitor vê.** O calendário é desenhado na convenção do próprio leitor, 08/10/2026 no Brasil e 10/08/2026 nos Estados Unidos, e o valor enviado é sempre `2026-10-08`. Isso ajuda o servidor e é um motivo para não montar um campo de data com três caixas de texto.
