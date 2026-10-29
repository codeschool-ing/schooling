---
title: A imagem do LCP
version: 1
---

**Faltam dois atributos, e os dois tratam do momento em que a imagem chega.**

## O espaço que ela vai ocupar

O CLS da primeira rodada foi o formulário descendo quando a imagem chegou, porque até ela chegar o
navegador não sabia qual seria a altura dela e não lhe deu espaço. **`width` e `height` no `<img>`** dizem:
não o tamanho em que ela é desenhada, que o CSS decide, mas a proporção, a partir da qual o navegador
calcula a altura antes de chegar um único byte da imagem. É o aviso da aula 5 de novo, resolvido pela
marcação em vez de um palpite no CSS.

A rodada simulada não consegue mais mostrar o deslocamento, porque os deslocamentos de layout que o
Lighthouse informa são os que de fato aconteceram enquanto ele carregava a página, e num computador só a
imagem chega cedo demais. Então esta seção mede com `devtools`, que deixa o navegador lento de verdade.
Como está agora:

```
ana@dev:~/planner$ npm run lighthouse -- http://localhost:3000/courses/git --throttling-method=devtools >/dev/null && node tools/report.ts report.report.json | grep -E 'performance|LCP|CLS|insight|cover'
performance 99, throttling devtools
  LCP  1.5 s    weight 25
  CLS  0.061    weight 25
  insight: Use efficient cache lifetimes, Est savings of 45 KiB
  insight: Forced reflow
  insight: Improve image delivery, Est savings of 29 KiB
  insight: LCP request discovery
  insight: Network dependency tree
  insight: Render-blocking requests, Est savings of 150 ms
  request /covers/git-800.avif         done at  1444 ms, 38255 B
```

**O deslocamento voltou**: com a rede de fato lenta, a imagem chega depois da primeira pintura.

## A prioridade dela

**`fetchpriority="high"`** diz ao navegador que esta requisição importa mais que as outras que ele achou.
Um navegador dá prioridade baixa às imagens no começo, porque não tem como saber qual vai ser grande antes
de fazer o layout da página; para a imagem que vai ser o LCP, a página sabe mais, e dizer isso é o que o
LCP request discovery pediu.

E nunca **`loading="lazy"`** nessa imagem. O carregamento lazy espera a imagem estar perto da janela para
pedi-la, o que é certo para as imagens mais abaixo numa página longa e errado para a do alto: transforma
uma requisição que o navegador começaria na hora numa que espera o layout.

No `src/view.ts`, troque a linha do `<img>` dentro do `cover` por estas duas:

```typescript
  <img class="cover" src="/covers/${slug}-800.jpg" srcset="${set("jpg")}" sizes="${sizes}" alt=""
    width="2400" height="1200" fetchpriority="high">
```

Só o `<img>` precisa deles: os elementos `<source>` escolhem o arquivo, e o `<img>` é o elemento cujo layout
a página faz, seja qual for o arquivo que mostra. Faça o build, reinicie e meça do mesmo jeito:

```
ana@dev:~/planner$ npm run lighthouse -- http://localhost:3000/courses/git --throttling-method=devtools >/dev/null && node tools/report.ts report.report.json | grep -E 'performance|LCP|CLS|insight|cover'
performance 100, throttling devtools
  LCP  1.5 s    weight 25
  CLS  0        weight 25
  insight: Use efficient cache lifetimes, Est savings of 45 KiB
  insight: Improve image delivery, Est savings of 29 KiB
  insight: Network dependency tree
  insight: Render-blocking requests, Est savings of 670 ms
  request /covers/git-800.avif         done at  1434 ms, 38255 B
```

**O CLS é zero e o LCP request discovery sumiu.** O LCP não se mexeu: com três requisições disputando, há
pouco a ganhar ordenando-as, e o `fetchpriority` paga o seu lugar numa página com dezenas.

## Um insight que fica

**Improve image delivery** ainda estima uma economia, e o relatório HTML diz por quê: ele compara o arquivo
de 800 pixels com os 380 por 190 pixels CSS em que a imagem é desenhada. Mas o celular do Lighthouse tem
1,75 pixel do aparelho para cada pixel CSS, então o navegador precisava de uns 665 pixels e escolheu o de
800, que é para isso que o `srcset` existe. Um de 400 ficaria borrado. Um insight é uma regra aplicada por
um programa, e esta acerta sobre a maioria das páginas e erra sobre esta.
