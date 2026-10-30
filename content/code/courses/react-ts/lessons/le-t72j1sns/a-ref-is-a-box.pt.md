---
title: Um ref é uma caixa que o React não observa
version: 1
---

**O `useRef` dá a um componente um objeto com uma propriedade, `current`, que sobrevive a toda
renderização e para a qual o React nunca olha.** O estado é um valor que o React observa: mude-o e o
componente renderiza de novo. Um ref é o contrário: mude-o e nada acontece, e a próxima renderização
encontra o valor que você deixou lá. Isso faz do ref o lugar certo para tudo o que um componente
precisa lembrar e não precisa desenhar.

A menor demonstração é um componente que conta as próprias renderizações. Ele é temporário; salve
como `src/RenderCount.tsx`:

```tsx
import { useRef } from 'react'

// For lesson 7 only: a ref survives renders and changing it renders nothing.
export function RenderCount() {
  const renders = useRef(0)
  renders.current += 1
  console.log('RenderCount has rendered', renders.current, 'times')
  return null
}
```

Ele não desenha nada, `return null`, e registra cada vez que é chamado. Ponha-o embaixo do `WeekNav`
no `App` e aperte "Next week" duas vezes:

```
ana@dev:~/planner$ sed -i 's|^      <WeekNav .*|&\n      <RenderCount />|; 1a import { RenderCount } from "./RenderCount"' src/App.tsx
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --quiet --do 'click button Next week' --do 'click button Next week'
RenderCount has rendered 1 times
RenderCount has rendered 2 times
-- click button Next week
RenderCount has rendered 3 times
RenderCount has rendered 4 times
-- click button Next week
RenderCount has rendered 5 times
RenderCount has rendered 6 times
ana@dev:~/planner$ sed -i '/RenderCount/d' src/App.tsx && rm src/RenderCount.tsx
```

Duas linhas por renderização, o strict mode de novo, e a contagem continua entre elas: 1 e 2 na
carga, 3 e 4 depois do primeiro clique, 5 e 6 depois do segundo. **O ref manteve o valor entre
renderizações, e mudá-lo não causou nenhuma.** Se `renders` fosse estado, `setRenders(renders + 1)`
durante a renderização pediria outra renderização, que pediria outra, e o React interromperia com um
erro sobre renderizações demais.

Mudar `renders.current` durante a renderização, como este faz, quebra a regra da aula 2 de que uma
renderização não muda nada, e a contagem dobrada do strict mode é o sintoma: num build, o número
seria a metade. Isso é aceitável num contador descartável e em nenhum outro lugar. **Leia e escreva
um ref em efeitos e handlers de evento, não durante a renderização**, e a próxima seção faz
exatamente isso.

| | `useState` | `useRef` |
|---|---|---|
| sobrevive entre renderizações | sim | sim |
| mudar renderiza de novo | sim | não |
| ler durante a renderização | sim: é para isso que serve | não: o valor pode estar velho ou mudado pela metade |
| uso típico | tudo o que a tela mostra | um elemento do DOM, o id de um timer, um valor de que um efeito precisa e a tela não |
