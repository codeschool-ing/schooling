---
title: Unidades de streaming, partições e a conta
version: 1
---

**Esta seção é ensinada a partir da documentação da Microsoft e não foi executada.** Nada no
laboratório do curso mede a capacidade de um job ou o custo dele.

**Um job do Stream Analytics é dimensionado em unidades de streaming (streaming units)**, uma mistura
de processador e memória definida no job, `streaming_units = 3` na declaração da primeira seção desta
lição. Mais unidades deixam o job ler mais rápido e guardar mais estado, as janelas abertas da seção
sobre janelas. A métrica do próprio job para isso é a **utilização de SU %**, a parcela da memória em
uso. A orientação da Microsoft é mantê-la abaixo de uns 80 por cento para que uma rajada não deixe
o job sem memória. Passando disso, os eventos se acumulam na entrada e a saída fica para trás, o que
aparece como um **atraso da marca d'água** crescente, a distância entre agora e a marca d'água do
job.

## Em paralelo quando as partições se alinham

**Um job roda em paralelo quando as partições da entrada, a consulta e a saída se alinham.** A
entrada é lida partição por partição; se o agrupamento da consulta mantém os eventos de cada partição
separados, e a saída também pode ser gravada por partição, cada partição é processada sozinha e o job
escala acrescentando unidades. A Microsoft chama uma consulta assim de **embarrassingly parallel**.
Com o nível de compatibilidade 1.2, o que a declaração define, o serviço alinha a consulta com as
partições da entrada sem que ninguém peça; consultas mais antigas dizem isso com `PARTITION BY
PartitionId`.

A contagem de checkouts desta lição não é uma dessas. Ela conta todos os checkouts de um minuto num
número só, então as quatro partições de `clicks` precisam se encontrar num lugar, e o formato de
costume são dois passos: contar por partição em paralelo, depois somar as quatro contagens. Na
linguagem de consulta isso é um passo `WITH`:

```sql
WITH per_partition AS (
    SELECT PartitionId, COUNT(*) AS checkouts
    FROM [clicks] TIMESTAMP BY at PARTITION BY PartitionId
    WHERE page = '/checkout'
    GROUP BY PartitionId, TumblingWindow(minute, 1)
)
SELECT System.Timestamp() AS window_end, SUM(checkouts) AS checkouts
INTO [checkouts-per-minute]
FROM per_partition
GROUP BY TumblingWindow(minute, 1)
```

O primeiro passo faz a parte pesada, ler e contar, uma vez por partição; o segundo soma quatro
números por minuto. **As partições da lição 22 são o teto aqui também**: um hub com quatro partições
dá a um job no máximo quatro leitores em paralelo, sejam quantas forem as unidades.

## Um job é cobrado enquanto roda

**A conta é de unidades de streaming por hora, para cada hora em que o job está iniciado**, chegue um
evento ou um milhão. Não há cobrança por evento processado nem por consulta; um job que espera a
noite toda por cliques que não vêm custa o que custa um movimentado. A conta abaixo usa um preço
ilustrativo, um número redondo para a soma e não o do Azure: 0,11 USD por unidade de streaming-hora.

| job | unidades | horas num mês de 30 dias | preço ilustrativo | mês |
|---|---|---|---|---|
| checkouts por minuto, sempre ligado | 3 | 730 | 0,11 USD | 240,90 USD |
| o mesmo job, ligado das 7h às 23h | 3 | 16 × 30 = 480 | 0,11 USD | 158,40 USD |

**Parar um job à noite economiza um terço da conta e custa as janelas da noite**, e quando ele volta
de manhã é preciso dizer onde começar: no momento em que é iniciado, numa hora que você informa, ou
de onde parou. A última opção lê os eventos da noite no event hub, o que só é possível se a retenção
do hub da lição 22 cobrir a noite. Essa escolha é a mesma do `starting_position` da lição 22, feita
pelo serviço para você.

Para preços reais, a tabela de preços da lição 1, com rede; ela não foi executada para este curso:

```sh
python prices.py "Stream Analytics" Standard
```

O nome que um serviço tem na lista de preços é escolha da Microsoft, e uma resposta vazia quer dizer
que o filtro não encontrou serviço nenhum, e não que o serviço é de graça.

O lado da saída tem conta própria: o banco SQL onde as contagens são gravadas, ou o event hub que
outro job lê. E o que um job promete sobre entregar cada linha exatamente uma vez a essa saída é o
assunto da lição 24.
