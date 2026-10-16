---
title: Three packets through both filters
version: 1
---

**A packet that crosses into a subnet meets the network ACL first and the security group second, and
it has to pass both.** On the way out it meets them in the other order. The two filters do not know
about each other. The network ACL cannot see which group an interface carries, and the security
group never sees a packet the network ACL dropped. This section walks three packets through the
rules the shop now has, the way you would on a whiteboard. Nothing in the lab will walk them for
you.

## The three walks

**A customer at `203.0.113.50` opens the shop on port 443.** The packet arrives at the load
balancer's interface in `public-a`. The `public` network ACL reads its inbound rules from the
lowest. Rule 90 names a different address and does not match, and rule 100 allows TCP 443 from
anywhere, so the packet passes into the subnet. `alb-sg` allows 443 from `0.0.0.0/0`, so it reaches
the load balancer. The reply leaves for the customer's ephemeral port, say 50812. `alb-sg` lets it
out because it belongs to a connection it let in. The network ACL lets it out because rule 100
outbound allows 1024 to 65535. **Two filters, four decisions, all of them allow.**

**`198.51.100.7` tries the same thing.** Rule 90 matches first and denies, and the network ACL drops
the packet at the edge of the subnet. `alb-sg` never sees it, and could not have refused it anyway.
It allows 443 from everywhere, and a security group has no way to say "except".

