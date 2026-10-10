---
title: O que é refatoração, e o que ela não é
version: 1
---

**"Estamos refatorando o módulo de pagamentos" costuma querer dizer que alguém está reescrevendo o
módulo, e que o programa não vai funcionar direito por duas semanas.** Isso não é refatoração, e a
confusão custa mais do que vocabulário. A definição de Martin Fowler, da segunda edição de
*Refactoring* (2018), é estreita de propósito: uma mudança na estrutura interna do software que o
torna mais fácil de entender e mais barato de modificar, **sem mudar o comportamento observável**. O
programa antes e o programa depois dão as mesmas respostas às mesmas perguntas.

Duas consequências decorrem disso, e são elas que tornam a definição útil em vez de pedante.

**A refatoração acontece em passos pequenos, e o código funciona depois de cada um.** Renomeie uma
variável, rode os testes. Tire quatro linhas para uma função, rode os testes. Cada movimento é
pequeno o bastante para que um erro seja óbvio e barato de desfazer. Uma mudança grande é alcançada
como uma corrente de mudanças pequenas, e em qualquer ponto da corrente você pode parar, fazer commit
e ir para casa com um programa que funciona. Essa é a diferença para uma reescrita, que é um único
passo grande cujo resultado ninguém consegue rodar até ficar pronto.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" data-fig=\"l14-moves\" aria-label=\"Duas maneiras de chegar ao mesmo código reestruturado, desenhadas ao longo de um eixo de tempo. Em cima, uma refatoração: dez movimentos pequenos como renomear, extrair e mover, cada um seguido de um ponto que é uma execução de testes que passou, então o programa funciona em todo momento e qualquer ponto é um lugar para parar e fazer commit. Embaixo, uma reescrita: uma barra longa com o rótulo &quot;nada roda&quot; cobrindo quase todo o tempo, terminando num amontoado de falhas na primeira execução.\"><defs><marker id=\"l14-moves-dp-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"60.0\" y=\"28.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">refatoração: movimentos pequenos, uma execução que passa depois de cada</text><path d=\"M60.0 70.0 L690.0 70.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><circle cx=\"123.0\" cy=\"70.0\" r=\"6\" fill=\"var(--phosphor)\"></circle><text x=\"91.5\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">renomear</text><circle cx=\"186.0\" cy=\"70.0\" r=\"6\" fill=\"var(--phosphor)\"></circle><text x=\"154.5\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">extrair</text><circle cx=\"249.0\" cy=\"70.0\" r=\"6\" fill=\"var(--phosphor)\"></circle><circle cx=\"312.0\" cy=\"70.0\" r=\"6\" fill=\"var(--phosphor)\"></circle><text x=\"280.5\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">extrair</text><circle cx=\"375.0\" cy=\"70.0\" r=\"6\" fill=\"var(--phosphor)\"></circle><circle cx=\"438.0\" cy=\"70.0\" r=\"6\" fill=\"var(--phosphor)\"></circle><text x=\"406.5\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">mover</text><circle cx=\"501.0\" cy=\"70.0\" r=\"6\" fill=\"var(--phosphor)\"></circle><circle cx=\"564.0\" cy=\"70.0\" r=\"6\" fill=\"var(--phosphor)\"></circle><text x=\"532.5\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">classe nova</text><circle cx=\"627.0\" cy=\"70.0\" r=\"6\" fill=\"var(--phosphor)\"></circle><circle cx=\"690.0\" cy=\"70.0\" r=\"6\" fill=\"var(--phosphor)\"></circle><text x=\"375.0\" y=\"96.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper)\">qualquer ponto é um programa que funciona: pare, faça commit, vá para casa</text><path d=\"M375.0 86.0 L375.0 79.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#l14-moves-dp-ah-paper-dim)\"></path><text x=\"60.0\" y=\"140.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">reescrita: um passo grande</text><rect x=\"60.0\" y=\"167.0\" width=\"516.6\" height=\"26.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"318.3\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">nada roda</text><circle cx=\"592.6\" cy=\"180.0\" r=\"5\" fill=\"var(--amber)\"></circle><circle cx=\"606.6\" cy=\"171.0\" r=\"5\" fill=\"var(--amber)\"></circle><circle cx=\"606.6\" cy=\"189.0\" r=\"5\" fill=\"var(--amber)\"></circle><circle cx=\"620.6\" cy=\"180.0\" r=\"5\" fill=\"var(--amber)\"></circle><circle cx=\"634.6\" cy=\"171.0\" r=\"5\" fill=\"var(--amber)\"></circle><circle cx=\"634.6\" cy=\"189.0\" r=\"5\" fill=\"var(--amber)\"></circle><text x=\"686.0\" y=\"210.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper)\">primeira execução: muitas falhas de uma vez</text><path d=\"M60.0 245.0 L690.0 245.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l14-moves-dp-ah-paper-dim)\"></path><text x=\"690.0\" y=\"258.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">tempo</text></svg>", "caption": "Os dois terminam com o mesmo código. Só um deles funciona em todos os dias do caminho."}
```

**Você precisa de um jeito de saber que o comportamento não mudou.** Na prática, isso quer dizer
testes, rodados depois de cada movimento. Sem eles, uma "refatoração" é uma edição que você espera
que tenha sido inofensiva. A próxima seção monta essa rede em volta de um arquivo que não tem
nenhuma, que é a situação em que a refatoração é mais necessária.

## Dois chapéus

Kent Beck descreve o desenvolvimento como usar um de dois chapéus. Com o primeiro, você acrescenta
comportamento: escreve um teste novo e o faz passar. Com o segundo, você refatora: muda a estrutura
e não acrescenta teste, porque nada de novo deveria acontecer. **Você pode trocar de chapéu a cada
poucos minutos, e nunca usa os dois ao mesmo tempo.** Um commit que renomeia meio módulo e também
muda o cálculo das multas não pode ser revisado, e se quebrar alguma coisa ninguém sabe qual metade
quebrou.

O ciclo de TDD da lição 13 são os dois chapéus num cronômetro: o passo verde usa o primeiro, o passo
de refatorar usa o segundo. Mas a refatoração não se limita ao TDD. O momento mais comum para ela é
logo antes de uma funcionalidade: quando a mudança de que você precisa é difícil de fazer no código
como está, você refatora até ela ficar fácil, depois faz a mudança fácil. A versão de Beck é *torne
a mudança fácil, depois faça a mudança fácil*, com o aviso de que a primeira metade pode ser difícil.

## Cheiros: os sinais de que um movimento é necessário

O catálogo de Beck e Fowler dá nome aos sintomas antes das curas. Um **cheiro** (*smell*) é um traço
superficial do código que costuma apontar para um problema mais fundo: não é bug, nem sempre está
errado, mas merece um olhar. Cada cheiro tem uma ou duas refatorações que costumam resolvê-lo. Esta
lição trabalha os cinco abaixo num arquivo legado, nesta ordem:

| cheiro | como aparece | o movimento de costume | seção |
|---|---|---|---|
| função longa | uma função em que você precisa rolar a tela, fazendo vários trabalhos | extrair função | long-function |
| código duplicado | a mesma expressão ou bloco em dois lugares | extrair função, depois chamá-la duas vezes | duplication |
| obsessão por primitivos | um `int` que na verdade é dinheiro, uma tupla que na verdade é um registro | trocar primitivo por objeto | primitive-obsession |
| aglomerados de dados e inveja de funcionalidade | três campos sempre passados juntos; uma função mais interessada nos dados de outro objeto do que nos próprios | introduzir uma classe; mover função | feature-envy-and-data-clumps |
| switches repetidos | a mesma cadeia `if kind == ...` em mais de um lugar | trocar condicional por polimorfismo | switch-on-type |

O catálogo é mais longo: o de Fowler tem umas duas dúzias de cheiros e mais de sessenta
refatorações. Estes cinco são os que um desenvolvedor back-end encontra toda semana. **Um cheiro é
motivo para olhar, não uma ordem para agir.** Uma função longa que ninguém vai tocar de novo pode
continuar longa; o argumento para refatorar é sempre a próxima mudança que alguém vai ter de fazer.

## Por que isso importa para o projeto

Todo padrão deste curso é mais fácil de alcançar refatorando do que projetando de antemão. Ninguém
escreve a strategy da lição 6 no primeiro dia; escreve um `if`, depois um segundo `if`, e no
terceiro refatora em direção a uma strategy, porque aí já sabe o que varia. **A refatoração é o que
permite a um projeto chegar tarde**, quando o problema está entendido, em vez de ser adivinhado cedo
e defendido depois.
