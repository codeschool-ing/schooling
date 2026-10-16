---
title: What the three cost
version: 1
---

Each service is priced by what it reads, so each grows with a different part of the system:

```
ana@laptop:~/aws$ python3 price.py AmazonGuardDuty "CloudTrail event analyzed"
AmazonGuardDuty, sa-east-1, published 2026-10-08
  SAE1-PaidEventsAnalyzed                  0.000007 USD per Events     $0.000007 per CloudTrail event analyzed in South America (Sao Paulo) region
ana@laptop:~/aws$ python3 price.py AmazonGuardDuty PaidEventsAnalyzed-Bytes
AmazonGuardDuty, sa-east-1, published 2026-10-08
  SAE1-PaidEventsAnalyzed-Bytes            0.260000 USD per GB         $0.26 per GB over 10000 GB / month of data analyzed South America (Sao Paulo) region
  SAE1-PaidEventsAnalyzed-Bytes            0.440000 USD per GB         $0.44 per GB for the next 7500 GB / month of data analyzed South America (Sao Paulo) region
  SAE1-PaidEventsAnalyzed-Bytes            0.880000 USD per GB         $0.88 per GB for the next 2000 GB / month of data analyzed South America (Sao Paulo) region
  SAE1-PaidEventsAnalyzed-Bytes            1.750000 USD per GB         $1.75 per GB for the first 500 GB / month of data analyzed South America (Sao Paulo) region
ana@laptop:~/aws$ python3 price.py AmazonInspectorV2 SAE1-container-image
AmazonInspectorV2, sa-east-1, published 2026-10-15
  SAE1-container-image-initial-scan        0.110000 USD per Resource-assessment $0.11 per Resource-assessment for container-image-initial-scan in South America (Sao Paulo)
  SAE1-container-image-initial-scan-free-trial     0.000000 USD per Resource-assessment $0.0 per Resource-assessment for container-image-initial-scan-free-trial in South America (Sao Paulo)
  SAE1-container-image-re-scan             0.010000 USD per Resource-assessment $0.01 per Resource-assessment for container-image-re-scan in South America (Sao Paulo)
  SAE1-container-image-re-scan-free-trial     0.000000 USD per Resource-assessment $0.0 per Resource-assessment for container-image-re-scan-free-trial in South America (Sao Paulo)
ana@laptop:~/aws$ python3 price.py AmazonInspectorV2 SAE1-EC2-Scanning
AmazonInspectorV2, sa-east-1, published 2026-10-15
  SAE1-EC2-Scanning                        0.002100 USD per Instance-hrs $0.0021 per Instance-hrs for EC2-Scanning in South America (Sao Paulo)
  SAE1-EC2-Scanning-agentless              0.002890 USD per Instance-hrs $0.00289 per Instance-hrs for EC2-Scanning-agentless in South America (Sao Paulo)
  SAE1-EC2-Scanning-agentless-free-trial     0.000000 USD per Instance-hrs $0.0 per Instance-hrs for EC2-Scanning-agentless in South America (Sao Paulo)
  SAE1-EC2-Scanning-free-trial             0.000000 USD per Instance-hrs $0.0 per Instance-hrs for EC2-Scanning-free-trial in South America (Sao Paulo)
ana@laptop:~/aws$ python3 price.py AWSSecurityHub "security checks per account"
AWSSecurityHub, sa-east-1, published 2026-09-30
  SAE1-PaidComplianceCheck                 0.000500 USD per Security Checks Over 500,000 security checks per account per region per month cost USD0.0005 per check
  SAE1-PaidComplianceCheck                 0.000800 USD per Security Checks 100,001 to 400,000 security checks per account per region per month cost USD0.0008 per check
  SAE1-PaidComplianceCheck                 0.001000 USD per Security Checks The first 100,000 security checks per account per region per month cost USD0.001 per check
```

**GuardDuty** charges for the CloudTrail events it analyses, 7 USD per million in São Paulo, and for the
flow and DNS logs by the gigabyte, 1.75 USD per GB for the first 500 GB of a month and less after. The
optional protections, runtime monitoring, malware scans, RDS and S3, have lines of their own. There is a
30-day free trial on each, which is the free lines in the list.

**Inspector** charges per thing scanned: 0.11 USD for an image's first scan in ECR and 0.01 USD for each
rescan, and 0.0021 USD an hour per EC2 instance scanned with its agent, 0.00289 without one.

**Security Hub** charges per control check, 0.001 USD for each of the first 100,000 a month and less
after, and per finding ingested beyond 10,000 a month. The list also carries per-resource lines for a
newer plan, which this lesson does not price.

## The shop, for a month

| line | quantity | USD a month |
|---|---|---|
| GuardDuty, CloudTrail events | 2 million × 0.000007 | 14.00 |
| GuardDuty, flow and DNS logs | 40 GB × 1.75 | 70.00 |
| Inspector, ECR images | 60 new images × 0.11, 900 rescans × 0.01 | 15.60 |
| Inspector, EC2 | 4 instances × 730 h × 0.0021 | 6.13 |
| Security Hub, checks | 20,000 × 0.001 | 20.00 |
| **total** | | **125.73** |

**The flow logs are the largest line**, and they grow with traffic. Most teams turn all three on in
every account and region they use, because the price of one finding missed is larger than the year; the
habit that keeps the bill sensible is to look at this table once, with the team's own numbers, before
somebody asks why it doubled.
