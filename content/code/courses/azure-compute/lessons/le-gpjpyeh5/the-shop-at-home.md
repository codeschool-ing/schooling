---
title: "The shop, at home and then written down for Azure"
version: 1
---

The shop's order API is a Python program of under fifty lines in an image of its own, and from
this lesson on it is the workload of the course. **Container Instances in this lesson, Container
Apps in lesson 8, AKS in lesson 11 and App Service in lesson 18 all run this one image**, so it
is worth knowing what it does before any of them gets it. This section runs it with Docker, on
your laptop, and then describes the same container to Container Instances in the file Azure
reads. The first half is practised in full. The second half ends where a subscription would
begin.

## The program

It uses nothing outside Python's standard library, so the image needs nothing from PyPI. Make a
directory for it:

```sh
mkdir -p ~/azure/shop
```

and save this as `~/azure/shop/app.py`. The copy button takes the whole file without the notes:

```schooling-example
{"language": "python", "file": "app.py", "parts": [{"code": "# app.py\nimport json\nimport os\nimport socket\nimport time\nfrom http.server import BaseHTTPRequestHandler, ThreadingHTTPServer\n\n", "note": "The standard library and nothing else, so the image needs nothing from PyPI and builds the same anywhere. `ThreadingHTTPServer` answers each request on a thread of its own, so one slow caller does not hold up the next."}, {"code": "VERSION = os.environ.get('SHOP_VERSION', '1.0')\nPORT = int(os.environ.get('PORT', '8080'))\nSTARTED = time.time()\nORDERS = []\n\n\n", "note": "Everything that differs between one place and another comes from the environment: the version it reports and the port it listens on. The image stays the same and the settings change around it. `ORDERS` is a list in memory, on purpose: it is lost whenever the process stops, and section 04 shows that happen."}, {"code": "class Shop(BaseHTTPRequestHandler):\n    def answer(self, status, body):\n        data = json.dumps(body).encode()\n        self.send_response(status)\n        self.send_header('Content-Type', 'application/json')\n        self.send_header('Content-Length', str(len(data)))\n        self.end_headers()\n        self.wfile.write(data)\n\n", "note": "Every answer goes out the same way, as JSON with its length stated, so `curl` and a load balancer's health check read it alike."}, {"code": "    def do_GET(self):\n        if self.path == '/healthz':\n            self.answer(200, {'status': 'ok'})\n        elif self.path == '/version':\n            self.answer(200, {'version': VERSION, 'host': socket.gethostname(),\n                              'up_s': round(time.time() - STARTED, 1)})\n        elif self.path == '/orders':\n            self.answer(200, ORDERS)\n        else:\n            self.answer(404, {'error': 'no such page'})\n\n", "note": "Three pages. `/healthz` is for a machine asking whether the process is alive. `/version` says which copy answered, by its host name, and how many seconds it has been up, which lessons 8 and 18 lean on when two versions run at once. `/orders` lists what was posted."}, {"code": "    def do_POST(self):\n        if self.path != '/orders':\n            return self.answer(404, {'error': 'no such page'})\n        size = int(self.headers.get('Content-Length', 0))\n        order = json.loads(self.rfile.read(size) or b'{}')\n        order['id'] = len(ORDERS) + 1\n        ORDERS.append(order)\n        self.answer(201, order)\n\n", "note": "A new order is whatever JSON was sent, given the next number as its `id`, and answered with `201 Created`."}, {"code": "    def log_message(self, fmt, *args):\n        print(json.dumps({'path': self.path, 'status': args[1], 'version': VERSION}), flush=True)\n\n\n", "note": "The standard library logs each request to standard error in its own format. This replaces it with one JSON line on standard output, because standard output and standard error are all a container platform collects, and `flush=True` sends each line now instead of when a buffer fills."}, {"code": "if __name__ == '__main__':\n    print(json.dumps({'msg': 'listening', 'port': PORT, 'version': VERSION}), flush=True)\n    ThreadingHTTPServer(('0.0.0.0', PORT), Shop).serve_forever()\n", "note": "One line to say it started, then serve until stopped. `0.0.0.0` means every interface: a server listening on `127.0.0.1` inside a container cannot be reached from outside it, whatever port is published."}]}
```

And this as `~/azure/shop/Dockerfile`:

