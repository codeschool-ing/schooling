---
title: Dez componentes renderizados, dez nós de texto mudados
version: 1
---

**Renderizar todos os componentes não reconstruiu a página.** O commit muda a página só onde a
árvore nova difere da antiga, e esta seção conta o quão pouco isso é. Outro arquivo temporário,
`src/watch.ts`, pede ao navegador que relate cada mudança feita dentro de `#root`:

```typescript
// For lesson 3 only: after each change React makes to the page, say how many
// nodes it touched and what they now read.
const root = document.getElementById('root')!
new MutationObserver((records) => {
  const touched = records.map((r) => `${r.type} "${r.target.textContent}"`)
  console.log(`DOM: ${records.length} change(s)`, touched.join(', '))
}).observe(root, { subtree: true, childList: true, characterData: true, attributes: true })
```

Um `MutationObserver` é o jeito do próprio navegador de vigiar uma parte da página; o React não sabe
nada dele. Importado no topo do `main.tsx`, ele relata cada commit numa linha do console:

```
ana@dev:~/planner$ sed -i '1i import "./watch"' src/main.tsx
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --quiet --do 'click button Next week'
render App
render WeekNav
render WeekSummary
render CourseList
render CourseCard
render Card
render CourseCard
render Card
render CourseCard
render Card
DOM: 1 change(s) childList "Study plannerPrevious weekNext weekWeek of 19 Oct 202680 of 195 minutes doneStatistics2 sessions · 90 minSpanish2 sessions · 60 minOrganic chemistry1 session · 45 min"
-- click button Next week
render App
render WeekNav
render WeekSummary
render CourseList
render CourseCard
render Card
render CourseCard
render Card
render CourseCard
render Card
DOM: 10 change(s) characterData "26 Oct 2026", characterData "0", characterData "0", characterData "0", characterData "0", characterData "0", characterData "0", characterData "0", characterData "sessions", characterData "0"
```

Na carga, **uma mudança**: o React inseriu a árvore inteira em `#root` de uma vez, com o texto todo
num nó só. Depois de "Next week", dez mudanças, todas `characterData`, que é a palavra do navegador
para o texto dentro de um nó de texto que já existe. "19 Oct 2026" virou "26 Oct 2026", oito números
viraram `0`, e a palavra "session" embaixo de Organic chemistry virou "sessions", porque uma sessão
tinha virado zero. **Nenhum elemento foi criado ou removido, e nenhum atributo mexeu.** Os títulos,
os botões e os articles são os mesmos nós do DOM de antes do clique.

Voltar no outro sentido muda os mesmos dez nós de volta:

```
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --quiet --do 'click button Next week' --do 'click button Previous week'
render App
render WeekNav
render WeekSummary
render CourseList
render CourseCard
render Card
render CourseCard
render Card
render CourseCard
render Card
DOM: 1 change(s) childList "Study plannerPrevious weekNext weekWeek of 19 Oct 202680 of 195 minutes doneStatistics2 sessions · 90 minSpanish2 sessions · 60 minOrganic chemistry1 session · 45 min"
-- click button Next week
render App
render WeekNav
render WeekSummary
render CourseList
render CourseCard
render Card
render CourseCard
render Card
render CourseCard
render Card
DOM: 10 change(s) characterData "26 Oct 2026", characterData "0", characterData "0", characterData "0", characterData "0", characterData "0", characterData "0", characterData "0", characterData "sessions", characterData "0"
-- click button Previous week
render App
render WeekNav
render WeekSummary
render CourseList
render CourseCard
render Card
render CourseCard
render Card
render CourseCard
render Card
DOM: 10 change(s) characterData "19 Oct 2026", characterData "80", characterData "195", characterData "2", characterData "90", characterData "2", characterData "60", characterData "1", characterData "session", characterData "45"
```

