---
title: Versões e faixas
version: 2
---

**Um número de versão é `MAJOR.MINOR.PATCH`, e cada parte é uma promessa sobre o que mudou.** Essa
convenção se chama **versionamento semântico**, ou semver, e todo o ecossistema do npm se apoia
nela:

- **PATCH** sobe numa correção. O código que funcionava continua funcionando;
- **MINOR** sobe quando algo é acrescentado. O código que funcionava continua funcionando, e código
  novo pode usar o acréscimo;
- **MAJOR** sobe quando algo que funcionava para de funcionar: uma função renomeada, um argumento
  removido, um padrão alterado.

O `publish-shelf.sh` publicou cinco versões de `shelf-slug`, uma de cada tipo de mudança:

```
ana@dev:~/js/first$ npm view shelf-slug versions
[ '1.0.0', '1.1.0', '1.1.1', '1.2.0', '2.0.0' ]
```

`1.1.0` acrescentou uma opção `max`, `1.1.1` corrigiu letras acentuadas, `1.2.0` acrescentou uma
opção `sep`, e `2.0.0` renomeou `slug` para `toSlug`.

## Faixas

Uma dependência no `package.json` é uma faixa, não uma versão, e `npm view` com uma faixa lista
toda versão publicada dentro dela:

```
ana@dev:~/js/first$ npm view shelf-slug@1.1.0 version
1.1.0
ana@dev:~/js/first$ npm view shelf-slug@~1.1.0 version
shelf-slug@1.1.0 '1.1.0'
shelf-slug@1.1.1 '1.1.1'
ana@dev:~/js/first$ npm view shelf-slug@^1.1.0 version
shelf-slug@1.1.0 '1.1.0'
shelf-slug@1.1.1 '1.1.1'
shelf-slug@1.2.0 '1.2.0'
ana@dev:~/js/first$ npm view shelf-slug@latest version
2.0.0
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Cinco versões publicadas de shelf-slug no alto, e quatro jeitos de pedi-lo na lateral. A versão exata 1.1.0 aceita só ela mesma. A faixa com til ~1.1.0 aceita 1.1.0 e 1.1.1 e instala 1.1.1. A faixa com circunflexo ^1.1.0 aceita 1.1.0, 1.1.1 e 1.2.0 e instala 1.2.0. A tag latest é 2.0.0. Nenhuma faixa que começa em 1 chega a 2.0.0.\"><rect x=\"208\" y=\"20\" width=\"84\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"250.0\" y=\"35.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">1.0.0</text><rect x=\"303\" y=\"20\" width=\"84\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"345.0\" y=\"35.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">1.1.0</text><rect x=\"398\" y=\"20\" width=\"84\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"440.0\" y=\"35.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">1.1.1</text><rect x=\"493\" y=\"20\" width=\"84\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"535.0\" y=\"35.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">1.2.0</text><rect x=\"588\" y=\"20\" width=\"84\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"630.0\" y=\"35.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">2.0.0</text><text x=\"320\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">patch: correção</text><text x=\"450\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">minor: algo novo</text><text x=\"600\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">major: algo quebrado</text><text x=\"30\" y=\"98\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">1.1.0</text><text x=\"30\" y=\"116\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">só esta versão</text><rect x=\"299\" y=\"92\" width=\"92\" height=\"32\" rx=\"4\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"5 3\"></rect><rect x=\"305\" y=\"96\" width=\"80\" height=\"24\" rx=\"4\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"345.0\" y=\"108.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--ink)\">1.1.0</text><text x=\"30\" y=\"142\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">~1.1.0</text><text x=\"30\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">só correções</text><rect x=\"299\" y=\"136\" width=\"187\" height=\"32\" rx=\"4\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"5 3\"></rect><text x=\"345\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">1.1.0</text><rect x=\"400\" y=\"140\" width=\"80\" height=\"24\" rx=\"4\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"440.0\" y=\"152.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--ink)\">1.1.1</text><text x=\"30\" y=\"186\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">^1.1.0</text><text x=\"30\" y=\"204\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">correções e adições</text><rect x=\"299\" y=\"180\" width=\"282\" height=\"32\" rx=\"4\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"5 3\"></rect><text x=\"345\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">1.1.0</text><text x=\"440\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">1.1.1</text><rect x=\"495\" y=\"184\" width=\"80\" height=\"24\" rx=\"4\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"535.0\" y=\"196.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--ink)\">1.2.0</text><text x=\"30\" y=\"230\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">latest</text><text x=\"30\" y=\"248\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o que for mais novo</text><rect x=\"584\" y=\"224\" width=\"92\" height=\"32\" rx=\"4\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"5 3\"></rect><rect x=\"590\" y=\"228\" width=\"80\" height=\"24\" rx=\"4\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"630.0\" y=\"240.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--ink)\">2.0.0</text></svg>", "caption": "Uma faixa é o conjunto de versões que você aceita; o gerenciador instala a mais nova dentro dela."}
```

