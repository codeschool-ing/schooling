---
title: Dizer o que a célula quer, e o que uma recusa faz
version: 1
---

**Uma regra sem mensagem recusa um valor sem dizer por quê, e quem digita não aprende nada além de
que o Excel disse não.** As outras duas guias da janela **Validação de Dados** resolvem isso: uma
fala antes de qualquer digitação, a outra decide o que uma regra desrespeitada faz.

## A mensagem de entrada: antes de digitar

Na guia **Mensagem de Entrada** (**Input Message**), um **título** e uma **mensagem** digitados ali
aparecem numa notinha ao lado da célula sempre que ela é selecionada. Para `Bags` (E2) poderia ser:

- **Título**: `Bags`
- **Mensagem de entrada**: `Sacos inteiros, de 1 a 50.`

A nota não custa nada e evita o erro em vez de pegá-lo depois. Mantenha uma linha sobre o que a
célula quer; quem lê está no meio da digitação de uma venda.

## O alerta de erro: depois que um valor desrespeita a regra

A guia **Alerta de Erro** (**Error Alert**) tem um **Estilo**, e o estilo decide o que a pessoa pode
fazer em seguida:

| estilo | a pessoa pode | use quando o valor é |
|---|---|---|
| **Parar** (**Stop**) | redigitar, ou cancelar; o valor não pode ficar | impossível: um produto que não existe, 0 sacos |
| **Aviso** (**Warning**) | mantê-lo com **Sim**, voltar e editá-lo com **Não**, ou cancelar | possível mas incomum, digno de um segundo olhar |
| **Informações** (**Information**) | mantê-lo com **OK**, ou cancelar | aceitável, com algo que a pessoa deveria saber |

**Parar é o único estilo que impõe alguma coisa.** Aviso e Informações perguntam à pessoa, e quem
está com pressa aperta o botão que faz a janela sumir. É o comportamento certo para um valor que às
vezes é legítimo, e o errado para um valor que nunca é.

A mensagem do próprio Excel, quando a guia fica vazia, não cita a regra nem o que digitar no lugar.
Escreva uma que faça as duas coisas: `Bags é um número inteiro de 1 a 50. Para um pedido maior,
divida em duas vendas.` diz exatamente o que fazer em seguida.

## Price: um aviso, não uma recusa

O preço de uma venda é o caso do **Aviso**. Clientes de atacado pagam abaixo do preço de tabela,
então um preço abaixo da tabela é normal; um preço muito abaixo dela geralmente é um deslize, como
`18` digitado no lugar de `118`. Selecione a célula de `Price` de `NewSales` (F2), escolha
**Permitir: Personalizado** e digite:

```localised
=F2>=0,8*PROCX(D2; Products!A:A; Products!F:F)
```

A regra busca o produto em `Products`, como a aula 4 fez, e aceita qualquer preço que seja pelo
menos 80% do preço de tabela. Para `CER1K`, cujo preço de tabela é 118, o limite é 94,4: os 106 que
os clientes de atacado pagaram em 2026 passam, e `18` desrespeita a regra. Na guia **Alerta de Erro**
escolha **Aviso**, com uma mensagem como `Isto é menos de 80% do preço de tabela. Sim mantém; Não
deixa corrigir.`

A regra lê `D2`, então depende de o produto ser escolhido antes. Com `D2` vazio a busca responde
`#N/D`, uma regra cuja fórmula responde um erro conta como desrespeitada, e o aviso aparece. Digitar
as colunas da esquerda para a direita, na ordem em que a planilha está montada, evita isso.

## Uma regra por célula

Uma célula guarda uma regra de validação, com um estilo. A regra acima avisa, então um preço de `-5`
também só é avisado em vez de recusado, e um **Sim** apressado o mantém. Escolher o estilo é escolher
qual erro importa mais: em `Price` um dígito esquecido é o deslize comum, e um aviso deixa passar os
preços baixos legítimos. Em `Product`, onde um valor errado nunca é legítimo, a regra de lista da
seção 04 continua como **Parar**.
