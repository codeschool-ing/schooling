---
title: Limpando o que você fez
version: 1
---

**O que um efeito começa, ele precisa conseguir parar.** O terceiro efeito do `App` escuta as setas
do teclado em qualquer lugar da página, para que as setas para a esquerda e para a direita andem
entre as semanas:

```tsx
useEffect(() => {
  function onKey(event: KeyboardEvent) {
    if (event.target instanceof HTMLInputElement) return
    if (event.key === 'ArrowLeft') setMonday((m) => addDays(m, -7))
    if (event.key === 'ArrowRight') setMonday((m) => addDays(m, 7))
  }
  window.addEventListener('keydown', onKey)
  return () => window.removeEventListener('keydown', onKey)
}, [])
```

O listener ignora teclas apertadas num input, onde as setas movem o cursor, e usa a forma de função
da aula 4 porque o efeito roda uma vez e a própria `monday` dele ficaria presa na primeira semana
para sempre. A limpeza remove exatamente a função que adicionou, e é por isso que `onKey` é uma
função com nome, e não uma anônima escrita duas vezes.

```
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'press ArrowRight' | grep 'Week of'
    - paragraph: Week of 26 Oct 2026
```

Uma tecla, uma semana. **Agora tire a limpeza**, a linha que devolve o `removeEventListener`:

```
ana@dev:~/planner$ sed -i '/return () => window.removeEventListener/d' src/App.tsx
ana@dev:~/planner$ grep -n "addEventListener\|removeEventListener" src/App.tsx
51:    window.addEventListener('keydown', onKey)
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'press ArrowRight' | grep 'Week of'
    - paragraph: Week of 2 Nov 2026
ana@dev:~/planner$ sed -i 's|^    window.addEventListener(.keydown., onKey)$|&\n    return () => window.removeEventListener('"'"'keydown'"'"', onKey)|' src/App.tsx
ana@dev:~/planner$ grep -n "addEventListener\|removeEventListener" src/App.tsx
51:    window.addEventListener('keydown', onKey)
52:    return () => window.removeEventListener('keydown', onKey)
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'press ArrowRight' | grep 'Week of'
    - paragraph: Week of 26 Oct 2026
```

**Uma tecla, duas semanas: 2 de novembro.** O strict mode rodou o efeito, rodou a limpeza dele, que
não existia mais, e rodou o efeito de novo, então dois listeners ficaram presos à janela e os dois
andaram a semana. Com a limpeza de volta, uma tecla anda uma semana de novo.

```schooling-figure
{"svg": "<svg data-fig=\"strict-effects\" viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"Strict mode na primeira carga: efeito, limpeza, efeito. Com limpeza, a contagem de listeners vai 1, 0, 1, e uma tecla anda uma semana. Sem limpeza, o passo de limpeza não faz nada e a contagem vai 1, 1, 2, então uma tecla anda duas semanas.\"><text x=\"20\" y=\"28\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">com a limpeza</text><rect x=\"20\" y=\"40\" width=\"120\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"80.0\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">effect</text><text x=\"80\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">listeners: 1</text><line x1=\"142\" y1=\"57\" x2=\"168\" y2=\"57\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"168.0,57.0 160.5,60.2 160.5,53.8\" fill=\"var(--wire)\"></polygon><rect x=\"170\" y=\"40\" width=\"120\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"230.0\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">cleanup</text><text x=\"230\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">listeners: 0</text><line x1=\"292\" y1=\"57\" x2=\"318\" y2=\"57\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"318.0,57.0 310.5,60.2 310.5,53.8\" fill=\"var(--wire)\"></polygon><rect x=\"320\" y=\"40\" width=\"120\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"380.0\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">effect</text><text x=\"380\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">listeners: 1</text><text x=\"480\" y=\"57\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">→ uma semana por tecla</text><text x=\"20\" y=\"118\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">sem ela</text><rect x=\"20\" y=\"130\" width=\"120\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"80.0\" y=\"147.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">effect</text><text x=\"80\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">listeners: 1</text><line x1=\"142\" y1=\"147\" x2=\"168\" y2=\"147\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"168.0,147.0 160.5,150.2 160.5,143.8\" fill=\"var(--wire)\"></polygon><rect x=\"170\" y=\"130\" width=\"120\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"230.0\" y=\"147.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">cleanup</text><text x=\"230\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">listeners: 1</text><line x1=\"292\" y1=\"147\" x2=\"318\" y2=\"147\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"318.0,147.0 310.5,150.2 310.5,143.8\" fill=\"var(--wire)\"></polygon><rect x=\"320\" y=\"130\" width=\"120\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"380.0\" y=\"147.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">effect</text><text x=\"380\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">listeners: 2</text><text x=\"480\" y=\"147\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">→ duas semanas por tecla</text></svg>", "caption": "A segunda execução do strict mode faz uma limpeza ausente aparecer na primeira carga.", "same": ["listeners: 1", "listeners: 0", "listeners: 2"]}
```

É para isso que serve a segunda execução do strict mode. Ele não enxerga o seu listener, mas consegue
tornar visível uma limpeza ausente na primeira carga, em desenvolvimento, em vez do dia em que um
usuário abre e fecha a tela do curso trinta vezes e cada seta anda trinta semanas. **Um efeito que se
comporta igual quando é rodado, limpo e rodado de novo é um efeito que limpa direito**, e esse é o
único tipo que vale publicar.

Uma nota sobre as próprias teclas. Setas não são caracteres imprimíveis, então a regra da WCAG sobre
atalhos de um caractere não se aplica a elas; o planejador ainda oferece a mesma ação em dois botões,
que é a versão que todo usuário alcança. Um atalho é um extra, nunca o único caminho.
