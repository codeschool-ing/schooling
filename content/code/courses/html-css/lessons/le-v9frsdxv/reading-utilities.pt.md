---
title: Lendo utilitários como o CSS que você conhece
version: 1
---

Todo utilitário é uma declaração que este curso ensinou, e a maioria dos nomes segue um padrão: uma abreviação da propriedade, um hífen e um valor de uma escala.

| Utilitário | O que ele gera | Aula |
| --- | --- | --- |
| `p-4`, `px-4`, `mt-1` | `padding`, `padding-inline`, `margin-top`, 4 ou 1 passos de `--spacing` | 6 |
| `max-w-3xl` | `max-width: var(--container-3xl)`, 48rem | 6 |
| `text-2xl` | `font-size: 1.5rem` e um `line-height` correspondente | 5 |
| `font-bold` | `font-weight: 700` | 5 |
| `flex`, `items-center`, `justify-between`, `gap-4` | `display: flex`, `align-items`, `justify-content`, `gap` | 8 |
| `grid`, `grid-cols-3`, `col-span-2` | `display: grid`, `grid-template-columns: repeat(3, minmax(0, 1fr))`, um span | 9 |
| `relative`, `absolute`, `top-0`, `z-10` | `position`, `top`, `z-index` | 7 |
| `sr-only` | a técnica de esconder visualmente | 7 |
| `rotate-6`, `scale-110`, `transition` | `rotate`, `scale`, `transition-property` e uma duração | 12 |

## A escala é um conjunto de propriedades personalizadas

Os números não são pixels. **Um passo é `--spacing`**, e o primeiro build o declarou, junto com toda cor que a página usou, em `:root`:

```
ana@laptop:~/site$ grep -n "@layer" first/out.css
2:@layer properties;
3:@layer theme, base, components, utilities;
4:@layer theme {
29:@layer base {
177:@layer utilities {
241:@layer properties {
ana@laptop:~/site$ grep -E -- "--(spacing|color-[a-z]+-[0-9]+):" first/out.css
    --color-emerald-700: oklch(50.8% 0.118 165.612);
    --color-stone-50: oklch(98.5% 0.001 106.423);
    --color-stone-600: oklch(44.4% 0.011 73.639);
    --color-stone-900: oklch(21.6% 0.006 56.043);
    --spacing: 0.25rem;
```

**`--spacing: 0.25rem`**, 4 pixels, então `p-4` são quatro passos, 16 pixels, e `mt-1` são 4. Esses são exatamente os design tokens da aula 10: a paleta e a escala são propriedades personalizadas, e todo utilitário lê uma delas com `var()`. O primeiro `grep` também mostra como a folha é organizada, que é o assunto da próxima seção: em **camadas de cascata**.
