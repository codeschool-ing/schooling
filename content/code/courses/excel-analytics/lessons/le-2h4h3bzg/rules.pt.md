---
title: Uma planilha para vendas novas, e uma regra em cada coluna
version: 1
---

**Uma regra de validação pertence a uma célula, confere um valor quando alguém o digita e aperta
Enter, e recusa ou questiona o valor quando a regra diz não.** Esta seção monta uma planilha chamada
`New sales`, onde a próxima venda seria digitada, e põe uma regra em cada coluna dela.

## A planilha

1. Crie uma planilha com o **+** ao lado das guias e chame-a de `New sales`.
2. De A1 a G1, digite os mesmos cabeçalhos de `Sales`, sem `Revenue`: `Sale`, `Date`, `Customer`,
   `Product`, `Bags`, `Price`, `Channel`.
3. Selecione A1:G2 e escolha **Inserir › Tabela** (**Insert › Table**), com **Minha tabela tem
   cabeçalhos** marcado. Agora você tem uma tabela com uma linha vazia.
4. Na guia **Design da Tabela** (**Table Design**), digite `NewSales` em **Nome da Tabela** (nome de
   tabela não aceita espaços).

A tabela está ali por um motivo: **uma regra posta numa coluna inteira de uma tabela é copiada para
cada linha que a tabela ganha**, como a aula 7 mostrou para fórmulas. Digite uma venda na linha logo
abaixo da tabela e a linha entra nela, com as regras.

## Onde as regras ficam

Selecione as células da regra e vá em **Dados › Validação de Dados** (**Data › Data Validation** no
Excel em inglês). A guia **Configurações** guarda a regra em si, e a lista **Permitir** diz que tipo
de valor as células aceitam:

| Permitir | a célula aceita | em `New sales` |
|---|---|---|
| **Número inteiro** | um inteiro, comparado com um limite | `Bags`: entre 1 e 50 |
| **Decimal** | qualquer número, comparado com um limite | |
| **Lista** | um valor de uma lista | `Customer`, `Product`, `Channel`, na próxima seção |
| **Data** | uma data, comparada com um limite | `Date`: de 1º de janeiro de 2025 até hoje |
| **Hora** | uma hora do dia | |
| **Comprimento do texto** | texto com um certo número de caracteres | |
| **Personalizado** | qualquer coisa para a qual uma fórmula responda `VERDADEIRO` | `Sale`, abaixo, e `Price`, na seção 05 |

Abaixo de **Permitir**, a lista **Dados** escolhe a comparação: *está entre*, *maior do que*,
*menor ou igual a* e as outras. As caixas embaixo aceitam um número, uma célula ou uma fórmula.

## Bags e Date

Selecione a célula de `Bags` da tabela (E2), escolha **Número inteiro**, **está entre**, e digite `1`
e `50`. Um valor `2,5`, `0`, `140` ou `catorze` agora é recusado.

Para a célula de `Date` (B2), escolha **Data**, **está entre**, e digite uma fórmula em cada caixa:

```localised
=DATA(2025;1;1)
=HOJE()
```

A primeira é o primeiro dia do ano em que começam os registros do Café Serra. A segunda é
recalculada todo dia, então o limite de cima anda sozinho, e uma data no futuro é recusada amanhã
como é hoje. Uma fórmula na caixa é mais segura que uma data digitada, porque o jeito como uma data
digitada é lida depende da região configurada no Windows, e a aula 6 mostra o que isso faz.

## Sale: uma regra personalizada

Um código de venda tem cinco caracteres e não pode já estar em uso, nem em `Sales` nem mais acima em
`New sales`. Nenhum item da lista **Permitir** diz isso, então a regra é uma fórmula. Selecione A2,
escolha **Personalizado** e digite:

```localised
=E(NÚM.CARACT(A2)=5; CONT.SE(Sales!A:A; A2)=0; CONT.SE(A:A; A2)=1)
```

**Uma regra personalizada é escrita para a primeira célula selecionada e anda como uma fórmula
preenchida para baixo.** `A2` é uma referência relativa, então na linha 3 o Excel a lê como `A3`, na
linha 4 como `A4`. As três condições dizem: cinco caracteres, em nenhum lugar da coluna A de `Sales`
e uma vez só na coluna A desta planilha, onde a célula sendo digitada conta como essa uma vez.

Nos dados que você colou, `S1050` é recusado porque a venda `S1050` existe, `S110` é recusado pelo
tamanho, e `S1109` é aceito. Digite `S1109` de novo na linha de baixo e esse é recusado, porque a
coluna A agora o tem duas vezes. A fórmula precisa citar células comuns: a caixa da regra não aceita
uma referência estruturada como `Sales[Sale]`.

## Uma célula em branco sempre passa

Toda regra tem a caixa **Ignorar em branco**, marcada por padrão, e mesmo desmarcada ela não torna a
célula obrigatória: uma célula em que ninguém digita nunca é conferida. A validação decide o que pode
entrar numa célula. Se algo foi digitado é outra pergunta, e a aula 9 responde com uma formatação
que mostra uma célula vazia numa linha que deveria estar completa.
