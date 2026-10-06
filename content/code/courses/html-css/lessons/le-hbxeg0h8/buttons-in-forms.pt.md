---
title: Botões num formulário
version: 1
---

A aula 2 terminou com um aviso que esta seção explica: **um `<button>` dentro de um formulário envia o formulário, a não ser que diga o contrário.** O atributo `type` de um botão tem três valores:

- `submit`, o padrão: envia o formulário.
- `button`: não faz nada sozinho, para um script lhe dar uma tarefa.
- `reset`: devolve todo campo ao valor inicial, o que quase ninguém quer e que apaga o que alguém digitou com um clique errado. Deixe de fora.

Aqui está um formulário de reserva com três botões. O primeiro não tem `type`; o segundo diz `type="button"`; o terceiro é o envio de verdade.

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>Reserve · Andorinha Books</title>
  </head>
  <body>
    <main>
      <h1>Reserve a book</h1>
      <form action="reserve" method="get">
        <label for="title">Title</label>
        <input id="title" name="title">
        <button class="check">Check the shelf</button>
        <button type="button" class="check2">Check the shelf (type="button")</button>
        <button type="submit" class="go">Reserve</button>
      </form>
    </main>
  </body>
</html>
```

```
ana@laptop:~/site$ probe buttons.html fill '#title' 'Vidas Secas' send .check2
nothing was sent
ana@laptop:~/site$ probe buttons.html fill '#title' 'Vidas Secas' send .check
GET /reserve?title=Vidas+Secas
```

O `type="button"` não enviou nada. O primeiro, escrito por alguém que só queria um botão para consultar a estante, **enviou o formulário inteiro**: o `type` que faltava fez dele um botão de envio. Um script preso a ele rodaria e em seguida a página navegaria para outro lugar, que é o bug que as pessoas conhecem como "meu botão recarrega a página".

## Enter também envia o formulário

Um formulário também é enviado quando alguém aperta Enter num campo de texto de uma linha, se o formulário tem um botão de envio. É o **envio implícito**, e é como a maioria das pessoas envia uma busca:

```
ana@laptop:~/site$ probe buttons.html fill '#title' 'Vidas Secas' focus '#title' press Enter fetched
reserve?title=Vidas+Secas
```

O navegador procura o primeiro botão de envio do formulário e age como se ele tivesse sido apertado. É mais um motivo para o primeiro botão de um formulário ser o de verdade, ou dizer `type="button"` se não for: o Enter aperta o botão de envio que vier primeiro.

## Um botão diz o que faz

O texto num botão de envio é o nome acessível dele, como o de qualquer botão. *Send the order*, *Reserve*, *Search the shelves* dizem ao leitor o que vai acontecer; *Submit* e *OK* dizem que algo vai acontecer. Um `<input type="submit" value="…">` também cria um botão de envio, e você vai encontrá-lo em código antigo; `<button>` pode conter outros elementos, como um ícone ao lado do texto, e é por isso que é o usado hoje.
