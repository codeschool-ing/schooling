---
title: Duas correções, e o teste verde
version: 1
---

**Cada achado tem uma correção de uma linha, e cada correção é uma decisão, não um jeito de calar o axe.**

**Os ícones são decoração.** Cada um fica ao lado do nome do curso, dentro do mesmo link, e não diz nada
que o nome não diga: um leitor de tela lendo *book.svg, HTML and CSS* diz à pessoa menos do que um que lê
*HTML and CSS*. Uma imagem decorativa é marcada com um `alt` **vazio**, que diz "pule-me" e não é a mesma
coisa que não ter `alt`. A aula 12 trata da diferença entre os dois tipos de imagem e de como saber qual é
qual.

**O cinza de uma sessão feita é claro demais.** `#6b6b6b` ainda é bem mais claro que o texto comum do
planner e chega a 5,33:1 sobre branco, acima dos 4,5 que o AA pede. A aula 13 calcula razões como essas à
mão e põe a conta num teste próprio.

```
ana@dev:~/planner$ git diff src
diff --git a/src/style.css b/src/style.css
index d3d4775..ada6bc6 100644
--- a/src/style.css
+++ b/src/style.css
@@ -5,7 +5,7 @@ ul { padding: 0; list-style: none; }
 li { padding: 0.4rem 0; border-bottom: 1px solid #ddd; }
 .courses img { vertical-align: middle; margin-right: 0.4rem; }
 .mins { color: #555; }
-.session.done { color: #aaa; }
+.session.done { color: #6b6b6b; }
 .tick { font-size: 0.7rem; padding: 1px 4px; }
 button:focus { outline: none; }
 .add { display: flex; gap: 0.5rem; margin: 1rem 0; }
diff --git a/src/view.ts b/src/view.ts
index 0a81f3f..44588f5 100644
--- a/src/view.ts
+++ b/src/view.ts
@@ -12,6 +12,7 @@ export function render(root: HTMLElement, plan: Plan, day: string, route: string
       link.href = `#/course/${c.id}`;
       const icon = el("img");
       icon.src = "/book.svg";
+      icon.alt = "";
       link.prepend(icon);
       const item = el("li");
       item.append(link, el("span", ` ${weekTotal(plan, day, c.id)} min this week`, "mins"));
```

```
ana@dev:~/planner$ npx playwright test e2e/a11y.spec.ts --reporter=list

Running 2 tests using 1 worker

  ✓  1 [chromium] › e2e/a11y.spec.ts:12:3 › the course list breaks no WCAG 2.2 AA rule axe can check (1.2s)
  ✓  2 [chromium] › e2e/a11y.spec.ts:12:3 › a course page breaks no WCAG 2.2 AA rule axe can check (1.0s)

  2 passed (5.4s)
```

**As duas páginas passam, e o relatório concorda:**

```
ana@dev:~/planner$ node server/axe.mjs http://localhost:5173/ 'http://localhost:5173/#/course/javascript'
http://localhost:5173/: 0 rule(s) broken
http://localhost:5173/#/course/javascript: 0 rule(s) broken
```

```
ana@dev:~/planner$ git add -A
ana@dev:~/planner$ git commit -q -m "axe at WCAG 2.2 AA: decorative icons, and a done grey that reads"
```

## O que o teste promete agora

Que nenhuma regra que o axe consegue verificar na WCAG 2.2 AA está quebrada nestas duas páginas, neste
estado, hoje. Cada parte dessa frase é um limite. Outros estados, um curso sem sessões ou um formulário
mostrando um erro, são outras páginas para o axe, e a aula 12 acrescenta uma. E "regras que o axe consegue
verificar" é o maior limite de todos, que é a próxima seção.
