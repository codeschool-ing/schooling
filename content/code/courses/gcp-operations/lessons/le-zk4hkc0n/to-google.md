---
title: Sending it to Google, and to anybody else
version: 1
---

**Sending the shop's spans to Cloud Trace is a change to the Collector's file, and nothing else.** The
program stays as it is: it still sends OTLP to `localhost:4318`. The Collector's exporter changes from
`debug` to `googlecloud`, which writes traces to Cloud Trace (and metrics to Cloud Monitoring, logs to Cloud
Logging, in pipelines of their own). Write it into `~/gcp/collector-gcp.yaml`:

```yaml
# collector-gcp.yaml
receivers:
  otlp:
    protocols:
      http:
        endpoint: 0.0.0.0:4318

processors:
  batch:
    timeout: 2s
  resourcedetection:
    detectors: [gcp]

exporters:
  googlecloud:
    project: planner-dev

service:
  pipelines:
    traces:
      receivers: [otlp]
      processors: [resourcedetection, batch]
      exporters: [googlecloud]
```

The Collector checks a configuration without starting it:

```
ana@laptop:~/gcp$ docker run --rm -v "$PWD/collector-gcp.yaml":/c.yaml otel/opentelemetry-collector-contrib:0.137.0 validate --config=/c.yaml; echo "exit $?"
exit 0
```

**Exit 0 says the file is well formed**: every component exists in this build of the Collector, and every
key is one the component knows. A misspelled key fails it:

```
ana@laptop:~/gcp$ sed 's/googlecloud:/googlecloud:\n    projectt: x/' collector-gcp.yaml > bad.yaml
ana@laptop:~/gcp$ docker run --rm -v "$PWD/bad.yaml":/c.yaml otel/opentelemetry-collector-contrib:0.137.0 validate --config=/c.yaml 2>&1 | tail -3
'exporters' error reading configuration for "googlecloud": decoding failed due to the following error(s):

'' has invalid keys: projectt
```

What validation cannot say is whether Google would accept the spans: **the Collector was not started with this
file**, because the exporter would try to authenticate to Google and there is no account here. On Google
Cloud, the exporter finds its credentials the way lesson 5's provider did, through Application Default
Credentials, which on Cloud Run or GKE is the service account the Collector runs as; that account needs
`roles/cloudtrace.agent` to write traces. `resourcedetection` with the `gcp` detector reads the metadata server
there and adds the project, the region and the service to every span.

## Where the Collector runs

| on | how |
|---|---|
| Cloud Run | a sidecar container in the same service, receiving on `localhost:4318` |
| GKE | a DaemonSet (one per node) or a Deployment the services send to |
| Compute Engine | Google's Ops Agent, which is a Collector underneath, or the Collector itself |

## What portability buys, and what it does not

The code is portable: it speaks OTLP, and moving to another vendor is a new exporter in one file. The
**semantics are portable too**, because OpenTelemetry's semantic conventions name attributes the same way
everywhere (`http.request.method`, `server.address`). What is not portable is everything on the other side:
the dashboards, the alert policies and the SLOs of lessons 8, 13 and 14 are written against Cloud Monitoring and
would be rewritten for another vendor. OpenTelemetry moves the instrumentation, which is the expensive part to
redo in every service, and leaves the rest where it was.
