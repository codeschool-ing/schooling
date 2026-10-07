---
title: Conferindo uma página com o axe
version: 1
---

A aula 1 conferiu o HTML contra as regras da linguagem. O **axe** o confere contra regras de acessibilidade: uma imagem sem alternativa em texto, um campo sem rótulo, uma página sem landmark principal, um texto com cor perto demais da do fundo. É o motor das verificações de acessibilidade do Lighthouse do Chrome e de muitas extensões de navegador, e este repositório o roda em toda tela da plataforma em que você está lendo isto. `probe axe` roda a versão 4.13.0 contra a página, com as regras da WCAG 2.2 no nível AA, o padrão para o qual a maioria das leis aponta, mais as boas práticas do próprio axe.

Aqui está a página sopa:

```
ana@laptop:~/site$ probe soup.html axe
landmark-one-main (moderate, 1 element): Document should have one main landmark
page-has-heading-one (moderate, 1 element): Page should contain a level-one heading
region (moderate, 3 elements): All page content should be contained by landmarks
target-size (serious, 3 elements): All touch targets must be 24px large, or leave sufficient space
```

Quatro regras, e três delas são esta aula: **landmark-one-main**, nenhum `<main>`; **page-has-heading-one**, nenhum `<h1>`; **region**, três elementos fora de todo landmark. A quarta, **target-size**, é sobre os três links do menu, e a próxima execução mostra o porquê. Aqui está a página semântica, com os links do menu medidos depois das regras:

```
ana@laptop:~/site$ probe semantic.html axe box "nav a"
target-size (serious, 3 elements): All touch targets must be 24px large, or leave sufficient space
a  x 48     y 50     width 43.55  height 17
a  x 48     y 68     width 84.42  height 17
a  x 48     y 86     width 94.66  height 17
```

As regras de estrutura sumiram. **target-size** continua ali, e as caixas dizem por quê: cada link tem 17 pixels de altura e o seguinte começa 18 pixels abaixo. A WCAG 2.2 pede alvos de pelo menos 24 por 24 pixels, ou espaço suficiente em volta de um menor, para que um dedo ou uma mão que treme acerte o que queria. Está certo deixar isso para depois, porque aumentar um link não é questão de em qual elemento ele está. É CSS, padding nos links, que é a aula 6.

## O que uma aprovação não quer dizer

O axe aponta o que um programa consegue decidir lendo a página. Ele não sabe dizer se um título descreve o que está embaixo, se o texto do `alt` diz a coisa certa, se a ordem em que o Tab anda faz sentido ou se o texto de um link é claro: *Click here* é um nome, e o axe o aceita. Verificações automáticas encontram só parte do que está errado numa página; quanto depende da página, e as estimativas publicadas vão de cerca de um terço a cerca de metade. **Uma página sem violações passou na parte que uma máquina consegue conferir**, e o resto continua sendo trabalho de alguém: experimente a página só com o teclado, e escute-a com um leitor de tela. Os dois vêm em todo sistema operacional: VoiceOver no macOS e no iOS, Narrador no Windows, TalkBack no Android, Orca no Linux.