**The load balancer is misconfigured and sends a request straight to the database**, at
`10.20.97.10` port 5432. The `public` network ACL lets it out under rule 120, and `data-a` is on the
default network ACL, which lets it in. Then `db-sg` reads its one rule: 5432 from interfaces
carrying `app-sg`. The load balancer's interface carries `alb-sg`, so **the security group refuses
it**, although every address and every subnet rule along the way allowed it. The same request from
an application machine would pass. That is exactly the chain the three groups describe.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 430\" role=\"img\" data-fig=\"l18-walks\" aria-label=\"Three packets, each meeting the network ACL at the edge of the subnet and then the security group on the interface. First: a customer at 203.0.113.50 sends to port 443. The public network ACL skips rule 90, which names another address, and rule 100 allows 443; alb-sg allows 443 from anywhere; the packet reaches the load balancer. Second: 198.51.100.7 sends to port 443. Rule 90 of the network ACL denies it, and alb-sg never sees it, though it would have allowed it. Third: the load balancer sends to the database on port 5432. The public network ACL allows it out under rule 120 and the default network ACL of data-a lets it in, but db-sg allows 5432 only from app-sg, and the load balancer carries alb-sg, so the security group refuses it.\"><defs><marker id=\"l18-walks-af-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l18-walks-af-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"82.5\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper-dim)\">from</text><text x=\"260.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper-dim)\">network ACL, at the subnet</text><text x=\"460.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper-dim)\">security group, on the interface</text><text x=\"637.5\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper-dim)\">to</text><path d=\"M20.0 36.0 L700.0 36.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><rect x=\"20.0\" y=\"62.0\" width=\"125.0\" height=\"52.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"82.5\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a customer</text><text x=\"82.5\" y=\"97.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">203.0.113.50</text><rect x=\"175.0\" y=\"62.0\" width=\"170.0\" height=\"52.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"260.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">90: no match</text><text x=\"260.0\" y=\"97.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">100: allow 443</text><rect x=\"375.0\" y=\"62.0\" width=\"170.0\" height=\"52.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"460.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">alb-sg:</text><text x=\"460.0\" y=\"97.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">443 from 0.0.0.0/0</text><rect x=\"575.0\" y=\"62.0\" width=\"125.0\" height=\"52.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"637.5\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">load balancer</text><text x=\"637.5\" y=\"97.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">public-a</text><path d=\"M147.0 88.0 L172.0 88.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l18-walks-af-ah-phosphor)\"></path><path d=\"M347.0 88.0 L372.0 88.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l18-walks-af-ah-phosphor)\"></path><path d=\"M547.0 88.0 L572.0 88.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l18-walks-af-ah-phosphor)\"></path><text x=\"360.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--phosphor)\">allowed twice in, and the reply leaves on rule 100 outbound</text><rect x=\"20.0\" y=\"182.0\" width=\"125.0\" height=\"52.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"82.5\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the refused one</text><text x=\"82.5\" y=\"217.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">198.51.100.7</text><rect x=\"175.0\" y=\"182.0\" width=\"170.0\" height=\"52.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"260.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">90: deny</text><text x=\"260.0\" y=\"217.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">198.51.100.7/32</text><rect x=\"375.0\" y=\"182.0\" width=\"170.0\" height=\"52.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"460.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">would allow it,</text><text x=\"460.0\" y=\"217.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">never sees it</text><rect x=\"575.0\" y=\"182.0\" width=\"125.0\" height=\"52.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"637.5\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">load balancer</text><text x=\"637.5\" y=\"217.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">public-a</text><path d=\"M147.0 208.0 L172.0 208.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l18-walks-af-ah-amber)\"></path><text x=\"360.0\" y=\"248.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--amber)\">dropped at the edge of the subnet: a security group cannot deny</text><rect x=\"20.0\" y=\"302.0\" width=\"125.0\" height=\"52.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"82.5\" y=\"320.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">load balancer</text><text x=\"82.5\" y=\"337.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">carries alb-sg</text><rect x=\"175.0\" y=\"302.0\" width=\"170.0\" height=\"52.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"260.0\" y=\"320.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">public out 120</text><text x=\"260.0\" y=\"337.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">data-a in: 100</text><rect x=\"375.0\" y=\"302.0\" width=\"170.0\" height=\"52.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"460.0\" y=\"320.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">db-sg: 5432</text><text x=\"460.0\" y=\"337.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">from app-sg only</text><rect x=\"575.0\" y=\"302.0\" width=\"125.0\" height=\"52.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"637.5\" y=\"320.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">database</text><text x=\"637.5\" y=\"337.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.20.97.10</text><path d=\"M147.0 328.0 L172.0 328.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l18-walks-af-ah-phosphor)\"></path><path d=\"M347.0 328.0 L372.0 328.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l18-walks-af-ah-phosphor)\"></path><text x=\"360.0\" y=\"368.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--amber)\">every address and subnet rule allowed it; the group it carries did not</text><text x=\"360.0\" y=\"412.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">the same request from a machine carrying app-sg would pass</text></svg>", "caption": "The network ACL can refuse an address. Only the security group can refuse an identity."}
```

The three walks are the reason for having both filters. The network ACL does the thing only it can
do, a deny for one address at the edge of a tier. The security groups do the thing only they can do,
**trust by identity rather than by address**. That is what keeps the load balancer away from the
database whatever addresses either one has.

## What was not run, and how you would check it on AWS

**moto filters nothing.** It stores every rule, checks their shape and refuses a duplicate. It lets
no packet through any of them, because no packet exists. The three walks above are reasoning from
the rules, and the figure is a drawing of that reasoning, not of a capture.

On AWS, two tools answer the question for real, and neither was run here:

- **VPC Flow Logs** record, for each network interface, every connection attempt with its addresses,
  ports and an `ACCEPT` or `REJECT`. They show what happened, after it happened. They are where you
  look when somebody says "it cannot connect".
- **VPC Reachability Analyzer** takes a source and a destination, such as the load balancer and the
  database. It reads the route tables, the network ACLs and the security groups between them. Then
  it says whether a packet could get through and, if not, which rule stops it. It sends no traffic.
  It reads the same configuration this section read, without the mistakes a person makes reading it.

Reachability Analyzer is billed per analysis, and its line is in the same VPC offer lesson 17 read,
of 17 September 2026:

```
ana@laptop:~/aws$ python3 price.py AmazonVPC 20260917190528 sa-east-1 SAE1-Analysis-Runs
AmazonVPC 20260917190528, published 2026-09-17, USD
SAE1-Analysis-Runs
          0 to       Inf ReachabilityAnalyses 0.1000
