---
title: Stop or delete, and a time limit
version: 1
---

When Compute Engine takes a Spot machine back, it has to do something with it, and you choose what.
**A preempted Spot machine is either stopped, keeping its disks and its name, or deleted, taking its
boot disk with it.** The choice decides what a preemption leaves behind and what it goes on costing.

## The two actions

```
ana@laptop:~/gcp$ gcloud compute instances create --help | sed -n '/^     --instance-termination-action/,/^     --internal-ipv6-address/p' | head -n -2
     --instance-termination-action=INSTANCE_TERMINATION_ACTION
        Specifies the termination action that will be taken upon VM preemption
        (--provisioning-model=SPOT) or automatic instance termination
        (--max-run-duration or --termination-time).

        INSTANCE_TERMINATION_ACTION must be one of:

         DELETE
            Permanently delete the VM.
         STOP
            Default only for Spot VMs. Stop the VM without preserving memory.
            The VM can be restarted later.
```

| action | what is left | what it costs afterwards |
|---|---|---|
| `STOP` | the machine, stopped, with its persistent disks | the disks, until somebody starts or deletes it |
| `DELETE` | nothing but disks marked to outlive it | nothing for the machine; a data disk still costs |

**`STOP` is right for a single machine you will start again**, when capacity returns, with its disk
as it was. **`DELETE` is right inside a managed group**, which creates a fresh machine from the
template anyway and has no use for a stopped corpse; section 04 comes back to that. A local SSD, from
lesson 3, is lost either way: the machine has left its host.

## Writing it

For a batch machine that resizes the shop's photos, in a folder `spot`:

```hcl
# spot/main.tf
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "8.9.0"
    }
  }
}

provider "google" {
  project = "planner-dev"
  region  = "southamerica-east1"
}

resource "google_compute_instance" "photos_batch" {
  name         = "photos-batch-1"
  machine_type = "e2-standard-2"
  zone         = "southamerica-east1-a"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }

  network_interface {
    network = "default"
  }

  scheduling {
    provisioning_model          = "SPOT"
    preemptible                 = true
    automatic_restart           = false
    instance_termination_action = "STOP"

    max_run_duration {
      seconds = 14400
    }
  }
}
```

```
ana@laptop:~/gcp/spot$ terraform plan -no-color | grep -E 'provisioning_model|preemptible|automatic_restart|instance_termination_action|seconds|^Plan'
          + automatic_restart           = false
          + instance_termination_action = "STOP"
          + preemptible                 = true
          + provisioning_model          = "SPOT"
              + seconds = 14400
Plan: 1 to add, 0 to change, 0 to destroy.
```

Three of those lines are not choices. **A Spot machine must have `preemptible = true` and
`automatic_restart = false`**: Google's API refuses the other values, because a machine it may take
back cannot also be one it promises to restart. The plan does not know that; set `automatic_restart =
true` and it plans just as cleanly, and the refusal comes at creation, as every rule in lessons 1
to 5 that belonged to Compute Engine did.

## A time limit of your own

`max_run_duration` is the opposite of a preemption: **a limit you set, after which Compute Engine
applies the termination action itself.** 14,400 seconds is four hours. It exists for the machine that
should never run long, a batch job that ought to finish in an hour, so that a job stuck in a loop stops
costing money after four rather than running until somebody notices. It works on standard machines
too, not only Spot ones. gcloud's help adds the detail that matters, which is when the clock starts:

```
ana@laptop:~/gcp$ gcloud compute instances create --help | sed -n '/^     --max-run-duration/,/^     --metadata=/p' | head -n -2
     --max-run-duration=MAX_RUN_DURATION
        Limits how long this VM instance can run, specified as a duration
        relative to the last time when the VM began running. Format the
        duration, MAX_RUN_DURATION, as the number of days, hours, minutes, and
        seconds followed by d, h, m, and s respectively. For example, specify
        30m for a duration of 30 minutes or specify 1d2h3m4s for a duration of
        1 day, 2 hours, 3 minutes, and 4 seconds. Alternatively, to specify a
        timestamp, use --termination-time instead.

        If neither --max-run-duration nor --termination-time is specified
        (default), the VM instance runs until prompted by a user action or
        system event. If either is specified, the VM instance is scheduled to
        be automatically terminated at the VM's termination timestamp
        (terminationTimestamp) using the action specified by
        --instance-termination-action.

        Note: The terminationTimestamp is removed whenever the VM is stopped or
        suspended and redefined whenever the VM is rerun. For
        --max-run-duration specifically, the terminationTimestamp is the sum of
        MAX_RUN_DURATION and the time when the VM last entered the RUNNING
        state, which changes whenever the VM is rerun.
```