```dockerfile
# Dockerfile
FROM python:3.12-slim
WORKDIR /app
COPY app.py .
ENV PORT=8080
EXPOSE 8080
USER nobody
CMD ["python", "app.py"]
```

Seven lines, and two of them are decisions. `ENV PORT=8080` gives the program its default port,
and whatever starts the container can set `PORT` to something else without a new image.
**`USER nobody` means the process does not run as root**: a flaw in the program then hands an
attacker an account that owns nothing. Section 05 shows the one place in Container Instances where
that choice costs something.

## Built and run

The `docker` course built images like this one. `--quiet` keeps the build's progress off the
screen and prints only the new image's id, which differs on every machine:

```
ana@laptop:~/azure$ ls shop
Dockerfile
app.py
ana@laptop:~/azure$ docker build --quiet --tag shop:1.0 shop | cut -c1-19
sha256:d19c8b927c16
ana@laptop:~/azure$ docker image ls shop:1.0 --format "{{.Repository}}:{{.Tag}}  {{.Size}}"
shop:1.0  178MB
```

178 MB, nearly all of it Python and the slim Debian under it. Running it, with the container's port
8080 published on the laptop's:

```
ana@laptop:~/azure$ docker run -d --name shop -p 8080:8080 shop:1.0 | cut -c1-12
fd5ab8c782d8
ana@laptop:~/azure$ curl -s -w '\n' localhost:8080/healthz
{"status": "ok"}
ana@laptop:~/azure$ curl -s -w '\n' localhost:8080/version
{"version": "1.0", "host": "fd5ab8c782d8", "up_s": 0.7}
ana@laptop:~/azure$ curl -s -w '\n' -X POST localhost:8080/orders -d '{"item": "coffee", "qty": 2}'
{"item": "coffee", "qty": 2, "id": 1}
ana@laptop:~/azure$ curl -s -w '\n' localhost:8080/orders
[{"item": "coffee", "qty": 2, "id": 1}]
ana@laptop:~/azure$ curl -s -o /dev/null -w '%{http_code}\n' localhost:8080/nothing
404
```

The four pages answered as `app.py` says they should. `/version` reports the version from the
environment, the host name, which inside a container is the container's short id, and the seconds
since the process started. The order came back with an `id`, and `/orders` lists it. A page that
does not exist is a 404. Each request left one line of JSON in the log, after the line the program
printed on starting:

```
ana@laptop:~/azure$ docker logs shop
{"msg": "listening", "port": 8080, "version": "1.0"}
{"path": "/healthz", "status": "200", "version": "1.0"}
{"path": "/version", "status": "200", "version": "1.0"}
{"path": "/orders", "status": "201", "version": "1.0"}
{"path": "/orders", "status": "200", "version": "1.0"}
{"path": "/nothing", "status": "404", "version": "1.0"}
```

**That log is the only window into the program, here and in Azure.** Container Instances keeps
what a container writes to standard output and standard error, and `az container logs` reads it
back, as `docker logs` did here. Section 05 says how little of it is kept.

## A second container, on the same localhost

The previous section said that containers in a group reach each other on `localhost`. Docker can
put two containers in that arrangement: `--network container:shop` starts a container inside the
network of an existing one instead of a network of its own. The shop's image has Python in it, so
it serves as the second container, asking the shop for its health exactly as a sidecar would:

```
ana@laptop:~/azure$ docker run --rm --network container:shop shop:1.0 python -c "import urllib.request; print(urllib.request.urlopen('http://localhost:8080/healthz').read().decode())"
{"status": "ok"}
ana@laptop:~/azure$ docker run --rm shop:1.0 python -c "import urllib.request; print(urllib.request.urlopen('http://localhost:8080/healthz').read().decode())" 2>&1 | tail -n 1
urllib.error.URLError: <urlopen error [Errno 111] Connection refused>
```

The first call reached the shop on `localhost:8080`. The second container, started without the
flag, has a `localhost` of its own, with nothing listening on it, and the connection was refused.
**A group in Container Instances is the first arrangement**, and Azure builds it for every
container in the group, with no flag to remember.

One more fact about the running container, which section 05 needs:

```
ana@laptop:~/azure$ docker exec shop id
uid=65534(nobody) gid=65534(nogroup) groups=65534(nogroup)
```

