---
title: O que este curso constrói, e para quem
version: 2
---

Quase todo banco de dados que você viu até aqui foi projetado para **registrar** coisas: um pedido,
um pagamento, uma mudança de endereço. Este curso é sobre um segundo tipo de banco, projetado para
**responder** coisas: quanto cada departamento vendeu este ano contra o ano passado, que clientes
pararam de comprar depois que se mudaram, se uma promoção trouxe leitores novos ou só deu desconto
aos antigos. Os dados são os mesmos. O projeto é quase o oposto, e as doze lições são os motivos.

## Uma empresa, do começo ao fim

Toda consulta do curso roda sobre o mesmo negócio. A **Ponto Final** é uma rede de livrarias que
não existe: seis lojas em São Paulo, Campinas, Belo Horizonte, Curitiba e Porto Alegre, e um site
que entrega em todo o Brasil. Os caixas e o site gravam num único banco PostgreSQL, e esse banco
guarda dois anos de vendas, de janeiro de 2024 a dezembro de 2025. A Ana é a analista de dados da
rede, e cada lição é um passo do projeto da Ana: um warehouse construído a partir desse banco.

Os números são inventados, por um programa que os sorteia a partir de sementes fixas, então saem
iguais em qualquer máquina. Tudo o que se faz com eles é real: toda consulta foi executada, e toda
linha de saída numa lição é o que o banco imprimiu.

## O que cada lição acrescenta

| lição | o que a Ana constrói ou mede |
|---|---|
| 1 | as duas cargas de trabalho, medidas no próprio banco da rede |
| 2 | a primeira tabela fato e suas dimensões |
| 3 | o mesmo modelo como estrela e como floco de neve |
| 4 | a granularidade, as chaves e uma tabela para livros com vários autores |
| 5 | clientes que se mudam e trocam de nível, guardados com o histórico |
| 6 | quanto custa normalizar e desnormalizar, em bytes e em joins |
| 7 | o que acontece quando uma máquina não basta |
| 8 | por que o warehouse guarda colunas em vez de linhas |
| 9 | o mesmo modelo no BigQuery, no Snowflake e no Redshift |
| 10 | arquivos num lake, e o formato de tabela que os torna uma tabela |
| 11 | data marts, data mesh e pipelines gerados a partir de metadados |
| 12 | o dicionário que diz o que cada coluna significa |

## Quem está lendo

::: track bi
Você chega de `analytics-bi`, onde montou relatórios sobre tabelas que outra pessoa tinha
desenhado. Este curso é como essas tabelas são desenhadas. No fim você consegue ler um modelo e
dizer se um número num painel merece confiança, e `pipelines-etl` vem a seguir para mantê-lo
carregado.
:::

::: track data
Você chega do lado da engenharia, escrevendo SQL e Python. Este curso é o projeto que você vai
carregar: `pipelines-etl` vem a seguir e é definido por aquilo em que carrega, e por isso o modelo
vem primeiro.
:::

::: track software-architecture
Talvez você nunca construa um warehouse. Mas vai estar na reunião em que alguém propõe um, ou
propõe rodar os relatórios no banco de produção, e este curso dá o vocabulário e as medições para
defender qualquer um dos lados. As lições 1, 6, 7 e 11 são aquelas em que essa decisão se apoia.
:::

::: track *
Você precisa de SQL: tabelas, chaves, joins e normalização, que é o que `sql-databases` ensina.
Metade deste curso discute com essa última, então ajuda tê-la fresca na memória.
:::

**Nada aqui exige uma linguagem de programação além de SQL.** Algumas lições usam um script de
shell curto ou umas linhas de Python para mover arquivos; eles aparecem inteiros, e dá para lê-los
como receitas. O mais longo é o programa da seção 05 que escreve os dados da rede, e esse basta
executar.
