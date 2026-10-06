---
title: One file, two objects
version: 1
---

**A first manifest is usually copied from somewhere and edited until it works, which leaves the
reader unsure which lines matter.** Nearly all of them do. This one holds the two objects every web
application on Kubernetes starts with: a Deployment, which keeps copies of the shop running, and a
Service, which gives those copies one address. Read it a piece at a time:

```schooling-example
{"language": "yaml", "file": "shop.yaml", "parts": [{"code": "apiVersion: apps/v1\nkind: Deployment\nmetadata:\n  name: shop\n  labels:\n    app: shop\n", "note": "**What the object is and what it is called**: a Deployment, from the `apps/v1` API, named `shop`. The label on the Deployment itself is only for finding it."}, {"code": "spec:\n  replicas: 3\n", "note": "**How many copies should exist.** This is the number the loop of lesson 1 keeps true."}, {"code": "  selector:\n    matchLabels:\n      app: shop\n", "note": "**Which pods count as this Deployment's.** The selector has to match the template's labels below, or the API server refuses the object."}, {"code": "  template:\n    metadata:\n      labels:\n        app: shop\n", "note": "**The pod to make copies of.** Every copy gets these labels, which is how the selector and, later, the Service find it."}, {"code": "    spec:\n      containers:\n      - name: shop\n        image: shop:1.0\n        ports:\n        - containerPort: 8080\n", "note": "**The container inside each pod**: the image and the port it listens on. `containerPort` documents the port; it does not open or publish anything."}, {"code": "---\n"}, {"code": "apiVersion: v1\nkind: Service\nmetadata:\n  name: shop\n", "note": "**A second object in the same file**, separated by `---`: a Service, also named `shop`. Objects of different kinds may share a name."}, {"code": "spec:\n  selector:\n    app: shop\n", "note": "**The same label again.** Every pod carrying `app: shop` is behind this Service, whoever made it."}, {"code": "  ports:\n  - port: 80\n    targetPort: 8080\n", "note": "**Port 80 on the Service's address leads to port 8080 on a pod.** Clients use 80; the shop never has to know."}]}
```

Three things in it are worth fixing in your memory now, because every later lesson relies on them.

**The labels are the glue.** `app: shop` appears four times, and none of them is decoration. The
template stamps it on every pod; the Deployment's selector uses it to count its pods; the Service's
selector uses it to find where to send traffic. Change it in one place and not the others, and the
Deployment stops recognising its own pods, or the Service has nowhere to send a request.

**Nothing here names a node, an address or a pod.** The file says what should exist and leaves
where and which to the cluster. That is why the same file runs unchanged on the laptop, on a managed
cluster and on the next cluster somebody builds.

**Two numbers that look alike are not the same port.** `8080` is where the shop listens inside its
container, and `80` is what the Service offers to clients. `targetPort` joins them. A client never
learns the 8080, so the shop could move to another port with one edit to this file and nobody
calling it would notice.

The file is ordinary YAML, and three details trip people up on their first one. Indentation is
structure, so two spaces in the wrong place silently move a field into a different object. A list
item begins with `-`, which is why `containers` and `ports` have dashes and `selector` does not. And
`---` on its own line separates documents, so one file can hold any number of objects, applied
together in the order they appear.
