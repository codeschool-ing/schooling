---
title: Trivy, and where its checks come from
version: 2
---

Trivy, from Aqua Security, is a scanner for container images, file systems and repositories, and
`trivy config` is the part of it that reads infrastructure code. Its checks are written in Rego, the
policy language of Open Policy Agent, and **the release you install carries a copy of them inside
the binary**.

**Installing Trivy.** It comes from Aqua Security's own package repository. The first command fetches
the key its packages are signed with, the second adds the repository, and the third installs the
newest release:

```sh
curl -fsSL https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo gpg --dearmor -o /usr/share/keyrings/trivy.gpg
echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb generic main" | sudo tee /etc/apt/sources.list.d/trivy.list
sudo apt-get update && sudo apt-get install -y trivy
```

These transcripts were recorded with 0.75.0, and a newer release may word a line differently:

```
ana@laptop:~/shop$ trivy --version
Version: 0.75.0
```

## A newer set of checks, if it can reach one

Trivy does not trust its built-in copy by default. On each run it looks for a newer *checks bundle*
on a container registry, and downloads it if the one in its cache is out of date. The machine these
lessons were recorded on had no internet, so the download failed and Trivy said what it did instead:

```
ana@laptop:~/shop$ trivy config . 2>&1 | head -n 5
2026-10-02T07:41:08-03:00	INFO	[misconfig] Misconfiguration scanning is enabled
2026-10-02T07:41:08-03:00	INFO	[checks-client] Need to update the checks bundle
2026-10-02T07:41:08-03:00	INFO	[checks-client] Downloading the checks bundle...
2026-10-02T07:41:08-03:00	ERROR	[misconfig] Falling back to embedded checks	err="failed to download checks bundle: download error: OCI repository error: 1 error occurred:\n\t* Get \"https://mirror.gcr.io/v2/\": dial tcp: lookup mirror.gcr.io on 127.0.0.1:53: server misbehaving\n\n"
2026-10-02T07:41:09-03:00	INFO	[terraform scanner] Scanning root module	file_path="."
```

`Falling back to embedded checks` is the line that matters. The scan went ahead with the checks
compiled into 0.75.0. On your computer the download succeeds, there is no `ERROR` line, and the
bundle is kept in Trivy's cache under `~/.cache/trivy`. `--skip-check-update` stops the attempt
altogether:

```
ana@laptop:~/shop$ trivy config --skip-check-update . 2>&1 | head -n 4
2026-10-02T07:41:10-03:00	INFO	[misconfig] Misconfiguration scanning is enabled
2026-10-02T07:41:10-03:00	INFO	[checks-client] No downloadable checks were loaded as --skip-check-update is enabled, loading from existing cache...
2026-10-02T07:41:10-03:00	ERROR	[misconfig] Falling back to embedded checks	err="failed to check cache: cache does not exist at \"/home/ana/.cache/trivy/policy/content\""
2026-10-02T07:41:11-03:00	INFO	[terraform scanner] Scanning root module	file_path="."
```

On the recording machine the `ERROR` is still there, now because the cache is empty, and the fallback
is the same, so every Trivy result on these pages is what the embedded checks say. On yours the
cache holds the bundle the first run downloaded, Trivy loads it, and there is no `ERROR`. That bundle
can be newer than the checks in the binary, so your counts may differ slightly from the page's.

That is the general point: **the same binary on the same code can report something different next
week** because the checks moved. In a pipeline that fails on findings, decide whether you want that.
`--skip-check-update` stops the checks moving on their own: it uses the cache, or the release's own
checks when there is none, and new rules arrive when you decide.

## Severity comes with every finding

`-q` drops the log lines. The full report prints the code of every finding, so here it is filtered
to the heading of each file, its count and the title of each finding:

```
ana@laptop:~/shop$ trivy config --skip-check-update -q . | grep -E "^(AWS-|Failures|[a-z]+\.tf )"
main.tf (terraform)
Failures: 11 (UNKNOWN: 0, LOW: 3, MEDIUM: 2, HIGH: 6, CRITICAL: 0)
AWS-0026 (HIGH): EBS volume is not encrypted.
AWS-0027 (LOW): EBS volume does not use a customer-managed KMS key.
AWS-0086 (HIGH): No public access block so not blocking public acls
AWS-0087 (HIGH): No public access block so not blocking public policies
AWS-0089 (LOW): Bucket has logging disabled
AWS-0090 (MEDIUM): Bucket does not have versioning enabled
AWS-0091 (HIGH): No public access block so not blocking public acls
AWS-0093 (HIGH): No public access block so not restricting public buckets
AWS-0094 (LOW): Bucket does not have a corresponding public access block.
AWS-0132 (HIGH): Bucket does not encrypt data with a customer managed key.
AWS-0178 (MEDIUM): VPC does not have VPC Flow Logs enabled.
ssh.tf (terraform)
Failures: 1 (UNKNOWN: 0, LOW: 0, MEDIUM: 0, HIGH: 1, CRITICAL: 0)
AWS-0107 (HIGH): Security group rule allows unrestricted ingress from any IP address.
```

Unlike Checkov's offline run, every Trivy finding has a severity, because the severity is part of
the check that ships in the binary: `UNKNOWN`, `LOW`, `MEDIUM`, `HIGH` or `CRITICAL`. The
`Failures:` line counts them per file. Twelve findings in all, and the shape matches Checkov's report without being the same list. Trivy reports the missing public access block five times, once for
the block and once for each of the four settings it would hold, and says nothing about replication or lifecycle rules.

## One finding in full

```
ana@laptop:~/shop$ trivy config --skip-check-update -q . | sed -n "/^ssh.tf/,\$p"
ssh.tf (terraform)
==================
Tests: 1 (SUCCESSES: 0, FAILURES: 1)
Failures: 1 (UNKNOWN: 0, LOW: 0, MEDIUM: 0, HIGH: 1, CRITICAL: 0)

AWS-0107 (HIGH): Security group rule allows unrestricted ingress from any IP address.
════════════════════════════════════════
Security groups provide stateful filtering of ingress and egress network traffic to AWS
resources. It is recommended that no security group allows unrestricted ingress access to
remote server administration ports, such as SSH to port 22 and RDP to port 3389.


See https://avd.aquasec.com/misconfig/aws-0107
────────────────────────────────────────
 ssh.tf:7
   via ssh.tf:1-8 (aws_vpc_security_group_ingress_rule.ssh)
────────────────────────────────────────
   1   resource "aws_vpc_security_group_ingress_rule" "ssh" {
   2     security_group_id = aws_security_group.web.id
   3     description       = "SSH for maintenance"
   4     ip_protocol       = "tcp"
   5     from_port         = 22
   6     to_port           = 22
   7 [   cidr_ipv4         = "0.0.0.0/0"
   8   }
────────────────────────────────────────
```

The parts are the ones Checkov had, in a different arrangement. The id is `AWS-0107` and the
severity sits beside it. The paragraph is the check's own explanation, and **the link is printed even
offline**, because it is part of the check rather than a download. Then comes the place, and it is
more precise than Checkov's: `ssh.tf:7` is the line with the offending value, and the `via` lines
walk out from it to the resource that holds it. The code repeats the resource with line 7 marked.

Notice what the explanation says the rule is about: *remote server administration ports, such as
SSH to port 22 and RDP to port 3389*. Port 443 from `0.0.0.0/0` is the HTTPS rule, it is the point
of a web server, and Trivy did not report it.
