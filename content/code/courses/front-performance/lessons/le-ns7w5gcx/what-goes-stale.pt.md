---
title: O que fica velho, e quanto custa um novo build
version: 1
---

**Uma página pré-renderizada continua dizendo o que os dados diziam no build, por mais que os dados
tenham mudado desde então.** Nada avisa ninguém. O arquivo é servido com um 200, é uma página
perfeitamente boa, e está errada.

## Vendo acontecer

Com o `static.ts` ainda rodando, renomeie o curso de Git nos dados do planner e peça a página dele:

```
ana@dev:~/planner$ sed -i 's/"title": "Git"/"title": "Git and GitHub"/' public/courses.json
ana@dev:~/planner$ grep -o '"title": "Git[^"]*"' public/courses.json
"title": "Git and GitHub"
ana@dev:~/planner$ curl -s http://localhost:8080/courses/git | grep -o '<h1>[^<]*</h1>'
<h1>Git</h1>
```

**Os dados dizem *Git and GitHub* e a página diz *Git*,** porque a página é o arquivo que o build
escreveu e o build não rodou desde então. Com o JavaScript ligado, a pessoa vê algo pior por um
instante: a página pré-renderizada diz *Git*, depois o script busca os dados novos e redesenha o
título. Um novo build corrige as duas coisas, e o `static.ts` serve o arquivo novo na hora, porque
lê do disco a cada requisição:

```
ana@dev:~/planner$ npm run build:static >/dev/null && curl -s http://localhost:8080/courses/git | grep -o '<h1>[^<]*</h1>'
<h1>Git and GitHub</h1>
```

Devolva o título do mesmo jeito antes de seguir, com as duas palavras trocadas no `sed`, e faça o
build mais uma vez.

## Quanto custa um build conforme o site cresce

Três páginas não levam tempo nenhum. A pergunta é como o tempo cresce. O `gen.ts` troca o plano em
`dist/` por quantos cursos inventados você pedir, uma sessão cada, para que o mesmo `prerender.ts`
possa ser cronometrado num site maior. Salve ao lado do `prerender.ts`:

```typescript
// gen.ts: replace dist/courses.json with N made-up courses, one session each,
// to time prerender.ts on a bigger site. npm run build:static puts the real one back.
import { writeFile } from "node:fs/promises";

const n = Number(process.argv[2]);
const courses = Array.from({ length: n }, (_, i) => ({ slug: `course-${i + 1}`, title: `Course ${i + 1}` }));
const sessions = courses.map((c, i) => ({ id: i + 1, course: c.slug, date: "2026-10-23", minutes: 30, done: false }));
await writeFile("dist/courses.json", JSON.stringify({ courses, sessions }));
console.log(`${n} courses`);
```

Cada rodada começa de um `npm run build` novo, porque o `prerender.ts` precisa da casca vazia:

```
ana@dev:~/planner$ TIMEFORMAT='%R s'; for n in 100 1000 5000; do npm run build >/dev/null && node gen.ts $n && time node prerender.ts >/dev/null; done
100 courses
0.207 s
1000 courses
1.108 s
5000 courses
4.773 s
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"Um gráfico de barras de quanto o prerender.ts levou para três tamanhos de site: 100 cursos em 0,207 segundo, 1000 em 1,108, e 5000 em 4,773.\"><text x=\"130\" y=\"43\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">100 cursos</text><rect x=\"140\" y=\"30\" width=\"20.817096165933375\" height=\"26\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"168.81709616593338\" y=\"43\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">0,207 s</text><text x=\"130\" y=\"87\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">1000 cursos</text><rect x=\"140\" y=\"74\" width=\"111.42677561282214\" height=\"26\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"259.42677561282215\" y=\"87\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">1,108 s</text><text x=\"130\" y=\"131\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">5000 cursos</text><rect x=\"140\" y=\"118\" width=\"480.0\" height=\"26\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"628.0\" y=\"131\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">4,773 s</text><line x1=\"140\" y1=\"170\" x2=\"630\" y2=\"170\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"140\" y=\"186\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">tempo para pré-renderizar todas as páginas, neste computador</text></svg>", "caption": "Toda página, todo build: o tempo segue o número de páginas, mude o que mudar."}
```

**Passados os primeiros cem, o tempo cresce junto com o número de páginas**: de 1000 para 5000
cursos ele foi de 1,108 para 4,773 segundos, uns 0,9 milissegundo para cada página a mais, a maior
parte escrevendo um arquivo. Os primeiros cem quase não custaram nada além de ligar o Node. Nesse
ritmo, um site com cem mil páginas gasta cerca de um minuto renderizando páginas a cada build, e uma
página de verdade, com um motor de templates e uma consulta ao banco cada, custa muitas vezes o que
esta custa.

**E o build renderiza todas as páginas todas as vezes, inclusive os milhares que ninguém mudou.** Um
título corrigido custa tanto quanto um site novo. Esse é o custo que a próxima seção elimina:
renderizar uma página de novo só quando ela é pedida e já está velha o bastante, ou só quando os
seus dados mudaram.
