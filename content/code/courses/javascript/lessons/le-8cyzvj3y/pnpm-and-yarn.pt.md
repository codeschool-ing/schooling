---
title: pnpm e Yarn
version: 2
---

**O pnpm e o Yarn leem o mesmo `package.json` e o mesmo registro que o npm, e arrumam o resultado no
disco de outro jeito.** O arranjo decide algo que importa mais que espaço em disco: quais pacotes o
seu código consegue importar.

## Uma dependência que você nunca declarou

De volta ao projeto do npm, o `package.json` nomeia só `shelf-format`. Estes dois arquivos importam
dele, e de `shelf-slug`, que ninguém declarou:

```javascript
import { line } from "shelf-format";

console.log(line({ title: "A Hora da Estrela", year: 1977 }));
```

```javascript
import { slug } from "shelf-slug";

console.log(slug("Dom Casmurro"));
```

```
ana@dev:~/js$ cp shelf.js phantom.js lock/ && cp shelf.js phantom.js pnpm/
ana@dev:~/js/lock$ node shelf.js
A Hora da Estrela (1977) /books/a-hora-da-estrela
ana@dev:~/js/lock$ node phantom.js
dom-casmurro
```

Os dois funcionam. O npm põe todo pacote, transitivos incluídos, lado a lado no topo do
`node_modules`, e o Node acha `shelf-slug` ali. Esse import é uma **dependência fantasma**: funciona
hoje só porque `shelf-format` por acaso precisa de `shelf-slug`. Se um `shelf-format` futuro deixar
de usá-lo, ou passar para `shelf-slug@2`, o `phantom.js` quebra sem que uma linha dele tenha mudado.

## pnpm

```
ana@dev:~/js/pnpm$ pnpm add shelf-format
Progress: resolved 1, reused 0, downloaded 0, added 0
Packages: +2
++
Progress: resolved 2, reused 0, downloaded 2, added 2, done

dependencies:
+ shelf-format 1.0.0

Done in 773ms using pnpm v10.28.0
ana@dev:~/js/pnpm$ ls -A node_modules
.modules.yaml
.pnpm
.pnpm-workspace-state-v1.json
shelf-format
ana@dev:~/js/pnpm$ readlink node_modules/shelf-format
.pnpm/shelf-format@1.0.0/node_modules/shelf-format
ana@dev:~/js/pnpm$ ls node_modules/.pnpm
lock.yaml
node_modules
shelf-format@1.0.0
shelf-slug@1.2.0
ana@dev:~/js/pnpm$ readlink node_modules/.pnpm/shelf-format@1.0.0/node_modules/shelf-slug
../../shelf-slug@1.2.0/node_modules/shelf-slug
ana@dev:~/js/pnpm$ pnpm store path
/home/ana/.local/share/pnpm/store/v10
```

O topo do `node_modules` guarda só `shelf-format`, e ele é um **link simbólico** para dentro da
pasta `.pnpm`. Dentro de `.pnpm`, cada pacote tem o seu próprio `node_modules`, com ele mesmo e
links para as suas próprias dependências, e nada mais. `shelf-format` enxerga `shelf-slug`; o
projeto não:

```
ana@dev:~/js/pnpm$ node shelf.js
A Hora da Estrela (1977) /books/a-hora-da-estrela
ana@dev:~/js/pnpm$ node phantom.js 2>&1 | head -n 5
node:internal/modules/package_json_reader:314
  throw new ERR_MODULE_NOT_FOUND(packageName, fileURLToPath(base), null);
        ^

Error [ERR_MODULE_NOT_FOUND]: Cannot find package 'shelf-slug' imported from /home/ana/js/pnpm/phantom.js
```

**O import fantasma falha na hora**, no dia em que é escrito, em vez de no dia em que `shelf-format`
mudar. Os arquivos em si moram uma vez por usuário, no armazém que o `pnpm store path` imprimiu, e
todo projeto aponta para essa cópia em vez de manter a sua. Dez projetos usando a mesma versão a
guardam uma vez.

O pnpm escreve `pnpm-lock.yaml` em vez de `package-lock.json`. Os comandos espelham os do npm:
`pnpm add`, `pnpm install`, `pnpm install --frozen-lockfile` para o que o `npm ci` faz.

## Yarn

O Yarn lê a configuração do `.yarnrc.yml`. Este aponta para o seu registro e permite HTTP
simples para esse endereço, porque o Yarn recusa um registro sem criptografia a menos que o host dele
esteja nesta lista:

```yaml
npmRegistryServer: "http://127.0.0.1:4873"
unsafeHttpWhitelist:
  - 127.0.0.1
```

```
ana@dev:~/js/yarn$ yarn add shelf-format | cut -b5-
YN0000: · Yarn 4.10.3
YN0000: ┌ Resolution step
YN0085: │ + shelf-format@npm:1.0.0, shelf-slug@npm:1.2.0
YN0000: └ Completed
YN0000: ┌ Fetch step
YN0013: │ 2 packages were added to the project (+ 1.78 KiB).
YN0000: └ Completed
YN0000: ┌ Link step
YN0000: │ ESM support for PnP uses the experimental loader API and is therefore experimental
YN0000: └ Completed
YN0000: · Done with warnings in 0s 258ms
ana@dev:~/js/yarn$ ls -A
.pnp.cjs
.pnp.loader.mjs
.yarn
.yarnrc.yml
package.json
yarn.lock
ana@dev:~/js/yarn$ ls ~/.yarn/berry/cache
shelf-format-npm-1.0.0-a4248973cd-10c0.zip
shelf-slug-npm-1.2.0-292c2e27b5-10c0.zip
```

O Yarn começa cada linha com uma seta que a fonte da escola não tem, então `cut -b5-` tira os quatro
primeiros bytes de cada linha, seta e espaço. Tudo depois deles é o que o Yarn imprimiu.

