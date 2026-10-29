---
title: A verificação que recusou o formulário
version: 1
---

**Qualquer página da web pode conter um formulário que envia para o planner.** Uma página de outro site,
aberta no mesmo navegador, pode ter um `<form method="POST" action="http://localhost:3000/courses/guitar?/add">`
com campos escondidos e um script que o envia no instante em que a página carrega. O navegador o envia, e
uma action que confiasse em todo `POST` salvaria uma sessão que o estudante nunca pediu. Num site em que a
pessoa está logada, o mesmo truque troca uma senha ou movimenta dinheiro. Hoje os navegadores seguram a
maior parte dos cookies numa requisição dessas, o que enfraquece o ataque, mas não todos, e não em todo
navegador. O ataque se chama **cross-site request forgery**, CSRF, falsificação de requisição entre sites.

**O SvelteKit recusa um formulário enviado de outro site.** Um navegador que envia um formulário diz de
onde veio a página que o enviou, num cabeçalho chamado `Origin`. Num build, o SvelteKit compara isso com a
sua própria origem, o esquema, o host e a porta em que o servidor acredita estar respondendo, e, se forem
diferentes, responde 403 sem rodar a action. O servidor de desenvolvimento não verifica, e é por isso que o
formulário funcionava lá.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Uma página em outro site, elsewhere.example, tem um formulário escondido que envia para o planner em localhost 3000. O navegador manda o POST com um cabeçalho Origin dizendo https://elsewhere.example. O servidor do planner compara com a sua própria origem, http://localhost:3000, vê que são diferentes e responde 403 sem rodar a action. Um formulário na própria página do planner manda a origem do planner e passa.\"><rect x=\"20\" y=\"30\" width=\"220\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"130\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">elsewhere.example</text><text x=\"130\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">um formulário escondido, enviado ao carregar</text><rect x=\"20\" y=\"140\" width=\"220\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"130\" y=\"162\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">localhost:3000</text><text x=\"130\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">o formulário do próprio planner</text><rect x=\"480\" y=\"85\" width=\"220\" height=\"70\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"590\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">o servidor do planner</text><text x=\"590\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">Origin === http://localhost:3000 ?</text><line x1=\"240\" y1=\"65\" x2=\"478\" y2=\"108\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"478.0,108.0 470.2,109.8 471.3,103.6\" fill=\"var(--amber)\"></polygon><text x=\"360\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--amber)\">Origin: https://elsewhere.example</text><line x1=\"240\" y1=\"175\" x2=\"478\" y2=\"132\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"478.0,132.0 471.3,136.4 470.2,130.2\" fill=\"var(--phosphor)\"></polygon><text x=\"360\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">Origin: http://localhost:3000</text><text x=\"590\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">não: 403, a action nem roda</text><text x=\"590\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">sim: a action roda</text><text x=\"360\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o próprio navegador escreve o cabeçalho Origin; uma página não consegue mudá-lo</text></svg>", "caption": "Um formulário de outro site leva a origem desse site, e um servidor SvelteKit de build o recusa."}
```

O servidor do build recusou o próprio formulário do planner porque acredita numa coisa errada sobre si
mesmo. Ele foi chamado em `http://localhost:3000`, mas o `adapter-node` não consegue saber, por uma
requisição, se a conexão era criptografada, então supõe `https`, o que está certo para a publicação comum:
o servidor Node fica atrás de um proxy que guarda o certificado e fala com os visitantes por HTTPS. Neste
computador não há proxy, a origem que o navegador manda é `http://localhost:3000`, e as duas não batem.

## Dizendo ao servidor onde ele mora

**`paths.origin`** na configuração diz qual é a origem, em vez de deixar o servidor descobrir. Leia-a de uma
variável de ambiente, para que cada lugar para o qual o planner é construído possa dar a sua. Substitua o
`vite.config.js`:

```schooling-example
{"language": "javascript", "file": "vite.config.js", "parts": [
 {"code": "import adapter from '@sveltejs/adapter-node';\nimport { sveltekit } from '@sveltejs/kit/vite';\nimport { defineConfig } from 'vite';\n\nexport default defineConfig({\n\tplugins: [\n\t\tsveltekit({\n\t\t\tcompilerOptions: {\n\t\t\t\t// Force runes mode for the project, except for libraries. Can be removed in svelte 6.\n\t\t\t\trunes: ({ filename }) =>\n\t\t\t\t\tfilename.split(/[/\\\\]/).includes('node_modules') ? undefined : true\n\t\t\t},\n\n\t\t\t// adapter-node builds a Node server: `npm run build`, then `node build`.\n\t\t\tadapter: adapter(),"},
 {"code": "\t\t\t// The address the planner is served at, given when it is built:\n\t\t\t//   ORIGIN=http://localhost:3000 npm run build\n\t\t\tpaths: { origin: process.env.ORIGIN }\n\t\t})\n\t]\n});", "note": "O `vite.config.js` roda quando o build começa, então a variável é lida nessa hora, e o valor fica embutido. Quando ela não está definida, o servidor descobre a origem a cada requisição, como antes."}
]}
```

Pare o servidor com Ctrl-C, faça o build de novo com a origem informada e inicie-o outra vez:

```
ana@dev:~/planner$ ORIGIN=http://localhost:3000 npm run build > /dev/null 2>&1; echo $?
0
```

```
ana@dev:~/planner$ look http://localhost:3000/courses/guitar --fill 'Date=2026-10-22' --click 'Add session' --wait 500 | head -6
-- fill Date=2026-10-22
-- click Add session
-- wait 500
at /courses/guitar?week=2026-10-19
title: Guitar · Study planner
- main:
```

O formulário funciona. Um formulário de outro lugar continua não funcionando, e nem uma requisição que não
diz de onde veio, que é a cara de um script fora de qualquer navegador:

```
ana@dev:~/planner$ curl -s -o /dev/null -w '%{http_code}\n' -H 'Accept: text/html' -H 'Origin: https://elsewhere.example' -d 'date=2026-10-23&minutes=30' 'http://localhost:3000/courses/guitar?/add'
403
ana@dev:~/planner$ curl -s -o /dev/null -w '%{http_code}\n' -H 'Accept: text/html' -d 'date=2026-10-23&minutes=30' 'http://localhost:3000/courses/guitar?/add'
403
```

**Vale a pena manter a verificação exatamente como está.** O SvelteKit tem uma opção, `csrf.trustedOrigins`,
para listar outros sites que podem enviar formulários, o que uma aplicação com um provedor de pagamento ou
uma página de login separados às vezes precisa. Listar `'*'` ali desliga a proteção, e o conselho para um
403 como o de cima é nunca recorrer a isso: a causa é um servidor que não sabe o próprio endereço, e a cura
é dizer a ele.
