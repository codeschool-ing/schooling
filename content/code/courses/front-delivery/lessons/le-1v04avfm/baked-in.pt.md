---
title: Uma variável que some antes de a página abrir
version: 1
---

**Num front-end, uma variável de ambiente é lida uma vez, pelo build, e gravada no JavaScript como um
valor.** O navegador que abre a página não tem ambiente para ler: nada de `process.env`, nada de shell,
nada de arquivo `.env`. O que ele recebe é a string que o build pôs ali, e mudar a variável depois não
muda nada até alguém construir de novo.

É o oposto do que a palavra quer dizer num servidor, onde `process.env.PORT` é consultado enquanto o
programa roda e reiniciar com um valor novo basta. A maior parte dos erros desta aula vem de levar a
imagem do servidor para o front-end.

## Vendo acontecer

O planner ganha uma configuração para mostrar isso: o título da página inicial. Um build para um site de
staging pode dizer isso no título, o que impede alguém de confundir uma cópia de teste com a de verdade.
Acrescente um arquivo pequeno para isso:

```typescript
// src/env.ts
export const title = import.meta.env.VITE_TITLE ?? "Study planner";
```

`import.meta.env` é onde o Vite põe as variáveis que ele expõe. Uma que não está definida é
`undefined`, então o `??` cai no nome de sempre do planner. Depois faça o título usá-la, com duas edições
no `view.ts` que o `git diff` mostra:

```
ana@dev:~/planner$ sed -i '2i import { title } from "./env";' src/view.ts
ana@dev:~/planner$ sed -i 's/el("h1", "Study planner")/el("h1", title)/' src/view.ts
ana@dev:~/planner$ git diff
diff --git a/src/view.ts b/src/view.ts
index 735101b..d3a3143 100644
--- a/src/view.ts
+++ b/src/view.ts
@@ -1,4 +1,5 @@
 // src/view.ts
+import { title } from "./env";
 import type { Course, Session } from "./planner";
 
 export interface Actions {
@@ -23,7 +24,7 @@ export function courseList(courses: Course[], week: { planned: number; done: num
     list.append(el("li"));
     list.lastElementChild!.append(link);
   }
-  main.append(el("h1", "Study planner"), el("p", `This week: ${week.planned} min planned, ${week.done} min done`), list);
+  main.append(el("h1", title), el("p", `This week: ${week.planned} min planned, ${week.done} min done`), list);
   return main;
 }
 
```

Construa uma vez sem nada definido, e outra com a variável na linha de comando, e procure o título no
pacote:

```
ana@dev:~/planner$ npm run build > /dev/null
ana@dev:~/planner$ grep -o 'Study planner[^`]*' dist/assets/*.js
Study planner
ana@dev:~/planner$ grep -c VITE_TITLE dist/assets/*.js
0
ana@dev:~/planner$ VITE_TITLE='Study planner (staging)' npm run build > /dev/null
ana@dev:~/planner$ grep -o 'Study planner[^`]*' dist/assets/*.js
Study planner (staging)
```

**O nome da variável nem está no pacote, e o valor dela está.** O Vite trocou
`import.meta.env.VITE_TITLE` pela string literal enquanto empacotava, e o minificador depois eliminou o
`??`, porque uma string nunca é `undefined`. O script que chega ao navegador não faz ideia de que uma
variável esteve envolvida.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Antes do build, src/env.ts lê import.meta.env.VITE_TITLE com um valor padrão, e o shell ou um arquivo .env guarda VITE_TITLE valendo Study planner (staging). O build troca a expressão pelo valor. Depois do build, o pacote contém só a string Study planner (staging); o nome da variável sumiu. O navegador recebe essa string e não tem ambiente próprio.\"><text x=\"20\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">antes do build</text><rect x=\"20\" y=\"34\" width=\"300\" height=\"62\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"32\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">src/env.ts</text><text x=\"32\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">import.meta.env.VITE_TITLE ?? …</text><rect x=\"20\" y=\"108\" width=\"300\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"32\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o shell, ou .env.staging</text><text x=\"32\" y=\"144\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">VITE_TITLE=Study planner (staging)</text><line x1=\"330\" y1=\"96\" x2=\"380\" y2=\"96\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"380.0,96.0 372.6,99.1 372.6,92.9\" fill=\"var(--paper-dim)\"></polygon><text x=\"355\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">build</text><text x=\"390\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">depois do build</text><rect x=\"390\" y=\"34\" width=\"310\" height=\"62\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"402\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">dist/assets/index-….js</text><text x=\"402\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">`Study planner (staging)`</text><text x=\"390\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">o nome VITE_TITLE: sumiu</text><text x=\"390\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o valor: uma string como outra qualquer</text><line x1=\"545\" y1=\"96\" x2=\"545\" y2=\"172\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"545.0,172.0 541.9,164.6 548.1,164.6\" fill=\"var(--paper-dim)\"></polygon><rect x=\"450\" y=\"176\" width=\"190\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"545\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o navegador</text><text x=\"545\" y=\"205\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">não tem ambiente para ler</text></svg>", "caption": "Uma variável de front-end é lida pelo build e gravada no pacote como valor; a página nunca vê a variável."}
```

## O que vem disso

Três consequências, e o resto da aula trata de uma de cada vez:

- **um valor diferente é um build diferente.** Um site de staging e um de produção que diferem numa
  variável são dois builds com dois hashes, não um build configurado duas vezes. A seção sobre um build
  ou vários pesa isso.
- **o valor é público.** É uma string num arquivo que qualquer pessoa pode baixar, o que vai bem para um
  título e é fatal para uma senha. Daqui a duas seções você põe um segredo ali de propósito.
- **o valor fica fixo no momento do build.** Num host em que você muda uma variável num painel, o valor
  antigo continua sendo servido até o próximo deploy, o que é um chamado de suporte esperando para
  acontecer se ninguém souber disso.

Faça o commit da mudança, para o planner carregá-la daqui em diante:

```
ana@dev:~/planner$ git add src/env.ts src/view.ts
ana@dev:~/planner$ git commit -qm "Take the title from VITE_TITLE"
```
