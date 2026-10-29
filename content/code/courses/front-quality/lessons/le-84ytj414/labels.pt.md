---
title: Um placeholder não é um rótulo
version: 1
---

**Um placeholder é um texto cinza dentro de um campo vazio, e some no momento em que alguém digita.**
Ele parece um rótulo para quem vê o formulário uma vez. E falha com todo mundo mais:

- **Uma pessoa que é interrompida** volta a um campo que diz `15` e já não diz o que é o 15. Quem tem
  pouca memória de curto prazo passa por isso toda vez.
- **Uma pessoa que usa um leitor de tela** pode ouvir o placeholder ou não: a especificação do HTML diz
  que um placeholder é uma dica, não um rótulo, e a tecnologia assistiva o trata como último recurso.
- **Uma pessoa com baixa visão** encontra texto cinza sobre branco, que é exatamente o contraste que um
  placeholder é feito para não ter.

A WCAG, o padrão de acessibilidade que a aula 10 apresenta, diz isso no critério de sucesso 3.3.2: um
campo precisa de um rótulo ou de instruções, e um rótulo visível é o jeito simples de dar um. **Um
teste que acha os campos pelos rótulos falha até os rótulos existirem**, e é por isso que o teste
reescrito está vermelho e por isso que isso é o teste funcionando.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" data-fig=\"l03-names\" aria-label=\"Duas versões do campo Minutes do planner, cada uma mostrada como marcação à esquerda e como o que a árvore de acessibilidade guarda à direita. Antes: um input com placeholder Minutes e sem rótulo; a árvore guarda um spinbutton cujo nome vem do placeholder como último recurso, e o getByLabelText não acha nada. Depois: o mesmo input dentro de um label que diz Minutes; a árvore guarda um spinbutton chamado Minutes, vindo do rótulo, e tanto o getByLabelText quanto um leitor de tela o acham.\"><defs><marker id=\"l03-names-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"170\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">a marcação</text><text x=\"450\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">a árvore de acessibilidade</text><text x=\"640\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">getByLabelText(\"Minutes\")</text><text x=\"14\" y=\"85\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">antes</text><rect x=\"70\" y=\"40\" width=\"200\" height=\"90\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"80\" y=\"73.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">&lt;input name=\"minutes\"</text><text x=\"80\" y=\"85.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">  type=\"number\"</text><text x=\"80\" y=\"97.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">  placeholder=\"Minutes\"&gt;</text><rect x=\"330\" y=\"40\" width=\"240\" height=\"90\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"450.0\" y=\"73.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">spinbutton</text><text x=\"450.0\" y=\"85.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">nome: \"Minutes\", do placeholder,</text><text x=\"450.0\" y=\"97.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">último recurso, e some da tela ao digitar</text><path d=\"M270 85 L330 85\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l03-names-ah-paper-dim)\"></path><path d=\"M570 85 L595 85\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l03-names-ah-paper-dim)\"></path><rect x=\"595\" y=\"65\" width=\"110\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"650.0\" y=\"85.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">nada encontrado</text><text x=\"14\" y=\"195\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">depois</text><rect x=\"70\" y=\"150\" width=\"200\" height=\"90\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"80\" y=\"183.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">&lt;label&gt;Minutes</text><text x=\"80\" y=\"195.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">  &lt;input name=\"minutes\"</text><text x=\"80\" y=\"207.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">    type=\"number\"&gt;&lt;/label&gt;</text><rect x=\"330\" y=\"150\" width=\"240\" height=\"90\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"450.0\" y=\"189.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">spinbutton</text><text x=\"450.0\" y=\"201.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">nome: \"Minutes\", do rótulo</text><path d=\"M270 195 L330 195\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l03-names-ah-paper-dim)\"></path><path d=\"M570 195 L595 195\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l03-names-ah-paper-dim)\"></path><rect x=\"595\" y=\"175\" width=\"110\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"650.0\" y=\"195.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">o campo</text></svg>", "caption": "A árvore é o que um leitor de tela lê e o que as buscas perguntam. Um rótulo dá ao campo um nome que fica; um placeholder empresta um até a primeira tecla.", "same": ["spinbutton"]}
```

## A correção

Um `<label>` em volta do seu campo é o jeito mais simples de ligar os dois: o texto do rótulo vira o
nome do campo, um clique no texto põe o cursor no campo, e um leitor de tela diz os dois. No
`src/view.ts` o formulário fica assim:

```
ana@dev:~/planner$ git diff src/view.ts
diff --git a/src/view.ts b/src/view.ts
index 2a75128..31c6742 100644
--- a/src/view.ts
+++ b/src/view.ts
@@ -36,8 +36,8 @@ export function render(root: HTMLElement, plan: Plan, day: string, route: string
     list.append(item);
   }
   const form = el("form", "", "add");
-  form.innerHTML = `<input name="date" type="date" placeholder="Date">
-    <input name="minutes" type="number" placeholder="Minutes">
+  form.innerHTML = `<label>Date <input name="date" type="date"></label>
+    <label>Minutes <input name="minutes" type="number" min="1" max="600"></label>
     <button>Add session</button>`;
   form.addEventListener("submit", (event) => {
     event.preventDefault();
```

O `min` e o `max` dizem a faixa no próprio campo, então o campo numérico do navegador recusa um valor
fora dela, e a pessoa aprende a regra antes de o `addSession` precisar recusar. Os placeholders saem:
o rótulo diz o que eles diziam, e fica lá.

```
ana@dev:~/planner$ npx vitest run src/view.test.ts

 RUN  v5.0.5 /home/ana/planner


 Test Files  1 passed (1)
      Tests  3 passed (3)
   Start at  19:53:22
   Duration  1.08s (environment 58%, tests 26%, import 9%, transform 6%)
```

Os três passam, e o formulário do planner agora tem nomes que um teste, um leitor de tela e uma pessoa
com um formulário pela metade conseguem ler. **Nada nos testes de componente mudou para isto
passar**; a página mudou para atendê-los, que é a direção em que isso deve sempre ir.

```
ana@dev:~/planner$ git add -A
ana@dev:~/planner$ git commit -q -m "Label the form fields, and test by role and label"
```
