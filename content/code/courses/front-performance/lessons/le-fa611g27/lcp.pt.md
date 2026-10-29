---
title: "LCP: quando a coisa principal apareceu"
version: 1
---

**O Largest Contentful Paint é o tempo desde o começo da navegação até a maior imagem ou o maior bloco
de texto da janela ser pintado.** Ele representa o momento em que a pessoa decide que a página
carregou, que não é o primeiro pixel e sim o momento em que aquilo que ela veio buscar está lá. Uma
página que pinta um cabeçalho em 200 milissegundos e o seu artigo em três segundos tem um LCP de três
segundos.

## O que conta como o maior

O navegador mantém um candidato enquanto a página carrega e o troca sempre que algo maior é pintado:

- imagens, inclusive uma imagem desenhada como fundo em CSS e o pôster de um vídeo;
- blocos de texto, medidos pela área do próprio texto, não da sua caixa;
- só o que está dentro da janela, e só a parte visível.

**O candidato para de mudar na primeira interação**, um toque, um clique ou uma tecla, ou quando a
página fica escondida. Depois disso a página é da pessoa, e o que carrega mais tarde não faz parte da
carga. É por isso que uma página pode ter um LCP atrasado por causa de algo que ninguém pediu, e a
seção "Um deslocamento de layout, criado e removido" acha exatamente isso no planner: o maior texto da
página de curso é um aviso que chega depois de todo o resto.

## Quatro partes de um número

A biblioteca `web-vitals` divide um LCP em quatro partes, e cada uma aponta para uma correção
diferente:

| parte | o que é | a correção de costume |
|---|---|---|
| tempo até o primeiro byte | até o HTML começar a chegar | um servidor mais rápido, mais perto, um cache (aula 9) |
| atraso de carga do recurso | até a imagem do LCP começar a carregar, se for imagem | deixar o navegador descobri-la no HTML, não por um script (aula 7) |
| duração da carga do recurso | quanto a imagem levou para baixar | uma imagem menor (aula 7) |
| atraso de renderização do elemento | de tê-lo até pintá-lo | menos CSS e script que bloqueiam (aulas 7 e 8) |

No planner, cujo maior elemento é texto, a segunda e a terceira partes são zero, e o número é o tempo
do servidor mais o que quer que tenha segurado a pintura. A medida da aula 1 já era este número em
tudo menos no nome: a página renderizada no cliente pintou o conteúdo aos 948 milissegundos com cada
requisição mais lenta, e a renderizada no servidor aos 640.

**O limite é 2,5 segundos para bom e 4 segundos para ruim**, medido como a seção "Bom, precisa
melhorar, ruim" descreve.