```schooling-figure
{"svg": "<svg data-fig=\"diff\" viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Duas colunas da mesma árvore, antes e depois do clique. A maioria dos nós aparece igual nas duas e está marcada como mantida. Só os nós de texto diferem: 19 Oct 2026 vira 26 Oct 2026, 80 e 195 viram 0, e as linhas dos cursos mudam os números. Setas marcam as dez mudanças de texto; nenhum elemento é criado ou removido.\"><text x=\"170\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">árvore anterior</text><text x=\"550\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">árvore nova</text><rect x=\"40\" y=\"38\" width=\"260\" height=\"20\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"170.0\" y=\"48.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">&lt;h1&gt; Study planner</text><rect x=\"420\" y=\"38\" width=\"260\" height=\"20\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"550.0\" y=\"48.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">&lt;h1&gt; Study planner</text><text x=\"360\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">mantido</text><rect x=\"40\" y=\"63\" width=\"260\" height=\"20\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"170.0\" y=\"73.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">&lt;button&gt; Previous week</text><rect x=\"420\" y=\"63\" width=\"260\" height=\"20\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"550.0\" y=\"73.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">&lt;button&gt; Previous week</text><text x=\"360\" y=\"73\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">mantido</text><rect x=\"40\" y=\"88\" width=\"260\" height=\"20\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"170.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">&lt;p&gt; Week of 19 Oct 2026</text><rect x=\"420\" y=\"88\" width=\"260\" height=\"20\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"550.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">&lt;p&gt; Week of 26 Oct 2026</text><line x1=\"302\" y1=\"98\" x2=\"418\" y2=\"98\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"418.0,98.0 410.5,101.2 410.5,94.8\" fill=\"var(--amber)\"></polygon><rect x=\"40\" y=\"113\" width=\"260\" height=\"20\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"170.0\" y=\"123.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">&lt;p&gt; 80 of 195 minutes done</text><rect x=\"420\" y=\"113\" width=\"260\" height=\"20\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"550.0\" y=\"123.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">&lt;p&gt; 0 of 0 minutes done</text><line x1=\"302\" y1=\"123\" x2=\"418\" y2=\"123\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"418.0,123.0 410.5,126.2 410.5,119.8\" fill=\"var(--amber)\"></polygon><rect x=\"40\" y=\"138\" width=\"260\" height=\"20\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"170.0\" y=\"148.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">&lt;h2&gt; Statistics</text><rect x=\"420\" y=\"138\" width=\"260\" height=\"20\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"550.0\" y=\"148.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">&lt;h2&gt; Statistics</text><text x=\"360\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">mantido</text><rect x=\"40\" y=\"163\" width=\"260\" height=\"20\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"170.0\" y=\"173.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">&lt;p&gt; 2 sessions · 90 min</text><rect x=\"420\" y=\"163\" width=\"260\" height=\"20\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"550.0\" y=\"173.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">&lt;p&gt; 0 sessions · 0 min</text><line x1=\"302\" y1=\"173\" x2=\"418\" y2=\"173\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"418.0,173.0 410.5,176.2 410.5,169.8\" fill=\"var(--amber)\"></polygon><rect x=\"40\" y=\"188\" width=\"260\" height=\"20\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"170.0\" y=\"198.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">&lt;h2&gt; Organic chemistry</text><rect x=\"420\" y=\"188\" width=\"260\" height=\"20\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"550.0\" y=\"198.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">&lt;h2&gt; Organic chemistry</text><text x=\"360\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">mantido</text><rect x=\"40\" y=\"213\" width=\"260\" height=\"20\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"170.0\" y=\"223.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">&lt;p&gt; 1 session · 45 min</text><rect x=\"420\" y=\"213\" width=\"260\" height=\"20\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"550.0\" y=\"223.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">&lt;p&gt; 0 sessions · 0 min</text><line x1=\"302\" y1=\"223\" x2=\"418\" y2=\"223\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"418.0,223.0 410.5,226.2 410.5,219.8\" fill=\"var(--amber)\"></polygon><text x=\"360\" y=\"242\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">só o texto mudou: 10 registros characterData</text></svg>", "caption": "O commit compara duas árvores e escreve só a diferença."}
```

Duas coisas a tirar disso. **Renderizar de novo é barato perto do que parece**, porque a parte cara,
mudar a página, fica limitada à diferença. E os nós que não mudaram guardam tudo o que o navegador
associa a eles: um botão que tinha o foco continua com ele depois do clique, e o texto que um
usuário selecionou continua selecionado. Esse segundo ponto é por que o React se esforça para manter
um nó em vez de recriá-lo, e a próxima seção mostra como ele decide qual nó é qual.
