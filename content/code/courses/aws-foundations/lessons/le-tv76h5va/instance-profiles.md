---
title: An instance profile, and the metadata service that hands it over
version: 1
---

**A machine on EC2 gets its permissions from a role, and the role reaches the machine inside an
instance profile.** Nobody copies a key onto the disk. The instance asks the metadata service, which
answers with temporary credentials for the role. The SDK at the bottom of the chain picks them up.
The shop's web servers read product photos from `shop-assets` this way, as the role `shop-app`.

The wrong picture is that a role is attached to an instance. **What is attached is an instance
profile**, a container that holds exactly one role. The console hides the difference: choosing a
role for an EC2 instance there creates a profile with the same name behind the scenes. The command
line makes you create both, and that is the clearest way to see that they are two things.

## A role that EC2 may wear

A role answers two questions, as lesson 9 showed. Its trust policy says who may assume it, and its
permission policies say what it may do. **For a machine, the principal in the trust policy is the
EC2 service itself.** Save this as `~/aws/trust-ec2.json`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {"Service": "ec2.amazonaws.com"},
      "Action": "sts:AssumeRole"
    }
  ]
}
```

Create the role, let it read S3 and nothing else, and put it into a profile:

```
ana@laptop:~/aws$ aws iam create-role --role-name shop-app --assume-role-policy-document file://trust-ec2.json --query Role.Arn --output text
arn:aws:iam::123456789012:role/shop-app
ana@laptop:~/aws$ aws iam attach-role-policy --role-name shop-app --policy-arn arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess
ana@laptop:~/aws$ aws iam create-instance-profile --instance-profile-name shop-app --query InstanceProfile.Arn --output text
arn:aws:iam::123456789012:instance-profile/shop-app
ana@laptop:~/aws$ aws iam add-role-to-instance-profile --instance-profile-name shop-app --role-name shop-app
ana@laptop:~/aws$ aws iam create-role --role-name shop-app-reports --assume-role-policy-document file://trust-ec2.json --query Role.Arn --output text
arn:aws:iam::123456789012:role/shop-app-reports
ana@laptop:~/aws$ aws iam add-role-to-instance-profile --instance-profile-name shop-app --role-name shop-app-reports

aws: [ERROR]: An error occurred (LimitExceeded) when calling the AddRoleToInstanceProfile operation: Cannot exceed quota for InstanceSessionsPerInstanceProfile: 1
```

The last command failed on purpose. **A profile holds one role, and moto enforces the limit**
exactly as AWS documents it. An instance that needs two sets of permissions needs one role whose
policies grant both.

## Launching a machine that wears it

`run-instances` takes the profile by name. The image is an Amazon Linux 2023 one from moto's own
catalogue, and the same id exists in every student's moto:

```
ana@laptop:~/aws$ aws ec2 run-instances --image-id ami-0629d059c178d0eac --instance-type t3.micro --iam-instance-profile Name=shop-app --metadata-options HttpTokens=required,HttpPutResponseHopLimit=1 --query "Instances[0].[InstanceId,IamInstanceProfile.Arn,MetadataOptions.[HttpTokens,HttpPutResponseHopLimit]]" --output text
i-0ee42130b0c3e009d	arn:aws:iam::123456789012:instance-profile/shop-app
required	1
ana@laptop:~/aws$ aws ec2 describe-iam-instance-profile-associations --query "IamInstanceProfileAssociations[].[InstanceId,IamInstanceProfile.Arn,State]" --output text
i-0ee42130b0c3e009d	arn:aws:iam::123456789012:instance-profile/shop-app	associated
```

**moto runs no machine.** It records an instance with an id, a state and a profile, and nothing
boots; there is no Linux behind `i-0ee42130b0c3e009d` to log into. Your id will differ from this
one. What moto does keep is the **association** between the instance and the profile. AWS keeps the
same record, and you can replace it on a running instance without stopping it.

On a real instance the rest happens without anybody. The SDK on the machine reaches the bottom of
the chain, asks `169.254.169.254` for `iam/security-credentials/`, gets `shop-app` back, reads the
credentials under that name and signs with them. When they near their expiry it asks again.

One more permission guards this, and it is easy to miss. **Whoever launches an instance with a
profile needs `iam:PassRole` on its role**, as well as `ec2:RunInstances`. Without that rule,
anybody allowed to start machines could start one wearing the most powerful role in the account.
They could then read its credentials from inside. A developer who may launch instances is given
`iam:PassRole` on `shop-app` and nothing wider.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 370\" role=\"img\" data-fig=\"l10-imds\" aria-label=\"Who gets an answer from the instance metadata service under IMDSv2. Inside an EC2 instance, the application sends a PUT for a token and the answer arrives, one hop away. A container behind a Docker bridge, also on the instance, asks too; with a hop limit of 1 the answer stops at the bridge, and with 2 it reaches the container. Outside the instance, a forged request from the internet makes the application send a plain GET, which carries no token and is refused with 401.\"><defs><marker id=\"l10-imds-af-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l10-imds-af-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20.0\" y=\"40.0\" width=\"450.0\" height=\"230.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"6 4\"></rect><text x=\"36.0\" y=\"58.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">an EC2 instance</text><rect x=\"50.0\" y=\"80.0\" width=\"170.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"135.0\" y=\"105.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">the application</text><rect x=\"250.0\" y=\"150.0\" width=\"200.0\" height=\"105.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"266.0\" y=\"166.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Docker bridge</text><rect x=\"275.0\" y=\"188.0\" width=\"150.0\" height=\"48.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"350.0\" y=\"212.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">a container</text><rect x=\"580.0\" y=\"80.0\" width=\"120.0\" height=\"175.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"640.0\" y=\"142.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">metadata</text><text x=\"640.0\" y=\"157.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">service</text><text x=\"640.0\" y=\"185.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">169.254.169.254</text><path d=\"M222.0 97.0 L577.0 97.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l10-imds-af-ah-phosphor)\" marker-start=\"url(#l10-imds-af-ah-phosphor)\"></path><text x=\"345.0\" y=\"86.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">PUT for a token: answered, one hop</text><path d=\"M577.0 212.0 L453.0 212.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l10-imds-af-ah-amber)\"></path><text x=\"515.0\" y=\"185.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">hop limit 1:</text><text x=\"515.0\" y=\"198.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">stops here</text><text x=\"515.0\" y=\"232.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">limit 2: through</text><rect x=\"50.0\" y=\"305.0\" width=\"170.0\" height=\"46.0\" rx=\"22\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"135.0\" y=\"328.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">a forged request</text><path d=\"M135.0 303.0 L135.0 133.0\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l10-imds-af-ah-amber)\"></path><text x=\"145.0\" y=\"290.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">from the internet</text><path d=\"M222.0 118.0 L577.0 118.0\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"5 3\" marker-end=\"url(#l10-imds-af-ah-amber)\"></path><text x=\"345.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">a plain GET, no token: 401</text></svg>", "caption": "IMDSv2 answers the instance's own processes, and nothing a hop further away or without the PUT."}
```

