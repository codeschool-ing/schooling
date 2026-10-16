---
title: O que é este curso, e a loja que ele estuda
version: 1
---

Toda empresa que guarda dados acaba com alguém que ouve uma pergunta no corredor — quantos
clientes perdemos no mês passado? — e precisa responder com um número que outras duas pessoas
vão conferir com os delas. Este curso é sobre essa ponta do dado: **a parte que o negócio de
fato lê**. Os pipelines rodaram, as tabelas existem, e agora uma pessoa precisa decidir alguma
coisa.

Ele cobre quatro trabalhos, nesta ordem:

| aulas | o trabalho |
|---|---|
| 1 a 3 | conhecer os dados, combinar o que cada número significa e escrever esses significados uma vez, em SQL, onde toda ferramenta os lê |
| 4 a 6 | pôr os números diante das pessoas: Power BI, outras quatro ferramentas e o que torna um painel legível |
| 7 e 8 | **reverse ETL**: devolver números calculados às ferramentas onde as pessoas trabalham, para que um vendedor veja uma pontuação sem abrir painel nenhum |
| 9 e 10 | as análises que o negócio mais pede — segmentos, coortes e funis — e os jeitos pelos quais um número verdadeiro ainda engana |

## Lantern Coffee

Todas as aulas trabalham sobre uma empresa. A **Lantern Coffee** é uma pequena torrefação de
São Paulo que vende grãos, café moído e equipamento de preparo pelo próprio site, para pessoas
em casa e para alguns escritórios. A loja online abriu em 1º de janeiro de 2025, e os dados vão
até 17 de junho de 2026, a noite da última extração.

A loja é inventada e os dados são gerados, por um script que você vai colar no seu próprio banco
nesta aula. O script foi escrito para produzir **as mesmas linhas em toda execução**: quando uma
aula diz que a mediana dos pedidos é R$ 95,80, o seu banco diz R$ 95,80 também. Ele também tem os
defeitos que dados reais têm, postos ali de propósito — e encontrá-los é a maior parte desta
aula.

## O que roda na sua máquina, e o que não roda

Três ferramentas deste curso são gratuitas, de código aberto e rodam no seu computador, e toda
transcrição do curso foi gravada com elas:

- **PostgreSQL 16**, o banco de dados, a partir desta aula;
- **Metabase**, uma ferramenta de business intelligence que se abre no navegador, a partir da
  aula 3;
- **Streamlit**, um jeito de transformar um arquivo curto de Python numa página web, na aula 5.

As outras que o curso cita são produtos que alguém vende, e **nada neste curso depende de licença
ou de período de teste**. O Power BI Desktop só roda no Windows, então a aula 4 mostra as fórmulas
dele ao lado do SQL que calcula os mesmos números, e diz com clareza qual dos dois rodou. Tableau
e Looker na aula 5, e Hightouch, Census e Segment na aula 8, são descritos a partir da própria
documentação e mapeados em coisas que você mesmo constrói. Quando uma aula mostra algo que não
pôde rodar, ela diz isso na frase de cima.

::: track bi
Você chega de `visualization` e de `statistics`, e este curso se apoia nos dois: mediana, quartil
e correlação são ferramentas que você já tem, e esta aula as usa num banco de dados em vez de
numa planilha.
:::

::: track data-platform
Você chega do lado da plataforma, onde as tabelas são construídas, carregadas e vigiadas. Este
curso é onde elas são lidas — e é o melhor lugar para ver por que uma coluna que ninguém
documentou, ou uma carga que pulou um dia em silêncio, custa a alguém uma decisão errada.
:::

::: track *
O curso pressupõe SQL: joins, `GROUP BY` e funções de janela. Onde usa uma ideia de estatística —
mediana, quartil, correlação — ele a explica na seção que precisa dela.
:::
