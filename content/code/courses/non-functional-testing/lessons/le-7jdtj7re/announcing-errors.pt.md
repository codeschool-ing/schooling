---
title: Um erro que se ouve
version: 1
---

O defeito 8 é a borda vermelha, e ele reprova duas vezes. Para quem não vê o vermelho como
vermelho, o campo parece igual antes e depois, que é o *1.4.1 Uso de cor*. Para quem usa leitor de
tela, não aconteceu nada: a árvore não mudou, então o leitor não tinha o que dizer, e o usuário
aperta Book, não ouve nada e não sabe se um assento foi reservado. É o *3.3.1 Identificação de
erro*, nível A: um erro detectado é identificado para o usuário **em texto**.

## Regiões vivas

Um leitor de tela lê aquilo para onde o usuário vai. Uma mensagem que aparece em outro lugar da
página, enquanto o foco fica onde estava, passa sem ser lida a menos que a página peça para ela ser
anunciada. **Uma região viva é como a página pede**: um elemento marcado para que o navegador avise
a tecnologia assistiva sempre que o conteúdo dele mudar.

| marcação | como é anunciada | para |
|---|---|---|
| `role="status"`, ou `aria-live="polite"` | quando o leitor termina o que está dizendo | um resultado, uma contagem, "reservado" |
| `role="alert"`, ou `aria-live="assertive"` | na hora, interrompendo | um erro de que o usuário precisa cuidar agora |

O *4.1.3 Mensagens de status*, nível AA desde a WCAG 2.1, é o critério por trás dos dois: uma
mensagem que relata um resultado sem mover o foco tem que ser anunciada por um papel ou uma
propriedade como estes. **A região tem que já estar na página, vazia, quando a mensagem chega.**
Uma região viva inserida junto com o texto muitas vezes nem é anunciada, porque não havia região
para observar até aquele momento.

## book4.html

A correção vai para um quarto arquivo. `nano book4.html` em `~/boxoffice/static`:

```html
<!-- boxoffice/static/book4.html -->
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Book a seat</title>
<style>
  body { font-family: sans-serif; max-width: 36rem; margin: 2rem auto; color: #222; }
  nav a { margin-right: 1rem; color: #7a1f2b; }
  .note { color: #767676; }
  :focus-visible { outline: 3px solid #1a5fb4; outline-offset: 2px; }
  .skip { position: absolute; left: -999px; }
  .skip:focus { left: 1rem; top: 1rem; background: #fff; padding: .4rem; }
  .book { padding: .6rem 1.4rem; border: 0; background: #7a1f2b; color: #fff;
          font: inherit; cursor: pointer; }
  [aria-invalid="true"] { border: 2px solid #d00; }
  .error { color: #b00; font-weight: bold; }
</style>
</head>
<body>
<a class="skip" href="#main">Skip to the booking form</a>
<img src="logo.svg" width="200" height="48" alt="boxoffice">
<nav><a href="/shows">What's on</a> <a href="/prices">Prices</a> <a href="/access">Access</a></nav>
<main id="main" tabindex="-1">
<h1>Book a seat</h1>
<p class="note">Seats are held for ten minutes. The price includes the booking fee.</p>
<form id="book" onsubmit="event.preventDefault(); book()">
  <p><label for="show">Show</label><br><select id="show"></select></p>
  <p><label for="seat">Seat</label><br><input id="seat" type="number" min="1" max="300" value="1"></p>
  <p><label for="customer">Your name</label><br>
     <input id="customer" autocomplete="name" aria-describedby="customer-error">
     <span id="customer-error" class="error" role="alert"></span></p>
  <button class="book">Book</button>
</form>
<p id="result" role="status"></p>
</main>
<script>
fetch("/shows").then(r => r.json()).then(shows => {
  for (const s of shows) document.getElementById("show").add(new Option(`${s.title}, ${s.day}`, s.id));
});
async function book() {
  const name = document.getElementById("customer");
  const missing = name.value.trim() === "";
  name.setAttribute("aria-invalid", missing);
  document.getElementById("customer-error").textContent =
    missing ? "Error: type the name the tickets are for." : "";
  if (missing) return name.focus();
  const answer = await fetch("/bookings", { method: "POST", body: JSON.stringify({
    show_id: document.getElementById("show").value,
    seat: document.getElementById("seat").value, customer: name.value }) });
  const body = await answer.json();
  document.getElementById("result").textContent =
    answer.ok ? `Booked: seat ${body.seat}, booking ${body.id}.` : `Not booked: ${body.error}.`;
}
</script>
</body>
</html>
```

