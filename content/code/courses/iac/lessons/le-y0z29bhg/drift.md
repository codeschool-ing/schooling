---
title: Drift, and the change nobody wrote down
version: 1
---

A week later somebody needs to look at one of the shop's servers from home, and opens SSH to the
world on the security group, from another machine, by hand. It takes one command, with the
group's id in `SG`, and it solves the problem of the day:

```sh
aws ec2 authorize-security-group-ingress --group-id "$SG" \
  --protocol tcp --port 22 --cidr 0.0.0.0/0
```

Nobody tells Ana, and nothing tells her either. When she asks AWS what the group allows, there is a
rule she never wrote:

```
ana@laptop:~/shop$ aws ec2 describe-security-groups --filters Name=group-name,Values=web --query "SecurityGroups[0].IpPermissions[].[IpProtocol,FromPort,IpRanges[0].CidrIp]" --output text
tcp	443	0.0.0.0/0
tcp	22	0.0.0.0/0
ana@laptop:~/shop$ grep -c 22 network.sh
0
```

Port 22 from `0.0.0.0/0` is there; `network.sh` has never heard of it. **That difference between
what was meant and what exists is called drift**, and it is the normal state of any
infrastructure managed by hand. Nobody did anything unusual. One person solved one problem, the
cloud accepted the change, and the only record of it is the resource itself.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Two timelines side by side. The file network.sh is written on day 1 and never changes. The real security group starts identical to it, gains port 22 by hand on day 8, and from then on differs from the file.\"><defs><marker id=\"dr-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><text x=\"70.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">network.sh</text><text x=\"70.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">in AWS</text><text x=\"170.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">day 1</text><text x=\"400.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">day 8</text><text x=\"620.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">day 30</text><path d=\"M220 70 L570 70\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M220 170 L570 170\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"120\" y=\"48\" width=\"100\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"170.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">443</text><rect x=\"120\" y=\"148\" width=\"100\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"170.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">443</text><rect x=\"570\" y=\"48\" width=\"100\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"620.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">443</text><rect x=\"570\" y=\"148\" width=\"100\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"620.0\" y=\"163.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">443</text><text x=\"620.0\" y=\"179.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">22</text><path d=\"M400 110 L400 146\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dr-ah-amber)\"></path><text x=\"400.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">a rule added by hand</text><text x=\"620.0\" y=\"220.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">the file and the cloud disagree</text></svg>", "caption": "Drift: the file stays as it was written, and the cloud keeps whatever anybody did to it."}
```

Drift is worse than a missing note, for three reasons.

**It is invisible until somebody compares.** The network works. The shop sells. The open port
shows up in an audit, or in an incident, or when the network is rebuilt from the script and the
person who needed SSH finds it gone.

**It compounds.** The next change is made against the network as it is, not as it was written, so
it is now built on a state that exists nowhere except in AWS. After a year, the script describes
something that was true for one afternoon.

**It cannot be reviewed.** A change to a file can be read by a colleague before it happens. A
change typed into a cloud console happened before anybody could read it, and in this case it
opened a port to the whole internet.

The cure is not discipline. Telling everybody to update the script after every manual change is
exactly the arrangement that produced the drift. The cure is to make the file the **only way** a
change happens: you edit the description, a program compares it with what exists, and the program
makes the change. Then a difference between the two is something the program can *find*, and
lesson 7 shows Terraform finding exactly this rule.
