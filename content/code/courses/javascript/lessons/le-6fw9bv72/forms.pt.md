---
title: Formulários
version: 1
---

Um formulário junta campos e os manda juntos. **Escute `submit` no formulário, não `click` no
botão**: o `submit` também dispara quando alguém aperta Enter num campo, e só dispara depois de o
navegador conferir os campos:

```html
<!doctype html>
<form id="loan">
  <label>Reader <input name="reader" required minlength="3"></label>
  <label>Copies <input name="copies" type="number" min="1" max="5" value="1"></label>
  <button>Lend</button>
</form>
<script>
  const form = document.querySelector("#loan");

  form.addEventListener("submit", (event) => {
    event.preventDefault();
    const data = new FormData(form);
    console.log("submitted:", JSON.stringify(Object.fromEntries(data)));
  });

  form.addEventListener("invalid", (event) => {
    console.log("invalid:", event.target.name, "-", event.target.validationMessage);
  }, { capture: true });

  form.elements.reader.addEventListener("input", (e) => console.log("input:", e.target.value));
  form.elements.reader.addEventListener("change", (e) => console.log("change:", e.target.value));
</script>
```

```
ana@dev:~/js$ page form.html --do 'click button'
-- click button
invalid: reader - Please fill out this field.
```

```
ana@dev:~/js$ page form.html --do 'fill [name=reader] an' --do 'click button'
-- fill [name=reader] an
-- click button
input: an
change: an
invalid: reader - Please lengthen this text to 3 characters or more (you are currently using 2 characters).
```

```
ana@dev:~/js$ page form.html --do 'focus [name=reader]' --do 'press a' --do 'press n' --do 'press a' --do 'press Tab' --do 'fill [name=copies] 3' --do 'click button'
-- focus [name=reader]
-- press a
input: a
-- press n
input: an
-- press a
input: ana
-- press Tab
change: ana
-- fill [name=copies] 3
-- click button
submitted: {"reader":"ana","copies":"3"}
```

## O navegador confere primeiro

`required` e `minlength="3"` no campo do leitor, e `min`/`max` nas cópias, são **validação de
restrições**: regras que o navegador confere antes de disparar o `submit`. As duas primeiras execuções
nunca chegaram ao listener de `submit` do script. O navegador disparou `invalid` no campo, com uma
`validationMessage` escrita por ele mesmo, e mostrou essa mensagem ao lado do campo. **Conferir no
HTML não custa nada e funciona antes de qualquer código seu rodar**, e é por isso que vem primeiro; o
servidor precisa conferir de novo mesmo assim, porque uma requisição pode ser feita sem a página.

## Lendo todos os campos de uma vez

`new FormData(form)` junta todo campo com nome, e `Object.fromEntries` (aula 5) o transformou num
objeto simples. **Todo valor voltou como string, `"3"` inclusive**, a regra da aula 2 sobre campos de
formulário; converta antes de calcular.

## `input` e `change`

Digitado uma tecla por vez, o campo do leitor disparou **`input` depois de cada tecla**, com o valor
até ali, e **`change` uma vez, quando o foco saiu do campo**. Use `input` para algo que reage enquanto
o usuário digita, como uma caixa de busca, e `change` para algo que deve esperar ele terminar.

## As suas próprias regras

```html
<!doctype html>
<form id="loan">
  <input name="reader" value="bia">
  <button>Lend</button>
</form>
<script>
  const blocked = new Set(["bia"]);
  const form = document.querySelector("#loan");
  const reader = form.elements.reader;

  form.addEventListener("submit", (event) => {
    event.preventDefault();
    reader.setCustomValidity(blocked.has(reader.value) ? "this reader has a book overdue" : "");
    if (!form.reportValidity()) {
      console.log("refused:", reader.validationMessage);
      return;
    }
    console.log("lent to", reader.value);
  });
</script>
```

```
ana@dev:~/js$ page custom.html --do 'click button' --do 'fill [name=reader] ana' --do 'click button'
-- click button
refused: this reader has a book overdue
-- fill [name=reader] ana
-- click button
```

`setCustomValidity` acrescenta uma regra que o HTML não consegue expressar: este leitor tem um livro
atrasado. O primeiro envio foi recusado, como devia. **O segundo, com um nome bom, não imprimiu
nada**: a mensagem personalizada ainda estava definida, então o navegador recusou o formulário antes
de o listener de `submit` poder rodar e limpá-la. Uma mensagem definida com `setCustomValidity` fica
até algo a limpar:

```
ana@dev:~/js$ page custom-fixed.html --do 'click button' --do 'fill [name=reader] ana' --do 'click button'
-- click button
refused: this reader has a book overdue
-- fill [name=reader] ana
-- click button
lent to ana
```

Uma linha consertou: **limpe a mensagem personalizada no `input`**, para cada edição começar válida e a
conferência rodar de novo no envio.