Em relação ao `book3.html`:

```
ana@nft:~/boxoffice/static$ diff book3.html book4.html
1c1
< <!-- boxoffice/static/book3.html -->
---
> <!-- boxoffice/static/book4.html -->
17c17,18
<   .wrong { border: 2px solid #d00; }
---
>   [aria-invalid="true"] { border: 2px solid #d00; }
>   .error { color: #b00; font-weight: bold; }
30c31,33
<   <p><label for="customer">Your name</label><br><input id="customer"></p>
---
>   <p><label for="customer">Your name</label><br>
>      <input id="customer" autocomplete="name" aria-describedby="customer-error">
>      <span id="customer-error" class="error" role="alert"></span></p>
33c36
< <p id="result"></p>
---
> <p id="result" role="status"></p>
41,42c44,48
<   name.classList.toggle("wrong", name.value.trim() === "");
<   if (name.value.trim() === "") return;
---
>   const missing = name.value.trim() === "";
>   name.setAttribute("aria-invalid", missing);
>   document.getElementById("customer-error").textContent =
>     missing ? "Error: type the name the tickets are for." : "";
>   if (missing) return name.focus();
```

- Um `<span role="alert">` vazio fica ao lado do campo desde o início, e o script escreve o erro
  nele. A mensagem começa com a palavra **"Error:"**, então a cor deixa de ser a única coisa que o
  carrega, e ela diz o que fazer, que é o *3.3.3 Sugestão de erro* no AA.
- O `aria-describedby` liga a mensagem ao campo, então ela é a **descrição** do campo além de um
  anúncio: quem volta ao campo com Tab depois a ouve de novo.
- O `aria-invalid` é posto no campo enquanto falta o nome. É um estado, então o leitor pode anunciar
  o campo como inválido, e a borda vermelha agora pende do mesmo atributo no CSS, então o que se vê
  e o que se ouve não podem discordar.
- O foco vai para o campo, onde o usuário tem que digitar.
- O `<p id="result" role="status">` faz o mesmo pelo resultado: "Booked: seat 20" é anunciado com
  educação, sem mover o foco.

## A árvore, depois

```
ana@nft:~/a11y$ node tree.js http://localhost:8000/book4.html
- link "Skip to the booking form":
  - /url: "#main"
- img "boxoffice"
- navigation:
  - link "What's on":
    - /url: /shows
  - link "Prices":
    - /url: /prices
  - link "Access":
    - /url: /access
- main:
  - heading "Book a seat" [level=1]
  - paragraph: Seats are held for ten minutes. The price includes the booking fee.
  - paragraph:
    - text: Show
    - combobox "Show":
      - option "Hamlet, 2027-10-02" [selected]  (and 19 more)
  - paragraph:
    - text: Seat
    - spinbutton "Seat": "1"
  - paragraph:
    - text: Your name
    - textbox "Your name"
    - alert
  - button "Book"
  - status

After Book with no name, the tree gains:
    - alert: "Error: type the name the tickets are for."
```

O `alert` e o `status` vazios estão lá no carregamento, e é isso que os faz regiões vivas e não
chegadas tardias. **Depois do envio vazio a árvore ganha o alerta com o texto**, que é a linha que
um leitor de tela transforma em fala. Duas coisas esta transcrição não mostra, porque o
`ariaSnapshot()` não as imprime: o estado `aria-invalid` do campo e a sua descrição. As duas estão
na árvore; conferir que um leitor de verdade as anuncia é para isso que serve a carta da próxima
seção.

E a auditoria automática, mais uma vez:

```
ana@nft:~/a11y$ node audit.js http://localhost:8000/book4.html
0 violations; to review by hand: none
```

Zero, como foi para o `book2.html` e o `book3.html`: três páginas muito diferentes de usar, e
idênticas para a ferramenta.
