---
title: Organizando a folha de estilos
version: 2
---

Uma folha de estilos que cresce sem plano acaba com o mesmo botão estilizado em quatro lugares e ninguém sabendo qual vence. A saída é uma **ordem**, escolhida uma vez, em que o geral vem antes do específico. Uma ordem comum tem seis partes, e o diretório `css/` do laboratório a segue:

```
ana@laptop:~/site$ find css -type f | sort
css/base.css
css/components/event-card.css
css/layout.css
css/main.css
css/reset.css
css/tokens.css
css/utilities.css
```

1. **`reset.css`**: as poucas regras que desfazem padrões do navegador que ninguém quer: `box-sizing: border-box` para tudo, aula 6, nenhuma margem no body, imagens como blocos.
2. **`tokens.css`**: as propriedades personalizadas da seção 08, e nada mais.
3. **`base.css`**: a aparência padrão dos elementos simples, só por seletor de tipo: a fonte e a cor do body, links, títulos, listas. Nenhuma classe.
4. **`layout.css`**: as formas grandes, o grid da página e os contêineres que seguram as coisas, aulas 8 e 9.
5. **`components/`**: um arquivo por componente, cada um estilizando só os próprios nomes de classe: o cartão de evento, o menu, o formulário de pedido.
6. **`utilities.css`**: classes pequenas, de um propósito só, que precisam vencer onde quer que sejam postas, como a classe `visually-hidden` da aula 7.

A ordem é também a de **especificidade crescente e alcance crescente**: seletores de elemento, depois algumas classes de layout, depois classes de componente, depois utilitários que sobrepõem. Escrita nessa ordem, a cascata quase sempre funciona sem ninguém brigar com ela, e a seção 10 transforma essa ordem numa regra que o navegador impõe.

## Um arquivo ou vários

O `main.css` traz os outros com **`@import`**, e isso tem um custo que o navegador mostra:

```
ana@laptop:~/site$ probe site.html fetched
main.css
reset.css
tokens.css
base.css
layout.css
event-card.css
utilities.css
```

Isso é o que a página pediu, em ordem: `main.css` primeiro, depois os seis arquivos que ele importa. O navegador não tem como saber de `reset.css` antes de baixar e ler o `main.css`, então os imports são descobertos com uma ida e volta de atraso, e nada é desenhado até que todos tenham chegado, seção 12 da aula 1. Num site servido pela rede, esse atraso é real. Então **os arquivos são para quem trabalha no CSS, e o navegador deve receber um arquivo só**: em desenvolvimento o `@import` é prático, e para produção uma etapa de build junta tudo numa folha de estilos. O `front-delivery` é onde esse build é montado. Para um site pequeno com uma folha de estilos, as partes são simplesmente seções de um arquivo, na mesma ordem.
