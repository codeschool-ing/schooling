---
title: Change sets, and the word Replacement
version: 1
---

Updating a stack directly, with `update-stack`, applies the change as soon as it is computed. **A
change set computes it and stops**: it lists what would happen to each resource and waits for
somebody to execute it or throw it away. It is `terraform plan` for CloudFormation, kept in AWS, and
for anything in production it is the only way to update a stack.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"A flow of four boxes: the template shop.yaml becomes a change set, computed and waiting; a person reviews it; executing it changes the stack. Below, what a change set lists per resource, in three columns: Action, LogicalResourceId and Replacement. Two example rows: Modify WebLogs False, where the retention changes in place; and Modify Uploads True, where a new bucket name means a new bucket and the old one deleted.\"><defs><marker id=\"cs-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"30\" width=\"130\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"85.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">template</text><text x=\"85.0\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">shop.yaml</text><rect x=\"205\" y=\"30\" width=\"150\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"280.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">change set</text><text x=\"280.0\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">computed, waiting</text><rect x=\"410\" y=\"30\" width=\"130\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"475.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">review</text><text x=\"475.0\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a person reads it</text><rect x=\"590\" y=\"30\" width=\"110\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"645.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">execute</text><text x=\"645.0\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the stack changes</text><path d=\"M152 58 L203 58\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#cs-ah)\"></path><path d=\"M357 58 L408 58\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#cs-ah)\"></path><path d=\"M542 58 L588 58\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#cs-ah)\"></path><rect x=\"20\" y=\"120\" width=\"680\" height=\"130\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"36\" y=\"138\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">what a change set lists, per resource</text><text x=\"60\" y=\"162\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">Action</text><text x=\"220\" y=\"162\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">LogicalResourceId</text><text x=\"420\" y=\"162\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">Replacement</text><text x=\"60\" y=\"188\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Modify</text><text x=\"220\" y=\"188\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">WebLogs</text><text x=\"420\" y=\"188\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">False</text><text x=\"490\" y=\"188\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">retention changes in place</text><text x=\"60\" y=\"218\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Modify</text><text x=\"220\" y=\"218\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Uploads</text><text x=\"420\" y=\"218\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\" font-weight=\"600\">True</text><text x=\"490\" y=\"218\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">new name: a new bucket, the old one deleted</text></svg>", "caption": "The two example rows follow AWS's documentation; moto computes no change set for an existing stack."}
```

## The three columns that matter

For each resource a change set says:

| field | values | what to look for |
|---|---|---|
| `Action` | `Add`, `Modify`, `Remove`, `Import` | a `Remove` nobody intended |
| `Replacement` | `True`, `False`, `Conditional` | **`True`**: the resource is deleted and created anew |
| `Scope` and `Details` | which properties changed | the property that caused a replacement |

`Replacement: True` is the line to stop at. Some properties can change in place, such as a log
group's retention or a topic's display name. Others cannot, and changing them makes CloudFormation
create a new resource and delete the old one: **a bucket's name, a database's identifier, a queue's
name**. For a bucket, the old one is deleted with its contents unless `UpdateReplacePolicy` says
`Retain`, which is why this lesson added it. `Conditional` means the answer depends on a value
CloudFormation will only know during the update; read it as `True`.

## Against moto

The shop raises the log retention to 30 days. The only change is a parameter, so the change set
should say `Modify`, with no replacement, for `WebLogs` alone:

```
ana@laptop:~/aws/cfn$ aws cloudformation create-change-set --stack-name shop-base --change-set-name retention-30 --template-body file://shop.yaml --parameters ParameterKey=Retention,ParameterValue=30 --query Id --output text
arn:aws:cloudformation:sa-east-1:123456789012:changeSet/retention-30/4ae1b614-db59-4089-b7f2-a2b4aee5a64a
ana@laptop:~/aws/cfn$ aws cloudformation wait change-set-create-complete --stack-name shop-base --change-set-name retention-30
ana@laptop:~/aws/cfn$ aws cloudformation describe-change-set --stack-name shop-base --change-set-name retention-30 --query 'Changes[].ResourceChange.[Action,LogicalResourceId,Replacement]' --output text
Add	WebLogs	None
Add	Uploads	None
Add	Alerts	None
```

**moto answers `Add` for all three resources**, which a change set on an existing stack never says
for resources that already exist; it computes every change set as if the stack were empty, and
reports no replacement at all. On AWS, that change set would have one line:
`Modify WebLogs False`. This is the part of the lesson the lab cannot show, so it is taught from
AWS's documentation, and the habit is the same either way: **read the change set before executing
it, and never execute one that has a `Replacement: True` you cannot explain**.

## In a pipeline

A pipeline does the same thing in two actions: one creates the change set, a manual approval shows
it to a person, and a second action executes it. CodePipeline's CloudFormation action has both modes,
`CHANGE_SET_REPLACE` and `CHANGE_SET_EXECUTE`, so the approval stage of lesson 1 sits between them.
