---
title: Kubernetes, briefly
version: 1
---

**Kubernetes runs containers on a fleet of machines, and Spark is one more thing it runs.** YARN was
built for data jobs and grew to run other things; Kubernetes was built for services, the web servers
and queues of an application, and grew to run data jobs. An organisation that already runs everything
on Kubernetes would rather run Spark there too than keep a Hadoop cluster beside it for one kind of
work.

Its vocabulary, against lesson 12's:

| Kubernetes | what it is | the nearest thing in YARN |
|---|---|---|
| node | a machine that runs containers | a NodeManager's machine |
| pod | one or more containers started together, with a fixed share of memory and cores | a container |
| image | the files a container starts from, Java and Spark and your code included | the jars YARN ships to every container |
| namespace | a named partition of the cluster, with its own quota | a queue |
| ResourceQuota | the most memory and cores a namespace may use at once | a queue's maximum capacity |
| the API server | what every request goes through: start this pod, list those | the ResourceManager |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l13-k8s\" aria-label=\"Spark on Kubernetes. spark-submit asks the API server for a driver pod. The driver, once running, asks the API server for executor pods, in its namespace and within its quota, and sends them tasks. Every pod starts from the same Spark image and reads its data from an object store.\"><defs><marker id=\"st-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"st-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20.0\" y=\"30.0\" width=\"130.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"85.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">spark-submit</text><rect x=\"250.0\" y=\"24.0\" width=\"200.0\" height=\"62.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"350.0\" y=\"47.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">API server</text><text x=\"350.0\" y=\"64.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">every request goes through it</text><path d=\"M150.0 55.0 L248.0 55.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><rect x=\"20.0\" y=\"120.0\" width=\"520.0\" height=\"140.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"30.0\" y=\"250.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">namespace analysts, quota 2 cores, 3 GiB</text><rect x=\"40.0\" y=\"160.0\" width=\"140.0\" height=\"56.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"110.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">driver pod</text><rect x=\"220.0\" y=\"160.0\" width=\"92.0\" height=\"56.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"266.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">executor pod</text><rect x=\"324.0\" y=\"160.0\" width=\"92.0\" height=\"56.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"370.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">executor pod</text><rect x=\"428.0\" y=\"160.0\" width=\"92.0\" height=\"56.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"474.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">executor pod</text><path d=\"M110.0 160.0 L300.0 88.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#st-ah-amber)\"></path><text x=\"170.0\" y=\"104.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">asks for pods</text><text x=\"530.0\" y=\"250.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">image: Spark, Python, your code</text><rect x=\"570.0\" y=\"160.0\" width=\"130.0\" height=\"56.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"635.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">object store</text><path d=\"M540.0 188.0 L568.0 188.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path></svg>", "caption": "There is no Spark daemon on the cluster: the driver asks Kubernetes for its own executors."}
```

**Spark talks to the API server directly.** `spark-submit --master k8s://https://<api server>` asks
it for a driver pod; the driver, once running, asks it for executor pods, watches them and deletes them
when the application ends. There is no Spark daemon on the cluster and no ApplicationMaster; the
driver plays that part itself. What Kubernetes needs that YARN did not is an **image**: every pod
starts from one, so Spark, Python and the job's own libraries have to be built into a container image
and pushed where the cluster can pull it.

**The data is never on the nodes.** A pod's disk lives and dies with the pod, so a Spark job on
Kubernetes reads and writes an object store, lesson 3's other half, and keeps nothing between runs on
the machines that ran it.
