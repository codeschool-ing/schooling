---
title: Modelos e métricas, a camada dentro do Metabase
version: 1
---

O Metabase tem dois recursos próprios que fazem o que as views da aula 3 fazem, e vale saber que os
dois existem, e o que custam.

Um **modelo** (*model*) é uma pergunta salva que o Metabase trata como tabela. A descrição dele mesmo
diz: *do all your joins and custom columns once, save it as a model, then query it like a table* —
faça os joins e as colunas calculadas uma vez, salve como modelo, e consulte como uma tabela. Um modelo
pode ter descrições para as colunas, e outras perguntas partem dele como se fosse uma view. Eles ficam
em **Browse models**, e **Create a new model** começa um.

Uma **métrica** (*metric*) é uma agregação salva com nome: *Receita líquida* definida uma vez como a
soma de `net_revenue` sobre `Orders`, e depois oferecida pelo nome no editor onde se aplicar, para que
quem monta uma pergunta escolha a métrica em vez de refazer a soma. Elas ficam em **Browse metrics**, e
**Create a new metric** começa uma. Um Metabase novo mostra duas dele mesmo ali, dos dados de exemplo.

## Qual camada, então

A Lantern agora tem dois lugares onde uma definição pode morar: as views do `semantic.sql`, e os
modelos e métricas do Metabase. A regra que este curso segue é a que a aula 3 defendeu:

| definição | onde | por quê |
|---|---|---|
| o que é receita líquida, quais linhas existem, em que dia um pedido cai | as views do banco | toda ferramenta as lê, inclusive o app Streamlit das próximas seções e o reverse ETL da aula 7 |
| como os usuários do Metabase encontram as coisas: uma métrica com nome para o menu, um modelo no formato das perguntas de um time | o Metabase | dizem respeito à interface da ferramenta, e nenhuma outra precisa delas |

**Uma métrica no Metabase deveria somar uma coluna cujo significado já foi decidido no banco.** No dia
em que uma métrica do Metabase passar a tirar pedidos estornados por conta própria, a definição de
receita líquida mora em dois lugares, e a reunião da aula 2 voltou.
