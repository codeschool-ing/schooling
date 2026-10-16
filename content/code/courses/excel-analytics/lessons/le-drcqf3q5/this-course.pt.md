---
title: O que este curso faz, e de onde vêm os números dele
version: 1
---

**Quase toda empresa já tem a ferramenta que este curso ensina, e quase todas usam um décimo
dela.** É no Excel que as vendas são somadas, os orçamentos discutidos e os relatórios montados
toda segunda-feira. O mesmo programa importa um arquivo e o limpa do mesmo jeito todo mês, junta
três tabelas sem uma única fórmula de busca e responde "como este trimestre se compara com o mesmo
trimestre do ano passado" com uma tabela dinâmica que se atualiza sozinha. Este curso vai do
primeiro uso ao segundo.

Ele sobe em cinco degraus, e cada um se apoia no anterior:

| aulas | o que você aprende a fazer |
|---|---|
| **1 a 6** | organizar os dados para que possam ser analisados, e escrever as fórmulas de que a análise é feita: referências, lógica, buscas, totais condicionais, limpeza de texto e datas |
| **7 a 9** | dar estrutura aos dados: tabelas que crescem, entrada conferida, formatação que diz alguma coisa |
| **10 a 12** | resumir: tabelas dinâmicas, segmentações, gráficos |
| **13 e 14** | importar e moldar com o **Power Query**, para que a limpeza vire receita e não uma tarde inteira |
| **15 a 18** | modelar com o **Power Pivot** e o **DAX**, montar um painel sobre o modelo e saber quando o trabalho ficou grande demais para o Excel |

## Uma empresa, do começo ao fim

Todas as aulas trabalham sobre os mesmos dados: dezoito meses de vendas da **Café Serra**, uma
torrefação que não existe, que você cola numa pasta de trabalho na seção 05 desta aula. Usar uma
empresa só significa que um número encontrado na aula 5 pode ser conferido com uma tabela dinâmica
na aula 10 e com uma medida DAX na aula 16, e os três precisam bater. Quando não batem, alguma
coisa na análise está errada, e descobrir o quê faz parte do curso.

## Como as fórmulas são escritas aqui

O Excel traduz os nomes das funções para o idioma em que está configurado, e em português também
troca a vírgula entre os argumentos por ponto e vírgula. Esta versão do curso imprime as fórmulas
como um Excel em **português** as escreve:

```localised
=SOMASES(E2:E109; G2:G109; "Online")
```

Se o seu Excel estiver em inglês, a função tem outro nome e os mesmos argumentos: `SOMASES` é
`SUMIFS`, `PROCX` é `XLOOKUP`, `SE` é `IF`, e as páginas de suporte da Microsoft listam cada função
com os dois nomes. Os argumentos, nesse caso, são separados por vírgula. O texto corrido cita os
dois nomes na primeira vez que uma função aparece.

Endereços de célula, nomes de planilhas e o texto entre aspas nunca mudam com o idioma. Os
cabeçalhos das colunas dos dados ficam em inglês nas duas versões do curso, porque são dados, e
dados não mudam quando muda quem os lê.

## De onde vêm os números

**Este curso foi escrito num computador que não tem Excel**, e diz isso em vez de fingir o
contrário. Mesmo assim, todo número citado foi calculado, nunca digitado:

- os resultados das fórmulas, nas aulas 1 a 12, por uma planilha eletrônica, o LibreOffice Calc,
  com cada fórmula digitada exatamente como a aula a imprime, numa pasta com os dados que você cola.
  O Calc implementa essas funções com os mesmos argumentos do Excel. O `PROCX`, que a versão usada
  não tem, foi calculado por uma calculadora separada, compatível com o Excel;
- as tabelas dinâmicas, pela tabela dinâmica do próprio Calc, conferidas com as fórmulas da aula 5;
- os resultados das etapas do Power Query e das medidas DAX, nas aulas 13 a 16, por um script que
  aplica as mesmas etapas aos mesmos dados, porque nenhum dos dois tem motor fora do Excel. Essas
  aulas dizem isso no lugar em que acontece.

O que não daria para produzir com honestidade é uma foto das telas do Excel, então não há nenhuma.
As figuras desenham a ideia: a forma de uma tabela, o caminho de uma busca, as etapas de uma
consulta. Os menus são citados por escrito, com o caminho até cada comando, e onde a Microsoft
mudou um comando de lugar entre versões a aula diz onde procurar.

## As questões

Cada aula termina com questões, e muitas pedem o número que uma fórmula devolve nos seus dados.
Elas não valem nota. Uma resposta errada mostra por que estava errada, e isso é o mais útil que uma
questão tem a dar; leia a explicação mesmo quando acertar.
