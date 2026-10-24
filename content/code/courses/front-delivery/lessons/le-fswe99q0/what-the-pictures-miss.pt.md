---
title: O que as fotos não veem, e o que as auditorias pegam
version: 1
---

**Uma comparação de capturas de tela pega mudanças, não erros, e só mudanças maiores que a tolerância
dela.** É por isso que o teste roda o axe ao lado, e o jeito mais claro de ver o motivo é uma mudança que
as fotos deixam passar.

## Um cinza que as fotos aceitaram

O `grey-400` da aula 5, o cinza que reprovou no script de contraste, posto de volta como o texto discreto
do tema claro, com os tokens gerados de novo e a oficina reconstruída:

```
ana@dev:~/planner$ sed -i 's/{color.grey-600}/{color.grey-400}/' tokens.json
ana@dev:~/planner$ npm run tokens > /dev/null
ana@dev:~/planner$ npm run build-storybook > /dev/null 2>&1
ana@dev:~/planner$ npx playwright test -g 'done in light' 2>&1 | sed -n '/Error:/,/^    + \]/p'
    Error: expect(received).toEqual(expected) // deep equality

    - Expected  - 1
    + Received  + 3

    - Array []
    + Array [
    +   "color-contrast",
    + ]
```

**A comparação de capturas passou.** A palavra *done* mudou de um cinza para um mais claro, e a comparação
do Playwright, por padrão, perdoa uma pequena diferença de cor por pixel, porque a suavização de bordas e
de fontes varia um pouco entre execuções, e um teste que falhasse por isso seria ignorado em uma semana.
Uma tolerância que aceita isso aceita também um cinza um pouco mais claro.

**O axe não deixou passar**: `color-contrast`, a regra que mede a mesma razão do WCAG que o script da aula
5 calculava, contra as cores que o navegador de fato desenhou. As duas conferências veem coisas
diferentes, e um teste precisa das duas. Ponha o cinza certo de volta:

```
ana@dev:~/planner$ git checkout tokens.json src/tokens.css
Updated 2 paths from the index
ana@dev:~/planner$ npm run build-storybook > /dev/null 2>&1
ana@dev:~/planner$ npx playwright test 2>&1 | tail -2

  10 passed (14.8s)
```

## As fotos pertencem a uma máquina

Capturas de tela dependem das fontes, do build do navegador e do sistema operacional que as desenhou, então
o Playwright dá a cada imagem o nome da plataforma: estas são `…-chromium-linux.png`. Num Mac o mesmo teste
procura `…-chromium-darwin.png`, não acha nenhuma e grava novas. A resposta de costume é fazer de **uma
máquina a fotógrafa**: o CI, no Linux, com as imagens que ele aprovou commitadas, e quem desenvolve em
outros sistemas atualizando-as pelo CI, e não pelo próprio computador.

## E o que nenhuma das duas vê

Nenhuma das duas conferências sabe se o componente está certo. Uma captura que sempre esteve errada passa
para sempre, e o axe confere só o que dá para decidir a partir da página: um rótulo faltando, uma razão de
contraste, um papel. Se *Mark done* são as palavras certas, se a ordem do foco faz sentido, se um leitor de
tela anuncia a mudança: essas são as aulas 10 a 13 de front-quality, e o julgamento de alguém. Os testes
garantem que esse julgamento, uma vez feito, continue feito.

Faça o commit da oficina, dos testes e das imagens deles:

```
ana@dev:~/planner$ git add .storybook src playwright.config.ts tests package.json package-lock.json .gitignore
ana@dev:~/planner$ git commit -qm "A component library, documented in Storybook and tested story by story"
```
