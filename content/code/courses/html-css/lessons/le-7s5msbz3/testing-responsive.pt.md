---
title: Testando em toda largura
version: 1
---

Uma página responsiva precisa ser conferida em mais larguras que a da tela em que você a constrói. Três hábitos acham a maior parte dos problemas.

**Arraste a largura.** No DevTools, a **barra de dispositivos** (o ícone de celular e tablet, ou Ctrl+Shift+M) deixa você pôr o viewport em qualquer largura, ou arrastá-lo. Arraste devagar do largo para o estreito e observe: os breakpoints são onde as coisas se movem, e os problemas costumam estar logo antes de um breakpoint, onde o layout antigo está mais apertado. A lista de aparelhos da barra é um conjunto de atalhos, não as larguras que importam.

**Confira 320.** O critério de sucesso 1.4.10 das WCAG, **Reflow**, pede que o conteúdo possa ser lido numa largura de **320 pixels CSS** sem rolar em duas direções, com exceções como tabelas e mapas, e é por isso que a rolagem da própria tabela, na seção 09, é aceitável e a da página não era. Os 320 não são um celular específico: são o que uma janela de 1280 vira quando a pessoa dá zoom de 400%. Uma página que funciona em 320 funciona para quem usa zoom, e `probe --width 320 PAGE overflow` é a conferência rápida que este curso vem usando.

**Confira as configurações de quem lê.** Dê zoom de 200% e olhe o texto, seção 06. Ligue o movimento reduzido e o esquema escuro, seção 08 e aula 10. Use a página com o teclado numa largura estreita, onde menus e ordem mudam.

::: track qa
Em `web-automation` isso vira teste. Um teste põe o viewport numa lista de larguras, 320 entre elas, e em cada uma afirma o que esta aula mediu à mão: que o documento não é mais largo que a janela, que o menu é alcançável, que uma barra lateral está abaixo do conteúdo e não ao lado. Uma captura de tela comparada com uma referência em cada largura pega o resto, como fazem os testes de grafo e de página inicial deste próprio repositório.
:::

::: track frontend
Em `front-delivery` as mesmas conferências rodam em todo pull request. Um breakpoint é fácil de quebrar a partir de um arquivo que parece não ter relação: um componente que ganha largura fixa, uma tabela acrescentada a uma página que nunca teve uma. Uma conferência em 320 no CI acha isso antes de alguém com um celular.
:::

::: track *
Quando uma página rola para o lado, ache o elemento largo demais antes de mudar qualquer coisa. No painel Elements, o elemento mais largo costuma ser uma tabela, uma sequência longa, uma imagem com largura fixa ou algo com `width: 100vw`, seção 10 da aula 6.
:::
