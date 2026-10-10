---
title: Achar, ordenar e limpar regras
version: 1
---

**As regras são invisíveis até dispararem, então uma planilha vai acumulando**: uma criada para
testar uma ideia, outra copiada junto com algumas células, uma terceira que sobrou do relatório do
ano passado. O **Gerenciador de Regras** é o único lugar que mostra todas, e é onde se decide a ordem
entre elas.

## O Gerenciador de Regras

**Página Inicial › Formatação Condicional › Gerenciar Regras** (**Manage Rules**) o abre. A lista no
alto, **Mostrar regras de formatação para**, começa na seleção atual; mude para **Esta Planilha** para
ver todas as regras da planilha. Cada linha mostra:

- a **regra**, como `Fórmula: =$G2="Wholesale"` ou `Valor da Célula >= 1500`;
- o **formato**, numa pequena amostra;
- **Aplica-se a**, o intervalo que ela cobre, que dá para editar ali mesmo;
- **Parar se Verdadeiro**, uma caixa que alguns tipos de regra oferecem.

**Nova Regra**, **Editar Regra** e **Excluir Regra** ficam acima da lista, e as duas setas ao lado
sobem ou descem a regra selecionada.

## A ordem decide qual cor ganha

Quando duas regras são verdadeiras para a mesma célula e as duas definem o preenchimento dela, **a
regra mais alta da lista ganha**. Formatos que não brigam se somam: uma regra pode definir o
preenchimento e outra o negrito.

Experimente em `Sales[Revenue]`. Crie uma regra que preenche células de **1.500 ou mais** com uma cor
forte, e outra que preenche células de **1.000 ou mais** com uma clara. Uma fórmula conta cada grupo:

```localised
=CONT.SE(Sales[Revenue]; ">=1500")
=CONT.SE(Sales[Revenue]; ">=1000")
```

**9** e **18**. Com a regra de 1.500 no alto, as 9 maiores vendas ficam fortes e as outras 9 claras, e
a planilha mostra dois níveis. Suba a regra de 1.000 para o alto e as 18 ficam claras: a regra de
1.500 continua verdadeira para 9 delas, e perde todas as vezes. Nada na planilha diz que uma regra foi
vencida, então **ponha a condição mais estreita acima da mais larga**.

**Parar se Verdadeiro** é um jeito mais antigo de dizer a mesma coisa. Marcado numa regra, ele faz o
Excel parar de olhar as regras abaixo dela para qualquer célula em que ela seja verdadeira, mesmo
quando elas definiriam outra propriedade.

## Como as regras se multiplicam

Copiar e colar células formatadas copia as regras delas, e inserir linhas, mover células ou colar no
meio de um intervalo pode partir uma regra em várias, com intervalos **Aplica-se a** estranhos e
sobrepostos. A planilha continua parecendo certa, e por isso ninguém percebe até o gerenciador listar
doze cópias da mesma regra. Dois hábitos seguram isso:

- **aplique regras a colunas inteiras de uma tabela**, que a tabela estende conforme cresce, em vez de
  a um intervalo que alguém depois estende colando;
- **abra o gerenciador em Esta Planilha de vez em quando**, junte duplicatas editando o **Aplica-se
  a** de uma regra para cobrir o intervalo todo, e exclua o resto.

## Limpar

**Formatação Condicional › Limpar Regras** (**Clear Rules**) tira as regras das células selecionadas,
da planilha inteira ou da tabela em que está a seleção. Tira só formatações condicionais:
preenchimentos e fontes aplicados à mão ficam.

Mantenha ou limpe o que esta aula criou, como preferir. Nada nas aulas 10 a 18 depende dessas regras
nem da planilha `By month`: as tabelas dinâmicas da aula 10 leem os valores de `Sales`, nunca as
cores deles.
