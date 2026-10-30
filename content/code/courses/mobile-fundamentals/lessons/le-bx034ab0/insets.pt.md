---
title: As partes da tela que o app não recebe
version: 1
---

**A janela de um celular chega até as bordas do vidro, mas partes dela são cobertas pelo sistema ou
cortadas pelo hardware, e o app fica sabendo até onde, a partir de cada borda, essas partes
chegam.** Cada uma dessas distâncias é um *inset*. A imagem comum é um retângulo limpo embaixo de
uma barra de status, que é como os celulares eram quando a barra de status era uma faixa opaca e o
app era desenhado abaixo dela. Num celular atual o app é desenhado atrás da barra de status, em
volta da câmera e embaixo da barra de gestos, e é tarefa do app manter o que importa longe delas.

## O que cobre as bordas

| região | onde | no Android | no iOS |
|---|---|---|---|
| barra de status | no alto | relógio, sinal, bateria, notificações | relógio, sinal, bateria |
| recorte da tela | no alto, ou na lateral em paisagem | um entalhe ou um furo para a câmera | o entalhe, ou a Dynamic Island |
| navegação | embaixo, ou numa lateral | uma alça de gestos, ou três botões | o indicador de início |
| cantos arredondados | os cantos | onde o vidro é arredondado | onde o vidro é arredondado |
| teclado | embaixo, quando um campo tem foco | o IME, o método de entrada | o teclado virtual |

A documentação do Android sobre insets nomeia os tipos do próprio sistema: barras de status,
barras de navegação, o recorte da tela, as bordas curvas de uma tela *waterfall*, o teclado como
`ime`, e as áreas em que o sistema fica com os gestos. Ela os resume em tipos seguros que o app lê
em vez de somá-los na mão: `safeDrawing` para conteúdo que não pode ser desenhado embaixo de
nenhuma interface do sistema, `safeGestures` para as partes da tela onde os gestos do próprio app
brigariam com os do sistema, e `safeContent` para as duas coisas. As Human Interface Guidelines da
Apple definem a versão do iOS numa frase: uma **área segura** é a parte de uma janela não coberta
por um recurso de hardware nem por outra view, como uma barra de ferramentas, uma barra de abas ou a barra de status. Respeitá-la impede que recursos como a Dynamic Island escondam conteúdo e
controles.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"l09-regions\" aria-label=\"Um diagrama da tela de um celular, não uma captura de tela. Em retrato, uma faixa no alto contém a barra de status, com um recorte da câmera no meio, e uma faixa embaixo contém a área de gestos; a área segura é o retângulo tracejado entre elas. Em paisagem o recorte fica no lado esquerdo, as faixas ficam à esquerda e à direita, uma faixa mais fina corre embaixo, e a área segura é o retângulo tracejado dentro delas.\"><defs><marker id=\"l09-regions-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"155\" y=\"14\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper-dim)\">retrato</text><rect x=\"60\" y=\"26\" width=\"190\" height=\"290\" rx=\"24\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.6\"></rect><rect x=\"60\" y=\"26\" width=\"190\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><rect x=\"122\" y=\"31\" width=\"66\" height=\"16\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"155.0\" y=\"39.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8\" fill=\"var(--amber)\">recorte</text><rect x=\"60\" y=\"290\" width=\"190\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><rect x=\"125\" y=\"301\" width=\"60\" height=\"4\" rx=\"2\" fill=\"var(--paper-dim)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></rect><rect x=\"70\" y=\"60\" width=\"170\" height=\"222\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"155.0\" y=\"171.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">área segura</text><path d=\"M272 39 L252 39\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l09-regions-ah-paper-dim)\"></path><text x=\"276\" y=\"39\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">barra de status</text><path d=\"M272 303 L252 303\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l09-regions-ah-paper-dim)\"></path><text x=\"276\" y=\"303\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">área de gestos</text><text x=\"565\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper-dim)\">paisagem: o recorte vai para um lado</text><rect x=\"420\" y=\"98\" width=\"290\" height=\"170\" rx=\"24\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.6\"></rect><rect x=\"420\" y=\"98\" width=\"28\" height=\"170\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><rect x=\"426\" y=\"158\" width=\"16\" height=\"50\" rx=\"6\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"682\" y=\"98\" width=\"28\" height=\"170\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><rect x=\"452\" y=\"250\" width=\"226\" height=\"18\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><rect x=\"535\" y=\"258\" width=\"60\" height=\"4\" rx=\"2\" fill=\"var(--paper-dim)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></rect><rect x=\"454\" y=\"104\" width=\"222\" height=\"140\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"565.0\" y=\"174.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">área segura</text></svg>", "caption": "Um diagrama das regiões, não a imagem de algum celular. O app desenha o fundo em todas elas e mantém o que o aluno lê ou toca dentro do retângulo tracejado, que se move quando o celular vira."}
```

## Atrás, mas não embaixo

**Um inset é uma regra sobre o que vai onde, não um buraco na janela.** Espera-se que o app desenhe
a cor de fundo ou uma foto até as bordas, atrás da barra de status e da alça de gestos, para que a
tela pareça inteira. O que ele mantém dentro da área segura é tudo o que o usuário lê ou toca:
texto, a lista de sessões, o botão de adicionar sessão. Um fundo embaixo do entalhe parece
proposital; a primeira linha de uma lista embaixo do entalhe é uma linha que ninguém lê.

**Os insets mudam com o app rodando.** Eles são diferentes em paisagem, onde o recorte vai para
uma lateral e o inset de cima muitas vezes some. Eles mudam quando o teclado abre e fecha, em
centenas de unidades de uma vez. No Android eles mudam quando o usuário troca os três botões por
gestos. Um app que lê os insets uma vez ao abrir e guarda os números tem o problema que a aula 8
descreveu para tamanhos de janela, num lugar menor.

**E eles vêm nas unidades da aula 7**: dp no Android, pontos no iOS, e a unidade da plataforma no
React Native. Um inset é um tamanho de layout como qualquer outro, e nunca é uma contagem de
pixels físicos.

## Os dois erros

Todo defeito de inset é um de dois, e eles parecem opostos:

- Ignorar os insets. O conteúdo começa na borda de cima e o título fica embaixo do relógio; o
  botão de adicionar sessão fica na borda de baixo e a alça de gestos o cobre, ou um gesto de ir
  para a tela inicial começa quando o aluno queria apertá-lo.
- Aplicá-los duas vezes. Um kit de interface que já acrescenta o espaço da área segura, e quem
  desenvolve acrescentando o mesmo espaço de novo na mão, produzem uma faixa vazia acima do
  conteúdo e uma lista que começa uma barra de status abaixo do lugar.

Os dois vêm de não saber que parte do código é responsável pelos insets. A próxima seção trata
dessa responsabilidade em cada plataforma, que é onde as duas mais diferem.
