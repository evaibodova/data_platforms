import json
import os
import subprocess
from pathlib import Path

from prefect import flow, task
from prefect.cache_policies import NO_CACHE


PROJECT_DIR = Path(__file__).resolve().parents[1]


def run_script(name):
    subprocess.run(
        ["bash", str(PROJECT_DIR / "scripts" / name)],
        cwd=PROJECT_DIR,
        check=True
    )


@task(name="check-hdfs-input", cache_policy=NO_CACHE)
def check_input():
    subprocess.run(
        [
            "bash", "-c",
            '''
            set -euo pipefail
            source "$1"
            as_hadoop "$HADOOP_HOME/bin/hdfs" dfs -test -d "$SPARK_INPUT"
            as_hadoop "$HADOOP_HOME/bin/hdfs" dfs -ls -R "$SPARK_INPUT"
            ''',
            "prefect-hdfs-check",
            str(PROJECT_DIR / "scripts" / "variables.sh")
        ],
        cwd=PROJECT_DIR,
        check=True
    )


@task(name="process-data-with-spark", cache_policy=NO_CACHE)
def process_data():
    run_script("23_run_spark.sh")


@task(name="check-hive-table", cache_policy=NO_CACHE)
def check_result():
    run_script("24_check_spark.sh")


@flow(name="hw5-colours", log_prints=True)
def colours_flow():
    check_input()
    process_data()
    check_result()


if __name__ == "__main__":
    run_file = Path(os.environ["PREFECT_RUN_FILE"])
    state = colours_flow(return_state=True)

    result = {
        "flow_run_id": str(state.state_details.flow_run_id),
        "state": state.type.value,
        "state_name": state.name
    }

    run_file.parent.mkdir(parents=True, exist_ok=True)
    run_file.write_text(
        json.dumps(result, ensure_ascii=False, indent=2),
        encoding="utf-8"
    )

    if not state.is_completed():
        raise SystemExit(1)