```

**Ten cents a question.** Asking it about the three walks above would cost thirty cents.

## The lesson as a script

The groups and the public network ACL, as one script for lessons 19 and 20 to rebuild from:

```sh
cat > ~/aws/net/18-filters.sh <<'EOF'
# Lesson 18: the shop's filters. Three security groups, each trusting the one
# in front of it, and a network ACL for the public subnets. Run after 17-routes.sh.
vpc=$(aws ec2 describe-vpcs --filters Name=tag:Name,Values=shop-prod \
  --query "Vpcs[0].VpcId" --output text)
group() { aws ec2 create-security-group --vpc-id "$vpc" --group-name "$1" \
  --description "$2" --query GroupId --output text; }
alb=$(group alb-sg "shop load balancer")
app=$(group app-sg "shop application")
db=$(group db-sg "shop database")
aws ec2 authorize-security-group-ingress --group-id "$alb" --protocol tcp --port 443 --cidr 0.0.0.0/0 > /dev/null
aws ec2 authorize-security-group-ingress --group-id "$app" --protocol tcp --port 8080 --source-group "$alb" > /dev/null
aws ec2 authorize-security-group-ingress --group-id "$db" --protocol tcp --port 5432 --source-group "$app" > /dev/null
aws ec2 revoke-security-group-egress --group-id "$db" --protocol all --cidr 0.0.0.0/0 > /dev/null
echo "alb-sg $alb, app-sg $app, db-sg $db"
acl=$(aws ec2 create-network-acl --vpc-id "$vpc" \
  --tag-specifications 'ResourceType=network-acl,Tags=[{Key=Name,Value=public}]' \
  --query NetworkAcl.NetworkAclId --output text)
rule() { aws ec2 create-network-acl-entry --network-acl-id "$acl" "$@"; }
rule --ingress --rule-number 90 --protocol -1 --cidr-block 198.51.100.7/32 --rule-action deny
rule --ingress --rule-number 100 --protocol tcp --port-range From=443,To=443 --cidr-block 0.0.0.0/0 --rule-action allow
rule --ingress --rule-number 110 --protocol tcp --port-range From=1024,To=65535 --cidr-block 0.0.0.0/0 --rule-action allow
rule --ingress --rule-number 120 --protocol -1 --cidr-block 10.20.0.0/16 --rule-action allow
rule --egress --rule-number 100 --protocol tcp --port-range From=1024,To=65535 --cidr-block 0.0.0.0/0 --rule-action allow
rule --egress --rule-number 110 --protocol tcp --port-range From=443,To=443 --cidr-block 0.0.0.0/0 --rule-action allow
rule --egress --rule-number 120 --protocol -1 --cidr-block 10.20.0.0/16 --rule-action allow
for z in a b c; do
  s=$(aws ec2 describe-subnets --filters Name=tag:Name,Values=public-$z --query "Subnets[0].SubnetId" --output text)
  old=$(aws ec2 describe-network-acls --filters Name=association.subnet-id,Values="$s" \
    --query "NetworkAcls[0].Associations[?SubnetId=='$s'].NetworkAclAssociationId" --output text)
  aws ec2 replace-network-acl-association --association-id "$old" --network-acl-id "$acl" > /dev/null
done
echo "network ACL public $acl on public-a, public-b and public-c"
EOF
```

Restart moto and run the three scripts in order to check it:

```
ana@laptop:~/aws$ bash net/16-vpc.sh > /dev/null && bash net/17-routes.sh > /dev/null && bash net/18-filters.sh
alb-sg sg-53a72398a75c4e2e7, app-sg sg-19bff292e592ad5d8, db-sg sg-f673dd8488f3156d0
network ACL public acl-9bc6a9407274c43a1 on public-a, public-b and public-c
```
