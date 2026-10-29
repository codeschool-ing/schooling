---
title: Um Storybook estático, publicado como o planner
version: 1
---

**`npm run build-storybook` grava a oficina inteira como uma pasta de arquivos estáticos, então ela é
publicada exatamente do jeito que a aula 1 publicou o planner.** É um segundo site, construído a partir do
mesmo repositório, com o próprio comando de build e a própria pasta de saída.

```
ana@dev:~/planner$ npm run build-storybook > /dev/null 2>&1 && ls storybook-static
_redirects
assets
courses.json
favicon-wrapper.svg
favicon.svg
iframe.html
index.html
index.json
nunito-sans-bold-italic.woff2
nunito-sans-bold.woff2
nunito-sans-italic.woff2
nunito-sans-regular.woff2
project.json
sb-addons
sb-common-assets
sb-manager
vite-inject-mocker-entry.js
```

`index.html` é a interface do Storybook, `iframe.html` o quadro em que uma story é desenhada, `index.json`
a lista de stories, e `assets` o código empacotado. `courses.json` e `_redirects` vieram junto porque o
Storybook também copia a pasta `public/` do projeto; a reescrita `/*` desse `_redirects` mandaria um link
profundo de dentro do Storybook para o `index.html` dele, o que aqui é inofensivo, porque os endereços do
próprio Storybook são parâmetros de consulta, e não caminhos.

Sirva-o com o host do planner, numa porta própria:

```
ana@dev:~/planner$ node host.mjs storybook-static 6007
serving storybook-static on http://127.0.0.1:6007
```

```
ana@dev:~/planner$ curl -s -o /dev/null -w '%{http_code}\n' 'http://127.0.0.1:6007/iframe.html?id=planner-session-row--done&viewMode=story'
200
```

## Publicando

Em qualquer host da aula 1, um Storybook é um segundo projeto do mesmo repositório: comando de build
`npm run build-storybook`, pasta de saída `storybook-static`. Com previews ligados, todo pull request ganha
um preview da oficina ao lado do preview do app, que é onde quem revisa vê um componente mudar em todo
estado de uma vez, em vez de na única tela em que calhou de clicar.

O **Chromatic**, um serviço dos mantenedores do Storybook, faz a mesma publicação e acrescenta revisão
visual: ele fotografa toda story em todo push e pede a uma pessoa que aprove cada mudança. Ele não foi
executado para este curso; precisa de uma conta, e a próxima seção monta o mesmo tipo de conferência no seu
computador.

## O site de um design system

Para uma equipe, esta pasta é o site de documentação do design system, e merece o mesmo cuidado do produto:
um endereço estável, HTTPS, um link no README do repositório. Uma oficina que só existe como o
`npm run storybook` de alguém some quando essa pessoa sai.
