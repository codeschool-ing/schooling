---
title: Visões materializadas, e uma resposta guardada pronta
version: 1
---

**Uma visão materializada é uma consulta cujo resultado o BigQuery guarda e mantém atualizado.** Uma view
comum é só uma consulta salva: toda vez que alguém a lê, o BigQuery a roda contra as tabelas base e cobra
o que ela lê. Uma visão materializada roda uma vez, guarda o resultado como uma tabela, e daí em diante o
mantém atual conforme as tabelas base mudam. Os painéis da Quitanda fazem as mesmas poucas perguntas toda
hora, vendas por bairro por dia acima de todas, e a resposta dessa pergunta para o mês passado não muda
desde o mês passado. Recalculá-la toda hora a partir de um milhão de pedidos é a conta que as aulas 14 a
16 precificaram; ler uma resposta guardada de algumas centenas de linhas é quase nada.

Tudo sobre o BigQuery nesta seção vem da documentação do Google, "Introduction to materialized views" e
as páginas sobre criá-las e gerenciá-las, e nada disso rodou. A próxima seção faz a mesma ideia à mão no
DuckDB, e diz com todas as letras que é a ideia.

## Uma, escrita

A view para os painéis, em GoogleSQL, como seria rodada e não rodada:

```sql
CREATE MATERIALIZED VIEW quitanda.daily_sales_mv
PARTITION BY dt
CLUSTER BY district
OPTIONS (enable_refresh = TRUE, refresh_interval_minutes = 60)
AS
SELECT dt, district, COUNT(*) AS orders, SUM(total_cents) AS sales
FROM quitanda.orders
GROUP BY dt, district;
```

**Ela é particionada pela mesma coluna da tabela base**, `dt`, o que importa para os próximos dois
parágrafos, e clusterizada por bairro, o que importa para os painéis que perguntam sobre um. Ela guarda
uma linha por dia e bairro: 480 linhas para os sessenta dias da aula 13, onde a tabela base tem 1.245.118.

## Atualização incremental

**O BigQuery mantém a view de forma incremental: quando linhas novas chegam à tabela base, ele agrega só
essas linhas e as combina com o que já guardou.** A carga de uma noite de 16.359 pedidos atualiza oito
linhas da view a partir de 16.359 linhas de entrada, não de 1.245.118. Essa é a propriedade que torna uma
visão materializada barata de manter, e é por isso que a documentação restringe o que uma view pode
conter: uma view incremental tem de ser feita de operações que se combinam pedaço a pedaço. `COUNT`,
`SUM`, `MIN`, `MAX` e `AVG` se qualificam, porque a soma das linhas novas mais a soma antiga é a soma
nova. Uma mediana não, nem nada que dependa da hora atual, e a documentação lista as funções e os joins que
uma view incremental aceita.

**`enable_refresh` e `refresh_interval_minutes` decidem quando o resultado guardado se atualiza.** Com a
atualização automática ligada, o BigQuery atualiza a view em segundo plano depois que a tabela base muda,
e `refresh_interval_minutes` fixa o tempo mínimo entre duas atualizações, para que uma tabela carregada a
cada minuto não provoque uma atualização a cada minuto. **Entre atualizações, uma consulta ainda recebe
uma resposta atual**: o BigQuery lê o resultado guardado e soma as linhas da base que chegaram desde
então, o delta, então o resultado nunca está velho, a menos que a view tenha sido criada com um
`max_staleness` que permita.

**Linhas que mudam, em vez de chegar, custam mais.** Uma correção num pedido de 15 de setembro não são
linhas novas para somar; ela muda uma soma já guardada. A documentação descreve o BigQuery invalidando o
que a mudança tocou e recalculando, e uma view particionada como a tabela base limita isso às partições
que mudaram. Uma view sobre uma tabela reescrita toda noite não ganha nada por ser incremental.

## Quanto custa

**Três linhas, todas conhecidas.** A view é guardada como uma tabela, pelas tarifas da aula 13, e 480
linhas de quatro colunas não custam nada que os 10 GiB gratuitos notem. Cada atualização é uma consulta,
cobrada sob demanda pelos bytes que lê ou numa reserva pelos slots que usa; atualizações incrementais
leem só as linhas novas. E uma consulta na view é cobrada pelos bytes que lê da view, mais qualquer delta
que precise ler da tabela base. A economia é a diferença entre ler uma resposta pequena guardada e ler a
tabela grande, toda vez que o painel pergunta, e a seção depois da próxima a mede.
