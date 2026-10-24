---
title: Contraste é aritmética
version: 1
---

**Uma razão de contraste compara quanta luz duas cores emitem, e ela é calculada, não julgada.** A aula 10
pegou duas do axe, 2,32:1 e 5,33:1. Esta seção as calcula, para que uma cor possa ser escolhida antes de
alguém rodar um verificador nela.

A WCAG a define em dois passos. Primeiro a **luminância relativa** de cada cor, de 0 para o preto a 1 para o branco. Cada canal passa do
valor codificado da tela para a luz que ele de fato faz, e os três são somados com pesos de acordo com a
sensibilidade do olho a cada um, verde mais e azul menos. Depois a
**razão** da mais clara pela mais escura, com 0,05 somado às duas pela luz que a tela reflete:

| passo | fórmula |
|---|---|
| canal, como luz | *c* / 12,92 se *c* ≤ 0,04045, senão ((*c* + 0,055) / 1,055)^2,4, para *c* de 0 a 1 |
| luminância relativa | *L* = 0,2126 *R* + 0,7152 *G* + 0,0722 *B* |
| razão de contraste | (*L*₁ + 0,05) / (*L*₂ + 0,05), a mais clara sobre a mais escura, de 1:1 a 21:1 |

## Os limites

| o quê | AA | AAA | critério |
|---|---|---|---|
| texto | 4,5:1 | 7:1 | 1.4.3, 1.4.6 |
| texto grande: 24 px, ou 18,66 px em negrito | 3:1 | 4,5:1 | 1.4.3, 1.4.6 |
| as partes de um controle, um anel de foco, as linhas de um gráfico | 3:1 | nenhum | 1.4.11 |
| um controle desabilitado, um logo, pura decoração | nenhum | nenhum | isento |

## A aritmética, no planner

Eis a fórmula como módulo, `src/contrast.ts`:

```schooling-example
{"language": "typescript", "file": "src/contrast.ts", "parts": [{"code": "// src/contrast.ts\nexport function luminance(hex: string): number {\n  const [r, g, b] = [1, 3, 5].map((i) => parseInt(hex.slice(i, i + 2), 16) / 255);\n", "note": "Uma cor escrita `#rrggbb` guarda três canais de dois dígitos hexadecimais cada. Cada um é lido e dividido por 255, para ir de 0 a 1."}, {"code": "  const light = (c: number) => (c <= 0.04045 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4);\n", "note": "Uma tela guarda um canal codificado, não como a luz que ele faz; isto desfaz a codificação. A WCAG 2.2 escreve o limite como 0.04045, onde versões antigas escreviam 0.03928, e nenhuma cor de 8 bits cai entre os dois."}, {"code": "  return 0.2126 * light(r) + 0.7152 * light(g) + 0.0722 * light(b);\n}\n", "note": "Os três são pesados pela sensibilidade do olho a cada um: verde mais, azul menos. Branco dá 1 e preto 0."}, {"code": "export function contrast(a: string, b: string): number {\n  const [lighter, darker] = [luminance(a), luminance(b)].sort((x, y) => y - x);\n  return (lighter + 0.05) / (darker + 0.05);\n}", "note": "A mais clara sobre a mais escura, em qualquer ordem que venham, com 0.05 somado às duas pela luz que a tela reflete. Preto sobre branco é (1 + 0.05) / (0 + 0.05), que dá 21."}]}
```

E um teste que a prende aos números que o axe imprimiu na aula 10. Salve como `src/contrast.test.ts`:

```typescript
// src/contrast.test.ts
import { expect, test } from "vitest";
import { contrast } from "./contrast";

test("the arithmetic agrees with axe", () => {
  expect(contrast("#aaaaaa", "#ffffff")).toBeCloseTo(2.32, 2);
  expect(contrast("#6b6b6b", "#ffffff")).toBeCloseTo(5.33, 2);
  expect(contrast("#000000", "#ffffff")).toBe(21);
  expect(contrast("#ffffff", "#000000")).toBe(21);
});
```

```
ana@dev:~/planner$ npx vitest run src/contrast.test.ts

 RUN  v5.0.5 /home/ana/planner


 Test Files  1 passed (1)
      Tests  1 passed (1)
   Start at  21:35:49
   Duration  229ms (transform 73%, import 16%, worker 7%, tests 4%)
```

As duas últimas linhas dizem que a ordem dos argumentos não importa, que é o `sort` do `contrast`. O
`toBeCloseTo(2.32, 2)` aceita qualquer coisa que arredonde para 2.32 com duas casas, que é como o axe
informa.
