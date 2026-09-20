---
title: O Sheets, e as quatro funções que não existem em outro lugar
version: 1
---

O modelo é o do Excel e as armadilhas também. Uma célula guarda um valor, uma fórmula calcula um,
um tipo é decidido na digitação, e zeros à esquerda continuam sumindo — o conserto do apóstrofo da
aula anterior funciona aqui sem mudança.

O que muda é que **a planilha está numa rede**, e quatro funções existem por causa disso.

## As quatro

| | o que faz |
|---|---|
| `IMPORTRANGE` | puxa um intervalo de **outra planilha**, ao vivo |
| `QUERY` | roda uma pequena consulta de banco sobre um intervalo — select, where, group by |
| `IMPORTHTML`, `IMPORTXML` | puxam uma tabela de uma **página web**, e a mantêm atual |
| `GOOGLEFINANCE` | uma cotação ou uma taxa de câmbio, como valor |

**O `IMPORTRANGE` é o que muda como as pessoas trabalham.** Uma planilha guarda os dados e seis
planilhas leem dela, então existe uma cópia e não seis que se afastaram. Ele pede permissão uma
vez, na planilha de destino, e depois fica ao vivo.

**O `QUERY` é o que vale aprender direito.** `=QUERY(A:D; "select B, sum(D) where C = 'SP' group
by B")` substitui uma tabela dinâmica, um filtro e três colunas auxiliares por uma célula, e se
atualiza sozinho.

E o `ARRAYFORMULA` merece uma linha própria: ele aplica uma fórmula a uma coluna inteira de uma
vez, então há uma fórmula no topo em vez de novecentas cópias. Uma coluna que cresce continua
funcionando, que é o mesmo problema que as tabelas do Excel resolvem por outro caminho.

## Onde o Sheets é pior, e quanto

| | |
|---|---|
| **tamanho** | 10 milhões de células contra o milhão de linhas *por aba* do Excel. O Sheets fica lento bem antes do limite |
| **velocidade em dados grandes** | visivelmente pior, porque o trabalho é num servidor |
| **profundidade estatística** | o Excel tem mais, e o Analysis ToolPak tem mais ainda |
| **macros** | o Apps Script é JavaScript e é genuinamente bom; não é VBA e não roda VBA |
| **offline** | arranjado de antemão, e mais lento |

**A fronteira honesta fica por volta de cinquenta mil linhas com fórmulas dentro.** Abaixo disso o
Sheets é agradável e a colaboração vale mais que a velocidade. Acima, o navegador começa a sentir
e o Excel é a ferramenta certa.

## A armadilha de localidade, que é a brasileira

Uma planilha tem uma **localidade**, ajustada em *Arquivo, Configurações*, e ela decide o
separador decimal, o de milhares e a ordem das datas. Ela vem de onde a conta está, não de onde os
dados vieram.

Então um CSV exportado de um sistema brasileiro, com `1.234,56` dentro, aberto numa planilha
ajustada para os Estados Unidos, produz ou texto ou um número mil vezes maior — e uma coluna de
datas escrita `03/04` cai no mês errado sem aviso algum.

**Ajuste a localidade antes de importar qualquer coisa**, e confira uma linha do resultado contra
a fonte. São trinta segundos e é a diferença entre um número e uma história sobre um número.

## E um hábito que compensa

`Ctrl+Alt+M` deixa um comentário numa célula. Uma planilha que outra pessoa vai ter de usar é uma
planilha com notas nas três células que não são óbvias — a alíquota, a premissa, a coluna que não
pode ser ordenada. Isso é documentação que viaja junto com a coisa documentada, que é o único tipo
que é lido.
