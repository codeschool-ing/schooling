---
title: Gherkin, o formato em que os exemplos são escritos
version: 1
---

**O Gherkin é uma pequena linguagem estruturada para escrever exemplos de comportamento de modo que pessoas
consigam lê-los e uma ferramenta consiga rodá-los.** Veio com o Cucumber, uma ferramenta de BDD que Aslak
Hellesøy começou em 2008, e hoje é lido por ferramentas na maioria das linguagens de programação; em Python a mais
comum é o **behave**, que você instalou na aula 1.

Um arquivo Gherkin descreve uma **feature** (funcionalidade) e guarda **cenários**, cada um um exemplo concreto. Eis
o primeiro cenário que o Cine Aurora escreveu para os cupons. Salve-o em `~/aurora`, numa pasta nova, como
`features/coupons.feature`:

```
# features/coupons.feature
Feature: Coupons
  A customer with a coupon code pays less for the order.

  Scenario: PIPOCA takes five reais off
    Given an order of R$ 36,00
    When the customer uses the code "PIPOCA"
    Then the order costs R$ 31,00
```

O time do Cine Aurora escreve os cenários em inglês, como o código. O Gherkin também aceita palavras-chave em
português (`Funcionalidade`, `Cenário`, `Dado`, `Quando`, `Então`) se o arquivo começar com `# language: pt`; o que
importa é o time inteiro, inclusive a dona do produto, conseguir ler.

## As palavras-chave

| palavra-chave | o que faz |
|---|---|
| `Feature:` | nomeia a funcionalidade; as linhas abaixo são uma descrição livre para pessoas, que a ferramenta ignora |
| `Scenario:` | um exemplo, com um nome que diz o que ele mostra |
| `Given` | a situação antes de qualquer coisa acontecer: o contexto |
| `When` | a única ação de que o exemplo trata |
| `Then` | o resultado que deve ser observável depois |
| `And`, `But` | continuam o passo de cima, para um cenário não ficar *Given … Given … Given* |
| `#` | um comentário, só para pessoas |

É o *dado, quando, então* da aula 12, com as palavras-chave no começo da linha para uma ferramenta achá-las. Vale a
mesma disciplina: um *When* por cenário, porque um cenário com três ações são três exemplos embolados, e uma falha
nele diz menos.

## Declarativo, não imperativo

O jeito mais comum de escrever Gherkin ruim é descrever os cliques em vez do comportamento. Compare dois cenários
que conferem a mesma coisa:

| imperativo | declarativo |
|---|---|
| Given I open the box office screen | Given an order of R$ 36,00 |
| And I click "new order" | When the customer uses the code "PIPOCA" |
| And I choose session "thu 20:00" | Then the order costs R$ 31,00 |
| And I type "35" in the age field | |
| And I click "add ticket" | |
| And I type "PIPOCA" in the coupon field | |
| And I click "apply" | |
| Then the total field shows "R$ 31,00" | |

O imperativo é mais longo, mais difícil para a Joana ler, e quebra toda vez que um botão muda de nome, embora a
regra não tenha mudado. O declarativo diz o que importa ao negócio e mais nada. O *como*, que tela, que campo,
fica no código que roda os passos, onde uma mudança conserta todos os cenários.

Um bom teste para um cenário: **a Joana poderia tê-lo escrito?** Não digitado a sintaxe, mas dito aquelas frases.
Se um passo menciona um botão, um banco de dados ou uma variável, está falando a língua de quem desenvolve, não a
compartilhada.

## O que um cenário não é

Um arquivo Gherkin não é um plano de teste num formato estranho. É um número pequeno de exemplos, escolhidos na
descoberta porque cada um mostra algo sobre a regra: o caso comum, a borda, a combinação que foi discutida. Um
arquivo de feature com duzentos cenários cobrindo cada preço do quadro é uma suíte de regressão que ninguém fora
do time vai ler, e o motivo de escrevê-la em Gherkin se perdeu. Os muitos casos ficam em verificações
automatizadas comuns como as da aula 15; os cenários são os que valem uma conversa.
