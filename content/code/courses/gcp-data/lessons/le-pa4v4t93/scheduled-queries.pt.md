---
title: Consultas agendadas, para o que uma view não comporta
version: 1
---

**Uma consulta agendada é uma consulta que o BigQuery roda numa agenda e escreve em algum lugar.** É o
outro jeito de manter uma resposta pronta, e o que não tem restrição no SQL: uma mediana, uma função de
janela, um join de cinco tabelas, qualquer coisa que nunca se qualificaria como visão materializada
incremental. O preço dessa liberdade é que nada é mantido por você. A agenda roda a consulta, a consulta
escreve o resultado, e fazer cada execução correta, completa e segura de repetir é trabalho de quem a
escreve.

Consultas agendadas são um recurso do **BigQuery Data Transfer Service**, o mesmo serviço que carrega dados
do Google Ads ou do Amazon S3 numa agenda, e tudo aqui vem da documentação dele. Nada disso rodou.

## Uma, escrita

**Uma consulta agendada que mantém uma tabela de valor mediano de pedido por bairro**, atualizada toda
noite para o dia anterior. O SQL usa `@run_date`, um parâmetro que o serviço preenche com a data de cada
execução; o companheiro dele, `@run_time`, guarda o instante para o qual a execução foi agendada:

```sql
MERGE quitanda.daily_median AS t
USING (
  SELECT dt, district,
         APPROX_QUANTILES(total_cents, 2)[OFFSET(1)] AS median_cents
  FROM quitanda.orders
  WHERE dt = DATE_SUB(@run_date, INTERVAL 1 DAY)
  GROUP BY dt, district
) AS s
ON t.dt = s.dt AND t.district = s.district
WHEN MATCHED THEN UPDATE SET median_cents = s.median_cents
WHEN NOT MATCHED THEN INSERT (dt, district, median_cents)
  VALUES (s.dt, s.district, s.median_cents);
```

**Uma mediana não pode ser mantida de forma incremental**: a mediana dos pedidos de ontem e a do dia
anterior não se combinam na mediana dos dois. Então isto é uma consulta agendada e não uma view, e ela
recalcula um dia por execução. **`MERGE` torna a execução segura de repetir**: rodada duas vezes para a
mesma data, ela atualiza as linhas que a primeira inseriu em vez de inseri-las de novo. Essa propriedade
importa, porque o serviço repete e faz backfill, e uma consulta agendada que acrescenta contaria um dia em
dobro na primeira vez que rodasse duas vezes.

A agenda é criada com a linha de comando `bq`, como você digitaria e não rodada aqui:

```sh
bq mk --transfer_config --data_source=scheduled_query \
  --target_dataset=quitanda --display_name='daily median per district' \
  --schedule='every day 06:00' --location=southamerica-east1 \
  --params='{"query": "MERGE quitanda.daily_median AS t USING ( ... )"}'
```

**A consulta em `--params` é o `MERGE` acima**, abreviado aqui para o comando caber. A agenda é escrita
na sintaxe própria do serviço e lida em UTC, a menos que as opções de fuso horário da documentação digam
outra coisa, que é a primeira coisa a conferir quando um relatório rodado "às seis" chega três horas
adiantado para São Paulo.

## Quanto custa, e do que precisa

**Uma consulta agendada é cobrada como a consulta que roda**, sob demanda ou numa reserva, pelas regras da
aula 14: esta lê três colunas de um dia de pedidos, o mínimo de 10 MB no tamanho da Quitanda. A agenda em
si não soma nada aos bytes. Num mês, o custo são trinta execuções da consulta, e o custo a vigiar é uma
consulta que lê mais a cada noite porque foi escrita sem filtro de partição.

**Ela roda como alguém**, o usuário que a criou ou uma service account, e essa identidade precisa ler a
origem e escrever o destino enquanto a agenda existir. Uma agenda criada por uma pessoa que depois sai da
empresa para no dia em que o acesso dela para; o conselho da documentação de rodar agendas como service
account é essa lição, aprendida antes.

**E ela falha em silêncio, a menos que se diga o contrário.** Uma execução que falha aparece no histórico
de execuções da transferência e em nenhum outro lugar, a menos que a agenda mande uma notificação por
e-mail ou para um tópico do Pub/Sub, que é uma opção da transferência. Um painel lendo `daily_median` na
manhã seguinte a uma execução que falhou mostra as medianas de ontem como se fossem de hoje, e só uma
notificação diz o contrário.

## View ou agenda

**Se o SQL se qualifica como visão materializada incremental, faça uma**: o BigQuery a mantém, responde
consultas com resultados atuais e reescreve consultas para usá-la. **Se não se qualifica, agende**, faça
cada execução segura de repetir, particione a saída como a entrada para uma execução tocar um dia, e faça
as falhas chegarem a uma pessoa. A aula 24 traz o Cloud Composer, que é no que uma cadeia de passos
agendados se transforma quando a saída de uma consulta é a entrada da seguinte.
