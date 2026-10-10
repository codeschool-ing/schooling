---
title: Quando os erros viram notícia
version: 1
---

**Os erros de planilha que viraram notícia não são exóticos. Cada um é um erro que este curso já
nomeou.** Um limite de linhas, uma fórmula cujo intervalo deixou linhas de fora, números levados de
uma planilha a outra copiando e colando, um valor que o Excel converteu na entrada. O que os tornou
públicos foi a escala: a planilha era o único controle do processo, e nada a conferia com outra
coisa.

Seguem quatro casos, todos bem documentados, cada um contado até onde vai o registro público.

## Public Health England, 2020: o limite antigo de linhas

Em outubro de 2020, a Public Health England, a agência de saúde pública da Inglaterra, informou que
**15.841 resultados positivos de COVID-19**, de 25 de setembro a 2 de outubro, tinham ficado de
fora dos números diários do país. Os resultados chegavam dos laboratórios como arquivos CSV, e uma
parte do processo os carregava em modelos do Excel salvos no formato antigo `.xls`, com suas 65.536
linhas. Cada resultado ocupava várias linhas, então cada modelo guardava bem menos casos do que
isso, e quando um arquivo passava do limite, as linhas além dele não chegavam. Os casos entraram nos
números quando o problema foi descoberto, e o rastreamento dos contatos dessas pessoas começou dias
atrasado.

O mecanismo é a borda da seção 02 desta aula, na forma antiga, mais próxima. Uma consulta da aula
13 carregando os mesmos arquivos no modelo de dados não teria esse teto, e uma contagem de linhas
que entram contra linhas que saem, como as conferências da aula 1, mostraria a diferença no
primeiro dia.

## Reinhart e Rogoff, 2010 e 2013: o intervalo que deixou linhas de fora

Em 2010, os economistas Carmen Reinhart e Kenneth Rogoff publicaram *Growth in a Time of Debt*
("Crescimento num tempo de dívida"), que concluía que países com dívida pública acima de 90% do PIB
cresciam bem mais devagar, e que foi muito citado em debates sobre gasto público. Em 2013, Thomas
Herndon, Michael Ash e Robert Pollin, da Universidade de Massachusetts em Amherst, trabalharam sobre
a própria planilha dos autores e encontraram **uma média cujo intervalo deixava cinco países de
fora**, além de escolhas sobre quais anos excluir e como ponderar os países. Reinhart e Rogoff
reconheceram o erro de planilha e mantiveram que dívida maior anda junto com crescimento menor; o
quanto as correções mudam a conclusão ainda é discutido.

O mecanismo é um intervalo digitado uma vez e que nunca cresceu. As tabelas da aula 7 existem para
que uma fórmula leia a coluna inteira, inclusive linhas acrescentadas depois que ela foi escrita.

## JPMorgan Chase, 2012: copiar, colar e um denominador errado

Em 2012, uma posição de operações do escritório do JPMorgan Chase em Londres, conhecida como
*London Whale* (a "baleia de Londres"), deu ao banco um prejuízo de mais de seis bilhões de dólares.
O próprio comitê de investigação do banco relatou em janeiro de 2013 que um novo modelo para medir
o risco da posição rodava numa série de planilhas **preenchidas copiando e colando à mão**. Achou
também uma fórmula que dividia pela soma de duas taxas quando deveria dividir pela média delas, o
que fazia o risco parecer menor do que era. As operações foram a causa do prejuízo. A planilha ajudou a
esconder o quanto tinham ficado arriscadas.

O mecanismo são dados levados à mão de um arquivo para outro, sem ninguém conferir cada passo. O
Power Query, nas aulas 13 e 14, existe para transformar esse movimento numa receita que roda igual
toda vez.

## Nomes de genes, 2016 e 2020: um valor convertido na entrada

O Excel lê como data um texto que parece data. Digitados ou abertos de um arquivo de texto, os
nomes de genes `SEPT2` e `MARCH1` viram 2 de setembro e 1º de março. Em 2016, Mark Ziemann, Yotam
Eren e Assam El-Osta relataram na revista *Genome Biology* que cerca de **um quinto** dos artigos
publicados que examinaram, com listas de genes em arquivos do Excel, tinham erros desse tipo. Em
2020, o comitê que dá nome aos genes humanos, o HGNC, renomeou alguns deles, `SEPT1` para `SEPTIN1`
e `MARCH1` para `MARCHF1` entre outros, em parte para que as planilhas os deixassem em paz.

O mecanismo é o que a aula 6 consertou à mão: um valor cujo tipo o arquivo nunca declarou, tipado
por quem o abriu. Uma etapa do Power Query que define o tipo da coluna como texto, na aula 13,
decide isso antes do Excel.

## O fio que liga os quatro

Nenhum deles precisou de uma fórmula difícil. Cada um foi **uma falha que nada pegou**, num processo
em que a planilha merecia confiança porque parecia pronta. O European Spreadsheet Risks Interest
Group, um grupo europeu que estuda riscos de planilhas, mantém uma lista pública desses casos. A
lição para este curso não é evitar o Excel. É que um número que importa precisa de um segundo
caminho para chegar a ele, e que um processo do qual muita gente depende precisa de conferências que
uma pasta de trabalho sozinha não tem.
