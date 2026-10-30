---
title: Três motores e duas edições
version: 1
---

**O Cloud SQL é um serviço com três motores dentro, e o motor decide quase tudo que importa para um
programa**: o dialeto de SQL, os drivers, as extensões, a porta, e se há licença a pagar. O que o
Cloud SQL acrescenta por cima é igual para os três. Uma instância de PostgreSQL e uma de SQL Server
são criadas com o mesmo comando, têm backup do mesmo jeito e ganham alta disponibilidade do mesmo
jeito, e custam valores muito diferentes pela mesma máquina.

| motor | `--database-version` | licença no Cloud SQL |
|---|---|---|
| MySQL | `MYSQL_8_0`, `MYSQL_8_4`, … | nenhuma, código aberto sob a GPL |
| PostgreSQL | `POSTGRES_16`, `POSTGRES_17`, … | nenhuma, código aberto |
| SQL Server | `SQLSERVER_2022_STANDARD`, … | incluída no preço, nunca a sua |

As versões não são questão de memória. A linha de comando traz a própria referência, e ela lista todo
valor que a flag aceita:

```
ana@laptop:~/gcp$ gcloud sql instances create --help | sed -n '/^     --database-version=/,/^$/p'
     --database-version=DATABASE_VERSION; default="MYSQL_8_0"
        The database engine type and versions. If left unspecified, MYSQL_8_0
        is used. See the list of database versions at
        https://cloud.google.com/sql/docs/mysql/admin-api/rest/v1beta4/SqlDatabaseVersion.
        Apart from listed major versions, DATABASE_VERSION also accepts
        supported minor versions. DATABASE_VERSION must be one of: MYSQL_5_6,
        MYSQL_5_7, MYSQL_8_0, MYSQL_8_4, MYSQL_9_7, POSTGRES_9_6, POSTGRES_10,
        POSTGRES_11, POSTGRES_12, POSTGRES_13, POSTGRES_14, POSTGRES_15,
        POSTGRES_16, POSTGRES_17, POSTGRES_18, POSTGRES_19,
        SQLSERVER_2017_EXPRESS, SQLSERVER_2017_WEB, SQLSERVER_2017_STANDARD,
        SQLSERVER_2017_ENTERPRISE, SQLSERVER_2019_EXPRESS, SQLSERVER_2019_WEB,
        SQLSERVER_2019_STANDARD, SQLSERVER_2019_ENTERPRISE,
        SQLSERVER_2022_EXPRESS, SQLSERVER_2022_WEB, SQLSERVER_2022_STANDARD,
        SQLSERVER_2022_ENTERPRISE, SQLSERVER_2025_EXPRESS,
        SQLSERVER_2025_STANDARD, SQLSERVER_2025_ENTERPRISE.
```

**O padrão é MySQL**, `MYSQL_8_0`, então uma instância criada sem a flag é uma instância MySQL, seja
o que for que o time quisesse. **Nomeie a versão em todo comando que escrever**, para que o que você
criou não dependa de qual padrão respondeu. E a lista é mais larga do que o que o Google suporta para
trabalho novo: versões como `POSTGRES_9_6` e `MYSQL_5_6` ainda são aceitas, e a página de preços tem
uma tabela chamada "Extended support" que cobra a mais, por vCPU e hora, de uma instância mantida numa
versão principal depois do fim do suporte padrão dela. A última seção desta aula põe um número nisso.

**A edição do SQL Server está no texto da versão**: Express, Web, Standard e Enterprise, sem Web para
2025, e a licença segue a edição. **Não existe trazer a própria licença**: a página de preços diz,
numa nota, que o Cloud SQL não aceita BYOL para SQL Server, então a licença está no preço por hora e
uma empresa que já comprou licenças de SQL Server paga de novo. Como escolher entre os motores como
bancos de dados é a aula 12 de `sql-databases`; este curso toma a escolha como feita, e os pedidos da
Quitanda estão em PostgreSQL.

## Enterprise e Enterprise Plus

**Uma edição é um nível de serviço, escolhido por instância, por cima de qualquer um dos três
motores**:

```
ana@laptop:~/gcp$ gcloud sql instances create --help | sed -n '/^     --edition=/,/^$/p'
     --edition=EDITION
        Specifies the edition of Cloud SQL instance. EDITION must be one of:
        enterprise, enterprise-plus.
```

As diferenças, como a documentação do Google as descreve ("Introduction to Cloud SQL editions"):

| | Enterprise | Enterprise Plus |
|---|---|---|
| máquinas | núcleo compartilhado, ou as vCPUs e a memória que você der | tipos de máquina predefinidos, com nome por série |
| disponibilidade no SLA | 99,95% | 99,99%, manutenção incluída |
| manutenção planejada | um reinício do motor | uma troca que o Google documenta em menos de um segundo |
| cache de dados | nenhum | um cache em SSD ao lado da memória, cobrado por GiB |
| logs de transação para recuperação | até 7 dias | até 35 dias |

**As máquinas são onde o comando muda.** A referência diz:

```
ana@laptop:~/gcp$ gcloud sql instances create --help | sed -n '/^        Enterprise Edition: Use --tier/,/C4A series/p'
        Enterprise Edition: Use --tier for shared-core instances (e.g.,
        db-f1-micro, db-g1-small). For dedicated-core instances, do not use
        --tier; instead, customize your instance by specifying its CPU and
        memory with the --cpu and --memory flags.

        Enterprise Plus Edition: --tier is required to specify the predefined
        machine type. The --cpu and --memory flags are not supported for
        Enterprise Plus. Examples include db-perf-optimized-N-2 (N2 series) or
        db-c4a-highmem-2 (C4A series).
```

**No Enterprise, uma máquina são dois números**: `--cpu=2 --memory=8GiB`, ou um tier de núcleo
compartilhado como `db-f1-micro` para um banco de que ninguém depende. **No Enterprise Plus, uma
máquina é um nome**: `db-perf-optimized-N-2` são duas vCPUs da série N2 com 16 GiB de memória, oito
por vCPU, e os dois números são recusados. A seção sobre custo mostra o que essa proporção faz com o
preço.

**Qual delas para os pedidos da Quitanda?** O banco de pedidos recebe dinheiro: uma hora perdida dele
é uma hora perdida de vendas. A diferença entre 99,95% e 99,99% é de uns 22 minutos contra 4 num mês de
730 horas, e a manutenção que o Enterprise conta fora do SLA está dentro do SLA do Enterprise Plus.
Uma empresa pode, com razão, pagar por isso nos pedidos e recusar na cópia de relatórios. O resto desta
aula usa o Enterprise, porque é a mais barata das duas e a conta fica mais fácil de acompanhar; a aula
7 lhe dá alta disponibilidade, que é uma decisão separada da edição.

O AlloyDB, o motor compatível com PostgreSQL do próprio Google com uma camada de armazenamento
própria, não está nesta lista, e o Spanner também não; a aula 8 situa o AlloyDB entre o Cloud SQL e o
Spanner, e a aula 9 é o Spanner.
