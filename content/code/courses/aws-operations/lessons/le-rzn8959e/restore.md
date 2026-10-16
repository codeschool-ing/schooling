---
title: Restoring the state from its own history
version: 1
---

Lesson 6 turned on versioning in the state bucket for this moment. Deleting an object in a versioned
bucket does not remove its data: S3 adds a **delete marker** on top, and every earlier version stays
underneath, readable by its version id. The state's history:

```
ana@laptop:~/aws/tf7/shop$ aws s3api list-object-versions --bucket shop-tfstate-123456789012 --prefix shop/terraform.tfstate --query "Versions[?Key=='shop/terraform.tfstate'].[LastModified,Size,VersionId]" --output text
2026-10-16T16:22:24+00:00	2744	3fb9b69f-91e3-4c92-8f84-22496f481bf7
2026-10-16T16:22:17+00:00	8403	c4dbd1b7-7504-44eb-9998-c78c8316bc6d
ana@laptop:~/aws/tf7/shop$ aws s3api list-object-versions --bucket shop-tfstate-123456789012 --prefix shop/terraform.tfstate --query "DeleteMarkers[?Key=='shop/terraform.tfstate'].[LastModified,VersionId]" --output text
2026-10-16T16:22:18+00:00	cf8e5336-4d4d-4f79-ae3c-383c510bea59
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"A timeline of one key in the state bucket. First a version of 8,403 bytes holding four resources. Then a delete marker, the accident. Then a version of 2,744 bytes written by the bad apply, holding one resource. Last, a version of 8,403 bytes, the restore, now the latest. A dashed arrow from the first version to the last is labelled copy-object with the first version&#x27;s id as the copy source.\"><defs><marker id=\"ver-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"24\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">one key, shop/terraform.tfstate, and its history</text><path d=\"M30 200 L700 200\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"700\" y=\"216\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">time</text><rect x=\"40\" y=\"120\" width=\"150\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"115.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">version, 8,403 bytes</text><text x=\"115.0\" y=\"156.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">four resources</text><path d=\"M115 176 L115 200\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"205\" y=\"120\" width=\"150\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"280.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">delete marker</text><text x=\"280.0\" y=\"156.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the accident</text><path d=\"M280 176 L280 200\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"370\" y=\"120\" width=\"150\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"445.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">version, 2,744 bytes</text><text x=\"445.0\" y=\"156.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the bad apply: one resource</text><path d=\"M445 176 L445 200\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"535\" y=\"120\" width=\"150\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"610.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">version, 8,403 bytes</text><text x=\"610.0\" y=\"156.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the restore, latest</text><path d=\"M610 176 L610 200\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M115 118 L115 70 L610 70 L610 118\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#ver-ah)\"></path><text x=\"362\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">copy-object --copy-source ...?versionId=c4db...</text></svg>", "caption": "Nothing in the history is removed. The restore is a new version whose content is an old one."}
```

Two versions and one delete marker. Read them by time: the 8,403-byte version is the state with four
resources, written by the apply; the delete marker came one second later; the 2,744-byte version
was written by the bad apply after it, and records only the topic. The version to bring back is the
one before the marker.

## Copying the good version on top

```
ana@laptop:~/aws/tf7/shop$ aws s3api copy-object --bucket shop-tfstate-123456789012 --key shop/terraform.tfstate --copy-source 'shop-tfstate-123456789012/shop/terraform.tfstate?versionId=c4dbd1b7-7504-44eb-9998-c78c8316bc6d' --query VersionId --output text
1691c2ba-3a9b-4346-89fc-61adcfbd6543
ana@laptop:~/aws/tf7/shop$ terraform plan -no-color | grep -E '^(No changes|Plan:)'
No changes. Your infrastructure matches the configuration.
ana@laptop:~/aws/tf7/shop$ terraform state list
aws_cloudwatch_log_group.web
aws_dynamodb_table.orders
aws_s3_bucket.uploads
aws_sns_topic.alerts
```

`copy-object` with a version id in `--copy-source` writes that old content as a **new** latest
version. Nothing is destroyed in the process: the bad version and the marker stay in the history, so
the restore itself can be undone. **No changes**, and four resources in the state again, which is
the evidence the restore worked: Terraform compared its restored memory with the account and found
them in agreement.

Two details decide whether this goes well on a real team:

- **stop everybody first**: a pipeline that applies between the accident and the restore writes a
  newer version, as the bad apply did here, and the restore must pick the right version by time and
  by size, never just "the previous one";
- **read the version before restoring it**: `aws s3api get-object --version-id ... restored.json`
  downloads it, and its `serial` and `resources` show what it holds.

## A copy that does not depend on the bucket

Versioning protects against a deleted object. It does not protect against a deleted bucket, a
mistaken lifecycle rule that expires old versions, or a KMS key nobody can use any more. The cheapest
second copy is the state itself, pulled before any risky operation:

```
ana@laptop:~/aws/tf7/shop$ terraform state pull > state-2026-10-16.json && wc -c state-2026-10-16.json
8404 state-2026-10-16.json
```

`terraform state pull` prints the current state, whatever backend holds it. **Keep that file as
carefully as the bucket**: it holds the same secrets, so it belongs in encrypted storage, never in the
repository. `terraform state push` puts a copy back, and it refuses one whose serial is older than
the state already there unless forced, which is the protection against pushing yesterday's copy over
today's work.
