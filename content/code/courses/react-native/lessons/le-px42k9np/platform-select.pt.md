---
title: Platform.select, um valor por plataforma
version: 1
---

**O `Platform.select` recebe um objeto com chaves por plataforma e devolve o valor da plataforma em que o app
está rodando.** É a forma arrumada de uma cadeia de ternários, e o lugar comum para ele é um estilo.

## Sombras, o caso clássico

**As duas plataformas desenham sombras de jeitos diferentes**, e durante quase toda a história do React
Native cada uma precisou das próprias propriedades. O iOS desenha uma sombra a partir de quatro delas, cor,
opacidade, raio e deslocamento, embaixo de qualquer view com fundo. O Android a desenha a partir de uma, a
`elevation`, uma altura acima da superfície a partir da qual o próprio sistema calcula a sombra. Um cartão
elevado precisa das duas. Salve isto como `src/card.ts`:

```typescript
// src/card.ts: a raised card, which each platform draws its own way.
import { Platform, type ViewStyle } from "react-native";

export const card: ViewStyle = {
  borderRadius: 12,
  padding: 16,
  ...Platform.select<ViewStyle>({
    ios: { shadowColor: "#000", shadowOpacity: 0.12, shadowRadius: 8, shadowOffset: { width: 0, height: 2 } },
    android: { elevation: 3 },
    default: { boxShadow: "0 2px 8px rgba(0, 0, 0, 0.12)" },
  }),
};
```

O espalhamento, `...Platform.select(…)`, mescla o objeto escolhido no estilo do cartão. O `default` cobre toda
plataforma não citada, aqui a web, que usa um `boxShadow` parecido com o do CSS. O React Native 0.76
acrescentou o `boxShadow` como estilo para os celulares também, desenhado do mesmo jeito nos dois, então um
projeto novo pode usá-lo em todo lugar; as duas formas mais antigas continuam em quase toda biblioteca e
resposta que você vai ler, e é por isso que este cartão as mostra.

## O que ele devolve

O `Platform.select` devolve o valor, não um estilo nem um componente, então serve para qualquer coisa:

```tsx
const keyboardOffset = Platform.select({ ios: 64, android: 0, default: 0 });
const title = Platform.select({ ios: "Settings", android: "Preferences", default: "Settings" });
```

A segunda linha é do tipo que vale pensar duas vezes. Cada plataforma tem uma palavra que os usuários dela
esperam em certos lugares, e segui-la faz o app parecer nativo; mas um texto que muda por plataforma também é
dois textos para traduzir e dois para testar. **Use a palavra da plataforma onde as pessoas a procuram**, num
título de menu ou numa ação do sistema, e a mesma palavra em todo o resto.

## Quando um valor não basta

Uma sombra é um valor. Um seletor de data não é: no iOS é uma roda ou um calendário dentro da tela, no
Android um diálogo que abre por cima dela, e o código em volta de cada um é diferente. Quando a diferença vale
um componente inteiro, as extensões de arquivo da próxima seção guardam cada versão num arquivo próprio, em
vez de um arquivo cheio de desvios.
