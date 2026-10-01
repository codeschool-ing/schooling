---
title: Asking NetBox for an address
version: 1
---

NetBox's IPAM side, the prefixes and the addresses in them, answers a question that spreadsheets
answer badly: which address is free. A prefix has an `available-ips` endpoint, and creating an
address on it takes the first free one:

```schooling-example
{
  "language": "python",
  "file": "allocate.py",
  "parts": [
    {
      "code": "import sys\n\nfrom nb import connect\n\nnb = connect()\nprefix = nb.ipam.prefixes.get(prefix=\"203.0.113.0/26\")"
    },
    {
      "code": "ip = prefix.available_ips.create({\"status\": \"active\", \"description\": sys.argv[1]})\nprint(f\"{ip.address} for {ip.description}\")",
      "note": "**NetBox picks the address.** `available_ips` is the list of free addresses in the prefix; creating on it takes the first one and records it, in one request."
    }
  ]
}
```

**The choice and the record happen in one request**, which is the whole point: two people reading a
spreadsheet at the same moment can both pick `.2`, while NetBox hands out each address once. Run
twice, with the same description:

```
ana@ctl:~$ cd sot && python allocate.py "printer, branch 1"
203.0.113.2/26 for printer, branch 1
ana@ctl:~$ cd sot && python allocate.py "printer, branch 1"
203.0.113.3/26 for printer, branch 1
```

Two printers' worth of addresses for one printer. **`create` is not idempotent**: NetBox did exactly
what it was asked twice, and nothing in the request said "the printer already has one". It is
lesson 9's idempotency question again, asked of an API instead of a playbook. A script that allocates has to look first, for an address with that description or DNS name,
and create only when there is none. Or the address has to be tied to something unique, such as
an interface, so that a second attempt fails instead of succeeding twice.

`203.0.113.10`, pc1's address, was not handed out, and only because it is not in NetBox. The pc
hosts were never recorded, so NetBox believes their addresses are free. **A source of truth is only
as true as what was put in it**, and an address in use that it does not know about is the next
duplicate it will hand out.
