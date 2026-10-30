---
title: VPC peering, and what it does not pass on
version: 1
---

**VPC peering joins two separate networks so that their machines reach each other on internal addresses.**
The two can be in different projects and different organisations, which is the case Shared VPC cannot
cover: a partner's network, or the network of a company the planner bought. Each side keeps its own network,
its own firewall rules and its own administrators.

Three rules decide what a peering does:

- **Both sides have to create it.** A peering from the planner to the partner is inactive until the partner
  creates one back. Neither side can join itself to a network that did not agree.
- **No range on one side may overlap a range on the other.** Peering exchanges subnet routes, and two routes
  for the same addresses would be two answers to one question. Google refuses the peering when it is
  created.
- **Peering is not transitive.** If the planner peers with the partner and with an analytics network, the
  partner and analytics do not reach each other through the planner. Each pair that must talk needs its own
  peering.

What it does not exchange matters as much. **Firewall rules stay on each side**: the planner's rules filter
what arrives at the planner's machines, the partner's what arrives at theirs, and a peering opens nothing
until both have written rules that allow it. **Custom routes are not exchanged unless asked for**, which is the
`export_custom_routes` setting below.

## The arithmetic of who reaches whom

The three rules can be checked before anyone creates anything. Save the planner's networks and peerings as
`~/gcp/peering/peerings.json`. `acquired` is the network of a small company the planner has just bought,
which numbered its São Paulo subnet the way the planner did:

```sh
mkdir -p ~/gcp/peering && cd ~/gcp/peering
```

```json
{
  "networks": {
    "planner": ["10.10.0.0/16", "10.11.0.0/16"],
    "partner": ["10.128.0.0/9"],
    "analytics": ["10.30.0.0/16"],
    "acquired": ["10.10.0.0/20", "192.168.0.0/24"]
  },
  "peerings": [["planner", "partner"], ["planner", "analytics"]]
}
```

And the program, as `reach.py`:

```schooling-example
{"language": "python", "file": "reach.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"Says whether one network reaches another through VPC peering.\n\n    python3 reach.py FROM TO\n\nThe networks, their ranges and the peerings that exist are read from\npeerings.json. A pair that is not peered is also checked for whether a\npeering between them could be made at all.\n\"\"\"\nimport ipaddress\nimport json\nimport sys\n\n", "note": "How it is called: two network names. What it answers comes from the file, so the same program checks any estate."}, {"code": "data = json.load(open('peerings.json'))\nranges = {name: [ipaddress.ip_network(r) for r in rs] for name, rs in data['networks'].items()}\npeered = {frozenset(pair) for pair in data['peerings']}\n\n", "note": "Read the networks with their ranges, and the peerings as unordered pairs: a peering between the planner and the partner is the same peering read from either end."}, {"code": "a, b = sys.argv[1], sys.argv[2]\nif frozenset((a, b)) in peered:\n    print(f'{a} -> {b}: reachable, they are peered')\n    sys.exit(0)\n\n", "note": "A pair that is peered reaches each other, and that is the whole answer."}, {"code": "via = sorted(n for n in ranges if frozenset((a, n)) in peered and frozenset((n, b)) in peered)\nif via:\n    print(f'{a} -> {b}: not reachable; both peer with {\", \".join(via)}, and peering is not transitive')\nelse:\n    print(f'{a} -> {b}: not reachable, no peering')\n\n", "note": "Otherwise, find any network both of them peer with. That is the case people expect to work, so the program names it: reaching a common neighbour is not reaching each other."}, {"code": "clash = [(x, y) for x in ranges[a] for y in ranges[b] if x.overlaps(y)]\nfor x, y in clash:\n    print(f'  a peering would be refused: {x} overlaps {y}')\nif not clash:\n    print('  a peering could be made: no ranges overlap')\nsys.exit(1)\n", "note": "Whether a peering between the two could be made: every pair of ranges compared, and any overlap named, since Google would refuse the peering for it."}]}
```

The planner and the partner, then the partner and analytics:

```
ana@laptop:~/gcp/peering$ python3 reach.py planner partner
planner -> partner: reachable, they are peered
ana@laptop:~/gcp/peering$ python3 reach.py partner analytics
partner -> analytics: not reachable; both peer with planner, and peering is not transitive
  a peering could be made: no ranges overlap
```

**Both of them peer with the planner and still do not reach each other.** If they need to, they peer
directly; the program says that would work, since `10.128.0.0/9` and `10.30.0.0/16` do not overlap. And the
acquired company:

```
ana@laptop:~/gcp/peering$ python3 reach.py planner acquired
planner -> acquired: not reachable, no peering
  a peering would be refused: 10.10.0.0/16 overlaps 10.10.0.0/20
```

That one cannot be peered at all until somebody renumbers, and renumbering a network that has machines in it
is the expensive change lesson 15 said ranges are. A VPN would not help either: the same overlap breaks it
too, lesson 21.

## Writing one side

Save this as `peering.tf` in the same directory, after copying lesson 2's provider file there:

```sh
cp ~/gcp/hierarchy/provider.tf . && terraform init -input=false
```

```hcl
resource "google_compute_network_peering" "planner_to_partner" {
  name         = "planner-to-partner"
  network      = "projects/planner-network/global/networks/planner"
  peer_network = "projects/partner-prod/global/networks/partner"
}
```

```
ana@laptop:~/gcp/peering$ terraform plan -input=false -no-color | grep -E "^Plan|# google|export_custom|import_custom"
  # google_compute_network_peering.planner_to_partner will be created
      + export_custom_routes                = false
      + import_custom_routes                = false
Plan: 1 to add, 0 to change, 0 to destroy.
```

One side, planned. The partner writes the other in their own project, with the two names swapped. The
defaults came back **false** for exporting and importing custom routes: the partner learns the planner's
subnets and nothing else, so a route the planner has to its office does not quietly become a route from the
partner to the planner's office.
