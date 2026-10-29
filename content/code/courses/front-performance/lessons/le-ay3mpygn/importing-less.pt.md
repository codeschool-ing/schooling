---
title: Importando menos
version: 1
---

**Um bundler manda o que é importado, e descarta o que nada importa.** Isso se chama **tree shaking**: o
Vite segue cada `import` a partir da entrada, e o código que nenhum import alcança fica fora do build. Só
funciona com código que o bundler consegue ver que não é usado, então funciona melhor com bibliotecas
escritas como módulos ES cujas partes são importadas pelo nome.

O `chart.js/auto` derrota isso de propósito. Ele importa todo controller, elemento, escala e plugin que o
Chart.js tem e registra todos, para que `new Chart(...)` funcione para qualquer tipo de gráfico sem uma
segunda linha; a conveniência é exatamente o código de que um gráfico de barras não precisa. O Chart.js
também oferece as peças uma a uma. Um gráfico de barras precisa de quatro: o controller de barras, o
elemento de barra, uma escala de categorias para as semanas e uma escala linear para os minutos. No
`src/chart.ts`, troque o import de `chart.js/auto` por:

```typescript
// Only the pieces a bar chart uses: the rest of Chart.js is never imported, so never shipped.
import { BarController, BarElement, CategoryScale, Chart, LinearScale } from "chart.js";
Chart.register(BarController, BarElement, CategoryScale, LinearScale);
```

A chamada a register é o que torna isso seguro: o Chart.js acha as peças por um registro e não por imports,
então uma peça deixada de fora não é um import quebrado, e sim um tipo de gráfico que não está lá, e pedir
um diz isso com um erro que o nomeia.

```
ana@dev:~/planner$ npm run build

> planner@0.0.0 build
> tsc && vite build

vite v8.3.5 building client environment for production...
transforming...
✓ 9 modules transformed.
rendering chunks...
computing gzip size...
dist/index.html                  0.69 kB │ gzip: 0.35 kB
dist/assets/index-gserWk4t.css   0.76 kB │ gzip: 0.41 kB
dist/assets/index-yh2nfJj3.js   18.08 kB │ gzip: 6.95 kB

✓ built in 192ms
```

**Setenta kilobytes a menos**, um terço do arquivo. Faça o build, reinicie e pergunte de novo:

```
ana@dev:~/planner$ node tools/unused.ts http://localhost:3000/stats
/assets/index-DG0BwuX_.js      147.5 KB, ran  75.5 KB (51%)
```

**A página de estatísticas agora roda cerca de metade do script**, contra menos da metade antes. A página de
curso ainda baixa tudo, porque um gráfico que a página de curso nunca desenha continua importado pelo
arquivo que toda página carrega. Importar menos encolheu a biblioteca; não a tirou das páginas que não a
usam. A próxima seção tira.

## Lendo o tamanho de uma biblioteca antes de instalar

A maioria das bibliotecas diz na documentação como importar só parte delas, e as que não dizem merecem um
olhar antes de serem instaladas. Um build é a medida que resolve: instale, importe do jeito que vai usar,
faça o build e leia o número que o Vite imprime. O hábito que mais custa é importar uma biblioteca de
utilitários inteira por uma função.
