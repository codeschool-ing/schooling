#!/bin/sh
# airflow dags test prints every line of every task's log. Keep the lines that
# say what ran, how it ended, and any error.
grep -oE "\[DAG TEST\] end task task_id=[a-z_]+|Running command: \[[^]]*\]|Command exited with return code [0-9]+|[A-Za-z0-9.]*(Error|NotFound): .*|DagRun Finished: dag_id=[a-z_]+, logical_date=[^,]+|state=[a-z]+, run_type=[a-z]+"
