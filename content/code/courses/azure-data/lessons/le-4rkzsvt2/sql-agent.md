---
title: SQL Agent, the job that runs at night
version: 1
---

**SQL Agent is the scheduler inside a SQL Server instance**, and in most companies that ran SQL Server
for a decade it holds work nobody has written down anywhere else: the nightly summary, the purge of old
rows, the export a partner collects at six. Its jobs, their steps, their schedules and their history
are rows in the `msdb` database, written and read with stored procedures. Managed Instance has SQL
Agent and `msdb`; Azure SQL Database has neither.

The container in `~/azure` runs SQL Agent too, because lesson 1's `compose.yaml` sets
`MSSQL_AGENT_ENABLED`. Quitanda's job sums every day of orders that has not been summed yet into a
table of daily totals, and runs at ten past three every night. Save this as `~/azure/job.sql`:

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

**Five procedures make one job.** `sp_add_job` names it, `sp_add_jobstep` gives it a step that runs
T-SQL in `quitanda`, `sp_add_schedule` makes a schedule, `@freq_type = 4` meaning daily and
`@active_start_time = 31000` meaning 03:10:00, `sp_attach_schedule` joins the two, and
`sp_add_jobserver` says which instance runs it, this one. Rather than wait for three in the morning,
start it by hand and read what it left:

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

**`run_status` 1 is success**, once for the step and once for the job as a whole, and the table now has
a row for every day the orders span: 348 of them, holding all 100,000 orders. The generated orders run
to 14 December, past the day this was recorded, which a generator does not mind. Because the step only sums days it has not summed, running it
again tomorrow adds tomorrow and nothing twice. A nightly job that is safe to run twice is the one that
survives the night somebody starts it by hand as well.

## On Azure

**On Managed Instance, `job.sql` runs unchanged**: SQL Agent and `msdb` are there, with the same
procedures and the same history tables. That is the documented promise and it was not run here.

**On Azure SQL Database it fails at the first line that names `msdb`**, because there is no instance and
so no SQL Agent. The documented replacement is elastic jobs: a job agent that is an Azure resource of
its own, keeping its jobs in a database you give it, and running T-SQL against target databases on a
schedule. It does the same work with a different vocabulary, and moving a company's SQL Agent jobs to
it is a rewrite of each one. Counting them, in `msdb.dbo.sysjobs` on the old server, is the first
question of any move to the database service.
