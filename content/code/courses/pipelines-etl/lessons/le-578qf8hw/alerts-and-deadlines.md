---
title: Telling somebody, and when
version: 1
---

A retry absorbs what passes. What does not pass has to reach a person, and there are two different
questions a person wants answered: **has something failed**, and **is something late**. They are
not the same question, and Airflow answers them with two different mechanisms.

## A failure callback

`on_failure_callback` is a function Airflow calls when a task instance ends in `failed` — not when
a try fails, but when **the task has failed for good**: its retries are spent, or it raised
`AirflowFailException`, or it timed out with no retries left. It runs in the same process as the
task, after the task, and receives its context. Ana's `failed` writes one line with what a person
needs to start: the DAG and task, the run, the try it got to, and the exception.

Put in `default_args`, it applies to every task of the DAG. That is usually right: a pipeline in
which one task can fail without anybody hearing about it is the silent failure this course has
been avoiding since lesson 1.

There is also `on_retry_callback`, called on every failed try that will be retried, and
`on_success_callback`. Ana uses neither: a retry is not news, and a success is what is supposed to
happen. **An alert channel that speaks when nothing is wrong teaches people to stop reading it.**

## A deadline

A failure callback cannot see a run that is slow. A night when the API answers every page in
twenty seconds instead of one, or a task stuck behind another DAG's lock, never fails — it only
finishes at nine in the morning, after the report that needed it has gone out with yesterday's
prices. **The question there is not whether something failed but whether the work is done by when
it is needed.**

Airflow 2 called this an SLA, and Airflow 3 removed it. What replaces it is a **deadline**: a
reference moment, an interval after it, and a callback to run if the run has not finished by then.
Ana's is `DeadlineReference.DAGRUN_QUEUED_AT` plus two minutes — the lab's scale; in production,
something like *the logical date plus three hours*, the time the morning report is read.

The deadline belongs to the **run** and is watched by the scheduler, not by a task, so it fires
even while every task is waiting or retrying. Its callback runs in the triggerer, which is why it
has to be `async`, and why `oncall.py` is in the plugins folder.

The next section is the night both of them were written for.
