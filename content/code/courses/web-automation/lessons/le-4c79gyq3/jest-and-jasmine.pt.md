---
title: Jest e Jasmine, executores que não conduzem nada
version: 1
---

A surpresa de costume sobre o Jest e o Jasmine é que **nenhum dos dois consegue abrir um
navegador**. São executores com asserções: acham arquivos de teste, rodam as funções de dentro
deles, comparam valores e imprimem um relatório. Se um teste toca num navegador depende do que o
teste importa. Eles estão na lista desta aula porque muita automação de navegador roda dentro deles,
com uma biblioteca de condução fazendo a condução.

## Jasmine

O Jasmine se descreve como "a simple JavaScript testing framework for browsers and Node", um
framework de testes simples para navegadores e Node. Ele deu ao JavaScript a forma que a maioria dos
testes ainda tem: `describe` para um grupo, `it` para um teste, `expect(value).toBe(other)` para uma
verificação, e **spies** (espiões) para observar se uma função foi chamada. O teste se lê como uma
frase, o estilo chamado orientado a comportamento. O pacote `jasmine`, na 7.0.0, roda specs no Node;
o `jasmine-browser-runner` as roda dentro de uma página do navegador, o que testa o JavaScript da
própria página sem conduzi-la de fora.

Hoje o Jasmine aparece na automação de navegador quase sempre como framework dentro do executor de
outro: o `@wdio/jasmine-framework` do WebdriverIO é um caso, e projetos Angular rodaram os testes
unitários nele por anos.

## Jest

O Jest tem a mesma forma, com mais coisa na caixa: o executor, as asserções, mocks, snapshots,
cobertura e um modo de observação. Ele saiu do Facebook, hoje mora na organização `jestjs`, e está
na 30.5.2. **A sintaxe dele é a do Jasmine**, porque o Jest começou rodando sobre o Jasmine, e uma
spec simples escrita para um roda no outro sem mudança.

Aqui está um teste do Jest que não precisa de navegador nenhum. Ele verifica a armadilha da aula 1,
o espaço inseparável que o `Intl.NumberFormat` põe depois de `R$`:

```javascript
test('a price has a non-breaking space after R$', () => {
  const money = new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' });
  expect(money.format(5.9)).toBe('R$ 5,90');
});
```

Nem o Jest nem o Jasmine foram instalados neste curso, e o trecho não rodou em nenhum dos dois. O
fato que ele verifica rodou: no Node 22, `money.format(5.9) === 'R$ 5,90'` dá `true`.

## O jsdom não é um navegador

O Jest consegue rodar um teste num ambiente chamado **jsdom**, o pacote `jest-environment-jsdom`: um
DOM escrito em JavaScript, dentro do Node. `document.querySelector` funciona ali, e um componente
pode ser desenhado nele e clicado. **O que o jsdom não faz é diagramar nem pintar nada.** Ele não
tem layout CSS, então nada ali tem tamanho ou posição de verdade, e um botão fora da tela ou debaixo
de outro elemento é tão clicável quanto qualquer outro. A cesta da aula 7, larga demais para um
celular, é invisível para ele. Testes no jsdom são rápidos, e são testes unitários do código da
página; a aula 1 de `testing-cicd` os põe nas camadas. O teste de navegador é o que acha o que só um
navegador mostra.

## Jest em volta de um navegador de verdade

Para pôr um navegador de verdade dentro do Jest, a equipe acrescenta uma biblioteca de condução. O
preset `jest-puppeteer`, na 11.0.0, inicia o Puppeteer antes dos testes e dá a cada teste uma
`page`; o Selenium e o WebdriverIO podem ser chamados de um teste do Jest do mesmo jeito. Aí o Jest
fornece o executor e o relatório, o Puppeteer o navegador, e a espera continua escrita à mão, como
no script da seção anterior.

**Uma equipe escolhe isso** quando os testes unitários dela já moram no Jest e um executor para
tudo vale mais para ela do que a espera do Playwright. O preço é a própria espera, que continua
por sua conta em cada teste.
