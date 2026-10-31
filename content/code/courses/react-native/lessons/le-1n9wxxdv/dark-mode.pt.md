---
title: O modo escuro é uma pergunta que o celular responde
version: 1
---

**As duas plataformas deixam a pessoa escolher uma aparência clara ou escura, e espera-se que os apps a
sigam.** No React Native a escolha chega como um valor, do `useColorScheme()`, que devolve `"light"`, `"dark"`
ou `null` quando a plataforma não diz, e renderiza o componente de novo quando a pessoa troca. Não há media
query para escrever; há um hook para ler.

## Uma paleta por esquema

O planner guarda as cores num arquivo só, para que nenhum componente escreva uma cor própria. Salve isto como
`src/theme.ts`:

```typescript
// src/theme.ts: the planner's colours, one set for each colour scheme.
import { useColorScheme } from "react-native";

const light = {
  background: "#ffffff",
  text: "#1f2328",
  muted: "#57606a",
  line: "#d0d7de",
  pressed: "#eef2f6",
  track: "#e6ebf0",
  accent: "#2f6f4e",
};
const dark: typeof light = {
  background: "#0d1117",
  text: "#e6edf3",
  muted: "#9198a1",
  line: "#3d444d",
  pressed: "#161b22",
  track: "#21262d",
  accent: "#57ab7a",
};
export type Theme = typeof light;

export function useTheme(): Theme {
  return useColorScheme() === "dark" ? dark : light;
}
```

O `useTheme()` é um **hook do próprio planner**, uma função cujo nome começa com `use` e que chama outro hook
dentro dela. Um componente chama `const t = useTheme()` e escreve `color: t.text`; quando o celular passa
para o escuro, todo componente que o chamou renderiza de novo com o outro conjunto. A aula 9 diz o que faz de
um hook um hook; aqui basta que ele funcione como o `useState`, do topo de um componente.

**O modelo tira o app disso tudo.** O `app.json` dele diz `"userInterfaceStyle": "light"`, para que as partes
nativas, a barra de status e o teclado, fiquem claras seja o que for que o celular diga. Troque para
`"automatic"` quando o app seguir o esquema, ou a barra de status desenha texto escuro sobre o fundo escuro do
planner.

## Escolhendo as cores

**Todo par de texto e fundo precisa ser legível, nas duas paletas.** Contra o fundo, o texto normal deste
arquivo chega a 15,8 para 1 na paleta clara e a 16,0 na escura, e o cinza atenuado a 6,4 e 6,5; numa linha
apertada, onde o fundo muda, o cinza ainda mantém 5,7 e 5,9. O nível AA das WCAG pede 4,5 para 1 para texto
normal. O destaque é usado na parte feita da barra, que não leva texto, e a barra diz o valor dela a um
leitor de tela em palavras. Uma paleta é conferida uma vez, com um verificador de contraste, e depois ninguém
precisa pensar nela de novo, que é o argumento para um arquivo só.

## Medido nos dois

O programa de medição da seção do flexbox aceita `--dark`, que pede ao navegador o esquema escuro do jeito
que um celular em modo escuro faria:

```
ana@dev:~/planner$ node boxes.mjs 'http://localhost:8082/?today=2026-10-21' --dark
header       x=24 y=64 w=342 h=40  rgba(0, 0, 0, 0)
week-bar     x=24 y=147 w=342 h=12  rgb(33, 38, 45)
week-done    x=24 y=147 w=205 h=12  rgb(87, 171, 122)
week-left    x=229 y=147 w=137 h=12  rgba(0, 0, 0, 0)
row-spanish  x=24 y=175 w=342 h=62  rgba(0, 0, 0, 0)
row-statistics x=24 y=237 w=342 h=62  rgba(0, 0, 0, 0)
row-guitar   x=24 y=299 w=342 h=62  rgba(0, 0, 0, 0)
```

As mesmas caixas, outras cores: o trilho e a parte feita são da paleta escura. `rgba(0, 0, 0, 0)` no
cabeçalho quer dizer *transparente*, o que está certo: ele não tem fundo próprio e mostra o da tela.
