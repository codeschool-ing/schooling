---
title: Fixing arguments in advance
version: 1
---

`bind` takes more than a `this`. **Any arguments after the first are fixed too, and come before
whatever the later call passes.** A function with some of its arguments filled in ahead of time is
called a **partial application**:

```javascript
function price(currency, cents) {
  return `${currency} ${(cents / 100).toFixed(2)}`;
}

const inReais = price.bind(null, "BRL");
const inEuros = price.bind(null, "EUR");
console.log(inReais(1990), "/", inEuros(1990));
console.log(inReais.length);

const inDollars = (cents) => price("USD", cents);
console.log(inDollars(1990));
```

```
ana@dev:~/js$ node partial.js
BRL 19.90 / EUR 19.90
1
USD 19.90
```

`price` takes a currency and an amount. `price.bind(null, "BRL")` made a function with the currency
already filled in, so `inReais(1990)` ran as `price("BRL", 1990)`. The `null` is there because
`price` does not use `this`, and **`bind` always takes the `this` first, even when nobody needs
it**. The bound function's `length` is 1, the parameters it still expects.

## The arrow does the same

`inDollars` does the same job with an arrow and no `bind`, and that is the form you will meet most
in new code: **a closure (lesson 6) that calls the function with the fixed part written in.** It is
easier to read, it can fix any argument and not only the leading ones, and it does not need the
dummy `null`.

The idea itself is what is worth keeping. A function that takes a setting and then data is common
in configuration code, and fixing the setting once gives you a small, specific function to pass
around: a formatter for one currency, a logger for one module, a request for one server. Whether
you write it with `bind` or an arrow is a matter of style; the team's existing code usually decides.
