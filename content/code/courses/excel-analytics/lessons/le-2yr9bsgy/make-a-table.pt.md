---
title: Transformando um intervalo em tabela
version: 1
---

**Um intervalo é um endereço; uma tabela é um objeto com nome que conhece as próprias bordas e os
nomes das suas colunas.** `E2:E109`, na aula 5, queria dizer *os sacos*, mas só enquanto as vendas
terminassem na linha 109. O endereço não dizia nada sobre sacos nem sobre onde os dados acabavam,
então a primeira venda acrescentada na linha 110 ficaria fora de toda fórmula. Uma tabela do Excel
acompanha as duas coisas para você.

## Criando as três tabelas

Antes de começar, os dados precisam estar sozinhos: nada digitado na linha de baixo nem na coluna ao
lado. As aulas anteriores pediram que você apagasse as células auxiliares, da coluna J em diante,
exatamente por isso. Depois, na planilha `Sales`:

1. Clique em qualquer célula dentro dos dados, por exemplo **A1**.
2. Use **Inserir › Tabela**, ou aperte **Ctrl+T** (no Mac, **Cmd+T**).
3. O Excel propõe o intervalo `=$A$1:$H$109` e marca **Minha tabela tem cabeçalhos**. Confira os
   dois e clique em **OK**.
4. Com uma célula da tabela selecionada, aparece na faixa de opções a guia **Design da Tabela**
   (Table Design). Na ponta esquerda dela há uma caixa **Nome da Tabela** com algo como `Tabela1`.
   Digite `Sales` ali e aperte Enter.

Faça o mesmo nas outras duas planilhas: `Products`, de A1 a G7, com o nome `Products`, e
`Customers`, de A1 a F12, com o nome `Customers`. Aqui a tabela tem o mesmo nome da planilha porque
essa é a escolha mais clara, e o Excel mantém os dois tipos de nome separados.

Se o Excel propuser um intervalo maior que o acima, alguma coisa está encostada nos dados, em geral
uma célula auxiliar esquecida. Cancele, apague-a e comece de novo. Se propuser um menor, há uma linha
ou coluna vazia no meio dos dados, contra o que a seção 07 da aula 1 avisou.

Um nome de tabela não pode ter espaços nem parecer um endereço de célula, então `Sales 2025` e `S1`
são recusados. `Sales`, `Products` e `Customers` são os nomes que toda aula seguinte usa.

## O que mudou, e o que não mudou

Os valores estão onde estavam. A tabela acrescenta quatro coisas em volta deles:

- **faixas de cor** em linhas alternadas, que são só um estilo e podem ser trocadas ou tiradas na
  guia **Design da Tabela**;
- **botões de filtro** em toda célula de cabeçalho, para que ordenar e filtrar sempre cubram a
  tabela inteira, e nunca metade dela;
- **cabeçalhos que continuam visíveis**: role para baixo da linha 1 e as letras das colunas no alto
  da planilha são trocadas por `Sale`, `Date`, `Customer` e as demais;
- **nomes**: a tabela agora se chama `Sales`, e cada coluna se chama pelo seu cabeçalho.

O último é o que as quatro seções seguintes usam.

## Revenue como coluna calculada

A coluna H ainda guarda as fórmulas da aula 2, `=E2*F2` na linha 2, `=E3*F3` na linha 3, e assim
por diante. Dentro de uma tabela há um jeito melhor de escrevê-las. Clique em **H2**, digite

```localised
=[@Bags]*[@Price]
```

e aperte Enter. `[@Bags]` quer dizer *o valor de Bags nesta linha*. O Excel preenche a fórmula pela
coluna inteira, e toda linha passa a guardar o mesmo texto: uma fórmula para a coluna em vez de 108
cópias de um padrão. Isso é uma **coluna calculada**, e uma linha nova a recebe sozinha. Se o Excel
não preencher a coluna por conta própria, clique no botãozinho **Opções de AutoCorreção** que
aparece ao lado de H2 e escolha a opção de substituir todas as células da coluna por esta fórmula
(Overwrite all cells in this column with this formula).

Os números não mudam, e dá para conferir numa célula vazia fora da tabela:

```localised
=SOMA(Sales[Revenue])
```

responde **51494**, os R$ 51.494 da aula 2.

Para transformar uma tabela de volta num intervalo comum, **Design da Tabela › Converter em
Intervalo** faz isso. Nada neste curso precisa disso, e as tabelas ficam até o fim.
