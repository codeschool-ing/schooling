---
title: A marca fica, as convenções mudam
version: 1
---

**A pergunta sobre a qual toda equipe discute é se o app deve parecer igual nos dois celulares, e a
resposta útil divide a tela em duas.** As cores do planner, o espaçamento, o tom das palavras e a
forma da semana pertencem ao planner: um aluno que o usa no iPhone de um amigo deve reconhecê-lo.
Onde fica a ação principal, qual barra troca de seção, qual fonte desenha um parágrafo e como uma
sheet aparece pertencem à plataforma: um aluno não deveria ter de aprender a ideia particular que o
planner faz de uma tab bar. Os dois guias traçam a linha mais ou menos nesse lugar. O Material foi
feito para levar uma marca pelos papéis dele; as HIG pedem a marca como uma tint e ficam com o resto.

| pertence à marca | pertence à plataforma |
|---|---|
| a cor de destaque e as outras cores que o planner escolheu | onde fica a ação principal |
| os passos de espaçamento, 8, 16, 24 | a barra que troca de seção, e o lugar dela |
| as palavras, os ícones desenhados para o planner | a fonte do sistema no iOS, e os estilos de texto |
| o que a tela da semana mostra, e em que ordem | voltar: o gesto do sistema, ou um botão no alto |
| um conjunto claro e um escuro de cores | o modo escuro seguindo o ajuste do sistema |

**A versão errada de "igual em todo lugar" desenha um conjunto de telas e o entrega duas vezes**: um
botão flutuante no iPhone, uma tab bar inventada pela própria equipe no Android. Parece coerente para
a equipe, que vê os dois celulares lado a lado todo dia, e estranho para cada usuário, que vê um só.

## Design tokens

**Um design token é uma decisão de design, com nome e escrita uma vez, num formato que as duas
plataformas conseguem ler.** `primary` é `#2F6F4E`; o espaço médio é 16; o texto do corpo é 16. Uma
equipe guarda os tokens num arquivo, e o tema de cada plataforma é construído a partir dele, então
trocar o verde da marca é uma edição e não duas que se desencontram. Os do planner são pequenos o
bastante para aparecer inteiros. Salve isto como `tokens.ts` em `~/planner`:

```schooling-example
{"language": "typescript", "file": "tokens.ts", "parts": [{"code": "// tokens.ts: the planner's design decisions, written once\ntype Palette = { primary: string; onPrimary: string; surface: string; onSurface: string; muted: string };\n\nexport const brand = {\n  light: { primary: \"#2F6F4E\", onPrimary: \"#FFFFFF\", surface: \"#FFFFFF\", onSurface: \"#1C1B1F\", muted: \"#8A8A8A\" },\n  dark: { primary: \"#8FD3AE\", onPrimary: \"#00391F\", surface: \"#1C1B1F\", onSurface: \"#E6E1E5\", muted: \"#938F99\" },\n  space: { s: 8, m: 16, l: 24 }, // dp on Android, pt on iOS\n  text: { body: 16, title: 22 }, // the brand's sizes; iOS keeps its own text styles\n};\n", "note": "A marca, e nada além dela. Cinco cores por papel, uma vez para o claro e outra para o escuro; três passos de espaçamento; dois tamanhos de texto. `muted` é o cinza da data embaixo de uma sessão. Nenhuma palavra de plataforma aparece aqui."}, {"code": "// Material 3: colour roles by name, sizes in dp and sp, Roboto, the action in a FAB.\nexport function materialTheme(mode: \"light\" | \"dark\") {\n  const c: Palette = brand[mode];\n  return {\n    colorScheme: { primary: c.primary, onPrimary: c.onPrimary, surface: c.surface, onSurface: c.onSurface, onSurfaceVariant: c.muted },\n    spacingDp: brand.space,\n    typography: { bodyLarge: `Roboto ${brand.text.body}sp`, titleLarge: `Roboto ${brand.text.title}sp` },\n    primaryAction: \"floating action button\",\n    sections: \"navigation bar\",\n  };\n}\n", "note": "O tema do Material leva os valores da marca para os nomes do próprio Material: o cinza vira `onSurfaceVariant`, o tamanho do corpo vira `bodyLarge` em `sp`. Os dois últimos campos nem são valores: são as convenções que a seção anterior desenhou."}, {"code": "// The HIG: the brand colour as the tint, sizes in pt, the system font through text styles.\nexport function iosTheme(mode: \"light\" | \"dark\") {\n  const c: Palette = brand[mode];\n  return {\n    tint: c.primary,\n    colors: { background: c.surface, label: c.onSurface, secondaryLabel: c.muted },\n    spacingPt: brand.space,\n    typography: { body: \"system font, .body\", title: \"system font, .largeTitle\" },\n    primaryAction: \"toolbar button, top trailing\",\n    sections: \"tab bar\",\n  };\n}", "note": "O tema iOS recebe as mesmas cores com os nomes das HIG, `tint`, `label`, `secondaryLabel`, e não repassa os tamanhos de texto da marca: ele pede estilos de texto, para o Dynamic Type continuar funcionando. Mesma marca, outras convenções."}]}
```

