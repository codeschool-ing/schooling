---
title: O tipo do campo muda o teclado
---

No computador, `type="email"` e `type="text"` parecem iguais. No celular, não: o tipo escolhe qual teclado aparece.

- `email` — traz o `@` e o ponto na primeira tela.
- `tel` — teclado numérico grande, o de discagem.
- `number` — numérico, mas cuidado: ele recusa zeros à esquerda e caracteres de formatação, então **não** serve para CEP, CPF nem cartão.
- `url`, `date`, `search` — cada um com o seu teclado e o seu seletor nativo.

Para CEP e telefone com máscara, o par que funciona é `type="text"` com `inputmode="numeric"`: teclado numérico, sem as restrições de `number`.
