---
title: Por que uma camada entre as tabelas e as pessoas
version: 1
---

A aula 2 terminou com uma definição de receita líquida escrita em dois lugares: uma view, e um
comentário nela. Isso funciona enquanto um analista escreve todas as consultas. Para de funcionar
no dia em que o negócio quer **autoatendimento**: uma gerente de marketing montando o próprio
gráfico, um analista financeiro explorando uma pergunta que ninguém previu, sem pedir ao time de
dados a cada vez.

Autoatendimento sobre tabelas cruas falha de um jeito previsível. Cada pessoa que monta um gráfico
escreve a definição de novo — pelos menus de uma ferramenta, e não em SQL, mas uma definição do
mesmo jeito — e cada uma escreve um pouco diferente. Uma esquece a conta de teste, outra soma o
valor bruto, outra agrupa pela data em UTC porque foi o que a ferramenta fez por padrão. Seis meses
depois a empresa tem quarenta gráficos de receita e nove números, que é a reunião da aula 2
multiplicada por todo mundo que tem login.

Uma **camada semântica** é a solução: um conjunto de tabelas ou views, mantido por gente que conhece
os dados, que apresenta o negócio nos termos dele, com as definições já aplicadas. Quem monta
gráficos lê só a camada. **Elas escolhem o que olhar; não escolhem o que uma palavra significa.** Na
camada, `net_revenue` é uma coluna que já é líquida, já exclui a conta de teste e já está no dia de
São Paulo, então somá-la é a definição, e ninguém montando um gráfico consegue errar sem querer.

O termo cobre uma faixa de coisas. Numa ponta, é o que esta aula constrói: um schema de views SQL
com nomes de negócio e comentários, que qualquer ferramenta que fala SQL consegue ler. Na outra
ponta, produtos cujo único trabalho é ser a camada — LookML no Looker, o dbt Semantic Layer, o Cube,
um modelo semântico do Power BI — e a última seção desta aula os situa. O que todos têm em comum é a
ideia, e a ideia é o que importa: **definições são escritas uma vez, por alguém responsável por
elas, num lugar que toda ferramenta lê.**

O que uma camada não faz é decidir as definições. A aula 2 continua sendo onde isso acontece. A
camada é onde uma decisão, uma vez tomada, deixa de depender de todo mundo lembrar dela.
