"""Ponto Final's nightly load: the shop into raw, staging rebuilt, the marts loaded."""
import pendulum
from airflow.providers.standard.operators.bash import BashOperator
from airflow.sdk import dag, task

ETL = "/home/ana/etl"
PSQL = "psql -q -v ON_ERROR_STOP=1 -d wh"


@dag(
    schedule="0 2 * * *",
    start_date=pendulum.datetime(2026, 3, 2, tz="America/Sao_Paulo"),
    catchup=False,
    tags=["shop"],
)
def shop_nightly():
    @task
    def day_to_load(logical_date=None) -> str:
        """The run at 02:00 loads the day that has just ended, in São Paulo."""
        return logical_date.in_timezone("America/Sao_Paulo").subtract(days=1).to_date_string()

    day = day_to_load()
    extract = BashOperator(task_id="extract", bash_command="python load_raw.py", cwd=ETL)
    # The space after run_sql.sh is deliberate: a command ending in ".sh" is read
    # as the name of a template file to load, and fails before it runs.
    transform = BashOperator(task_id="transform", bash_command="sh run_sql.sh ", cwd=ETL)
    dim_customer = BashOperator(task_id="dim_customer",
                                bash_command=f"{PSQL} -f load/dim_customer.sql", cwd=ETL)
    dim_book = BashOperator(task_id="dim_book",
                            bash_command=f"{PSQL} -f load/dim_book.sql", cwd=ETL)
    fact_sales = BashOperator(task_id="fact_sales",
                              bash_command=f"{PSQL} -v day={day} -f load/fact_sales.sql",
                              cwd=ETL)

    extract >> transform >> [dim_customer, dim_book]
    [day, dim_customer] >> fact_sales


shop_nightly()
