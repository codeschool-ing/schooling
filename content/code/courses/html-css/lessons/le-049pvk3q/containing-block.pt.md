---
title: O bloco de contenção
version: 1
---

A aula 6 disse que uma largura percentual é uma fração do **bloco de contenção**, e que para a maioria dos elementos ele é o pai. O selo da seção anterior mostrou a exceção que importa. A partir de que caixa uma caixa é medida depende do próprio `position` dela:

- **`static` e `relative`**: a área de conteúdo do ancestral block mais próximo, o que na prática é o pai.
- **`absolute`**: a **caixa de padding do ancestral posicionado mais próximo**, ou seja, o ancestral mais próximo cujo `position` é qualquer coisa diferente de `static`. Se não houver nenhum, o bloco de contenção inicial, que tem o tamanho da janela no topo da página.
- **`fixed`**: a janela, o viewport, seção 06.
- **`sticky`**: ela está no fluxo como uma caixa relative, e gruda dentro do ancestral com rolagem mais próximo, seção 07.

"Posicionado" quer dizer `relative`, `absolute`, `fixed` ou `sticky`. É por isso que `position: relative` sem deslocamento é tão comum: não muda nada na própria caixa e a torna a referência para tudo o que for absoluto dentro dela.

Dois detalhes decorrem de "caixa de padding". Um filho absoluto em `top: 0; left: 0` fica dentro da borda do pai, no canto do padding dele. E `width: 100%` nele é a largura do pai incluindo o padding, não só a área de conteúdo, o que é diferente do que um filho no fluxo recebe.

## Três outras coisas criam um bloco de contenção

Um `transform` num ancestral, aula 12, um `filter` e algumas propriedades mais raras também o tornam o bloco de contenção dos descendentes absolutos e até dos fixos. É uma surpresa que vale conhecer uma vez: um cabeçalho "fixo" dentro de um elemento transformado rola junto com esse elemento em vez de ficar na tela. Quando uma caixa posicionada é medida a partir de um lugar inesperado, procure árvore acima um `position`, um `transform` ou um `filter`, nessa ordem. O DevTools ajuda: no painel Elements o **bloco de contenção** de um elemento não aparece diretamente, mas passar o mouse por cada ancestral e comparar a caixa dele com onde o seu elemento está o encontra em um minuto.
