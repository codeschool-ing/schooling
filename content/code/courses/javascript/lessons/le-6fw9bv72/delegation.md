---
title: One listener for many elements
version: 1
---

Bubbling means a listener on a list hears every click on everything inside it. **Event delegation is
putting one listener on the container and working out, from `event.target`, which item was
clicked**:

```html
<!doctype html>
<ul id="books">
  <li class="book" data-id="7">Iracema <button class="lend">Lend</button></li>
  <li class="book" data-id="12">Dom Casmurro <button class="lend">Lend</button></li>
</ul>
<button id="add">Add a book</button>
<script>
  const list = document.querySelector("#books");

  list.addEventListener("click", (event) => {
    const button = event.target.closest(".lend");
    if (!button) return;
    const row = button.closest(".book");
    console.log("lend book", row.dataset.id);
  });

  document.querySelector("#add").addEventListener("click", () => {
    const li = document.createElement("li");
    li.className = "book";
    li.dataset.id = "19";
    li.append("Macunaíma ");
    const b = document.createElement("button");
    b.className = "lend";
    b.textContent = "Lend";
    li.append(b);
    list.append(li);
  });
</script>
```

```
ana@dev:~/js$ page delegate.html --do 'click li:nth-child(2) .lend' --do 'click #add' --do 'click li:nth-child(3) .lend' --do 'click li:nth-child(1)'
-- click li:nth-child(2) .lend
lend book 12
-- click #add
-- click li:nth-child(3) .lend
lend book 19
-- click li:nth-child(1)
```

The list has one listener and no button has any. For each click:

- `event.target.closest(".lend")` walks up from whatever was clicked to the nearest lend button, the
  method lesson 11 introduced for exactly this. **Clicking the row's text, the last action, found no
  button, and the listener returned without doing anything**;
- from the button, `closest(".book")` found the row, and `data-id` said which book. The book is known
  by its id, never by its title or its position in the list.

The third click is the reason delegation exists. **The book with id 19 was added after the listener
was set up, and its button worked.** A listener attached to each button would have had to be attached
to the new one too, by whoever added it, and forgetting is the usual bug.

## When to delegate

**Delegate for lists, tables and anything whose items come and go.** It is one listener instead of
hundreds, it covers items that do not exist yet, and removing an item needs no cleanup. For a single
button that is always there, a listener on the button is simpler and clearer. Frameworks delegate for
you behind their own syntax, which is why a listener written on every row in React does not cost a
listener per row.
