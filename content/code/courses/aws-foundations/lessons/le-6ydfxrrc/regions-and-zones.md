---
title: Regions, zones, and the two names a zone has
version: 1
---

**A region is a place on the map; an Availability Zone is a separate failure inside it.** The
`cloud` course drew that picture for every provider. This section is the AWS spelling of it, and the
two details AWS adds that catch people out.

The common wrong picture is that an Availability Zone is a datacentre. **An AZ is one or more
datacentres with their own power, cooling and network**, far enough from the other zones of its
region that a flood or a fire takes one of them and not the next, and close enough that a round trip
between them stays around a millisecond or two. A region is a group of these, at least three in
every region AWS builds now. The point of the arrangement is that **you choose the zones, AWS
chooses the buildings**, and an application spread across two or three zones survives the loss of
one.

## Asking moto, the way you would ask AWS

With moto running in the first terminal and `env.sh` read into the second, the command line asks
for regions and zones exactly as it would ask AWS:

```
ana@laptop:~/aws$ aws ec2 describe-regions --query "length(Regions)"
38
ana@laptop:~/aws$ aws ec2 describe-regions --query "Regions[?starts_with(RegionName, \`sa-\`) || starts_with(RegionName, \`us-east\`)].[RegionName,Endpoint]" --output text
sa-east-1	ec2.sa-east-1.amazonaws.com
us-east-1	ec2.us-east-1.amazonaws.com
us-east-2	ec2.us-east-2.amazonaws.com
ana@laptop:~/aws$ aws ec2 describe-availability-zones --query "AvailabilityZones[].[ZoneName,ZoneId,ZoneType,State]" --output text
sa-east-1a	sae1-az1	availability-zone	available
sa-east-1b	sae1-az2	availability-zone	available
sa-east-1c	sae1-az3	availability-zone	available
ana@laptop:~/aws$ aws ec2 describe-availability-zones --region us-east-1 --query "AvailabilityZones[].[ZoneName,ZoneId]" --output text
us-east-1a	use1-az6
us-east-1b	use1-az1
us-east-1c	use1-az2
us-east-1d	use1-az4
us-east-1e	use1-az3
us-east-1f	use1-az5
```

The `--query` option is a filter the command line applies to the answer before printing it, written
in a small language called JMESPath. `length(Regions)` counts; the second command keeps only the
regions whose name starts with `sa-` or `us-east`; `--output text` prints one line per item instead
of JSON. Lesson 25 says more about both. **The count is moto's**: the list it carries is close to
AWS's own and is not guaranteed to be the same on any given day, so trust AWS's documentation, not a
number in a course, when the exact list matters.

`sa-east-1` has three zones, and each one carries **two names**.

## A zone name is yours; a zone id is everybody's

`sa-east-1a` is a **zone name**, and AWS may map it to a different physical zone in your account
than in somebody else's. It did that on purpose for its older regions, so that everybody who picked
the first zone in the list did not land in the same building. **`sae1-az1` is a zone id**, and it
names the same physical zone in every account.

