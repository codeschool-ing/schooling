---
title: Rules, and what decides compliance
version: 1
---

A **Config rule** looks at configuration items and says, for each resource in its scope, `COMPLIANT` or
`NON_COMPLIANT`. AWS writes several hundred **managed rules**, named by an identifier, and a team uses
them by name, with parameters where the rule takes any. Two for the shop's buckets: one that fails a
bucket readable by the public, and one that fails a bucket without an `owner` tag. The second takes its
parameter as a JSON string inside the JSON, which is easier to keep in a file.

`required-owner.json`:

```json
{
  "ConfigRuleName": "required-owner",
  "Source": { "Owner": "AWS", "SourceIdentifier": "REQUIRED_TAGS" },
  "InputParameters": "{\"tag1Key\":\"owner\"}",
  "Scope": { "ComplianceResourceTypes": ["AWS::S3::Bucket"] }
}
```

```
ana@laptop:~/aws/config$ aws configservice put-config-rule --config-rule '{"ConfigRuleName":"s3-public-read","Source":{"Owner":"AWS","SourceIdentifier":"S3_BUCKET_PUBLIC_READ_PROHIBITED"},"Scope":{"ComplianceResourceTypes":["AWS::S3::Bucket"]}}'
ana@laptop:~/aws/config$ aws configservice put-config-rule --config-rule file://required-owner.json
ana@laptop:~/aws/config$ aws configservice describe-config-rules --query 'ConfigRules[].[ConfigRuleName,Source.SourceIdentifier,ConfigRuleState]' --output text
required-owner	REQUIRED_TAGS	ACTIVE
s3-public-read	S3_BUCKET_PUBLIC_READ_PROHIBITED	ACTIVE
```

Both rules are `ACTIVE`. A rule is **triggered** in one of two ways. A rule triggered by a configuration change, as both of these
are, judges a bucket within minutes of its being changed. A periodic rule runs every one to twenty-four
hours, for things that are not a resource's configuration, such as whether CloudTrail is on in the
account.

moto knows the managed rules' names, and refuses one that does not exist, as AWS does:

```
ana@laptop:~/aws/config$ aws configservice put-config-rule --config-rule '{"ConfigRuleName":"tags","Source":{"Owner":"AWS","SourceIdentifier":"REQUIRED_TAG"}}' 2>&1 | tail -1
aws: [ERROR]: An error occurred (InvalidParameterValueException) when calling the PutConfigRule operation: The sourceIdentifier REQUIRED_TAG is invalid.  Please refer to the documentation for a list of valid sourceIdentifiers that can be used when AWS is the Owner
```

## The verdict, which the lab does not have

```
ana@laptop:~/aws/config$ aws configservice get-compliance-details-by-config-rule --config-rule-name required-owner 2>&1 | grep -m1 ERROR
aws: [ERROR]: An error occurred (500) when calling the GetComplianceDetailsByConfigRule operation (reached max retries: 2): <!doctype html>
```

**moto evaluates no rule.** On AWS, `get-compliance-details-by-config-rule` would list each bucket with its
result: `tmp-test-ana` non-compliant on `required-owner`, and each bucket with no public access block
evaluated by `s3-public-read` on its actual policy and ACLs. The results are also configuration-like
history: Config keeps when each resource became non-compliant and when it was fixed, which is the
evidence an auditor asks for, and the reason teams run Config rather than a script.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"A time line of three configuration items of the bucket shop-exports. First, discovered, with no owner tag and no public access block, judged NON_COMPLIANT. Then a tag added, owner=data, still with no block, still NON_COMPLIANT. Then the block turned on, all four settings on, judged COMPLIANT. On AWS the rule&#x27;s verdict on each item is kept as history beside it.\"><defs><marker id=\"hst-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M40 150 L690 150\" stroke=\"var(--wire)\" stroke-width=\"1.5\" fill=\"none\"></path><rect x=\"25\" y=\"52\" width=\"190\" height=\"64\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"120.0\" y=\"76.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">discovered</text><text x=\"120.0\" y=\"91.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">no owner, no block</text><path d=\"M120 118 L120 144\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"50\" y=\"162\" width=\"140\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"120.0\" y=\"177.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">NON_COMPLIANT</text><rect x=\"265\" y=\"52\" width=\"190\" height=\"64\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"76.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">tag added</text><text x=\"360.0\" y=\"91.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">owner=data, no block</text><path d=\"M360 118 L360 144\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"290\" y=\"162\" width=\"140\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"177.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">NON_COMPLIANT</text><rect x=\"505\" y=\"52\" width=\"190\" height=\"64\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"600.0\" y=\"76.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">block turned on</text><text x=\"600.0\" y=\"91.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">owner=data, all four on</text><path d=\"M600 118 L600 144\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"530\" y=\"162\" width=\"140\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"600.0\" y=\"177.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">COMPLIANT</text><text x=\"40\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">configuration items of shop-exports on AWS, oldest first; moto keeps only the latest</text><text x=\"40\" y=\"222\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the rule's verdict on each item; on AWS, kept as history beside it</text></svg>", "caption": "Every change is a new item, and every item gets a verdict: the history says when a resource became compliant, not only whether it is."}
```

What a rule decides from is the configuration item of the previous section, and nothing else. The next
section writes a rule by hand, to see that.
