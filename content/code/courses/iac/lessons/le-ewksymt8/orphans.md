---
title: The resource nobody owns
version: 2
---

Every review in this course looks at a configuration: a diff, a plan, a price. **A resource that is
in no configuration is in no review**, and it costs exactly what an owned one costs. That is an
orphan: something running in the account that no state file records and no tag assigns to anybody.
It is never the big line on the bill. It is the small one that nobody recognises, every month.

They come from a few places, and each has been met before:

- **made by hand**, for a test or an urgent fix, by somebody who meant to delete it;
- **released by Terraform**: a `removed` block with `destroy = false` (lesson 6), a `terraform state
  rm`, or a state file that was lost (lesson 7). The resource keeps running; nothing tracks it;
- **an environment nobody destroyed**, which is common enough to get the next section.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 320\" role=\"img\" aria-label=\"One large box, the AWS account, holds two overlapping boxes: what a state file records and what carries an Owner tag. In the overlap are the web servers and the NAT gateway. Only in a state are the web servers' disks, created before the tags. Only tagged is pr-17's environment once its state is lost. Outside both, at the bottom, are Bruno's volume and address: the orphans.\"><rect x=\"20\" y=\"20\" width=\"680\" height=\"285\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"40.0\" y=\"40.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">the AWS account</text><rect x=\"50\" y=\"60\" width=\"340\" height=\"160\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"290\" y=\"80\" width=\"380\" height=\"160\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"62.0\" y=\"78.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">in a state file</text><text x=\"658.0\" y=\"98.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">has an Owner tag</text><text x=\"340.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">web servers</text><text x=\"340.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">NAT gateway</text><text x=\"170.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the web servers' disks</text><text x=\"170.0\" y=\"168.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">(tags came later)</text><text x=\"510.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">pr-17, state lost</text><rect x=\"40\" y=\"245\" width=\"240\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"160.0\" y=\"261.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">orphans</text><text x=\"160.0\" y=\"277.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Bruno's volume and address</text><text x=\"460.0\" y=\"270.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">in no state, with no tag: in no review</text></svg>", "caption": "What a review can see is what is in a configuration. The orphan is the corner outside both boxes."}
```

## A search that cannot see what it is looking for

A colleague, Bruno, needed space for a one-off export last week. From his own machine he created a
100 GB volume and reserved a public address, and then the export was done. Neither went through
Terraform, so neither has a tag. These were Bruno's two commands; run them to have the same two in
your moto:

```sh
aws ec2 create-volume --size 100 --availability-zone sa-east-1a --volume-type gp3
aws ec2 allocate-address --domain vpc
```

The obvious tool is the one AWS made for finding resources by tag, the Resource Groups Tagging API.
Ask it for volumes:

```
ana@laptop:~/shop$ aws resourcegroupstaggingapi get-resources --resource-type-filters ec2:volume --query "ResourceTagMappingList[].ResourceARN"
[]
```

**Nothing, and that is the design.** The tagging API answers from tags: AWS documents that it returns
resources that are tagged or were tagged once, so a resource that never had a tag is not in its
world. A search by tag finds everything except the thing you are hunting. The question has to go to
each service instead, asking for what has no tags:

```
ana@laptop:~/shop$ aws ec2 describe-volumes --output json | jq -r '.Volumes[] | select((.Tags // []) | length == 0) | [.VolumeId, .State, .Size, .Size * 0.1520] | @tsv'
vol-ec23023a06e407706	in-use	20	3.04
vol-30a55504c45f96cfd	in-use	20	3.04
vol-f86f3ff8e4622769a	available	100	15.2
```

Three volumes, and only one is an orphan. The two `in-use` ones of 20 GB are the web servers' disks
from the previous section: untagged because the defaults arrived after them, but attached to
instances that Terraform does track. The third is `available`, which means attached to nothing.
**An available volume is a disk that no machine can read, billed by the gigabyte**: the last column
is its size times the 0.1520 per GB-month on the sheet, 15.2 USD a month.

Addresses are found the same way, by asking for the ones attached to nothing:

```
ana@laptop:~/shop$ aws ec2 describe-addresses --output json | jq -r '.Addresses[] | select((.AssociationId // "") == "") | [.AllocationId, .PublicIp, ((.Tags // []) | length)] | @tsv'
eipalloc-f0930f8c1f0ff56f9	127.28.101.243	0
```

That is Bruno's, with no tags, and it costs the same 3.65 a month as `aws_eip.nat` in the priced
plan, for an address nobody is using.

## What to do with one

Find the owner before deleting anything. CloudTrail, which records AWS API calls, shows who called
`CreateVolume`, and the answer is usually a person who knows whether the data matters. Then one of two
things happens. **Either it is adopted**, written into a configuration and imported (lesson 8), and
from then on it is tagged, reviewed and priced like everything else. **Or it is deleted**, after a
snapshot if it is a disk somebody might miss.

The search above is two commands. Run on a schedule, with its output sent to whoever owns the account,
it turns orphans from something found on an invoice into a short weekly list.
