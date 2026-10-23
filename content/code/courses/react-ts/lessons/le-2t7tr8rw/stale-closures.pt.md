---
title: Closures velhas
version: 1
---

**Uma função criada durante uma renderização vê os valores daquela renderização, enquanto a função
viver.** É isso que a aula 6 do `javascript` chamou de closure, e num componente quer dizer que um
callback guardado por algo fora do React (um intervalo, um listener, uma promise) continua lendo o
estado da renderização que o criou. Isso não quebra regra nenhuma dos hooks, e é o bug de hook mais
comum que existe.

Aqui está um pequeno hook próprio, acrescentado ao fim do `App.tsx` para esta seção: a cada segundo,
ele registra qual semana enxerga. O array vazio diz que o efeito não lê nada, o que é falso:

```tsx

// A mistake, on purpose: an interval that reads state, with an empty array.
export function useWeekLogger(monday: string) {
  useEffect(() => {
    const id = setInterval(() => console.log('the interval sees', monday), 1000)
    return () => clearInterval(id)
  }, [])
}
```

O `App` o chama com `monday`. O `look` espera pouco mais de dois segundos, aperta "Next week" e espera
de novo; o `uniq -c` junta linhas idênticas numa contagem:

```
ana@dev:~/planner$ sed -i 's|^  const \[openId, setOpenId\] = useState<string \| null>(null)$|&\n  useWeekLogger(monday)|' src/App.tsx
ana@dev:~/planner$ grep -n "useWeekLogger" src/App.tsx
17:  useWeekLogger(monday)
91:export function useWeekLogger(monday: string) {
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --quiet --do 'wait 2200' --do 'click button Next week' --do 'wait 2200' | uniq -c
      1 -- wait 2200
      2 the interval sees 2026-10-19
      1 -- click button Next week
      1 -- wait 2200
      3 the interval sees 2026-10-19
ana@dev:~/planner$ npm run lint 2>&1 | grep -A 2 exhaustive
  ! react-hooks(exhaustive-deps): React Hook useEffect has a missing dependency: 'monday'
    ,-[src/App.tsx:95:6]
 92 |   useEffect(() => {
```

**Depois de "Next week", o intervalo ainda vê 19 de outubro.** Ele foi criado no efeito da primeira
renderização, capturou a `monday` da primeira renderização, e como o array estava vazio o efeito
nunca rodou de novo para substituí-lo. A tela andou; o intervalo não. O Oxlint disse isso antes de
qualquer coisa rodar, com o mesmo aviso da aula 5.

```schooling-figure
{"svg": "<svg data-fig=\"closure\" viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"A renderização 1 tem monday 19 Oct e cria um intervalo que a captura. A renderização 2 tem monday 26 Oct. Com array vazio, o intervalo da renderização 1 continua rodando e imprimindo 19 Oct. Com monday no array, o efeito da renderização 2 limpa o intervalo antigo e começa um que imprime 26 Oct.\"><rect x=\"20\" y=\"30\" width=\"200\" height=\"44\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"120.0\" y=\"45.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">render 1</text><text x=\"120.0\" y=\"59.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">monday = 19 Oct</text><rect x=\"20\" y=\"120\" width=\"200\" height=\"44\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"120.0\" y=\"135.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">render 2</text><text x=\"120.0\" y=\"149.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">monday = 26 Oct</text><rect x=\"300\" y=\"30\" width=\"180\" height=\"44\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"390.0\" y=\"45.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">interval A</text><text x=\"390.0\" y=\"59.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">logs 19 Oct</text><line x1=\"222\" y1=\"52\" x2=\"298\" y2=\"52\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"298.0,52.0 290.5,55.2 290.5,48.8\" fill=\"var(--amber)\"></polygon><text x=\"590\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">com []: A roda para sempre</text><line x1=\"480\" y1=\"52\" x2=\"510\" y2=\"52\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></line><polygon points=\"510.0,52.0 502.5,55.2 502.5,48.8\" fill=\"var(--amber)\"></polygon><rect x=\"300\" y=\"120\" width=\"180\" height=\"44\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"390.0\" y=\"135.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">interval B</text><text x=\"390.0\" y=\"149.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">logs 26 Oct</text><line x1=\"222\" y1=\"142\" x2=\"298\" y2=\"142\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"298.0,142.0 290.5,145.2 290.5,138.8\" fill=\"var(--phosphor)\"></polygon><text x=\"590\" y=\"142\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">com [monday]: A limpo, B roda</text></svg>", "caption": "Um callback vê a renderização que o criou. Rode o efeito de novo, e um callback novo vê a renderização nova."}
```

Com `[monday]`, o efeito é limpo e rodado de novo sempre que a semana muda, então o intervalo antigo é
limpo e um novo, que capturou a `monday` nova, toma o lugar dele:

```
ana@dev:~/planner$ sed -i 's|^  }, \[\])$|  }, [monday])|' src/App.tsx
ana@dev:~/planner$ tail -n 3 src/App.tsx
    return () => clearInterval(id)
  }, [monday])
}
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --quiet --do 'wait 2200' --do 'click button Next week' --do 'wait 2200' | uniq -c
      1 -- wait 2200
      2 the interval sees 2026-10-19
      1 -- click button Next week
      1 -- wait 2200
      2 the interval sees 2026-10-26
ana@dev:~/planner$ cp /tmp/App.tsx src/App.tsx
ana@dev:~/planner$ npm run lint && npx tsc -b && echo no errors

> planner@0.0.0 lint
> oxlint

Found 0 warnings and 0 errors.
Finished in 37ms on 11 files with 116 rules using 4 threads.
no errors
```

O intervalo vê 26 de outubro depois do clique. Os últimos comandos põem o planejador de volta como a
aula 5 o deixou, e o linter e o verificador de tipos concordam que está limpo.

Havia duas saídas, e a aula 5 usou a outra para o teclado: **ler o valor dentro de uma função que o
React chama com o mais recente**, que para estado é a forma de função, `setMonday((m) => …)`. Rodar o
efeito de novo é o certo quando o trabalho do efeito depende do valor, como um timer que o registra.
A função de atualização é o certo quando o efeito só precisa mudar o valor, como o teclado, e
reacrescentar um listener a cada semana seria trabalho à toa.
