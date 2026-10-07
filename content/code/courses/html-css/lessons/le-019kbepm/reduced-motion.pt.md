---
title: Movimento que quem lê pode desligar
version: 1
---

A seção 08 da aula 11 apresentou **`prefers-reduced-motion`**. Um site com muitas animações pode responder a ela num lugar só, com uma regra como esta, carregada depois das outras:

```css
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
  }
}
```

Para quem pediu menos movimento, toda animação e transição passa a durar **0,01 ms** e roda **uma vez**. A página é a mesma, sem o movimento: o que desliza para dentro simplesmente está lá, porque, como a seção 08 recomendou, os estilos normais são o estado final.

```
ana@laptop:~/site$ probe --reduced-motion reduced.html style .spinner animation-duration,animation-iteration-count style .notice opacity
div.spinner  animation-duration: 1e-05s
div.spinner  animation-iteration-count: 1
p.notice  opacity: 1
```

A duração do spinner é **1e-05s**, que é 0,01 ms, e o número de repetições **1**: ele não gira mais. O aviso está totalmente opaco, **1**, desde a primeira medida. A regra usa uma duração minúscula em vez de `none` para que qualquer coisa esperando o fim de uma animação em JavaScript ainda receba o evento.

## Ao contrário

A regra global é uma rede de segurança. O padrão oposto é melhor quando você mesmo escreve as animações: ponha **o movimento dentro** de uma query `no-preference`, para que quem não disse nada o receba, e o padrão seja parado:

```css
@media (prefers-reduced-motion: no-preference) {
  .notice { animation: drop-in 400ms ease-out; }
}
```

**Reduzido não quer dizer nenhum.** Um esmaecimento ou uma mudança de cor não é o movimento de que a configuração trata; deslizar, dar zoom, girar e parallax são. Um site pode trocar um deslizamento por um esmaecimento curto para essas pessoas em vez de tirar o retorno de vez.

## O que as WCAG pedem

O critério de sucesso **2.2.2, Pausar, Parar, Ocultar**, no nível A, pede que qualquer coisa em movimento que começa sozinha e dura mais de cinco segundos, um carrossel ou um letreiro rolando, possa ser pausada, parada ou escondida por quem lê. Um indicador de carregamento é a exceção de costume, porque para quando o carregamento para. O critério **2.3.1** proíbe conteúdo que pisca mais de três vezes por segundo, que pode causar convulsões. E o 2.3.3, no AAA, é o movimento a partir de interações que a aula 11 descreveu.