- **`1.1.0`**, sem nada na frente, é exatamente essa versão;
- **`~1.1.0`**, o til, aceita correções: `1.1.x`, de `1.1.0` para cima;
- **`^1.1.0`**, o circunflexo, aceita correções e acréscimos: qualquer `1.x` de `1.1.0` para cima.
  É o que o `npm install` escreve se você não disser outra coisa;
- **`latest`** é uma tag, não uma faixa: um nome que quem publica aponta para uma versão,
  normalmente a mais nova.

Quando o gerenciador instala, ele pega **a versão mais nova dentro da faixa**. O circunflexo é a
escolha comum porque traz correções e acréscimos sem perguntar, e para antes do único tipo de
mudança que tem permissão para quebrar você.

Uma faixa que começa em `0` é mais estrita: `^0.3.1` aceita `0.3.x` e não `0.4.0`, porque antes de
`1.0.0` o semver trata toda versão minor como possivelmente incompatível.

## Atrás da faixa

`npm outdated` compara o que está instalado com a faixa e com a versão mais nova publicada. Aqui a
ana instala uma versão antiga de propósito:

```
ana@dev:~/js/first$ npm install shelf-slug@1.0.0

changed 1 package in 574ms
ana@dev:~/js/first$ node slug.js
grande-sertão:-veredas
ana@dev:~/js/first$ npm outdated
Package     Current  Wanted  Latest  Location                 Depended by
shelf-slug    1.0.0   1.2.0   2.0.0  node_modules/shelf-slug  first
```

**Current** é o que está em `node_modules`. **Wanted** é a versão mais nova que a faixa do
`package.json` aceita. **Latest** é a mais nova publicada. `npm update` a levaria para Wanted. Ir
para Latest é cruzar uma versão major, e isso nunca é automático. `npm outdated` termina com status
de saída 1 quando algo está atrasado, então um build pode usá-lo como verificação.

A saída da `1.0.0` também mostra o bug do acento que a `1.1.1` corrigiu: `sertão` manteve o `ã`.

## Cruzando uma versão major

Pedir `@2` instala a `2.0.0` e reescreve a faixa para `^2.0.0`:

```
ana@dev:~/js/first$ npm install shelf-slug@2

changed 1 package in 534ms
ana@dev:~/js/first$ node slug.js 2>&1 | head -n 5
file:///home/ana/js/first/slug.js:1
import { slug } from "shelf-slug";
         ^^^^
SyntaxError: The requested module 'shelf-slug' does not provide an export named 'slug'
    at ModuleJob._instantiate (node:internal/modules/esm/module_job:226:21)
```

O import de `slug` falha antes de uma linha do programa rodar, porque os imports de ES modules são
verificados quando o módulo carrega. Essa é a quebra que o número major avisou. **Leia o changelog
antes de mudar de versão major**, e então mude o código, aqui para `toSlug`, no mesmo commit.

Semver é uma promessa feita por pessoas, e pessoas erram. Um patch que quebra algo acontece. O
lockfile, a seguir, é o que impede um erro desses de chegar até você sem você perceber.
