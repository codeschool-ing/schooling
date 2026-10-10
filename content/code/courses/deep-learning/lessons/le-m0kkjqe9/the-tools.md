---
title: The tools, and what they add to a JSON file
version: 1
---

`track.py` is about forty lines and does the essential part: every run leaves a record that says
what produced it. **The tracking tools people use at work do the same thing at the core**, and sell
what grows around it. None of them was installed or run for this course; what follows is what each
one is, and the shape of its code.

## What a file stops being enough for

`runs.jsonl` is enough for one person, one machine and a few dozen runs. It starts to hurt when:

- **there are curves, not just final numbers.** A run that logs the loss of every epoch is a series,
  and comparing twenty series needs a plot, not `tail`.
- **several people or machines run experiments.** A file on one VM is not where a colleague looks,
  and two machines appending to copies of it end up with two histories.
- **a run produces files.** Saved weights, a confusion matrix, a sample of predictions: the record
  should point at them, and they have to be kept somewhere.
- **the runs number in the hundreds**, from a search over settings, and the question becomes
  filtering and sorting them.

## MLflow

Open source, run on your own machine or a server of your team's. A run is opened, given its
parameters, and fed metrics; the records go to a local directory or a tracking server, and a web
page lists and plots them. The calls map almost one to one onto `track.record`:

```python
import mlflow

with mlflow.start_run():
    mlflow.log_params({**config, "seed": seed})
    for epoch, train_loss, val_loss, val_acc in history:
        mlflow.log_metric("val_acc", val_acc, step=epoch)
```

Inside a git repository, MLflow notes the commit of the code that started the run, the same idea as
`code_version`, done for you.

## Weights & Biases

A hosted service, free for individuals within limits, paid for teams. The same shape: `wandb.init`
opens a run with its configuration, `log` sends metrics, and the service keeps the runs, draws the
curves, and records the machine and the libraries. The runs live on the company's servers, which is
the convenience and also the thing to check before sending anything confidential.

```python
import wandb

run = wandb.init(project="digits", config={**config, "seed": seed})
for epoch, train_loss, val_loss, val_acc in history:
    run.log({"val_acc": val_acc}, step=epoch)
run.finish()
```

## TensorBoard

Older, and narrower: it draws curves from event files a program writes, and was born for watching a
single training run live. PyTorch ships the writer, `torch.utils.tensorboard.SummaryWriter`, but not
the package it writes for, which this course never installed:

```
PENDING tensorboard
```

It records metrics and leaves the configuration, the seed and the code version to you, which makes
it a viewer more than a tracker.

## Which, then

For this course, the file. **Every one of these tools records what `track.py` records, and none of
them decides anything for you**: the five seeds per configuration, the commit before the run, the
choice on validation and the single look at test are habits, and a dashboard displays them well or
badly. Pick a tool when one of the four pains above actually arrives, and keep the habits when it
does.