Um segundo arquivo pede os dois temas e os imprime lado a lado, marcando com `=` toda linha em que os
dois guardam o mesmo valor. Salve-o como `themes.ts`:

```typescript
// themes.ts: the two themes side by side, to see what stayed and what moved
import { materialTheme, iosTheme } from "./tokens.ts";

const mode = process.argv[2] === "dark" ? "dark" : "light";
const m = materialTheme(mode);
const i = iosTheme(mode);
const rows = [
  ["accent", m.colorScheme.primary, i.tint],
  ["text", m.colorScheme.onSurface, i.colors.label],
  ["secondary text", m.colorScheme.onSurfaceVariant, i.colors.secondaryLabel],
  ["background", m.colorScheme.surface, i.colors.background],
  ["medium gap", `${m.spacingDp.m} dp`, `${i.spacingPt.m} pt`],
  ["body text", m.typography.bodyLarge, i.typography.body],
  ["primary action", m.primaryAction, i.primaryAction],
  ["sections", m.sections, i.sections],
];
console.log(`${mode}`.padEnd(18) + "Material".padEnd(26) + "iOS");
for (const [role, a, b] of rows) {
  const kept = a.split(" ")[0] === b.split(" ")[0]; // the same value, whatever the unit
  console.log((kept ? "= " : "  ") + role.padEnd(16) + a.padEnd(26) + b);
}
```

Rode-o para a aparência clara, e depois para a escura:

```
ana@dev:~/planner$ node themes.ts
light             Material                  iOS
= accent          #2F6F4E                   #2F6F4E
= text            #1C1B1F                   #1C1B1F
= secondary text  #8A8A8A                   #8A8A8A
= background      #FFFFFF                   #FFFFFF
= medium gap      16 dp                     16 pt
  body text       Roboto 16sp               system font, .body
  primary action  floating action button    toolbar button, top trailing
  sections        navigation bar            tab bar
ana@dev:~/planner$ node themes.ts dark
dark              Material                  iOS
= accent          #8FD3AE                   #8FD3AE
= text            #E6E1E5                   #E6E1E5
= secondary text  #938F99                   #938F99
= background      #1C1B1F                   #1C1B1F
= medium gap      16 dp                     16 pt
  body text       Roboto 16sp               system font, .body
  primary action  floating action button    toolbar button, top trailing
  sections        navigation bar            tab bar
```

**Leia a coluna do `=`.** As cinco primeiras linhas são a marca, e são iguais nas duas plataformas
nas duas aparências: o mesmo verde, a mesma cor de texto, o mesmo 16 para o espaço médio, medido em
`dp` numa e em `pt` na outra, que são o assunto da aula 7. As três últimas são as convenções, e todas
diferem. O texto do corpo fica entre as duas coisas: o 16 da marca chega ao Material como
`bodyLarge`, enquanto o iOS fica com o estilo de texto `.body` do sistema, que tem 17 pontos no
tamanho padrão e segue o Dynamic Type em todos os outros.

**Nada aqui desenha uma tela**, e é por isso que roda no Node.js. O Compose leria `materialTheme`
para um `ColorScheme` e uma `Typography`; o SwiftUI leria a tint para `.tint()`. Esses são trabalhos
do curso `android-apps`, cuja aula 7 é o tema do Material 3, e do `ios-apps`, se você seguir um
desses caminhos; um app React Native pode importar `tokens.ts` como está, porque é TypeScript. Em
todos os casos, o arquivo que a equipe edita são os tokens.

## O que os tokens não resolvem

**Um token diz qual é a cor, e nada sobre se ela pode ser lida.** O cinza `muted` do planner é a cor
da data embaixo de cada sessão, e os dois temas o levam fielmente. A aula 19 passa esse cinza pela
fórmula de contraste e descobre que o claro reprova, e é por isso que este arquivo guarda as cores
num lugar só: a correção vai ser uma linha, aqui, e as duas plataformas a recebem.

Faça o commit dos dois arquivos junto com o resto do planner. O hash da última linha vai ser outro
no seu, porque depende de todos os commits anteriores:

```
ana@dev:~/planner$ git add tokens.ts themes.ts
ana@dev:~/planner$ git commit -q -m "Design tokens, and a theme for each platform"
ana@dev:~/planner$ git log --oneline -1
2ad5024 Design tokens, and a theme for each platform
```
