---
title: Escolhendo entre elas
version: 1
---

Um time raramente escolhe uma ferramenta de BI por recursos, porque todas desenham um gráfico de
barras. As perguntas que decidem são sobre pessoas, dinheiro e onde as definições vão morar.

| pergunta | aponta para |
|---|---|
| A maioria dos leitores vai montar as próprias perguntas, sem SQL? | Metabase, Tableau, Power BI |
| Toda definição precisa ser revisada como código antes de alguém vê-la? | Looker, ou views no banco, seja qual for a ferramenta |
| Não há verba para licenças? | Metabase rodado por você, Streamlit |
| A página precisa de algo que nenhuma ferramenta de BI desenha — uma simulação, um formulário, um gráfico próprio? | Streamlit |
| A empresa já paga pelo Microsoft 365 ou pelo Google Cloud? | Power BI ou Looker, vendidos junto com eles |
| Quem a constrói vai sair em um ano? | a ferramenta cujas definições moram onde um sucessor consegue ler |

A última linha é a que os times esquecem. Um app Streamlit é tão manutenível quanto o código dele; um
Metabase cheio de coleções pessoais é tão manutenível quanto a memória dos donos delas; um servidor
Tableau com cem pastas de trabalho, cada uma com campos calculados próprios, são cem lugares para
procurar.

**Seja qual for a ferramenta, as definições que importam pertencem a uma camada abaixo dela**, no
banco, onde a aula 3 as pôs. A receita líquida da Lantern chegou aos mesmos R$ 1.046.756,40 pelo
`psql`, pelo Metabase e pelo Streamlit nesta aula, e chegaria pelos arquivos do Power BI da aula 4,
porque nenhuma das quatro ferramentas pôde decidir o que receita líquida significa. A empresa pode
então trocar de ferramenta de BI — e a maioria troca mais de uma vez — sem mudar um único número.
