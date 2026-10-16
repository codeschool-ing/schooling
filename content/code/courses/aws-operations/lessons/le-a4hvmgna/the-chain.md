---
title: Three services and the bucket between them
version: 1
---

The common picture of AWS's delivery tools is one product that takes code and puts it in
production. **It is three, and they do not talk to each other directly.** CodePipeline knows the
order of the steps and nothing about building or deploying. CodeBuild runs commands in a fresh
container and knows nothing about what comes before or after. CodeDeploy moves traffic from one
version to the next, and is the subject of lesson 3. What joins them is a bucket.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Three boxes in a row: Source, Build run by CodeBuild, and Deploy run by ECS or CodeDeploy, under a band saying that CodePipeline knows the order of the steps and runs none of them. Below, an artifact bucket holds src.zip and image.zip: Source writes src.zip, Build reads it and writes image.zip, Deploy reads image.zip. Beside the bucket, an image registry, ECR: dashed arrows show the build pushing the image to it and the deploy pulling it.\"><defs><marker id=\"chn-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"16\" width=\"680\" height=\"32\" rx=\"3\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"360\" y=\"32\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\">CodePipeline knows the order of the steps and runs none of them</text><rect x=\"30\" y=\"76\" width=\"170\" height=\"62\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"115.0\" y=\"99.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Source</text><text x=\"115.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the commit, zipped</text><rect x=\"275\" y=\"76\" width=\"170\" height=\"62\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"99.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Build</text><text x=\"360.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">CodeBuild</text><rect x=\"520\" y=\"76\" width=\"170\" height=\"62\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"605.0\" y=\"99.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Deploy</text><text x=\"605.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">ECS / CodeDeploy</text><rect x=\"30\" y=\"180\" width=\"470\" height=\"76\" rx=\"3\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"44\" y=\"196\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\" font-weight=\"600\">artifact bucket</text><rect x=\"70\" y=\"212\" width=\"130\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"135.0\" y=\"227.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">src.zip</text><rect x=\"320\" y=\"212\" width=\"150\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"395.0\" y=\"227.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">image.zip</text><path d=\"M115 140 L125 210\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#chn-ah)\"></path><path d=\"M175 210 L300 140\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#chn-ah)\"></path><path d=\"M390 140 L395 210\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#chn-ah)\"></path><path d=\"M450 210 L560 140\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#chn-ah)\"></path><rect x=\"540\" y=\"196\" width=\"150\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"615.0\" y=\"211.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">image registry</text><text x=\"615.0\" y=\"227.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">ECR</text><path d=\"M430 140 L545 194\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#chn-ah)\"></path><path d=\"M640 194 L640 140\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#chn-ah)\"></path><text x=\"360\" y=\"280\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Solid: the artifacts in the bucket. Dashed: the image, pushed by the build and pulled at deploy.</text></svg>", "caption": "Nothing passes from one step to the next except a zip file in the bucket. The image travels separately, through the registry."}
```

## The pipeline passes files, not programs

Each action of a pipeline takes **input artifacts** and produces **output artifacts**, and an
artifact is a zip file in the pipeline's artifact bucket. The source action zips the commit and
writes it there as `src`. The build action is handed `src`, CodeBuild unpacks it into its
container, runs the build, and zips whatever the build named as its output into `image`. The deploy
action is handed `image`. **Nothing passes from one step to the next except what was written to the
bucket**, which has two consequences people meet late:

- a file the build produced and did not list as an artifact does not exist for the deploy step,
  however long the build worked on it;
- the bucket holds every version of every artifact of every run, and it is the bucket you clean up
  with a lifecycle rule, not the pipeline.

For a container service, what the build passes on is not the image. The image goes to a registry,
ECR in lesson 2; the artifact is a small file naming it, `imagedefinitions.json`, which the deploy
action reads to tell ECS which image to run.

## Each service acts as a role

None of the three acts with your permissions. Each one **assumes a role**: an identity in your
account whose trust policy names the service that may take it, and whose permissions say what it may
do once it has. `aws-foundations` lesson 9 is about roles; what matters here is that a pipeline
involves at least two of them, and that each is as narrow as its step.

| role | trusted by | needs, at least |
|---|---|---|
| the pipeline's | `codepipeline.amazonaws.com` | read and write the artifact bucket, start the build, start the deployment |
| the build's | `codebuild.amazonaws.com` | read and write the artifact bucket, write its logs, push to one repository |
| the deployment's | `codedeploy.amazonaws.com`, or ECS for the ECS action | change one service, read its load balancer |

A role that can do everything everywhere makes the pipeline easier to set up and turns the build,
which runs whatever is in the repository, into a way for anyone who can open a pull request to do
anything in the account. **The build's role is the one to keep small**, because it is the one
running code somebody else wrote.

## Where the chain starts

A pipeline starts on a change in its source. For code on GitHub or GitLab, the source action reads
the repository through a **connection** (the service is called CodeConnections) that somebody
authorises once in the console; for this course's lessons the source is an object in S3, which needs
no outside account. The bucket must keep versions, and a rule in EventBridge starts the pipeline
whenever a new version of the object is written.

Many teams keep the build and the tests in GitHub Actions or GitLab CI, which `iac` lesson 15 uses,
and hand only the deployment to AWS. The chain is the same three steps either way; what changes is
who holds the role that may change production, and that is the question to ask of any pipeline.
