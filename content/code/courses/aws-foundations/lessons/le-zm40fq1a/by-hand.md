---
title: The same shape by hand, and what it leaves out
version: 1
---

**Control Tower cannot be run in this lab, but the shape it builds can.** moto has no Control Tower:
the service answers every call with a failure, as the first command below shows. Most of what
Control Tower sets up, though, is Organizations underneath, and lessons 3 and 4 have already
driven Organizations by hand. This section puts those steps into one script, runs it against an
empty moto, and then says plainly which parts of a landing zone the script does not and cannot
build.

## What moto says

Restart moto in the first terminal (Ctrl+C, then `moto_server -p 4567`) so this lesson starts from
an empty AWS, and ask it for a landing zone:

```
ana@laptop:~/aws$ aws controltower list-landing-zones

aws: [ERROR]: An error occurred (500) when calling the ListLandingZones operation (reached max retries: 2): <!doctype html>
<html lang=en>
<title>500 Internal Server Error</title>
<h1>Internal Server Error</h1>
<p>The server encountered an internal error and was unable to complete your request. Either the server is overloaded or there is an error in the application.</p>
```

**A `500` is moto failing, not AWS answering.** The command exists in the AWS CLI and against an
account it lists the landing zone, if there is one; moto implements none of the service. So nothing
in this lesson about Control Tower itself was run.

## `landing-zone.sh`

The script builds the tree a Control Tower landing zone would start the shop with: the `Security`
OU with the two accounts that watch the others, the shop's own `Workloads` and `Sandbox` OUs, one
guardrail on the record, and the `security` account named as the administrator of GuardDuty for the
organisation. Paste the whole block into the second terminal; it writes the file:

```sh
cat > ~/aws/landing-zone.sh <<'EOF'
#!/usr/bin/env bash
# The shop's landing zone by hand: the shape Control Tower would build, in Organizations.
set -euo pipefail

aws organizations create-organization --query Organization.Id --output text
root=$(aws organizations list-roots --query "Roots[0].Id" --output text)
# AWS enables SCPs with the organisation; moto has to be asked (lessons 3 and 4)
scps=$(aws organizations list-roots \
  --query "Roots[0].PolicyTypes[?Type=='SERVICE_CONTROL_POLICY'].Status" --output text)
if [ "$scps" != ENABLED ]; then
  aws organizations enable-policy-type --root-id "$root" --policy-type SERVICE_CONTROL_POLICY > /dev/null
fi

ou() {  # PARENT NAME: create an OU, print its id
  aws organizations create-organizational-unit --parent-id "$1" --name "$2" \
    --query OrganizationalUnit.Id --output text
}
security=$(ou "$root" Security)
workloads=$(ou "$root" Workloads)
ou "$workloads" Prod > /dev/null
ou "$workloads" Staging > /dev/null
ou "$root" Sandbox > /dev/null

account() {  # NAME PARENT: create an account, wait for it, move it into PARENT
  local req state id
  req=$(aws organizations create-account --email "aws+$1@example.com" --account-name "$1" \
    --query CreateAccountStatus.Id --output text)
  while :; do
    state=$(aws organizations describe-create-account-status --create-account-request-id "$req" \
      --query CreateAccountStatus.State --output text)
    case $state in
      SUCCEEDED) break ;;
      FAILED) echo "creating $1 failed" >&2; exit 1 ;;
    esac
    sleep 10
  done
  id=$(aws organizations describe-create-account-status --create-account-request-id "$req" \
    --query CreateAccountStatus.AccountId --output text)
  aws organizations move-account --account-id "$id" --source-parent-id "$root" --destination-parent-id "$2"
  echo "$1 $id"
}
account log-archive "$security"
security_id=$(account security "$security" | cut -d' ' -f2)
echo "security $security_id"

# one guardrail on the record: nobody but the platform deletes the logs or stops a trail
policy=$(aws organizations create-policy --name protect-the-record --type SERVICE_CONTROL_POLICY \
  --description "Nobody deletes the shop's logs or stops a trail" --query Policy.PolicySummary.Id --output text \
  --content '{"Version": "2012-10-17", "Statement": [{"Effect": "Deny",
    "Action": ["s3:DeleteBucket", "s3:DeleteObject", "s3:PutLifecycleConfiguration", "s3:PutBucketPolicy",
               "cloudtrail:StopLogging", "cloudtrail:DeleteTrail"],
    "Resource": "*",
    "Condition": {"ArnNotLike": {"aws:PrincipalArn": "arn:aws:iam::*:role/OrganizationAccountAccessRole"}}}]}')
aws organizations attach-policy --policy-id "$policy" --target-id "$security"
echo "guardrail $policy on Security"

# the security account runs GuardDuty for the whole organisation
aws organizations enable-aws-service-access --service-principal guardduty.amazonaws.com
aws organizations register-delegated-administrator --account-id "$security_id" \
  --service-principal guardduty.amazonaws.com
echo "delegated administrator for GuardDuty: $security_id"
EOF
```

