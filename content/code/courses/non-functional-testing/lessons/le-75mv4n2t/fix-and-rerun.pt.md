---
title: Corrigindo o que ele achou, e rodando de novo
version: 1
---

As quatro correções são pequenas, e **cada uma é o primeiro item do cardápio que o axe imprimiu**:
um `lang`, um `alt` de verdade, um `<label>` de verdade, um cinza mais escuro. Elas vão para um
arquivo novo, `book2.html`, para que o `book.html` continue quebrado para as aulas 14 e 15
compararem. Em `~/boxoffice/static`, `nano book2.html`:

```html
<!-- boxoffice/static/book2.html -->
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
  *:focus { outline: none; }
  .book { display: inline-block; padding: .6rem 1.4rem; background: #7a1f2b; color: #fff;
          cursor: pointer; }
  .wrong { border: 2px solid #d00; }
</style>
</head>
<body>
<img src="logo.svg" width="200" height="48" alt="boxoffice">
<nav><a href="/shows">What's on</a> <a href="/prices">Prices</a> <a href="/access">Access</a></nav>
<h1>Book a seat</h1>
<p class="note">Seats are held for ten minutes. The price includes the booking fee.</p>
<form id="book">
  <p><label for="show">Show</label><br><select id="show"></select></p>
  <p><label for="seat">Seat</label><br><input id="seat" type="number" min="1" max="300" value="1"></p>
  <p><label for="customer">Your name</label><br><input id="customer" tabindex="1"></p>
  <div class="book" onclick="book()">Book</div>
</form>
<p id="result"></p>
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

O `diff` mostra as cinco linhas que mudaram, entre elas o comentário com o nome do arquivo:

```
ana@nft:~/boxoffice/static$ diff book.html book2.html
1c1
< <!-- boxoffice/static/book.html -->
---
> <!-- boxoffice/static/book2.html -->
3c3
< <html>
---
> <html lang="en">
11c11
<   .note { color: #999; }
---
>   .note { color: #767676; }
19c19
< <img src="logo.svg" width="200" height="48">
---
> <img src="logo.svg" width="200" height="48" alt="boxoffice">
26c26
<   <p>Your name<br><input id="customer" tabindex="1"></p>
---
>   <p><label for="customer">Your name</label><br><input id="customer" tabindex="1"></p>
```

- `lang="en"` diz ao navegador, e a todo leitor de tela, em que idioma falar.
- `alt="boxoffice"` é **a palavra que está na imagem**, porque a alternativa em texto de um logo é
  o texto que ele mostra. Não é "logo", nem uma descrição das cores.
- `<label for="customer">` liga as palavras ao campo, então o campo tem nome, e clicar nas palavras
  põe o cursor nele.
- `#767676` é o cinza mais claro que chega a 4.5:1 sobre branco, como a aula 12 calculou.

Audite:

```
ana@nft:~/a11y$ node audit.js http://localhost:8000/book2.html
0 violations; to review by hand: none
```

## Zero, e o que zero quer dizer

**Zero violações quer dizer que toda regra que o axe conseguiu rodar passou.** Não quer dizer que
a página está conforme à WCAG 2.2 AA, e os quatro defeitos que continuam no `book2.html` são a
prova: a `<div>` continua inalcançável pelo teclado, o foco continua invisível, o `tabindex`
continua embaralhando a ordem e o erro continua só vermelho. Um testador que relata esta execução
como "a página é acessível" relatou algo que a ferramenta nunca disse.

## Como barreira na suíte

O código de saída transforma a auditoria num passo em que um pipeline pode reprovar. Rode-a sobre
toda página, como um job de CI faria:

```
ana@nft:~/a11y$ for page in book.html book2.html; do node audit.js http://localhost:8000/$page > /dev/null && echo "$page passes" || echo "$page fails"; done
book.html fails
book2.html passes
```

É o que a plataforma em que este curso é servido faz com a própria interface. A suíte dela abre
toda tela, nos dois temas, com e sem login, e roda o axe com as mesmas cinco tags que o `audit.js`
usa. Na primeira execução ela descobriu que um cartão de curso bloqueado, desenhado com opacidade
reduzida, levava o próprio texto a 4.09:1 no tema escuro e a 3.32:1 no claro: uma cor que ninguém
escolheu, produzida por um efeito que ninguém via como cor. **É para esse defeito que serve uma
barreira**: um que ninguém teria procurado, pego no commit que o introduziu, antes de um aluno
encontrá-lo.

Três hábitos mantêm a barreira honesta:

- **Audite os estados, não só a página como ela carrega.** Um formulário depois de um envio
  reprovado, um menu aberto, um diálogo na tela: cada um é um documento diferente, e o axe só vê o
  que existia quando o `analyze()` rodou.
- **Nunca silencie uma regra para chegar ao verde.** O `AxeBuilder` consegue desligar uma regra ou
  excluir um elemento, e às vezes isso é o certo, para um widget de terceiros cujo defeito você já
  relatou ao fornecedor, por exemplo. Toda exclusão é uma frase no teste dizendo por quê, ou é um
  buraco.
- **Imprima o `incomplete`, e entregue a alguém.** Uma execução sem nada para revisar é uma
  afirmação sobre esta página; uma execução com doze itens para revisar e um tique verde passou
  trabalho para ninguém.
