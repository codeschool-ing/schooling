---
title: As correções de teclado
version: 1
---

Quatro mudanças fazem a página de reserva funcionar pelo teclado, e elas vão para um terceiro
arquivo, `book3.html`, ao lado dos outros dois. Em `~/boxoffice/static`, `nano book3.html`:

```html
<!-- boxoffice/static/book3.html -->
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
  .wrong { border: 2px solid #d00; }
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
  <p><label for="customer">Your name</label><br><input id="customer"></p>
  <button class="book">Book</button>
</form>
<p id="result"></p>
</main>
<script>
fetch("/shows").then(r => r.json()).then(shows => {
  for (const s of shows) document.getElementById("show").add(new Option(`${s.title}, ${s.day}`, s.id));
});
async function book() {
  const name = document.getElementById("customer");
  name.classList.toggle("wrong", name.value.trim() === "");
  if (name.value.trim() === "") return;
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

Em relação ao `book2.html`, as mudanças são estas:

```
ana@nft:~/boxoffice/static$ diff book2.html book3.html
1c1
< <!-- boxoffice/static/book2.html -->
---
> <!-- boxoffice/static/book3.html -->
12,14c12,16
<   *:focus { outline: none; }
<   .book { display: inline-block; padding: .6rem 1.4rem; background: #7a1f2b; color: #fff;
<           cursor: pointer; }
---
>   :focus-visible { outline: 3px solid #1a5fb4; outline-offset: 2px; }
>   .skip { position: absolute; left: -999px; }
>   .skip:focus { left: 1rem; top: 1rem; background: #fff; padding: .4rem; }
>   .book { padding: .6rem 1.4rem; border: 0; background: #7a1f2b; color: #fff;
>           font: inherit; cursor: pointer; }
18a21
> <a class="skip" href="#main">Skip to the booking form</a>
20a24
> <main id="main" tabindex="-1">
23c27
< <form id="book">
---
> <form id="book" onsubmit="event.preventDefault(); book()">
26,27c30,31
<   <p><label for="customer">Your name</label><br><input id="customer" tabindex="1"></p>
<   <div class="book" onclick="book()">Book</div>
---
>   <p><label for="customer">Your name</label><br><input id="customer"></p>
>   <button class="book">Book</button>
29a34
> </main>
```

- **O foco voltou a aparecer.** O `*:focus { outline: none; }` saiu, e o `:focus-visible` desenha
  um contorno azul de 3 pixels, como a seção anterior explicou.
- **Book é um `<button>`.** Ele é focável, tem o papel *button* e responde a Enter e a Espaço sem
  código para nenhum dos dois, porque o navegador dá tudo isso a um botão. Ele fica dentro do
  formulário, então apertá-lo envia o formulário; o `onsubmit` impede o envio do próprio navegador
  e chama `book()` no lugar. Um bônus de usar o formulário: Enter no campo de nome também reserva.
- **Nenhum `tabindex` positivo.** O campo de nome volta ao seu lugar na ordem do documento.
- **Um link de pular e um `<main>`.** O link é a primeira parada e pula o logo e a navegação; o
  `<main>` é o alvo, com `tabindex="-1"` para poder receber o foco. As regras de `.skip` o mantêm
  fora da tela até ele receber o foco.

A classe `.wrong` e a borda vermelha continuam lá. É o defeito 8, e ele pertence à aula 15.

## O mesmo script, depois

Rode `python3 seed.py` em `~/boxoffice` de novo, para que os assentos que o `tab.js` reserva
estejam livres, e então:

```
ana@nft:~/a11y$ node tab.js http://localhost:8000/book3.html
Tab order:
  1. link "Skip to the booking form"
  2. link "What's on"
  3. link "Prices"
  4. link "Access"
  5. combobox "Show"
  6. spinbutton "Seat": "1"
  7. textbox "Your name"
  8. button "Book"
  9. (focus left the page)
Enter on the skip link, then Tab: combobox "Show"
Keyboard, Enter on Book: Booked: seat 20, booking 295113.
Mouse, click on Book: Booked: seat 21, booking 295114.
```

**Oito paradas, em ordem de leitura, cada uma com contorno**, terminando no botão. O link de pular
vem primeiro, e Enter nele põe o próximo Tab no campo Show, depois dos três links do cabeçalho. O
teclado reserva o assento 20 e o mouse reserva o assento 21, e as duas linhas enfim dizem a mesma
coisa.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 400\" role=\"img\" data-fig=\"l14-tab-order\" aria-label=\"A ordem de tabulação desenhada sobre dois esboços da página de reserva. À esquerda, o book2.html: a parada 1 é o campo de nome no fim do formulário, por causa do tabindex 1; as paradas 2 a 4 são os três links do cabeçalho; 5 é Show e 6 é Seat; a div Book nunca é alcançada, e nenhuma parada mostra contorno de foco. À direita, o book3.html: a parada 1 é o link de pular, 2 a 4 os links, 5 Show, 6 Seat, 7 o campo de nome e 8 o botão Book, na ordem de leitura, cada uma com contorno visível.\"><text x=\"176.0\" y=\"24.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper-dim)\">book2.html</text><rect x=\"16.0\" y=\"38.0\" width=\"320.0\" height=\"340.0\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"30.0\" y=\"76.0\" width=\"110.0\" height=\"26.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"85.0\" y=\"89.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">boxoffice</text><text x=\"65.0\" y=\"118.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">What's on</text><text x=\"140.0\" y=\"118.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">Prices</text><text x=\"208.0\" y=\"118.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">Access</text><text x=\"30.0\" y=\"164.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">Book a seat</text><text x=\"30.0\" y=\"186.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">Show</text><rect x=\"30.0\" y=\"194.0\" width=\"180.0\" height=\"20.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"30.0\" y=\"228.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">Seat</text><rect x=\"30.0\" y=\"236.0\" width=\"180.0\" height=\"20.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"30.0\" y=\"270.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">Your name</text><rect x=\"30.0\" y=\"278.0\" width=\"180.0\" height=\"20.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><rect x=\"30.0\" y=\"314.0\" width=\"70.0\" height=\"26.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"65.0\" y=\"327.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Book</text><circle cx=\"230.0\" cy=\"288.0\" r=\"9\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></circle><text x=\"230.0\" y=\"288.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">1</text><circle cx=\"65.0\" cy=\"136.0\" r=\"9\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></circle><text x=\"65.0\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">2</text><circle cx=\"140.0\" cy=\"136.0\" r=\"9\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></circle><text x=\"140.0\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">3</text><circle cx=\"208.0\" cy=\"136.0\" r=\"9\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></circle><text x=\"208.0\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">4</text><circle cx=\"230.0\" cy=\"204.0\" r=\"9\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></circle><text x=\"230.0\" y=\"204.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">5</text><circle cx=\"230.0\" cy=\"246.0\" r=\"9\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></circle><text x=\"230.0\" y=\"246.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">6</text><text x=\"176.0\" y=\"362.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">Book: nunca alcançado</text><text x=\"544.0\" y=\"24.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper-dim)\">book3.html</text><rect x=\"384.0\" y=\"38.0\" width=\"320.0\" height=\"340.0\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"398.0\" y=\"48.0\" width=\"170.0\" height=\"20.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></rect><text x=\"483.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">Skip to the booking form</text><rect x=\"398.0\" y=\"76.0\" width=\"110.0\" height=\"26.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"453.0\" y=\"89.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">boxoffice</text><text x=\"433.0\" y=\"118.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">What's on</text><text x=\"508.0\" y=\"118.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">Prices</text><text x=\"576.0\" y=\"118.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">Access</text><text x=\"398.0\" y=\"164.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">Book a seat</text><text x=\"398.0\" y=\"186.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">Show</text><rect x=\"398.0\" y=\"194.0\" width=\"180.0\" height=\"20.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"398.0\" y=\"228.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">Seat</text><rect x=\"398.0\" y=\"236.0\" width=\"180.0\" height=\"20.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"398.0\" y=\"270.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">Your name</text><rect x=\"398.0\" y=\"278.0\" width=\"180.0\" height=\"20.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><rect x=\"398.0\" y=\"314.0\" width=\"70.0\" height=\"26.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"433.0\" y=\"327.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Book</text><circle cx=\"588.0\" cy=\"58.0\" r=\"9\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></circle><text x=\"588.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">1</text><circle cx=\"433.0\" cy=\"136.0\" r=\"9\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></circle><text x=\"433.0\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">2</text><circle cx=\"508.0\" cy=\"136.0\" r=\"9\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></circle><text x=\"508.0\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">3</text><circle cx=\"576.0\" cy=\"136.0\" r=\"9\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></circle><text x=\"576.0\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">4</text><circle cx=\"598.0\" cy=\"204.0\" r=\"9\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></circle><text x=\"598.0\" y=\"204.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">5</text><circle cx=\"598.0\" cy=\"246.0\" r=\"9\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></circle><text x=\"598.0\" y=\"246.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">6</text><circle cx=\"598.0\" cy=\"288.0\" r=\"9\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></circle><text x=\"598.0\" y=\"288.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">7</text><circle cx=\"488.0\" cy=\"327.0\" r=\"9\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></circle><text x=\"488.0\" y=\"327.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">8</text><text x=\"544.0\" y=\"362.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">oito paradas, na ordem de leitura</text></svg>", "caption": "Para onde o Tab vai, antes e depois das correções de teclado. À esquerda a ordem começa embaixo e nunca chega ao Book.", "same": ["Access", "Book", "Book a seat", "Prices", "Seat", "Show", "Skip to the booking form", "What's on", "Your name", "book2.html", "book3.html"]}
```

E a auditoria automática, que deu 0 para o `book2.html` também, dá 0 de novo:

```
ana@nft:~/a11y$ node audit.js http://localhost:8000/book3.html
0 violations; to review by hand: none
```

**Esse zero repetido é a aula numa linha**: a auditoria não viu diferença entre a página que quem
usa teclado não consegue terminar e a página que consegue. Só a caminhada de Tab viu.
