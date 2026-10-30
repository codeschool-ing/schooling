---
title: Workers, Streaming Engine, Prime and templates on Dataflow
version: 1
---

**Nothing in this section was run.** There is no emulator for Dataflow and no local stand-in for
what it adds, which is machines: starting them, sizing them, moving work between them and taking
them away. What follows is taught from Google's documentation, the Dataflow pages at
`cloud.google.com/dataflow/docs`, and the commands are the ones you would type with a real project.
None of them has output in this lesson, because none of them was given anywhere to go. The
`gcloud` flags were checked against the help of the lab's own Google Cloud CLI 591.0.0, which
answers `--help` with no network and no account.

## Sending the pipeline to Dataflow

The program does not change. The runner does, and the runner needs a project, a region and a
bucket for its files:

```sh
pip install -q 'apache-beam[gcp]==2.76.0'
python3 orders_beam.py --subscription order-events-beam --topic order-totals --streaming \
  --runner=DataflowRunner --project=planner-dev --region=southamerica-east1 \
  --temp_location=gs://quitanda-dataflow-prod/tmp/ --job_name=order-totals \
  --enable_streaming_engine --max_num_workers=3
```

**The `gcp` extra is the first line for a reason**: the DataflowRunner is a client of the Dataflow
API, and its libraries are not in the plain package. On that command, Beam builds the graph on your laptop exactly as it did for the DirectRunner and
**stages** it: it uploads the program, its description and Beam's own packages to
`--temp_location`. Then it asks Dataflow to create a job in `southamerica-east1`. From there the laptop is not needed: closing it does not stop the job. The
workers run as a service account, by default the project's Compute Engine one, which needs the
`roles/dataflow.worker` role and read access to the subscription. A pipeline whose steps import
libraries beyond Beam names them in `--requirements_file`, so that each worker installs them when it
starts.

## What Dataflow does with the graph

**It fuses steps first.** `Parse`, `Placed` and `Key` each look at one element at a time, so
Dataflow runs them as one stage, passing each element from one function to the next in memory on the
same worker, with no copy in between. A stage ends where elements must change machines, which in
this pipeline is `Add`, the combine. That boundary is the **shuffle**, and how it is done is the
main difference between Dataflow's two modes:

| | batch | streaming |
|---|---|---|
| the shuffle | **Dataflow Shuffle**, done by the service and not on the workers' disks | **Streaming Engine**, which also keeps the windows' state outside the workers |
| default worker | 1 vCPU, 3.75 GB, 25 GB of disk with Dataflow Shuffle | 4 vCPU, 15 GB, 30 GB of disk with Streaming Engine, 400 GB without |
| how it ends | when the input is read and every step done | never by itself: **drain** or **cancel** |
| autoscaling on | work remaining | backlog in the subscription and how busy the workers are |

The defaults are the ones the pricing page prints. **Streaming Engine is what lets a streaming job run on fewer, smaller workers.** With windows and
their state kept by the service, a worker holds little and can be replaced without losing anything,
and the job can scale down without moving state from one disk to another. Without it, each worker carries its share of the state on its own
persistent disk, which is why the default disk is 400 GB.

**Autoscaling is horizontal**: Dataflow adds and removes workers between one and
`--max_num_workers`. It never goes above that number, which is the first thing to set on any job
you pay for. **Dataflow Prime** adds vertical autoscaling, changing a worker's memory when the job
runs short of it instead of failing, and bills differently, in Data Compute Units, the next
section's subject. It is chosen per job with `--dataflow_service_options=enable_prime`.

## Stopping a stream: drain or cancel

**Cancel stops at once and throws away what is in flight**: windows not yet closed are lost,
together with every message already acknowledged into them. **Drain stops reading**, lets every open
window close as if its time had come, emits what they hold, and then ends. For this pipeline, a
cancel at 19:00:40 loses the 40 seconds of totals already counted in that minute; a drain publishes
them, early. The commands take the job's id, which `gcloud dataflow jobs list` shows:

```sh
gcloud dataflow jobs list --region=southamerica-east1 --status=active
gcloud dataflow jobs drain JOB_ID --region=southamerica-east1
gcloud dataflow jobs cancel JOB_ID --region=southamerica-east1
```

A third option keeps the job running: **update** replaces the code of a streaming job in place,
keeping its state and its subscription, by running the program again with `--update` and the same
`--job_name`. Dataflow checks that the new graph is compatible with the old, and refuses the update
if, say, a step it holds state for has been renamed. That is one more reason the steps in
`orders_beam.py` have names: `'Add' >> beam.CombinePerKey(add)` keeps the name `Add` however the
code around it changes.

## Templates

Running a pipeline from a laptop is fine for its author and wrong for a schedule. A **template**
stages the pipeline once so that it can be launched later with parameters, by somebody or something
that does not have the code, such as Cloud Composer in lesson 24 or a Cloud Scheduler job. There are
two kinds:

- **Classic templates** stage the graph itself in Cloud Storage. Parameters can only change what the
  graph was built to take as a runtime value, and the graph's shape is fixed when it is staged.
- **Flex Templates** package the program as a container image in Artifact Registry, with a small
  metadata file in Cloud Storage. Each launch starts the container, which builds the graph then, so
  parameters can change the graph itself. Google recommends them for new pipelines.

```sh
gcloud dataflow flex-template build gs://quitanda-dataflow-prod/templates/order-totals.json \
  --image-gcr-path=southamerica-east1-docker.pkg.dev/planner-dev/dataflow/order-totals:1 \
  --sdk-language=PYTHON --flex-template-base-image=PYTHON3 \
  --py-path=. --env=FLEX_TEMPLATE_PYTHON_PY_FILE=orders_beam.py
gcloud dataflow flex-template run order-totals-nightly --region=southamerica-east1 \
  --template-file-gcs-location=gs://quitanda-dataflow-prod/templates/order-totals.json \
  --parameters=input=gs://quitanda-raw-prod/raw/events/dt=2026-10-15/events.jsonl,output=gs://quitanda-curated-prod/order-totals/dt=2026-10-15/
```

Google also publishes ready-made templates, such as Pub/Sub to BigQuery and Cloud Storage text to
BigQuery, which cover the common copies without any code of your own. **A ready-made template is
the Dataflow equivalent of a managed connector**: worth checking for before writing a pipeline whose
whole job is to move records from one service to another unchanged.
