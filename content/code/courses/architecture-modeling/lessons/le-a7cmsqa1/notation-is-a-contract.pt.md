---
title: Uma notação é um contrato com quem lê
version: 1
---

**Uma notação é um acordo, feito antes de o leitor olhar, sobre o que cada tipo de marca quer
dizer.** Uma notação padronizada como a UML faz esse acordo uma vez, para todo mundo que a aprendeu.
Uma informal o faz na própria página, numa legenda. As duas funcionam. O que não funciona é um
desenho sem acordo nenhum, em que o leitor precisa adivinhar as regras a partir das marcas.

## Formal, informal e o meio-termo

| | onde o sentido está escrito | serve para | o preço |
| --- | --- | --- | --- |
| **uma notação padronizada** (UML, BPMN, ArchiMate) | numa especificação que o leitor estudou | leitores que a conhecem; afirmações precisas sobre estrutura e comportamento | quem não a conhece vê caixas com pontas de seta estranhas, e um losango na ponta errada muda o sentido |
| **uma convenção leve** (C4) | num conjunto curto de regras, mais uma legenda em cada diagrama | públicos mistos; detalhe técnico sem manual | diz pouco sobre comportamento; para isso, pega emprestado da UML |
| **caixas e linhas** | só na legenda, se houver | um esboço rápido, um quadro branco, um primeiro rascunho | sem legenda é decoração, seja qual for a intenção |

Nenhuma delas é melhor em geral. **A notação certa é a que o seu leitor consegue ler**, com precisão
suficiente para a pergunta. Um diagrama de sequência UML é o desenho certo para um engenheiro
investigando um timeout e o errado para Celeste, a diretora de operações, que quer saber se um
ônibus consegue sair quando o provedor de pagamento está fora do ar.

## A legenda é o contrato à vista

Uma legenda lista cada tipo de marca que o diagrama usa e o que ela significa. Duas objeções comuns
estão ambas erradas:

- *"Todo mundo sabe o que uma caixa quer dizer."* Cada um sabe uma coisa diferente, e é esse o
  problema que a legenda resolve.
- *"Ela polui o desenho."* Uma legenda ocupa um canto. A falta dela custa a cada leitor um palpite
  para cada marca.

Uma boa legenda cobre **tipos de elemento** (pessoa, serviço, banco de dados, sistema externo),
**estilos de linha** (contínua para chamadas síncronas, tracejada para mensagens assíncronas, se essa
for a convenção), **cores** e **fronteiras**. Se um tipo de marca aparece uma vez só, ainda precisa
de uma entrada.

## Um sentido por marca, no documento inteiro

O contrato vale para um conjunto de diagramas, não só dentro de um. Se uma linha tracejada quer
dizer *assíncrona* no diagrama de containers e *planejada, ainda não construída* no diagrama de
implantação, quem viu o primeiro vai ler errado o segundo. A Carcará resolveu isso do jeito sem
graça: uma página curta no repositório de arquitetura, chamada *Como desenhamos*, para a qual todo
diagrama aponta. Ela cabe numa tela:

- pessoas são caixas arredondadas com cabeça; nossos serviços são caixas na cor de destaque; o que
  não rodamos é cinza;
- linha contínua é uma chamada que espera resposta; linha tracejada é uma mensagem que não espera;
- toda linha tem um verbo, e o protocolo quando o leitor é técnico;
- uma fronteira é tracejada e tem o nome no canto superior esquerdo;
- todo diagrama tem um título que diz o que mostra e a data da última conferência.

**Uma notação própria serve, desde que esteja escrita.** O que causa problema é uma notação privada:
as convenções estão todas na cabeça de quem desenhou, coerentes e invisíveis, e o primeiro leitor a
aprendê-las é o que pergunta.
