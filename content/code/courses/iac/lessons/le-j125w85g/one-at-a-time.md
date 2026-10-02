---
title: One apply at a time
version: 1
---

Two merges close together start two pipeline runs, and both runs plan against the same state. The
state lock from lesson 7 does not help with this. **A lock stops two writes at the same instant; it
does nothing about two plans made before either was applied.** Here is run 2, for the `Owner` tag
commit, planning while run 1 still waited for its approval:

```
ana@laptop:~$ git clone -q git/shop.git ci/run-2
ana@laptop:~/ci/run-2$ git log --oneline -1
53a4007 shop: Owner tag on the VPC
ana@laptop:~/ci/run-2$ ./ci.sh plan 2>&1 | grep -E "# aws|Plan:"
  # aws_security_group.web will be created
  # aws_subnet.a will be created
  # aws_vpc.shop will be created
Plan: 3 to add, 0 to change, 0 to destroy.
```

Three to add. Run 2's plan is correct for the state it read, which was still empty, and its file
describes a whole second network. Run 1 was then approved and applied, as the last section showed,
and run 2's approval arrived after that:

```
+ terraform apply -input=false -lock-timeout=5m tfplan
╷
│ Error: Saved plan is stale
│ 
│ The given plan file can no longer be applied because the state was changed
│ by another operation after the plan was created.
╵
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"A timeline of two pipeline runs against one state. Run 1 plans while the state is empty. Run 2, for a later commit, also plans against the empty state, three to add. Run 1 applies, three added, and the state now holds the network. Run 2's saved plan is refused as stale. Run 2 plans again, one to change, and applies that.\"><text x=\"20.0\" y=\"70.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">run 1</text><text x=\"20.0\" y=\"150.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">run 2</text><text x=\"20.0\" y=\"236.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">state</text><rect x=\"100\" y=\"46\" width=\"110\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"155.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">plan</text><text x=\"155.0\" y=\"78.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">3 to add</text><rect x=\"330\" y=\"46\" width=\"110\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"385.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">apply</text><text x=\"385.0\" y=\"78.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">3 added</text><rect x=\"215\" y=\"126\" width=\"110\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"270.0\" y=\"142.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">plan</text><text x=\"270.0\" y=\"158.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">3 to add</text><rect x=\"450\" y=\"126\" width=\"120\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"510.0\" y=\"142.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">apply</text><text x=\"510.0\" y=\"158.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">refused: stale</text><rect x=\"590\" y=\"126\" width=\"120\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"650.0\" y=\"142.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">plan, apply</text><text x=\"650.0\" y=\"158.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1 to change</text><path d=\"M100 236 L385 236\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M385 236 L710 236\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M385 94 L385 226\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"240.0\" y=\"252.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">empty</text><text x=\"548.0\" y=\"252.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the network, written by run 1</text><text x=\"270.0\" y=\"196.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">planned against the empty state</text></svg>", "caption": "Two runs, one state. Run 2's plan was true when it was made and false by the time anybody applied it, and Terraform noticed."}
```

**The stale-plan refusal from lesson 9 is what stood between this pipeline and a duplicate VPC.**
Applied as it was, run 2's plan would have created a second `shop` network beside the first, which
is exactly the accident lesson 7 produced by losing a state. The pipeline does the honest thing
with the refusal and plans again:

```
ana@laptop:~/ci/run-2$ ./ci.sh plan 2>&1 | grep -E "# aws|Plan:"
  # aws_vpc.shop will be updated in-place
Plan: 0 to add, 1 to change, 0 to destroy.
ana@laptop:~/ci/run-2-apply$ ./ci.sh apply 2>&1 | tail -n 1
Apply complete! Resources: 0 added, 1 changed, 0 destroyed.
```

```
ana@laptop:~/ci/run-2-apply$ aws ec2 describe-vpcs --filters Name=tag:Name,Values=shop --query "Vpcs[].[VpcId,CidrBlock]" --output text
vpc-d23fdf50099101ff0	10.20.0.0/16
```

One change, one VPC. It ended well because Terraform checks the state's serial, but the run still
asked a reviewer to approve a plan that was wrong by the time they read it. Better to stop the
second run planning until the first has finished.

## Queuing the runs

Both CI services can do that. In the GitHub workflow, the `concurrency` block puts every run for
the same ref into one group, and **only one run of a group is in progress at a time**. A run that
starts while another is in progress waits, pending, and plans only once the first has applied, so
its plan is computed against the state it will really meet. Two details of it decide the settings:

`cancel-in-progress: false` matters because the alternative cancels a running job, and a job
cancelled halfway through `apply` is lesson 9's partial apply, made on purpose. And a group holds
at most one pending run: when a third arrives, GitHub cancels the waiting one and queues the newest.
On `main` that is acceptable, because the newest commit contains every change merged before it, so
its plan covers them all.

The price is that a run waiting for an approval holds up every run behind it: the queue is only as
fast as the people approving it.

In GitLab, `resource_group: production` on the `apply` job means only one job of that group runs
at a time, across every pipeline of the project. Only `apply` is in it in this file, so a plan can
still go stale while it waits, and the refusal above is what catches it.

## The last line, and tools that do all of this

Whatever the queue does, **the state lock is still the last line**: two applies that reach the
bucket in the same second cannot both write, and `-lock-timeout=5m` in `ci.sh` makes the second
wait for the first instead of failing. Lesson 7 showed both outcomes.

Some tools are built around exactly these problems. **Atlantis** is a server you run yourself: it
plans when a pull request opens, applies when someone comments `atlantis apply`, and locks each
directory to one pull request until it is merged, so applying happens before the merge rather than
after. **HCP Terraform**, HashiCorp's service, runs plans and applies itself and queues the runs of
each workspace one at a time. Neither is installed here, and neither changes the ideas: one place
applies, it applies a plan somebody read, and it applies one at a time.
