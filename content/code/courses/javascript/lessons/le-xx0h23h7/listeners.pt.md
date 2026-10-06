---
title: Um listener que você não consegue remover
version: 1
---

Um uso do `bind` sobrevive em toda parte, em classes que tratam eventos, e vem com um bug próprio. A
aula 12 trata de eventos; esta seção só precisa de dois fatos. `addEventListener("click", fn)` roda
`fn` a cada clique, e **`removeEventListener("click", fn)` só o interrompe se `fn` for a mesma
função**, comparada com `===`.

```html
<!doctype html>
<button id="ring">Ring</button>
<script>
  "use strict";

  class Bell {
    constructor(name) {
      this.name = name;
      this.boundRing = this.ring.bind(this);
    }
    ring() {
      console.log(`${this.name} rang`);
    }
  }

  const bell = new Bell("front door");
  const button = document.querySelector("#ring");

  button.addEventListener("click", bell.ring.bind(bell));
  button.addEventListener("click", bell.boundRing);

  button.addEventListener("click", () => {
    button.removeEventListener("click", bell.ring.bind(bell));
    button.removeEventListener("click", bell.boundRing);
    console.log("removed both, supposedly");
  });
</script>
```

```
ana@dev:~/js$ page listeners.html --do 'click #ring' --do 'click #ring'
-- click #ring
front door rang
front door rang
removed both, supposedly
-- click #ring
front door rang
removed both, supposedly
```

Três listeners foram acrescentados. O primeiro clique rodou os três, e o terceiro tentou remover os
dois primeiros. O segundo clique mostra como foi: **a campainha ainda tocou uma vez, então uma das
duas remoções não fez nada.** Foi a primeira.

`bell.ring.bind(bell)` cria **uma função nova a cada vez que roda**. O listener acrescentado foi uma
função vinculada; a passada para `removeEventListener` foi uma segunda, feita um instante depois, e as
duas não são `===`. O navegador procurou a segunda, não achou nada, e manteve a primeira.
`bell.boundRing` foi vinculada uma vez, no construtor, e a mesma função foi usada para acrescentar e
para remover, então essa remoção funcionou.

O terceiro listener rodou de novo no segundo clique também, porque nada o removeu. A aula 19 volta
aos listeners que ninguém remove, pelo lado da memória.

## A regra

**Faça o bind uma vez, guarde o resultado, e use esse único valor para acrescentar e para remover.**
O construtor é o lugar de costume. A aula 8 mostra a forma mais curta que as classes têm para isso,
um campo arrow function, que dá a mesma garantia: uma função por objeto, feita uma vez, com o `this`
fixo.
