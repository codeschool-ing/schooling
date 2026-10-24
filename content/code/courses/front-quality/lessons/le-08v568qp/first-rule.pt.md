---
title: A primeira regra do ARIA
version: 1
---

**O ARIA, Accessible Rich Internet Applications, é um conjunto de atributos que muda o que a árvore de
acessibilidade diz sobre um elemento.** O `role` muda o que ele é, o `aria-label` e o `aria-labelledby`
mudam o nome, e os estados, `aria-expanded`, `aria-checked`, `aria-current` e os outros, dizem em que
condição ele está. **O ARIA muda só o que é anunciado, nunca o que o elemento faz.** Uma `div` com
`role="button"` é anunciada como botão e continua ignorando o Enter, como a aula 11 mostrou.

O próprio guia do W3C para usar ARIA abre com cinco regras, e a primeira é a que mais vale guardar:

1. **Se um elemento nativo do HTML tem o significado e o comportamento de que você precisa, use-o** em vez de
   dar um papel a outro elemento.
2. Não mude o significado de um elemento nativo a não ser que precise: um título que também é uma aba deve
   ser um título dentro de uma aba, não um título com `role="tab"`.
3. Todo controle interativo em ARIA precisa funcionar pelo teclado.
4. Nunca ponha `role="presentation"` nem `aria-hidden="true"` num elemento que pode receber o foco, ou o
   foco cai em algo que o leitor diz que não existe.
5. Todo elemento interativo precisa ter um nome acessível.

**Nenhum ARIA é melhor que ARIA ruim.** O WebAIM verifica um milhão de páginas iniciais todo ano, e todo
ano encontra mais erros nas páginas que usam ARIA do que nas que não usam. A culpa não é do ARIA; é o que
acontece quando ele é usado para remendar o que o elemento certo teria feito de graça. Um `role` errado é
pior que nenhum, porque faz o leitor dizer algo falso com confiança.

## O que o planner usa, e por quê

| atributo | onde | por que está lá |
|---|---|---|
| `aria-hidden="true"` | a seta do link de voltar | a palavra já diz; a seta seria lida como o nome de um símbolo |
| `role="status"` | a mensagem depois de acrescentar uma sessão | não existe elemento cujo significado seja *anuncie isto com educação*; a próxima seção |
| nenhum | todo o resto | um `button`, um `a`, um `label`, um `h1` e um `ul` dizem o que são |

Dois atributos no app inteiro, e cada um para algo que o HTML não consegue dizer. Essa é mais ou menos a
quantidade certa.