## IMDSv2, and what it defends against

The metadata service answers anything that can open a connection from inside the instance, the
application included. **The danger is a server-side request forgery, SSRF**: an application that
fetches an address a user supplies, such as a picture to preview or a webhook to call. A stranger
can hand it the metadata address instead. Under IMDSv1 that is a single `GET`, and the credentials
come back in the response to whoever sent the address. A public breach in 2019 went through exactly
that path. It ran from a misconfigured firewall in front of an application to the role of the
machine behind it.

**IMDSv2 closes the common forms of that hole with three rules**, all from AWS's documentation:

- reading anything needs a token, and the token comes only from a `PUT` with a custom header, which
  a request forged through a URL parameter cannot usually send;
- a `PUT` that carries an `X-Forwarded-For` header gets no token, so a proxy on the machine that
  forwards requests does not forward this one;
- the token's answer leaves with an IP time-to-live equal to the **hop limit**, 1 by default, so it
  dies after one hop and never reaches anything behind another network device.

`HttpTokens=required` is what turns IMDSv1 off, and the launch above set it. Here moto's imitation
stops. **moto records the setting and does not enforce it**: its metadata service still answers a
plain `GET` with no token, where AWS would answer `401 Unauthorized`.

```
ana@laptop:~/aws$ curl -s -o /dev/null -w "%{http_code}\n" http://localhost:4567/latest/meta-data/iam/security-credentials/
200
```

AWS's own images now ask for IMDSv2 themselves. **Amazon Linux 2023 images carry `ImdsSupport` set
to `v2.0`.** An instance launched from one requires tokens even when the launch says nothing. moto's
copy of the image does not carry the field:

```
ana@laptop:~/aws$ aws ec2 describe-images --image-ids ami-0629d059c178d0eac --query "Images[0].[Name,ImdsSupport]" --output text
al2023-ami-2023.12.20260727.0-kernel-6.12-x86_64	None
```

An account can also set the default for every new instance in a region with
`aws ec2 modify-instance-metadata-defaults --http-tokens required`. **That one was not run**: moto
5.2.3 answers its companion `get-instance-metadata-defaults` with an internal error, so this course
describes it from AWS's documentation.

## The hop limit, and containers

A hop limit of 1 means the instance's own processes get a token and nothing beyond them does. **A
container on Docker's default bridge network is one hop further away.** On a machine whose
containers should use the instance's role, AWS's documentation recommends a limit of 2. Put your own
instance's id in place of this one:

```
ana@laptop:~/aws$ aws ec2 modify-instance-metadata-options --instance-id i-0ee42130b0c3e009d --http-tokens required --http-put-response-hop-limit 2
{
    "InstanceId": "i-0ee42130b0c3e009d",
    "InstanceMetadataOptions": {
        "State": "applied",
        "HttpTokens": "required",
        "HttpPutResponseHopLimit": 2
    }
}
```

The opposite case is just as common. On an EKS node, the instance's role is the node's own, with the
permissions the node needs to join the cluster and pull images. **A pod that could read it would
hold the node's permissions.** That is why EKS's guidance keeps the limit at 1 on its nodes and
gives each pod a role of its own instead. That is the next section.
