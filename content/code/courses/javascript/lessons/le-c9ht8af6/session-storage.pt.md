---
title: sessionStorage: uma aba, uma sessão
version: 1
---

**O `sessionStorage` tem exatamente a mesma interface, e uma vida mais curta e mais estreita**: ele
pertence a uma aba, sobrevive a um recarregamento dela, e some quando a aba é fechada.

```html
<!doctype html>
<script>
  const before = sessionStorage.getItem("draft");
  console.log("draft found:", before);
  sessionStorage.setItem("draft", "half a review of Iracema");
  localStorage.setItem("seen", "yes");
</script>
```

```
ana@dev:~/js$ page draft.html --fresh --do reload --do newtab
draft found: null
-- reload
draft found: half a review of Iracema
-- newtab
draft found: null
```

A primeira carga não achou rascunho e salvou um. **O recarregamento o achou**: mesma aba, mesma
sessão. **A aba nova não achou nada**, embora fosse a mesma página no mesmo site, porque uma aba nova
começa uma sessão nova. O `localStorage`, escrito no mesmo script, estaria visível nas duas.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Uma origem, http://127.0.0.1:8080, com duas abas abertas. As duas abas compartilham o único localStorage da origem. Cada aba tem o seu próprio sessionStorage, que a outra não vê e que some quando a aba é fechada. Outra origem tem armazenamento próprio que esta não alcança.\"><rect x=\"16\" y=\"14\" width=\"500\" height=\"202\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"30\" y=\"34\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">http://127.0.0.1:8080</text><rect x=\"40\" y=\"50\" width=\"210\" height=\"90\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"145\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">aba 1</text><rect x=\"60\" y=\"82\" width=\"170\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"145.0\" y=\"96.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">sessionStorage</text><text x=\"145.0\" y=\"113.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">só desta aba</text><rect x=\"270\" y=\"50\" width=\"210\" height=\"90\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"375\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">aba 2</text><rect x=\"290\" y=\"82\" width=\"170\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"375.0\" y=\"96.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">sessionStorage</text><text x=\"375.0\" y=\"113.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">só desta aba</text><rect x=\"40\" y=\"156\" width=\"440\" height=\"44\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"260.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">localStorage</text><text x=\"260.0\" y=\"187.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">compartilhado por toda aba da origem, guardado entre visitas</text><rect x=\"540\" y=\"14\" width=\"164\" height=\"202\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 3\"></rect><text x=\"622\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">outra origem</text><text x=\"622\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">armazenamento próprio,</text><text x=\"622\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">fora de alcance</text></svg>", "caption": "O localStorage pertence à origem; o sessionStorage pertence a uma aba dela."}
```

## Qual usar

- **`sessionStorage`** para o estado de uma tarefa numa aba: o passo em que está um formulário de
  várias páginas, um filtro que o usuário definiu só nesta aba. Duas abas fazendo duas coisas
  diferentes então não se sobrescrevem;
- **`localStorage`** para preferências que devem acompanhar o usuário em toda aba e toda visita.

Os dois pertencem a uma **origem**: o esquema, o host e a porta juntos. Uma página em
`http://127.0.0.1:8080` não lê o que uma página de outra origem guardou, e um site não lê o
armazenamento de outro site de jeito nenhum. Essa fronteira é do navegador, e nada que uma página faça
a alarga.
