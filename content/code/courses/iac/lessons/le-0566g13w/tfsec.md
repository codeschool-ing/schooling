---
title: tfsec, a scanner that stopped learning, and Terrascan
version: 2
---

tfsec is one Go binary, made only for Terraform and its HCL.

**Installing tfsec.** It is that one file, downloaded from the project's releases on GitHub and put
on your `PATH`:

```sh
curl -fsSLo tfsec https://github.com/aquasecurity/tfsec/releases/download/v1.28.14/tfsec-linux-amd64
sudo install tfsec /usr/local/bin/tfsec && rm tfsec
```

On an ARM machine the file ends in `-linux-arm64`. Ask it its version and it answers with a notice
first:

```
ana@laptop:~/shop$ tfsec --version

======================================================
tfsec is joining the Trivy family

tfsec will continue to remain available 
for the time being, although our engineering 
attention will be directed at Trivy going forward.

You can read more here: 
https://github.com/aquasecurity/tfsec/discussions/1994
======================================================
v1.28.14
```

**tfsec has become part of Trivy.** Its checks were carried into Trivy's, which is why the two
tools' findings have such similar titles, and its authors now put their work into Trivy. The binary
still runs and prints that notice on every run (to the error stream, so a pipe does not swallow it).
Here is its report on the shop, filtered to one line per result and the place it points at:

```
ana@laptop:~/shop$ tfsec --no-colour . | grep -E "^(Result|  [a-z]+\.tf)"

======================================================
tfsec is joining the Trivy family

tfsec will continue to remain available 
for the time being, although our engineering 
attention will be directed at Trivy going forward.

You can read more here: 
https://github.com/aquasecurity/tfsec/discussions/1994
======================================================
Result #1 HIGH No public access block so not blocking public acls 
  main.tf:42-44
Result #2 HIGH No public access block so not blocking public policies 
  main.tf:42-44
Result #3 HIGH Bucket does not have encryption enabled 
  main.tf:42-44
Result #4 HIGH No public access block so not ignoring public acls 
  main.tf:42-44
Result #5 HIGH No public access block so not restricting public buckets 
  main.tf:42-44
Result #6 HIGH Bucket does not encrypt data with a customer managed key. 
  main.tf:42-44
Result #7 HIGH EBS volume is not encrypted. 
  main.tf:46-50
Result #8 MEDIUM VPC Flow Logs is not enabled for VPC  
  main.tf:14-17
Result #9 MEDIUM Bucket does not have logging enabled 
  main.tf:42-44
Result #10 MEDIUM Bucket does not have versioning enabled 
  main.tf:42-44
Result #11 LOW Bucket does not have a corresponding public access block. 
  main.tf:42-44
Result #12 LOW EBS volume does not use a customer-managed KMS key. 
  main.tf:46-50
```

Twelve results, three severities, and the same themes as the other two scanners. Read the places,
though: every one is in `main.tf`. **The SSH rule in `ssh.tf`, the finding the other two put first,
is not there.**

## A resource it was never taught

tfsec did not decide port 22 was fine. Its check for public ingress was written for the shapes a
security group rule could take when the check was written, and `aws_vpc_security_group_ingress_rule`
is not one of them. Write the same rule in the older form, as an `ingress` block inside the group,
in a directory of its own, `~/legacy/main.tf`, and tfsec finds it at once:

```hcl
resource "aws_security_group" "web" {
  name        = "web"
  description = "web servers"

  ingress {
    description = "SSH for maintenance"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

```
ana@laptop:~/legacy$ tfsec --no-colour . | sed -n "/^Result/,/^  Resolution/p"

======================================================
tfsec is joining the Trivy family

tfsec will continue to remain available 
for the time being, although our engineering 
attention will be directed at Trivy going forward.

You can read more here: 
https://github.com/aquasecurity/tfsec/discussions/1994
======================================================
Result #1 CRITICAL Security group rule allows ingress from public internet. 
────────────────────────────────────────────────────────────────────────────────
  main.tf:10
────────────────────────────────────────────────────────────────────────────────
    1    resource "aws_security_group" "web" {
    .  
   10  [     cidr_blocks = ["0.0.0.0/0"]
   ..  
   12    }
────────────────────────────────────────────────────────────────────────────────
          ID aws-ec2-no-public-ingress-sgr
      Impact Your port exposed to the internet
  Resolution Set a more restrictive cidr range
```

So the same nine characters, `0.0.0.0/0` on port 22, are `CRITICAL` in one spelling and invisible in
the other. Nothing printed a warning. A scanner reports what its rules match, and a resource type no
rule mentions produces silence, which looks exactly like a pass.

**That is the cost of a tool nobody is developing**, and it grows. The AWS provider keeps
adding resources and arguments, and a frozen catalogue covers less of a configuration with
each one. It is also a reason to keep a known-bad example like `legacy/main.tf` in a repository
and scan it in the pipeline: if a scanner upgrade or a rewrite of your code makes the finding
disappear, you find out from the build, not from an incident. If you have tfsec in a pipeline
today, the move its own notice suggests is to `trivy config`, which carries the same checks forward
and knows the newer resource.

## Terrascan

Terrascan, from Tenable, is a fourth tool of the same kind, with its policies written in Rego like
Trivy's. It was not installed for this lesson, and back in `~/shop` the shell confirms it:

```
ana@laptop:~/shop$ which terrascan; echo "exit $?"
exit 1
```

and nothing in this lesson says what its output looks like, because nothing here ran it. What you
already know carries over: it reads files, it matches resources against rules, and what it reports
depends on which resource types those rules know.

## Which one

The three that ran here agree on most of the shop and disagree at the edges. A table of what each
reported, from the transcripts above:

| | Checkov | Trivy | tfsec |
|---|---|---|---|
| findings on the shop | 13 | 12 | 12 |
| the SSH rule in `ssh.tf` | found | found | not found |
| severity offline | none | every finding | every finding |
| custom rules | Python or YAML | Rego | (not shown here) |

Checkov and Trivy are both maintained, and running both costs little: neither needs credentials,
and both reported every finding here with their downloads switched off. tfsec belongs in this lesson because you will meet it in
existing pipelines, and now you know what to check before trusting its silence.
