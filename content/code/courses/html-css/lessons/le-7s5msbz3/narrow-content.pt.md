---
title: Palavras longas e tabelas largas numa tela estreita
version: 2
---

Um layout pode estar perfeito e a página ainda rolar para o lado, porque um pedaço de **conteúdo** é mais largo que a tela. Os dois culpados de costume são uma sequência longa sem espaços, como um endereço web, e uma tabela:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Andorinha Books</title>
    <style>
      body { margin: 0; padding: 0 1rem; font-family: system-ui, sans-serif; }
      th, td { padding: 0.25rem 0.75rem; text-align: left; white-space: nowrap; }
    </style>
  </head>
  <body>
    <main>
      <h1>Events</h1>
      <p>Our catalogue is at https://andorinha.example/catalogue/second-hand/poetry-and-plays</p>
      <table>
        <caption>Events this week</caption>
        <thead>
          <tr><th scope="col">Day</th><th scope="col">Time</th><th scope="col">Event</th><th scope="col">Places</th></tr>
        </thead>
        <tbody>
          <tr><td>Thursday</td><td>7 pm</td><td>Poetry reading</td><td>40</td></tr>
          <tr><td>Saturday</td><td>2 pm</td><td>Bookbinding workshop</td><td>12</td></tr>
        </tbody>
      </table>
    </main>
  </body>
</html>
```

```
ana@laptop:~/site$ probe --width 320 reflow.html overflow spill p
page is 458 wide in a 320 window: it scrolls sideways
p  content 347 wide in a box 288 wide: it spills
```

Numa janela de 320, a página tem **458** de largura e rola para o lado. O conteúdo do parágrafo tem **347** numa caixa de 288: o endereço não tem espaços, então o navegador não tem onde quebrar a linha. E a tabela, que mantém cada célula numa linha só, é o que deixou a página com 458.

Duas correções diferentes, porque os dois problemas são diferentes:

```css
.url { overflow-wrap: anywhere; }
.table-wrap { overflow-x: auto; }
```

**`overflow-wrap: anywhere`** deixa o navegador quebrar uma palavra que não caberia de outro jeito, em qualquer ponto dela. É o certo para endereços, códigos e nomes longos, onde quebrar é melhor que transbordar; palavras comuns nunca precisam, porque são curtas o bastante. **Uma tabela não pode ser quebrada** sem perder o que faz dela uma tabela, as colunas. Então ela vai num invólucro com **`overflow-x: auto`**, o contêiner de rolagem da seção 11 da aula 6, e a tabela rola dentro da própria caixa enquanto a página fica parada.

Aqui está a página com as duas correções, `reflow-fixed.html`:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Andorinha Books</title>
    <style>
      body { margin: 0; padding: 0 1rem; font-family: system-ui, sans-serif; }
      th, td { padding: 0.25rem 0.75rem; text-align: left; white-space: nowrap; }
      .url { overflow-wrap: anywhere; }
      .table-wrap { overflow-x: auto; }
    </style>
  </head>
  <body>
    <main>
      <h1>Events</h1>
      <p class="url">Our catalogue is at https://andorinha.example/catalogue/second-hand/poetry-and-plays</p>
      <div class="table-wrap" tabindex="0" role="region" aria-label="Events this week">
        <table>
          <caption>Events this week</caption>
          <thead>
            <tr><th scope="col">Day</th><th scope="col">Time</th><th scope="col">Event</th><th scope="col">Places</th></tr>
          </thead>
          <tbody>
            <tr><td>Thursday</td><td>7 pm</td><td>Poetry reading</td><td>40</td></tr>
            <tr><td>Saturday</td><td>2 pm</td><td>Bookbinding workshop</td><td>12</td></tr>
          </tbody>
        </table>
      </div>
    </main>
  </body>
</html>
```

```
ana@laptop:~/site$ probe --width 320 reflow-fixed.html overflow spill .url spill .table-wrap
page fits: 320 wide in a 320 window
p.url  content 288 wide in a box 288 wide
div.table-wrap  content 442 wide in a box 288 wide: it spills
```

A página cabe, **320** em 320. O endereço agora cabe na caixa, 288 em 288. O conteúdo do invólucro continua com **442** em 288: a tabela rola dentro dele, como se queria.

## O invólucro precisa de teclado

Uma caixa que rola tem de rolar sem mouse. Aqui está a mesma página com o `tabindex="0"` do invólucro retirado, salva como `notab.html`:

```
ana@laptop:~/site$ probe --width 320 notab.html axe tab
scrollable-region-focusable (serious, 1 element): Scrollable region must have keyboard access
focus: div "Events this week DayTimeEventPlaces Thur"
ana@laptop:~/site$ probe --width 320 reflow-fixed.html axe
axe: no violations
```

O axe relata **`scrollable-region-focusable`**: uma região com rolagem que quem usa teclado pode não conseguir alcançar, e então não consegue rolar, e as últimas colunas ficam fora de alcance. Depois o Tab pôs o foco no invólucro mesmo assim: versões recentes do Chromium tornam um contêiner de rolagem focável por conta própria, e nem todo navegador faz isso, e é por isso que o axe ainda pergunta. Com `tabindex="0"` o invólucro recebe foco em todo lugar e as setas o rolam; `role="region"` e `aria-label` dão um nome a ele, para que um leitor de tela anuncie o que recebeu o foco.