Four things in it are there because AWS is not moto. **The test before `enable-policy-type`** is
there because in AWS the type is already on, and asking again is an error,
`PolicyTypeAlreadyEnabledException`, which would stop the script. **The wait loop** exists because AWS creates
an account in the background, as lesson 2 said; in moto the first answer is already `SUCCEEDED`, so
the loop never sleeps. **`set -euo pipefail`** stops the script at the first command that fails,
so a half-built landing zone says so rather than carrying on. And the guardrail is lesson 4's pattern again: a deny with
`Resource` `*`, attached to `Security` rather than to the root, because inside `Security` there is
nothing anybody should delete. The role the management account comes in through is left out by
`aws:PrincipalArn`, since somebody has to be able to write the log bucket's policy in the first
place.

## Running it

```
ana@laptop:~/aws$ bash landing-zone.sh
o-vpkre95at2
log-archive 178477898891
security 028214792238
guardrail p-s645pgwp on Security
delegated administrator for GuardDuty: 028214792238
```

Then ask the organisation what it now holds:

```
ana@laptop:~/aws$ root=$(aws organizations list-roots --query "Roots[0].Id" --output text)
ana@laptop:~/aws$ aws organizations list-organizational-units-for-parent --parent-id $root --query "OrganizationalUnits[].[Id,Name]" --output text
ou-ucqy-2ezpckv1	Security
ou-ucqy-pubvas6q	Workloads
ou-ucqy-0tp6pz8a	Sandbox
ana@laptop:~/aws$ security=$(aws organizations list-organizational-units-for-parent --parent-id $root --query "OrganizationalUnits[?Name=='Security'].Id" --output text)
ana@laptop:~/aws$ aws organizations list-accounts-for-parent --parent-id $security --query "Accounts[].[Id,Name]" --output text
178477898891	log-archive
028214792238	security
ana@laptop:~/aws$ aws organizations list-policies-for-target --target-id $security --filter SERVICE_CONTROL_POLICY --query "Policies[].Name" --output text
FullAWSAccess	protect-the-record
ana@laptop:~/aws$ aws organizations list-delegated-administrators --query "DelegatedAdministrators[].[Id,Name]" --output text
028214792238	security
```

