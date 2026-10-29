---
title: Um botão de instalar do próprio planner
version: 1
---

**A oferta de instalação do próprio navegador passa despercebida com facilidade**: um ícone na barra de endereço, ou
um item de um menu. O Chromium deixa uma página fazer a oferta ela mesma. Quando uma página se qualifica, o
navegador dispara **`beforeinstallprompt`** nela; uma página que chama `preventDefault()` guarda o evento, e chamar o
`prompt()` dele depois, a partir de um clique, mostra a caixa de instalação do navegador nessa hora.

No `index.html`, um botão para isso, escondido até haver o que oferecer; acrescente-o logo antes do
`<main id="app">`:

```html
    <button id="install" class="install" hidden>Install the planner</button>
```

Ele é posicionado com `position: fixed`, no fim do `src/style.css`, para que aparecer tarde não mexa nada na página,
que é o deslocamento de layout da aula 5 evitado de propósito:

```css
.install { position: fixed; right: 1rem; bottom: 1rem; }
```

E no fim do `src/main.ts`:

```typescript

// Chromium offers to install an app by firing beforeinstallprompt. The page keeps the
// event and shows its own button, so the offer comes when the person asks for it.
type InstallOffer = Event & { prompt(): Promise<void> };
let offer: InstallOffer | null = null;
const install = document.getElementById("install")!;
addEventListener("beforeinstallprompt", (e) => {
  e.preventDefault();
  offer = e as InstallOffer;
  install.hidden = false;
});
install.addEventListener("click", async () => {
  install.hidden = true;
  await offer?.prompt();
  offer = null;
});
```

O `InstallOffer` é escrito por extenso porque a descrição do DOM do TypeScript não inclui o evento: ele é um recurso
do Chromium, não um padrão. O `prompt()` só pode ser chamado uma vez por evento, então o botão se esconde e a oferta
é descartada depois dele.

O `tools/installable.ts` já procura um botão com esse id, alguns segundos depois de a página carregar. Faça o build,
reinicie e pergunte:

```
ana@dev:~/planner$ node tools/installable.ts http://localhost:3000/
manifest: http://localhost:3000/manifest.webmanifest
not installable: no-acceptable-icon (minimum-icon-size-in-pixels=144)
```

**O botão aparece**, porque o navegador disparou o evento. Num navegador que nunca o dispara, o Safari e o Firefox,
ele continua escondido, e a página é exatamente o que era. Essa é a falha certa: uma página que mostrasse o botão em
todo lugar ofereceria algo que não pode dar. Para o Safari, a alternativa honesta é uma frase dizendo onde fica o
*Adicionar à Tela de Início*, mostrada só lá.

**O planner não aperta o botão.** O `prompt()` abre uma caixa para uma pessoa responder, e um teste que a
respondesse estaria testando o navegador.
