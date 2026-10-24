---
title: A folha de estilo, dentro da página
version: 1
---

**O Lighthouse diz desde a aula 6 que a folha de estilo bloqueia a primeira pintura**, e isso vale para
toda folha de estilo que uma página cita: o navegador a pede quando lê o `<link>`, e não pinta nada até
tê-la. Num celular lento isso é uma ida e volta com a tela em branco. Meça como está:

```
ana@dev:~/planner$ npm run lighthouse -- http://localhost:3000/courses/git >/dev/null && node tools/report.ts report.report.json | grep -E 'performance|FCP|LCP|insight'
performance 100, throttling simulate
  FCP  1.0 s    weight 10
  LCP  1.6 s    weight 25
  insight: Use efficient cache lifetimes, Est savings of 90 KiB
  insight: Improve image delivery, Est savings of 29 KiB
  insight: Network dependency tree
  insight: Render-blocking requests, Est savings of 150 ms
```

**O CSS de que uma página precisa para desenhar a primeira tela se chama CSS crítico**, e a correção é
pô-lo no HTML, num elemento `<style>`, para ele chegar com a página e não bloquear nada. A folha de estilo
do planner é toda crítica, e pequena, então ela inteira pode ir.

O `server.ts` lê a casca que o build escreveu uma vez, ao iniciar. Troque essa linha por estas, que acham o
`<link>` que o build escreveu, leem o arquivo que ele cita e põem o conteúdo no lugar dele na casca:

```typescript
// The shell the build wrote, with its stylesheet inlined: the CSS is small, and inside
// the HTML it arrives with it rather than one round trip later. The replacement is a
// function so that a "$" in the CSS is not read as part of a pattern.
const built = await readFile(join(dist, "index.html"), "utf8");
const link = built.match(/<link rel="stylesheet"[^>]*href="([^"]+)">/)!;
const css = await readFile(join(dist, link[1]), "utf8");
const shell = built.replace(link[0], () => `<style>${css}</style>`);
```

Faça o build, reinicie e meça:

```
ana@dev:~/planner$ npm run lighthouse -- http://localhost:3000/courses/git >/dev/null && node tools/report.ts report.report.json | grep -E 'performance|FCP|LCP|insight'
performance 100, throttling simulate
  FCP  0.8 s    weight 10
  LCP  1.4 s    weight 25
  insight: Use efficient cache lifetimes, Est savings of 89 KiB
  insight: Improve image delivery, Est savings of 29 KiB
  insight: Network dependency tree
```

**O Render-blocking requests sumiu, e a primeira pintura veio para a frente.** A cascata mostra por quê,
numa rede desacelerada: a folha de estilo não é mais uma requisição.

```
ana@dev:~/planner$ node tools/waterfall.ts http://localhost:3000/courses/git --slow
/courses/git                   306 ms    1302 B  ######
/fonts/plex-400.woff2          623 ms   22611 B        ######
/fonts/plex-700.woff2          624 ms   22842 B        ######
/assets/index-yh2nfJj3.js      628 ms    6918 B        #######
/covers/git-800.avif           629 ms   38037 B        #######
```

## O que embutir custa

- **Ela é mandada de novo em toda página.** Uma folha de estilo citada é baixada uma vez e guardada no
  cache, que a aula 9 configura; uma embutida faz parte de toda resposta HTML. Para meio kilobyte isso não é
  nada. Para uma folha de estilo de cem kilobytes são cem kilobytes em toda página.
- Então, para uma folha de estilo grande, a técnica é **embutir só a parte crítica** e carregar o resto sem
  bloquear. Ferramentas fazem a extração: renderizam a página, veem que regras se aplicam ao que está na
  primeira tela, e embutem essas. O Beasties é uma, e o Angular o roda em todo build de produção.
- **O CSS agora está em dois lugares**: o arquivo que o build escreveu, e a página. O `server.ts` lê o
  arquivo que o build citou, então os dois não podem se separar, que é o motivo de lê-lo em vez de copiá-lo.