Não há `node_modules`. O padrão do Yarn 4, o **Plug'n'Play**, escreve `.pnp.cjs`, um mapa de cada
pacote para um arquivo zip num cache, e os pacotes ficam compactados. O `node` sozinho não sabe nada
do mapa, então o programa precisa ser iniciado pelo Yarn:

```
ana@dev:~/js$ cp shelf.js phantom.js yarn/
ana@dev:~/js/yarn$ node shelf.js 2>&1 | head -n 5
node:internal/modules/package_json_reader:314
  throw new ERR_MODULE_NOT_FOUND(packageName, fileURLToPath(base), null);
        ^

Error [ERR_MODULE_NOT_FOUND]: Cannot find package 'shelf-format' imported from /home/ana/js/yarn/shelf.js
ana@dev:~/js/yarn$ yarn node shelf.js
A Hora da Estrela (1977) /books/a-hora-da-estrela
ana@dev:~/js/yarn$ yarn node phantom.js 2>&1 | head -n 8

node:internal/modules/run_main:123
    triggerUncaughtException(
    ^
Error: Your application tried to access shelf-slug, but it isn't declared in your dependencies; this makes the require call ambiguous and unsound.

Required package: shelf-slug (via "shelf-slug/package.json")
Required by: /home/ana/js/yarn/phantom.js
```

O `yarn node` carrega o mapa primeiro. O import fantasma é recusado aqui também, com uma frase que
nomeia o pacote não declarado e o arquivo que pediu por ele. O aviso sobre o loader experimental é o
preço do Plug'n'Play com ES modules no Node 22, e o Yarn o repete a cada instalação. Um projeto que
quer um `node_modules` comum no Yarn define `nodeLinker: node-modules` no `.yarnrc.yml`; essa
configuração não foi rodada aqui.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Os mesmos dois pacotes instalados de três jeitos. O npm copia shelf-format e shelf-slug lado a lado em node_modules, então o projeto pode importar qualquer um. O pnpm põe só shelf-format no topo de node_modules, como um link para dentro da pasta .pnpm, onde shelf-format enxerga shelf-slug e o projeto não; os arquivos em si são hard links para um armazém por usuário. O Yarn não escreve node_modules nenhum: .pnp.cjs é um mapa de cada pacote para um arquivo zip num cache, e só responde por pacotes declarados.\"><defs><marker id=\"layouts-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><defs><marker id=\"layouts-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"120\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" font-weight=\"600\" fill=\"var(--phosphor)\">npm</text><rect x=\"20\" y=\"40\" width=\"200\" height=\"150\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"32\" y=\"58\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">node_modules/</text><rect x=\"40\" y=\"76\" width=\"160\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"120.0\" y=\"91.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">shelf-format</text><rect x=\"40\" y=\"120\" width=\"160\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"120.0\" y=\"135.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">shelf-slug</text><text x=\"120\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">plano: todo pacote no topo</text><text x=\"120\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">seu código pode importar</text><text x=\"120\" y=\"230\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">os dois, declarados ou não</text><text x=\"360\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" font-weight=\"600\" fill=\"var(--phosphor)\">pnpm</text><rect x=\"250\" y=\"40\" width=\"220\" height=\"196\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"262\" y=\"58\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">node_modules/</text><rect x=\"270\" y=\"70\" width=\"180\" height=\"28\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">shelf-format</text><rect x=\"262\" y=\"112\" width=\"196\" height=\"112\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 3\"></rect><text x=\"274\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">.pnpm/</text><rect x=\"274\" y=\"140\" width=\"172\" height=\"28\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"154.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">shelf-format@1.0.0</text><rect x=\"274\" y=\"184\" width=\"172\" height=\"28\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"198.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">shelf-slug@1.2.0</text><path d=\"M456 84 L462 84 L462 154 L450 154\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#layouts-ah-phosphor)\"></path><path d=\"M290 168 L290 180\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#layouts-ah-amber)\"></path><text x=\"360\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">só o que o package.json nomeia</text><text x=\"360\" y=\"272\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">fica no topo</text><text x=\"600\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" font-weight=\"600\" fill=\"var(--phosphor)\">Yarn</text><rect x=\"510\" y=\"40\" width=\"180\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">.pnp.cjs</text><text x=\"600.0\" y=\"69.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">um mapa, sem node_modules</text><rect x=\"500\" y=\"120\" width=\"200\" height=\"104\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"512\" y=\"138\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">~/.yarn/berry/cache/</text><rect x=\"516\" y=\"150\" width=\"168\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"163.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">shelf-format…zip</text><rect x=\"516\" y=\"186\" width=\"168\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"199.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">shelf-slug…zip</text><path d=\"M670 80 L670 146\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#layouts-ah-phosphor)\"></path><text x=\"600\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">imports não declarados são recusados</text><text x=\"600\" y=\"272\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">pelo nome, com uma frase</text></svg>", "caption": "Três respostas para onde um pacote mora e quem pode importá-lo."}
```

## Escolhendo

| | npm | pnpm | Yarn 4 |
| --- | --- | --- | --- |
| vem com o Node | sim | não | não |
| lockfile | `package-lock.json` | `pnpm-lock.yaml` | `yarn.lock` |
| instalar a partir do lockfile | `npm ci` | `pnpm install --frozen-lockfile` | `yarn install --immutable` |
| imports não declarados | permitidos | recusados | recusados |

**Use o que o projeto já usa**: o lockfile dele diz qual. Misturar dois gerenciadores num projeto
deixa dois lockfiles que discordam, e o build instala a partir de só um deles. Para um projeto novo,
o npm não precisa de nada instalado; o pnpm é o estrito que economiza disco.
