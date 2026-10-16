---
title: Registrar a escolha numa página que alguém vai ler
version: 1
---

**Uma escolha de padrão que não é registrada é feita de novo por quem ler o código depois, e
normalmente ao contrário.** Quem encontra um dicionário de funções onde esperava uma hierarquia de
strategy não tem como saber que foi de propósito. Quem encontra um protocolo com uma implementação
não tem como saber que uma segunda está planejada para junho. Os dois vão "consertar", e o argumento
que resolveu a questão se perde com o conserto.

A resposta leve é um **registro de decisão de arquitetura**, um ADR (*architecture decision
record*): uma página curta no repositório, uma por decisão, numerada e nunca reescrita. A lição 20
de `architecture` trata de ADRs a fundo, de onde guardá-los a como defender um numa revisão. Esta
seção não repete isso. Ela mostra o que o registro de uma escolha de *padrão* precisa ter e que
outros registros às vezes dispensam.

## O que uma decisão de padrão precisa dizer

Uma escolha de padrão é especialmente fácil de desfazer sem querer, porque o código que a
implementa parece que poderia ser "melhorado" nos dois sentidos. Então o registro precisa carregar
três coisas que o código não carrega:

- a força, na forma de uma frase da seção 02, para quem lê conferir se ela ainda vale;
- a resposta maior que foi rejeitada, e o custo dela, para ninguém propô-la de novo achando que
  ninguém pensou nela;
- a condição que reabriria a decisão, para a próxima pessoa saber o que vigiar em vez de rediscutir
  por gosto.

A terceira é a parte que a seção 05 chamou de a mais pulada. Sem ela, um registro diz o que foi
decidido e deixa quem lê adivinhar se aquilo ainda se aplica.

## O caso 1 da seção 05, como registro

O formato abaixo é o de Michael Nygard, o mais comum: um título, um status, o contexto, a decisão e
as consequências. Cabe numa tela, e esse é o objetivo.

```localised
# 7. Multas: uma tabela de taxas e um dicionário de funções de regra

Status: aceito, 2026-10-10

## Contexto
A taxa diária varia pela categoria do membro (adulto 50, estudante
25, funcionário 0, idoso 25 a partir do próximo semestre). Filmes são
limitados ao seu preço. As categorias mudam mais ou menos uma vez por
semestre; as regras por tipo de item mudaram uma vez em três anos.

## Decisão
As taxas ficam num dicionário, DAILY_CENTS. As regras são funções
simples com uma assinatura, escolhidas pelo tipo de item em RULES.
Consideramos uma classe strategy por categoria, escolhida por uma
factory. Rejeitada: ela põe um número dentro de uma classe, e uma
categoria nova exigiria uma classe nova e uma mudança na factory em
vez de uma linha de dados.

## Consequências
Uma categoria nova é uma linha. Uma regra nova é uma função e uma
entrada. Toda regra recebe price, mesmo as que o ignoram.
Reabrir se uma regra precisar de estado ou configuração próprios,
como uma multa que cresce depois de enviado um aviso.
```

Repare no que não está ali. Não há descrição do código, que o próprio código já dá, nem histórico
da reunião. O registro é curto o bastante para as pessoas lerem, e fica no repositório ao lado do
código, então viaja com cada cópia e aparece na mesma revisão da mudança que explica.

## Quando um registro vale a pena

Nem toda função precisa de uma página. Uma regra razoável é escrever um quando a escolha foi
discutida, ou seja, alguém propôs a alternativa e ela foi recusada, ou quando a escolha vai parecer
estranha a quem não tem o contexto. Duas situações desta lição se encaixam: um protocolo com uma
implementação mantido de propósito merece um registro que diga qual será a segunda implementação, e
uma função simples mantida onde um padrão foi proposto merece um que diga que força mudaria isso.

**Um registro nunca é editado para mudar sua decisão.** Quando a condição de reabertura chega e a
escolha muda, um registro novo é escrito, numerado depois do último, e o status do antigo passa a
ser *substituído pelo 12*. A história de por que o código tem a forma que tem passa então a ser
lida em ordem, que é justamente o que um log de commits conta mal.
