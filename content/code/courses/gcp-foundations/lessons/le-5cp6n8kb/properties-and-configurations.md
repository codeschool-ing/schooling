---
title: Properties and configurations
version: 1
---

**Every setting gcloud has is a property, and a configuration is a named set of them.** `core/project`,
`compute/region`, `auth/access_token_file`: a section, a slash and a name. Lesson 1 set five of them, and they
have been in force in every lesson since, which is why no command in this course has had to say
`--project=planner-dev`. They live in the **active configuration**, which for this lab has always been the
one called `default`:

```
ana@laptop:~/gcp$ gcloud config list
[api_endpoint_overrides]
pubsub = http://localhost:8085/
[auth]
access_token_file = /home/ana/gcp/placeholder-token
[compute]
region = southamerica-east1
[core]
disable_usage_reporting = true
project = planner-dev

Your active configuration is: [default]
```

That is the lab exactly as lesson 1 left it: the project, the region, the placeholder token, and the override
that sends Pub/Sub to the emulator. **A configuration is a whole set**, and a second one starts empty.

## A second configuration

The planner's engineers work in development all day and in production rarely, and want the two never to be
confused. One configuration each does it. Create one for production without switching to it, give it its project, and list the two:

```
ana@laptop:~/gcp$ gcloud config configurations create prod --no-activate
Created [prod].
To use this configuration, activate it by running:
  $ gcloud config configurations activate prod


ana@laptop:~/gcp$ gcloud config set project planner-prod --configuration=prod
Updated property [core/project].
ana@laptop:~/gcp$ gcloud config configurations list
NAME     IS_ACTIVE  ACCOUNT  PROJECT       COMPUTE_DEFAULT_ZONE  COMPUTE_DEFAULT_REGION
default  True                planner-dev                         southamerica-east1
prod     False               planner-prod
```

`prod` has a project and nothing else: no account, no token, no override, which the next section runs into.
Each configuration is a small text file in the gcloud directory, which in this lab is `~/gcp/gcloud`, lesson 1's
`CLOUDSDK_CONFIG`:

```
ana@laptop:~/gcp$ ls ~/gcp/gcloud/configurations
config_default
config_prod
```

## Which value wins

A property can be given in four places, and **the most specific one wins**:

1. a **flag** on the command, such as `--project=planner-staging`;
2. an **environment variable** named after the property, `CLOUDSDK_CORE_PROJECT` for `core/project`;
3. the **configuration** the command runs with: the one named by `--configuration`, or by
   `CLOUDSDK_ACTIVE_CONFIG_NAME`, or the active one;
4. nothing, and the command asks or refuses.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" data-fig=\"l22-precedence\" aria-label=\"Where gcloud takes the value of core/project from, as four stacked layers, the most specific on top. A flag on the command, --project=planner-staging, wins over everything. Below it, an environment variable, CLOUDSDK_CORE_PROJECT. Below that, the configuration the command runs with, chosen by --configuration, by CLOUDSDK_ACTIVE_CONFIG_NAME or by being the active one: default holds planner-dev and prod holds planner-prod. At the bottom, nothing, where the command asks or refuses.\"><rect x=\"60.0\" y=\"20.0\" width=\"600.0\" height=\"42.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"80.0\" y=\"41.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">1. a flag</text><text x=\"640.0\" y=\"41.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">--project=planner-staging</text><rect x=\"80.0\" y=\"72.0\" width=\"560.0\" height=\"42.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"100.0\" y=\"93.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">2. an environment variable</text><text x=\"620.0\" y=\"93.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">CLOUDSDK_CORE_PROJECT</text><rect x=\"100.0\" y=\"124.0\" width=\"520.0\" height=\"42.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"120.0\" y=\"145.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">3. the configuration</text><text x=\"600.0\" y=\"145.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">default: planner-dev · prod: planner-prod</text><rect x=\"120.0\" y=\"176.0\" width=\"480.0\" height=\"42.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"140.0\" y=\"197.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">4. nothing</text><text x=\"580.0\" y=\"197.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">the command asks or refuses</text><text x=\"360.0\" y=\"238.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the first layer that holds a value wins</text><text x=\"360.0\" y=\"258.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">the configuration is chosen by --configuration, CLOUDSDK_ACTIVE_CONFIG_NAME, or being active</text></svg>", "caption": "The most specific place a property is set wins."}
```

Ask for the project four ways: from the active configuration, from another one, from a variable and from a
flag:

```
ana@laptop:~/gcp$ gcloud config get project
planner-dev
ana@laptop:~/gcp$ CLOUDSDK_ACTIVE_CONFIG_NAME=prod gcloud config get project
Your active configuration is: [prod]
planner-prod
ana@laptop:~/gcp$ CLOUDSDK_CORE_PROJECT=planner-staging gcloud config get project
planner-staging
ana@laptop:~/gcp$ gcloud config get project --project=planner-staging
planner-staging
```

**`CLOUDSDK_ACTIVE_CONFIG_NAME` chooses the configuration for one terminal**, or one command, without changing
which is active for every other terminal, and gcloud says on the error stream which one it is using. That is
the planner's habit: production is never the active configuration, and a terminal that works on production
says so in the variable it was opened with. A shell prompt that prints the variable makes the habit visible.
