---
title: The credentials a library finds
version: 1
---

**`publish.py` names no credential, and that is the design.** Every Google client library looks for
credentials in the same order, called **Application Default Credentials**, ADC, and takes the first it finds:

1. **`GOOGLE_APPLICATION_CREDENTIALS`**, an environment variable naming a credential file: lesson 9's
   federation file, or, where nothing better exists, a service account key, lesson 8;
2. **the file `gcloud auth application-default login` writes**, `application_default_credentials.json` in
   gcloud's directory, which is a person's own credential lent to the programs they run;
3. **the metadata server**, `169.254.169.254`, when the program runs on Google Cloud: a machine, a Cloud Run
   service, a function, each answering with a token for the service account attached to it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" data-fig=\"l24-adc\" aria-label=\"A program calls a client library, which looks for credentials in a fixed order and takes the first it finds. First, the environment variable GOOGLE_APPLICATION_CREDENTIALS naming a file, which in CI is a federation file and as a last resort a service account key. Second, the file that gcloud auth application-default login writes, which on a laptop is the person's own credential. Third, the metadata server at 169.254.169.254, which on Google Cloud answers for the attached service account. If none answers, the library raises DefaultCredentialsError, which is what the lab's laptop gets.\"><defs><marker id=\"l24-adc-af-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20.0\" y=\"90.0\" width=\"150.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"95.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a program</text><text x=\"95.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">publish.py</text><rect x=\"240.0\" y=\"20.0\" width=\"460.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"256.0\" y=\"38.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">1. GOOGLE_APPLICATION_CREDENTIALS</text><text x=\"256.0\" y=\"56.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">CI: a federation file</text><rect x=\"240.0\" y=\"82.0\" width=\"460.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"256.0\" y=\"100.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">2. application_default_credentials.json</text><text x=\"256.0\" y=\"118.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">a laptop: the person</text><rect x=\"240.0\" y=\"144.0\" width=\"460.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"256.0\" y=\"162.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">3. 169.254.169.254</text><text x=\"256.0\" y=\"180.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">Google Cloud: the attached account</text><path d=\"M172.0 110.0 L236.0 45.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l24-adc-af-ah-phosphor)\"></path><text x=\"470.0\" y=\"222.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">none answers: DefaultCredentialsError, as on the lab's laptop</text><text x=\"360.0\" y=\"246.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the first that answers is used; the program names none</text></svg>", "caption": "The library looks in three places, in order; where it runs decides what it finds."}
```

The same program therefore runs as the developer on a laptop, as the pipeline's federated identity in CI, and
as its own service account in production, without a line of it changing. **What changes is where it runs**,
and that is where the decision about its identity belongs.

## The emulator skips the question

`publish.py` worked in the previous section without any of the three: when `PUBSUB_EMULATOR_HOST` is set, the
Pub/Sub library sends no credentials at all, because the emulator checks none. Take the variable away, and the
same program asks ADC, finds nothing on the laptop, and says so:

```
ana@laptop:~/gcp$ env -u PUBSUB_EMULATOR_HOST python3 publish.py 2>&1 | tail -1
google.auth.exceptions.DefaultCredentialsError: Your default credentials were not found. To set up Application Default Credentials, see https://cloud.google.com/docs/authentication/external/set-up-adc for more information.
```

**`DefaultCredentialsError`**: none of the three answered. The laptop has no variable, no ADC file, and no
metadata server. That is the honest state of this lab, and the error a program first meets on any new machine.

## Pointing ADC at lesson 9's file

Lesson 9 wrote `~/gcp/federation/credentials.json`, the file a CI job uses to exchange its own token for
Google's. Name it in the variable, and ask the library what it finds, without making a request:

```
ana@laptop:~/gcp$ GOOGLE_APPLICATION_CREDENTIALS=~/gcp/federation/credentials.json python3 -c 'import google.auth; c, p = google.auth.default(); print(type(c).__module__, type(c).__name__, p)'
google.auth.identity_pool Credentials None
```

**`identity_pool` credentials, and no project**: the library recognised a workload identity federation file
and built the credential lesson 9 described. The project is `None` because a federated identity carries none,
which is why a program that relies on ADC should name its project, as `publish.py` does, rather than ask for
the default one. Now run the program with it, against Google:

```
ana@laptop:~/gcp$ env -u PUBSUB_EMULATOR_HOST GOOGLE_APPLICATION_CREDENTIALS=~/gcp/federation/credentials.json python3 publish.py 2>&1 | tail -1
google.auth.exceptions.RefreshError: File '/tmp/github-token' was not found.
```

The library followed the file's instructions to the first step and stopped there: the file says the CI
system's own token is in `/tmp/github-token`, and on a laptop there is none. In a GitHub Actions job that file
exists, the exchange of lesson 9 happens, and the program publishes as `deployer@`, with no key anywhere.

## Which to use where

| where the program runs | what ADC should find |
|---|---|
| a developer's laptop | the person's own credential, from `gcloud auth application-default login`, or impersonation of a service account |
| CI outside Google | a federation file, lesson 9 |
| on Google Cloud | the attached service account, through the metadata server; nothing to configure |
| anywhere, as a last resort | a service account key in `GOOGLE_APPLICATION_CREDENTIALS`, with lesson 8's warnings |
