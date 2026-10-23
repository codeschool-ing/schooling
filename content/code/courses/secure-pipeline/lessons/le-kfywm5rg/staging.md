---
title: Staging, made for one run and thrown away
version: 1
---

"Staging" usually names a server: a long-lived copy of production that a team deploys to before
the real thing, shared by everybody, with whatever data the last person left in it. A scan pointed
at that server measures the server's state on the day, which includes other people's half-finished
deployments. **The staging this pipeline uses is made for one run and deleted when the run ends.**
It is a Docker network of its own, the image the run just built, and the scanner beside it on the
same network. Nothing else is on it, and nothing on it is reachable from the host.

### Why one per run

Each property of that arrangement removes a way for a scan to lie or to cause harm.

- **Nothing carries over.** The database starts empty every time, so a finding cannot depend on a
  link somebody created during yesterday's run.
- **Two runs do not collide.** The network's name carries the process id of the script that made
  it, so two pipelines scanning at once each get their own.
- **Nothing is published.** The container's port is reachable on the private network and nowhere
  else: not on the host, not on the local network the laptop is on.
- **The scanner reaches only what is there.** Pointed at a name on that network, it can only scan
  the service the run built.
- **No real data is exposed.** A staging server loaded with a copy of production is a copy of
  production with weaker controls. This one holds nothing.

**The image is the one the pipeline ships.** The scan runs against `linkbox:<commit>`, started
the way the Dockerfile starts it, with gunicorn. Scanning the service under `flask run` on a
laptop would scan a different server, with different headers and different error pages, and its
findings would describe something nobody deploys.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" data-fig=\"sp-l04-staging\" aria-label=\"The staging environment of one pipeline run. Inside your machine, a Docker network named linkbox-staging followed by the process id holds two containers: the service, the image linkbox at the commit, listening on port 8000, and the scanner running zap-baseline.py. The scanner sends requests to the service and reads the answers. The network is made by ci/dast.sh when it starts and removed by its trap when it ends. Nothing is published on the host's port 8000, and with -silent the scanner calls nobody outside.\"><defs><marker id=\"sp-l04-staging-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"270\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"24\" y=\"28\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">your machine</text><rect x=\"30\" y=\"50\" width=\"470\" height=\"210\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"5 3\"></rect><text x=\"46\" y=\"68\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">network linkbox-staging-&lt;pid&gt;</text><rect x=\"60\" y=\"100\" width=\"180\" height=\"64\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"150.0\" y=\"124.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">the service</text><text x=\"150.0\" y=\"141.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">linkbox:&lt;commit&gt; :8000</text><rect x=\"300\" y=\"100\" width=\"170\" height=\"64\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"385.0\" y=\"124.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">the scanner</text><text x=\"385.0\" y=\"141.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">zap-baseline.py</text><path d=\"M298 122 L242 122\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l04-staging-ah-phosphor)\"></path><path d=\"M242 144 L298 144\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l04-staging-ah-phosphor)\"></path><text x=\"270\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">requests</text><text x=\"270\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">answers</text><text x=\"265\" y=\"220\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">made by ci/dast.sh when it starts, removed by its trap when it ends</text><rect x=\"515\" y=\"70\" width=\"185\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"607.5\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">127.0.0.1:8000</text><text x=\"607.5\" y=\"107.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">nothing published</text><rect x=\"515\" y=\"170\" width=\"185\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"607.5\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">outside</text><text x=\"607.5\" y=\"207.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">-silent: ZAP calls nobody</text></svg>", "caption": "Everything a scan touches is on one private network that exists for one run."}
```

### Building it by hand

The pipeline will do this in a script, in the next section but one. Doing it by hand first shows
each piece. Build the image from lesson 3's code; with no `CI_COMMIT` set, the build script tags it
`linkbox:dev`:

```
ana@vm:~$ cd linkbox
ana@vm:~/linkbox$ bash ci/build.sh
sha256:1b5f69ebcc9f7a8fa9f1d372415f9e0e1f2f1e6e909c5ec329d925c95f68691a
```

Make the network, start the service on it, and ask for the home page from a second container on
the same network. ZAP's image is already on the machine, and it carries `curl`, so it serves as
that second container. The last command asks the host's own port 8000, where nothing listens:

```
ana@vm:~/linkbox$ docker network create linkbox-staging
e7b3e89df325c4f551f2fb8f5ae3947501c01ec22a0894ae2ffea79e3b9d83f6
ana@vm:~/linkbox$ docker run -d --rm --name linkbox-app --network linkbox-staging linkbox:dev
a436665d429fea055e285f54252e300be9cf974618b262c9352196a8a2aae815
ana@vm:~/linkbox$ docker run --rm --network linkbox-staging zaproxy/zap-stable:2.17.0 curl -sI http://linkbox-app:8000/
HTTP/1.1 200 OK
Server: gunicorn
Date: Fri, 23 Oct 2026 04:46:42 GMT
Connection: close
Content-Type: text/html; charset=utf-8
Content-Length: 127

ana@vm:~/linkbox$ curl -sS http://127.0.0.1:8000/
curl: (7) Failed to connect to 127.0.0.1 port 8000 after 0 ms: Couldn't connect to server
```

The container answers by its name, `linkbox-app`, because Docker runs a name server on every
network a user creates; the default bridge network has no such names, which is one reason to make
a network rather than use the default one. The host gets nothing, because `docker run` published
no port.

**The response is the defect.** It names the server and it carries no `Content-Security-Policy`,
no `X-Frame-Options` and no `X-Content-Type-Options`. You could have found that with `curl` and a
list of headers to look for, and many teams start that way. The scanner in the next section does
the same reading with some sixty rules instead of three, and keeps doing it on every run.

### Two limits of this staging

A network created this way still routes its containers out to the internet by default.
`docker network create --internal` would close that, at the price of every container on it losing
any outside access it needs. This pipeline leaves the network ordinary and relies on the scanner's
own setting, in the next section, to keep it from calling anywhere.

And a staging this small cannot reproduce what sits in front of production: a reverse proxy, a
content delivery network, a load balancer, any of which can add a header or strip one. A scan of
staging says what the service sends. What the user's browser receives is a second question, and
answering it means scanning the production address with a scan that only reads, on purpose and
with the owner's agreement.