That matters the moment two accounts have to meet. Lesson 2 splits the platform into several
accounts, and lesson 19 connects services across them; if the shop's account puts its database in
`sa-east-1a` and the payments account puts its client in `sa-east-1a` too, the two may still be in
different buildings, paying for every byte between them as the next section shows. **Coordinate by
zone id**, and translate to a zone name inside each account.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" data-fig=\"l01-zone-names\" aria-label=\"Zone names against zone ids in us-east-1. In the middle, three physical zones, labelled with their ids use1-az1, use1-az2 and use1-az6. On the left, the account from the transcript: us-east-1a points at use1-az6, us-east-1b at use1-az1 and us-east-1c at use1-az2. On the right, another account, drawn as an illustration: its us-east-1a points at use1-az2, b at use1-az6 and c at use1-az1. The same name lands in different zones; the id does not change.\"><defs><marker id=\"l01-zone-names-af-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l01-zone-names-af-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"110.0\" y=\"26.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper-dim)\">this account</text><text x=\"360.0\" y=\"26.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper-dim)\">the physical zones</text><text x=\"610.0\" y=\"26.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper-dim)\">another account</text><text x=\"610.0\" y=\"44.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">(an illustration)</text><rect x=\"290.0\" y=\"66.0\" width=\"140.0\" height=\"48.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">use1-az1</text><rect x=\"290.0\" y=\"136.0\" width=\"140.0\" height=\"48.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">use1-az2</text><rect x=\"290.0\" y=\"206.0\" width=\"140.0\" height=\"48.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"230.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">use1-az6</text><rect x=\"40.0\" y=\"72.0\" width=\"140.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"110.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">us-east-1a</text><path d=\"M182.0 90.0 L286.0 230.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l01-zone-names-af-ah-paper-dim)\"></path><rect x=\"540.0\" y=\"72.0\" width=\"140.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"610.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">us-east-1a</text><path d=\"M538.0 90.0 L434.0 160.0\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l01-zone-names-af-ah-amber)\"></path><rect x=\"40.0\" y=\"142.0\" width=\"140.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"110.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">us-east-1b</text><path d=\"M182.0 160.0 L286.0 90.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l01-zone-names-af-ah-paper-dim)\"></path><rect x=\"540.0\" y=\"142.0\" width=\"140.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"610.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">us-east-1b</text><path d=\"M538.0 160.0 L434.0 230.0\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l01-zone-names-af-ah-amber)\"></path><rect x=\"40.0\" y=\"212.0\" width=\"140.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"110.0\" y=\"230.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">us-east-1c</text><path d=\"M182.0 230.0 L286.0 160.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l01-zone-names-af-ah-paper-dim)\"></path><rect x=\"540.0\" y=\"212.0\" width=\"140.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"610.0\" y=\"230.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">us-east-1c</text><path d=\"M538.0 230.0 L434.0 90.0\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l01-zone-names-af-ah-amber)\"></path><text x=\"360.0\" y=\"276.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">coordinate two accounts by the id in the middle</text></svg>", "caption": "A zone name is a label your account gives a zone. A zone id is the zone."}
```

The transcript shows both behaviours. In `sa-east-1` moto maps the names to the ids in order; in
`us-east-1` it does what AWS does in an older region, and **`us-east-1a` is `use1-az6`**. Another
account may get another mapping, and `describe-availability-zones` is how you find out: it is the one
command that prints both names side by side.

## Local Zones, and the other edges of a region

**A Local Zone extends a region into a city where AWS has no region**: a small set of services,
usually compute, block storage and a slice of the network, placed close to people who need a few
milliseconds less than the region can give them. Video editing, games and trading are the usual
reasons. A Local Zone belongs to a parent region, has a name built from it (`us-west-2-lax-1a` is
Los Angeles, attached to Oregon), and has to be opted into before it appears.

moto carries none, and this is what it answers when asked for every zone of `us-west-2`, a region
that has several Local Zones in AWS, the Los Angeles one among them:

```
ana@laptop:~/aws$ aws ec2 describe-availability-zones --region us-west-2 --all-availability-zones --query "AvailabilityZones[].[ZoneName,ZoneType]" --output text
us-west-2a	availability-zone
us-west-2b	availability-zone
us-west-2c	availability-zone
us-west-2d	availability-zone
```

**Against AWS the same command also lists the Local Zones, with `local-zone` in the second column
and `opted-in` or `not-opted-in` in `OptInStatus`. That part was not run here**, since it needs an
account; the shape of the answer is AWS's documented one.

Two more edges, which this course names and does not use: **Wavelength Zones** put AWS equipment
inside a mobile operator's network, and **Outposts** are AWS racks installed in your own datacentre.
Both answer to a parent region, as a Local Zone does.

## Which region, for this course and for you

Every lesson works in **`sa-east-1`**, the region `env.sh` names. For a Brazilian business it is
usually the obvious one: the data stays in the country, which the LGPD does not demand but customers
and contracts often do, and a student in São Paulo is a few milliseconds from it instead of a hundred
from Virginia. It is also one of the dearest regions AWS has, which the next section measures. The
`cloud` course, lesson 9, has the full argument for choosing a region; the line that matters here is
that **the choice decides the price of everything that crosses it**.