**This is the shape, and only the shape.** The OUs, the two accounts in `Security`, the guardrail
and the delegated administrator are all there, and in AWS every one of those commands would have
done the same. What a real landing zone also has is everything that lives **inside** the accounts,
and that is where the script stops.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 470\" role=\"img\" data-fig=\"l05-compare\" aria-label=\"The shop's landing zone, with what landing-zone.sh built in moto drawn solid and what Control Tower would add drawn dashed. Solid: the organisation and its SCPs in the management account; the OUs Security, Workloads and Sandbox; the accounts log-archive and security in Security; the guardrail protect-the-record on Security; security registered as GuardDuty's delegated administrator. Dashed, not run: Control Tower and Account Factory, IAM Identity Center, the organisation trail and the log bucket in log-archive, the Config aggregator in security, a Config recorder and the trail in every workload account, the controls of three kinds, and drift detection.\"><rect x=\"20.0\" y=\"20.0\" width=\"330.0\" height=\"150.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"36.0\" y=\"38.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">management account</text><rect x=\"36.0\" y=\"54.0\" width=\"298.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"185.0\" y=\"69.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the organisation, its OUs and SCPs</text><rect x=\"36.0\" y=\"92.0\" width=\"298.0\" height=\"30.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"185.0\" y=\"107.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">Control Tower and Account Factory</text><rect x=\"36.0\" y=\"130.0\" width=\"298.0\" height=\"30.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"185.0\" y=\"145.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">IAM Identity Center (lesson 11)</text><rect x=\"380.0\" y=\"20.0\" width=\"320.0\" height=\"150.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"540.0\" y=\"67.7\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">the controls, on every OU:</text><text x=\"540.0\" y=\"81.4\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">preventive (SCPs)</text><text x=\"540.0\" y=\"95.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">detective (Config rules)</text><text x=\"540.0\" y=\"108.7\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">proactive (CloudFormation hooks)</text><text x=\"540.0\" y=\"122.3\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">and drift detection</text><rect x=\"20.0\" y=\"200.0\" width=\"440.0\" height=\"220.0\" rx=\"10\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"36.0\" y=\"218.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Security</text><text x=\"444.0\" y=\"218.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">protect-the-record</text><rect x=\"36.0\" y=\"234.0\" width=\"196.0\" height=\"172.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"134.0\" y=\"250.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">log-archive</text><rect x=\"248.0\" y=\"234.0\" width=\"196.0\" height=\"172.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"346.0\" y=\"250.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">security</text><rect x=\"48.0\" y=\"266.0\" width=\"172.0\" height=\"48.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"134.0\" y=\"283.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">organisation trail</text><text x=\"134.0\" y=\"296.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">delivers here</text><rect x=\"48.0\" y=\"324.0\" width=\"172.0\" height=\"70.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"134.0\" y=\"346.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">the log bucket</text><text x=\"134.0\" y=\"359.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">for every account's</text><text x=\"134.0\" y=\"372.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">records</text><rect x=\"260.0\" y=\"266.0\" width=\"172.0\" height=\"48.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"346.0\" y=\"283.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">GuardDuty: delegated</text><text x=\"346.0\" y=\"296.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">administrator</text><rect x=\"260.0\" y=\"324.0\" width=\"172.0\" height=\"70.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"346.0\" y=\"346.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">Config aggregator</text><text x=\"346.0\" y=\"359.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">and the security</text><text x=\"346.0\" y=\"372.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">team's notifications</text><rect x=\"480.0\" y=\"200.0\" width=\"220.0\" height=\"120.0\" rx=\"10\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"496.0\" y=\"218.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Workloads</text><text x=\"684.0\" y=\"218.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Prod, Staging</text><rect x=\"494.0\" y=\"234.0\" width=\"192.0\" height=\"72.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"590.0\" y=\"257.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">in every account:</text><text x=\"590.0\" y=\"270.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">a Config recorder</text><text x=\"590.0\" y=\"283.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">and the trail</text><rect x=\"480.0\" y=\"340.0\" width=\"220.0\" height=\"80.0\" rx=\"10\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"496.0\" y=\"358.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Sandbox</text><rect x=\"494.0\" y=\"370.0\" width=\"192.0\" height=\"38.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"590.0\" y=\"389.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">the same, once accounts arrive</text><rect x=\"140.0\" y=\"438.0\" width=\"26.0\" height=\"16.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"174.0\" y=\"446.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">built by landing-zone.sh, in moto</text><rect x=\"420.0\" y=\"438.0\" width=\"26.0\" height=\"16.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"454.0\" y=\"446.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Control Tower adds; not run</text></svg>", "caption": "The script built the tree. Everything that lives inside the accounts is still dashed."}
```

## What the script leaves out

**No trail and no bucket.** The `log-archive` account holds nothing: a landing zone puts an
organisation trail into CloudTrail, whose records from every account land in a bucket there. The
script would have to take on a role in `log-archive`, create the bucket with a policy that lets
CloudTrail write to it, and create the trail from the management account; lesson 9 has the
cross-account part. **No Config**, and therefore no detective controls: nothing records what the
accounts contain. **No way in for people**: IAM Identity Center is lesson 11. **No detection of
drift**: the script runs once, and anything changed afterwards stays changed. And it takes no
decision about **root credentials** in the member accounts, which lesson 2 said the management
account can remove; a landing zone should settle that too.

**Not run here, for any of it**: Control Tower's setup, Account Factory, the controls it enables,
and its drift detection. Those are described from AWS's documentation in this lesson's two sections
before this one.

## The other ways to build it

Control Tower is the service AWS sells for this, and it is not the only way.

- **Account Factory for Terraform**, AFT, keeps Control Tower and replaces its account form with a
  Terraform pipeline: a new account is a file in a repository, reviewed and merged like code. The
  `iac` course teaches Terraform itself.
- **Landing Zone Accelerator on AWS** is a solution AWS publishes and supports, deployed into the
  management account, that builds a larger baseline from configuration files and works alongside
  Control Tower. It is aimed at organisations with strict compliance requirements.
- **Organizations and infrastructure as code, with no Control Tower at all**, which is
  `landing-zone.sh` grown up: the same calls, in Terraform or CloudFormation, with the trail, the
  bucket and Config added. It is more work and fewer surprises, and the company owns every part.

Whichever is chosen, **the test of a landing zone is the next account**. If `shop-analytics` were
created tomorrow, would it arrive in its OU, under its guardrails, logging to `log-archive` and
watched from `security`, with nobody having to remember anything? A script that only ever ran once
does not answer that; a factory does.
