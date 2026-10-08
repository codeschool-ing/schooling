---
title: Um framework, código próprio, ou os dois
version: 2
---

Depois das aulas 8 a 12 o curso tem as duas coisas: verificações escritas em poucas linhas cada, e dois
frameworks que podem rodá-las ou substituí-las. A escolha não é uma ou outra, e a troca é clara o
bastante para ser escrita.

**Um framework dá** um vocabulário comum que outras pessoas reconhecem, dezenas de métricas já escritas
com os seus prompts, um executor e um relatório, e uma integração com o pytest. Quando uma equipe precisa
de faithfulness avaliada por modelo amanhã, uma métrica de framework é um dia de trabalho poupado.

**Código próprio dá** uma definição que cabe numa tela, nenhuma dependência para fixar, e números que não
mudam quando uma biblioteca é atualizada. Toda métrica em que este curso se apoia para decidir algo é uma
cuja docstring é a definição inteira.

**Os dois** é onde a maioria das equipes chega, e funciona quando três regras valem:

1. **Toda métrica que decide alguma coisa é medida contra rótulos** antes de receber confiança, o kappa
   da aula 10, tenha sido escrita em casa ou importada.
2. **Uma métrica de framework é fixada junto com o framework**: a versão, o nome da classe e o modelo de
   juiz ficam registrados ao lado de cada nota, porque o mesmo nome quer dizer aritmética diferente em
   versões diferentes, como a aula 11 mostrou entre frameworks.
3. **A métrica pronta de um framework é lida antes de ser rodada.** O prompt dela está no pacote
   instalado, e lê-lo diz o que ela vai premiar.

A aula 14 usa essas métricas para comparar duas versões do assistente, e a aula 15 transforma a
comparação num teste que pode reprovar um build. As duas funcionam com as verificações do curso ou com
as de um framework, e as duas usam as quarenta e oito respostas rotuladas para dizer em quais verificações dá
para acreditar.
