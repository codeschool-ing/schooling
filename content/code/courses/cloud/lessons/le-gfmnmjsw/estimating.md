---
title: Estimating a month before it happens
version: 1
---

An estimate is **the design from lessons 4 to 9, multiplied by the price list**. Nothing more
sophisticated than that is needed to get within the right order of magnitude, and nothing less will
do: a design nobody priced is a bill nobody expected.

Take a small web application in São Paulo, drawn the way lesson 6 drew one:

- two `t3.medium` machines, one in each of two zones, in private subnets;
- an application load balancer in front of them, facing the internet;
- a 30 GB gp3 root volume on each machine;
- one NAT gateway, so the machines can reach the internet for updates and outside APIs, processing
  about 50 GB a month;
- 200 GB of uploads and images in S3 Standard;
- about 500 GB a month of pages and images sent to users on the internet.

There is one line nobody drew: **public IPv4 addresses**. The machines have none, being private, but
the NAT gateway has one, and a load balancer facing the internet has at least one in each zone it
runs in. That is three addresses, and each is billed by the hour.

The estimate is a short program. Each price is copied from the sheet with a comment naming the line it
came from, so anybody checking it can find the number in `python3 prices.py`:

```schooling-example
{
  "language": "python",
  "file": "estimate.py",
  "parts": [
    {
      "code": "# One month of a small web application in sa-east-1 (Sao Paulo),\n# from the public price list: python3 prices.py, the sa-east-1 column.\nHOURS = 730\n",
      "note": "A month is **730 hours**: a year's 8,760 divided by twelve, the same convention the providers' calculators use."
    },
    {
      "code": "T3_MEDIUM = 0.06720      # EC2, on demand: t3.medium\nALB = 0.0340             # load balancer (ALB), per hour\nNAT_HOUR = 0.0930        # NAT gateway, per hour\nNAT_GB = 0.0930          # NAT gateway, per GB processed\nIPV4 = 0.0050            # public IPv4 address, per hour\nGP3 = 0.1520             # EBS: gp3 SSD volume, per GB-month\nS3_STANDARD = 0.04050    # S3: Standard, per GB-month\nOUT_GB = 0.1500          # out to the internet, first 10 TB\n",
      "note": "Every price is **copied from the sheet**, the `sa-east-1` column, with a comment naming the line. A number without its line cannot be checked, and next year it cannot be updated."
    },
    {
      "code": "lines = [\n    ('2 x t3.medium', 2 * T3_MEDIUM * HOURS),\n    ('load balancer, hours', ALB * HOURS),",
      "note": "The machines and the load balancer are **billed for existing**: an hourly price times every hour of the month, busy or not."
    },
    {
      "code": "    ('NAT gateway, hours', NAT_HOUR * HOURS),\n    ('NAT gateway, 50 GB', 50 * NAT_GB),\n    ('3 public IPv4 addresses', 3 * IPV4 * HOURS),",
      "note": "The network's own lines. The NAT gateway is billed twice, by the hour and by the gigabyte it processes, and the **three addresses** belong to the NAT gateway and to the load balancer, one in each of its two zones."
    },
    {
      "code": "    ('2 x 30 GB gp3', 2 * 30 * GP3),\n    ('S3 Standard, 200 GB', 200 * S3_STANDARD),",
      "note": "Storage in GB-months. The gp3 volumes are billed for the 30 GB **provisioned**, full or empty; the bucket for the 200 GB it **stores**."
    },
    {
      "code": "    ('500 GB out', 500 * OUT_GB),\n]",
      "note": "Traffic out to the internet, all of it inside the first 10 TB tier. Traffic in is free, so it has no line."
    },
    {
      "code": "\nfor name, usd in lines:\n    print(f'{name:<26}{usd:>9.2f}')\nprint(f'{\"total, USD a month\":<26}{sum(u for _, u in lines):>9.2f}')",
      "note": "Print each line and the total. The output below is what this program printed."
    }
  ],
  "output": "2 x t3.medium                 98.11\nload balancer, hours          24.82\nNAT gateway, hours            67.89\nNAT gateway, 50 GB             4.65\n3 public IPv4 addresses       10.95\n2 x 30 GB gp3                  9.12\nS3 Standard, 200 GB            8.10\n500 GB out                    75.00\ntotal, USD a month           298.64"
}
```

A month here is **730 hours**, which is a year's 8,760 hours divided by twelve; it is the convention
the providers' calculators use, and it makes months of 28 and 31 days cost the same.

The total is **298.64 USD a month**, before tax. Read down the column before trusting it, because an
estimate is also the first look at where the money goes. The two machines are 98.11, the largest line
and about a third of the total. The NAT gateway's hours are 67.89: one network device that exists so
the machines can reach out costs more than either machine it serves, at 49.06 each. The next section
takes that line, the traffic out and the three addresses apart.

## What the estimate leaves out

An estimate is honest when it says what it did not count. This one leaves out:

- **tax**, which the price list excludes and the bill adds;
- **a support plan**, which the providers sell separately and charge as a share of the bill or a
  monthly minimum;
- **the load balancer's capacity units**. An application load balancer is billed by the hour, which is
  on the sheet, and also by a measure of the traffic and connections it handles, which is not;
- **requests**: every GET and PUT on the S3 bucket, 0.00056 and 0.00700 per thousand;
- **logs and metrics**, whose storage grows every month the application runs;
- **snapshots and backups** of the volumes;
- **traffic between the two zones**, 0.0100 per GB each way, whenever one machine talks to something in
  the other zone;
- DNS, a domain and anything bought outside the provider;
- **free allowances**. The price list gives every account its first 100 GB out to the internet each
  month for nothing, which would take 15.00 off the last line; the section on free tiers says why an
  estimate leaves them out.

None of these is large for this application on its own, and together they are why a sensible budget
for it is not 298.64. Rounding it up to 400, about a third more, is the number the section on budgets
uses.

**What an estimate is for** is two decisions, not a prediction to the cent. It tells you whether the
design is affordable before you build it, and it lets you compare two designs on the same terms:
replace the NAT gateway, move to `us-east-1`, change the machine size, run the program again. It is
also the baseline the real bill is read against. When the first invoice says 520, the estimate is what
tells you which line to look at.
