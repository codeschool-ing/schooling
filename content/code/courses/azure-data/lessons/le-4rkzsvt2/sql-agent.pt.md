---
title: SQL Agent, o job que roda à noite
version: 1
---

**O SQL Agent é o agendador dentro de uma instância do SQL Server**, e na maioria das empresas que
rodaram SQL Server por uma década ele guarda trabalho que ninguém escreveu em nenhum outro lugar: o
resumo noturno, a limpeza de linhas antigas, a exportação que um parceiro busca às seis. Os jobs dele,
os passos, as agendas e o histórico são linhas no banco `msdb`, escritas e lidas com stored procedures.
A Managed Instance tem SQL Agent e `msdb`; o Azure SQL Database não tem nenhum dos dois.

O contêiner em `~/azure` também roda o SQL Agent, porque o `compose.yaml` da lição 1 define
`MSSQL_AGENT_ENABLED`. O job da Quitanda soma cada dia de pedidos que ainda não foi somado numa tabela
de totais diários, e roda às três e dez de toda noite. Salve isto como `~/azure/job.sql`:

`job.sql`:

```sql
USE quitanda;
CREATE TABLE dbo.daily_totals (day date PRIMARY KEY, orders int NOT NULL, cents bigint NOT NULL);
GO
USE msdb;
EXEC dbo.sp_add_job @job_name = N'nightly-totals';
EXEC dbo.sp_add_jobstep @job_name = N'nightly-totals', @step_name = N'sum new days',
  @database_name = N'quitanda',
  @command = N'INSERT dbo.daily_totals
    SELECT CAST(placed_at AS date), COUNT(*), SUM(total_cents) FROM dbo.orders
    WHERE CAST(placed_at AS date) NOT IN (SELECT day FROM dbo.daily_totals)
    GROUP BY CAST(placed_at AS date);';
EXEC dbo.sp_add_schedule @schedule_name = N'nightly 03:10', @freq_type = 4,
  @freq_interval = 1, @active_start_time = 31000;
EXEC dbo.sp_attach_schedule @job_name = N'nightly-totals', @schedule_name = N'nightly 03:10';
EXEC dbo.sp_add_jobserver @job_name = N'nightly-totals';
GO
```

**Cinco procedimentos fazem um job.** `sp_add_job` dá o nome, `sp_add_jobstep` dá um passo que roda
T-SQL em `quitanda`, `sp_add_schedule` cria uma agenda, com `@freq_type = 4` querendo dizer diária e
`@active_start_time = 31000` querendo dizer 03:10:00, `sp_attach_schedule` junta os dois, e
`sp_add_jobserver` diz que instância o roda, esta. Em vez de esperar as três da manhã, dispare-o à mão e
leia o que ele deixou:

```
ana@laptop:~/azure$ sql < job.sql
Changed database context to 'quitanda'.
Changed database context to 'msdb'.
ana@laptop:~/azure$ sql -Q "EXEC msdb.dbo.sp_start_job @job_name = N'nightly-totals'"
Job 'nightly-totals' started successfully.
ana@laptop:~/azure$ sleep 5; sql -Q "SELECT j.name, h.step_name, h.run_status FROM msdb.dbo.sysjobhistory h JOIN msdb.dbo.sysjobs j ON j.job_id = h.job_id"
name|step_name|run_status
----|---------|----------
nightly-totals|sum new days|1
nightly-totals|(Job outcome)|1

(2 rows affected)
ana@laptop:~/azure$ sql -d quitanda -Q "SELECT COUNT(*) AS days, MIN(day) AS first_day, MAX(day) AS last_day, SUM(orders) AS orders FROM dbo.daily_totals"
days|first_day|last_day|orders
----|---------|--------|------
348|2026-01-01|2026-12-14|100000

(1 rows affected)
```

**`run_status` 1 é sucesso**, uma vez para o passo e uma para o job inteiro, e a tabela agora tem uma
linha para cada dia que os pedidos cobrem: 348 delas, com todos os 100.000 pedidos. Os pedidos gerados
vão até 14 de dezembro, depois do dia em que isto foi gravado, o que um gerador não se importa. Como o
passo só soma dias que ainda não somou, rodá-lo de novo amanhã acrescenta amanhã e nada duas vezes. Um
job noturno que aguenta rodar duas vezes é o que sobrevive à noite em que alguém também o dispara à
mão.

## No Azure

**Na Managed Instance, o `job.sql` roda sem mudança**: o SQL Agent e o `msdb` estão lá, com os mesmos
procedimentos e as mesmas tabelas de histórico. Essa é a promessa documentada e não foi rodada aqui.

**No Azure SQL Database ele falha na primeira linha que nomeia o `msdb`**, porque não há instância e
portanto não há SQL Agent. O substituto documentado são os elastic jobs: um agente de jobs que é um
recurso próprio do Azure, que guarda os jobs num banco que você dá a ele e roda T-SQL contra bancos de
destino numa agenda. Ele faz o mesmo trabalho com outro vocabulário, e levar os jobs do SQL Agent de
uma empresa para ele é reescrever cada um. Contá-los, em `msdb.dbo.sysjobs` no servidor antigo, é a
primeira pergunta de qualquer mudança para o serviço de banco de dados.
