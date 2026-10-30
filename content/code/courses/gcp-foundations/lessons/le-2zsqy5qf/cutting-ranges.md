---
title: Cutting the ranges
version: 1
---

**Ranges are the one decision in a network that is expensive to change**, because everything else is
attached to them: machines take addresses from them, firewall rules name them, and every network the planner
will ever join, lessons 18 and 21, must not overlap them. Choosing them is arithmetic, and arithmetic can be
done before anything exists.

Three rules of Google's frame it:

- **Google keeps four addresses of every subnet's primary range**: the first, which is the network itself;
  the second, the subnet's gateway; the second-to-last, kept for Google's future use; and the last, the
  broadcast address. A `/24` leaves 252 for machines, a `/29`, the smallest a subnet may be, leaves four.
- **A primary range can be expanded and never shrunk.** gcloud's help for `subnets expand-ip-range` says the
  new prefix length *must be smaller than the original*, that is a larger range, and the addresses next to
  the old range must be free for it to grow into. Leaving room beside each range is cheaper than guessing its
  size right.
- **No two subnets of a network may overlap**, and Google checks it when a subnet is created.

The provider checks none of the third rule. Add a staging subnet to `~/gcp/network/network.tf` whose range
falls inside São Paulo's:

```hcl
resource "google_compute_subnetwork" "staging" {
  project       = "planner-dev"
  name          = "planner-staging"
  network       = google_compute_network.planner.id
  region        = "southamerica-east1"
  ip_cidr_range = "10.10.8.0/21"
}
```

```
ana@laptop:~/gcp/network$ terraform plan -input=false -no-color | grep -E "^Plan:"
Plan: 4 to add, 0 to change, 0 to destroy.
```

**The plan is clean, and the apply would fail**: `10.10.8.0/21` is the top half of `10.10.0.0/20`, and Google
would refuse the staging subnet when asked to create it, after the network and the other subnets were
already made. That refusal was not produced here; it is the rule above, from Google's documentation. The way
to see it before an apply is to check the ranges on the laptop. Save this as `~/gcp/ranges.py`:

```schooling-example
{"language": "python", "file": "ranges.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"Checks a plan of subnet ranges before any of them is created.\n\n    python3 ranges.py NAME=CIDR [NAME=CIDR ...]\n\nPrints how many addresses each range leaves for machines, then every pair that overlaps, and exits 1 if\nany do. A range is also compared with 10.128.0.0/9, the block every\nauto mode network takes its subnets from.\n\"\"\"\nimport ipaddress\nimport sys\n\n", "note": "What the program checks, and how it is called: one `NAME=CIDR` argument per range, from the standard library's `ipaddress` alone."}, {"code": "AUTO = ipaddress.ip_network('10.128.0.0/9')\nRESERVED = 4  # network, gateway, second-to-last, broadcast\n\n", "note": "Two facts the program needs from Google: the block auto mode networks cut their subnets from, and the four addresses Google keeps in every subnet's primary range."}, {"code": "plan = []\nfor arg in sys.argv[1:]:\n    name, cidr = arg.split('=')\n    plan.append((name, ipaddress.ip_network(cidr)))\n\n", "note": "Read the plan. `ip_network` refuses a range written with host bits set, `10.10.0.1/20` for instance, which is the program's first check and costs nothing to write."}, {"code": "for name, net in plan:\n    note = '' if net.is_private else '  (not a private range)'\n    print(f'{name:18} {str(net):16} {net.num_addresses - RESERVED:>7} usable{note}')\n\n", "note": "One line per range: its name, the range, and how many addresses it leaves for machines once Google's four are taken. A range outside the private blocks is marked, because it may be somebody's on the internet."}, {"code": "clashes = [(a, b) for i, (a, x) in enumerate(plan) for b, y in plan[i + 1:] if x.overlaps(y)]\nclashes += [(name, 'any auto mode network') for name, net in plan if net.overlaps(AUTO)]\nfor a, b in clashes:\n    print(f'overlap: {a} and {b}')\nsys.exit(1 if clashes else 0)\n", "note": "Every pair of ranges that overlap, and every range that falls in the auto mode block. Exiting 1 when there is one means the program can stand in front of `terraform apply` in a pipeline and stop it."}]}
```

The planner's plan, three regions with a `/20` each and room between them:

```
ana@laptop:~/gcp$ python3 ranges.py sao-paulo=10.10.0.0/20 santiago=10.11.0.0/20 virginia=10.12.0.0/20; echo "exit $?"
sao-paulo          10.10.0.0/20        4092 usable
santiago           10.11.0.0/20        4092 usable
virginia           10.12.0.0/20        4092 usable
exit 0
```

Exit 0: no overlap, and each region has 4,092 addresses with the rest of its `/16` free to grow into. Now
the staging mistake, and a development network somebody made in auto mode, whose subnets all fall in
`10.128.0.0/9`; `10.158.0.0/20` stands for one of them:

```
ana@laptop:~/gcp$ python3 ranges.py sao-paulo=10.10.0.0/20 staging=10.10.8.0/21 dev=10.158.0.0/20; echo "exit $?"
sao-paulo          10.10.0.0/20        4092 usable
staging            10.10.8.0/21        2044 usable
dev                10.158.0.0/20       4092 usable
overlap: sao-paulo and staging
overlap: dev and any auto mode network
exit 1
```

Both found, and the exit status says so. **The planner's rule of thumb** comes out of the same arithmetic: one
`/16` of `10.0.0.0/8` per network and environment, a `/20` from it per region, and a written list of which
`/16` belongs to whom, kept with the Terraform. The eight bits between `/8` and `/16` give 256 such blocks, which is
more networks than the planner will ever have and few enough that a list of them fits on a screen.