## Written down for Azure

Container Instances takes a group in two forms besides flags on `az container create`: a YAML file
and a Resource Manager template, written in Bicep or JSON. Microsoft recommends the YAML file
when the group is all you are deploying, and a template when other resources come with it, such as
a storage account for a file share. Here is the shop's group in YAML. Save it as
`~/azure/shop-aci.yaml`:

```schooling-example
{"language": "yaml", "file": "shop-aci.yaml", "parts": [{"code": "# shop-aci.yaml\napiVersion: '2021-10-01'\nlocation: brazilsouth\nname: shop\ntype: Microsoft.ContainerInstance/containerGroups\n", "note": "The resource type and the API version, the same pair lesson 1 met in a template. Microsoft documents the YAML format against API version `2021-10-01`. `name` is the group's name, and what every later `az container` command calls it by."}, {"code": "properties:\n  osType: Linux\n  restartPolicy: Always\n", "note": "Two settings that belong to the group and not to a container: the operating system every container in it runs, and the restart policy, which section 04 is about."}, {"code": "  containers:\n  - name: shop\n    properties:\n      image: shopregistry.azurecr.io/shop:1.0\n      environmentVariables:\n      - name: SHOP_VERSION\n        value: '1.0'\n", "note": "The containers, a list of one. The image has to be in a registry Azure can reach, and `shopregistry.azurecr.io` is a placeholder for the one lesson 10 creates. `'1.0'` is quoted so that YAML keeps it as text and does not read it as a number."}, {"code": "      ports:\n      - port: 8080\n      resources:\n        requests:\n          cpu: 1\n          memoryInGB: 1.5\n", "note": "The port the container listens on, and what it asks for: one CPU and 1.5 GB of memory. The request is the one size every container has to state."}, {"code": "  ipAddress:\n    type: Public\n    dnsNameLabel: shop-sp\n    ports:\n    - protocol: TCP\n      port: 8080\n", "note": "How the group is reached: a public address, the DNS label `shop-sp`, and 8080 opened on the group as well as on the container. A port written in only one of the two places is reachable through neither."}]}
```

Every line of it is something you just did by hand. The image is the one you built, once it is in
a registry. `SHOP_VERSION` is what `/version` reports. Port 8080 is what `-p 8080:8080` published,
and `shop-sp` is the name a customer types instead of `localhost`. The one setting Docker never
asked for is the size, and section 04 is about it.

**The image Azure runs must be built for `amd64`.** Container Instances runs x64 images only, and
Microsoft's documentation says an image built only for `arm64` may fail to start. On an Arm
laptop, which includes a Mac with Apple silicon, `docker build` makes an `arm64` image unless it is
told otherwise, with `--platform linux/amd64`. Lesson 10 builds and pushes the image Azure pulls.

Handing the file to Azure is one command, and it meets the same refusal as every command in this
course that needs a subscription:

```
ana@laptop:~/azure$ az container create --resource-group shop --file shop-aci.yaml
ERROR: Please run 'az login' to setup account.
```

## On a subscription

What follows was not run in this course: it needs a subscription. With one, the group goes into a
resource group, and the commands below create it, ask for its full DNS name and whether it was
provisioned, read its log, call it by that name and delete it, which asks you to confirm first. A
private registry also needs the group to prove who it is when it pulls, with the registry's
credentials or, better, a managed identity, from `azure-foundations` lesson 8.

```sh
az group create --name shop --location brazilsouth
az container create --resource-group shop --file shop-aci.yaml
az container show --resource-group shop --name shop --query "{FQDN:ipAddress.fqdn,ProvisioningState:provisioningState}" --output table
az container logs --resource-group shop --name shop
curl -s http://shop-sp.brazilsouth.azurecontainer.io:8080/version
az container delete --resource-group shop --name shop
```

The same group without a file is a single `az container create` with `--image`, `--cpu`,
`--memory`, `--ports 8080`, `--ip-address Public`, `--dns-name-label shop-sp` and
`--environment-variables SHOP_VERSION=1.0`. The file is what you keep in Git, and `az container
export` writes one from a group that already exists. On your laptop, the container is still
running; stop and remove it before the next section:

```sh
docker rm -f shop
```
