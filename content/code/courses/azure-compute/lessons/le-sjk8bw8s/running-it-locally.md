---
title: Running it on the laptop, with Azurite for storage
version: 1
---

The app runs as two containers on one Docker network: **Azurite, standing in for the storage
account, and the function app built from the four files**. The app finds Azurite by its container
name, as it would find a storage account by its address, and your terminal reaches both through
ports published on the laptop. Everything in this section is practised, and the setup is the one
lessons 16 and 17 start from, so it is worth keeping the files.

## The two images

Both come from Microsoft's registry. The Functions image is large, about 770 MB to download and 2.8
GB once unpacked, because it carries the host, the Python worker and an extension bundle:

```sh
docker pull mcr.microsoft.com/azure-storage/azurite:3.37.0
docker pull mcr.microsoft.com/azure-functions/python:4-python3.12
```

Both were already on the machine these transcripts were recorded on.

## Two connection strings to one emulator

Azurite accepts one account out of the box, `devstoreaccount1`, with one key. **That key is printed
in Microsoft's documentation and is the same in every copy of Azurite. It is not a secret, and the
strings below send it to the emulator and nowhere else.** It is safe to write in a file, which is
what this one is for. Save it as `~/azure/storage.sh`:

```sh
# storage.sh
# Azurite's development account: a published key, not a secret
KEY='Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw=='
ACCOUNT="DefaultEndpointsProtocol=http;AccountName=devstoreaccount1;AccountKey=$KEY"
# for the function app, inside the Docker network
export FN_STORAGE="$ACCOUNT;BlobEndpoint=http://azurite:10000/devstoreaccount1;QueueEndpoint=http://azurite:10001/devstoreaccount1;TableEndpoint=http://azurite:10002/devstoreaccount1;"
# for az storage, on the laptop
export AZURE_STORAGE_CONNECTION_STRING="$ACCOUNT;BlobEndpoint=http://127.0.0.1:10000/devstoreaccount1;QueueEndpoint=http://127.0.0.1:10001/devstoreaccount1;TableEndpoint=http://127.0.0.1:10002/devstoreaccount1;"
```

The two strings differ only in where the services are. Port 10000 is blobs, 10001 queues and 10002
tables, and the app needs all three: the host uses blobs for its own state, this lesson's functions
use a queue and blobs, and lesson 17 uses tables. Inside the network the address is the container's
name, `azurite`; from your terminal it is `127.0.0.1`. `AZURE_STORAGE_CONNECTION_STRING` is the
variable `az storage` reads when no account is named on its command line, **so the Azure CLI, with
no login, can read and write the emulator's queues and blobs**. It is the CLI's data plane, talking
to Azurite, and none of it reaches Azure.

`source storage.sh` in every terminal that works with the function app, after the four lines lesson
1 put at the start of every terminal.

## Starting it

```
ana@laptop:~/azure$ source storage.sh
ana@laptop:~/azure$ docker network create functions
3d376dcbec7ec84e8052ab6d4235865a5fd71331faed7208b9a7077c76351384
ana@laptop:~/azure$ docker run -d --name azurite --network functions -p 10000-10002:10000-10002 mcr.microsoft.com/azure-storage/azurite:3.37.0
f331f706299a2cbc98fd47925e64341ee64b4507c1e90b3fe0d580ada928fae0
ana@laptop:~/azure$ docker build -q -t shopfn:1 shopfn
sha256:309dd51b2c36fe562acda7c37b056a48611cb6acade93dff524cfcbbd6bcd27d
ana@laptop:~/azure$ docker run -d --name shopfn --network functions -p 8080:80 -e AzureWebJobsStorage="$FN_STORAGE" shopfn:1
b07ba9e36af6b449b8b4288c778910d271a1ce8d5d3d9b86bd6c7c43c8586fcf
```

The network is named `functions` and both containers join it. Azurite publishes its three ports on
the laptop. The build prints the new image's id. The app's container publishes its port 80, which is
the port the Functions image listens on, as port 8080 on the laptop, and it gets one setting,
`AzureWebJobsStorage`, pointing at Azurite. The host takes a few seconds to start; when it is ready
its log says what it found:

```
ana@laptop:~/azure$ docker logs shopfn 2>&1 | grep -A1 "Found the following functions"
      Found the following functions:
      Host.Functions.take_order
ana@laptop:~/azure$ docker logs shopfn 2>&1 | grep "Mapped function route"
      Mapped function route 'api/orders' [POST] to 'take_order'
```

**One function, and one route, `api/orders`, taken for `POST` only.** The `api/` in front is the
host's route prefix, the same for every HTTP function in an app unless `host.json` changes it. A
request now reaches the function:

```
ana@laptop:~/azure$ curl -s -XPOST localhost:8080/api/orders -d '{"order": "A-1001", "sku": "mug", "qty": 2}'
{"received": "A-1001"}
ana@laptop:~/azure$ docker logs shopfn 2>&1 | grep -A1 -E '^info: Function\.'
info: Function.take_order[1]
      Executing 'Functions.take_order' (Reason='This function was programmatically called via the host APIs.', Id=f55efa35-8e2c-47b9-828b-e5d6a4d816f5)
info: Function.take_order.User[0]
      order A-1001 for 2 x mug
info: Function.take_order[2]
      Executed 'Functions.take_order' (Succeeded, Id=f55efa35-8e2c-47b9-828b-e5d6a4d816f5, Duration=117ms)
```

Each run of a function is two lines in the host's log, `Executing` and `Executed`, with the
function's own `logging` line between them under the category `Function.take_order.User`. The
reason, "programmatically called via the host APIs", is how the host describes every HTTP call, and
the id and the duration differ on every run.

## Two processes in one container

```
ana@laptop:~/azure$ docker exec shopfn ps -eo pid,args | cut -c1-125
    PID COMMAND
      1 bash /opt/startup/start_nonappservice.sh
     10 /azure-functions-host/Microsoft.Azure.WebJobs.Script.WebHost
     74 python -X no_debug_ranges /azure-functions-host/workers/python/3.12/LINUX/X64/worker.py --host 127.0.0.1 --port 43513
    100 ps -eo pid,args
```

Under the start-up script are the host, `Microsoft.Azure.WebJobs.Script.WebHost`, and the Python
worker it started, told on its command line where to reach the host: a port on `127.0.0.1`, inside
the container. It is the split drawn in the previous section, and what the worker reads is only what
the host sends it. The process ids and the port differ on every start.

## What the host wrote before any function ran

Nothing in `take_order` touches storage, and the storage account already has something in it:

```
ana@laptop:~/azure$ az storage container list --query "[].name" -o tsv
azure-webjobs-hosts
ana@laptop:~/azure$ az storage blob list -c azure-webjobs-hosts --only-show-errors --query "[].name" -o tsv
locks/b07ba9e36af6-2137340777/host
```

`azure-webjobs-hosts` is the host's container, and `locks/…/host` is the blob it holds a lease on.
The path carries the host's id, which on the laptop begins with the container's id, so every new
container takes a lease of its own. In Azure the id is made from the function app's name, every
instance of the app shares it, and the lease is how they agree on which one runs what must run once,
such as a timer trigger. **The storage account is part of the app even when no function uses it**,
and the documentation is blunt about the setting: "Your function app can't start without this
connection setting."

`--only-show-errors` on the second command silences a warning the CLI prints for command groups it
calls preview; the later transcripts carry it for the same reason.

## The same image in Azure, not run here

Deploying the app is not run in this course: it needs a subscription. Microsoft's documentation
describes it in three steps. Push the image to a registry, which lesson 10 did for the shop's image.
Create a storage account for `AzureWebJobsStorage`. Then create the function app with `--image`
naming the image:

```sh
az functionapp create --name shop-fn --resource-group shop-rg --storage-account shopfnstore --plan shop-premium --image shopregistry.azurecr.io/shopfn:1 --functions-version 4
```

`--plan` names an existing plan, and the plan is where the hosting choice is made. The CLI's help
lists the other ways to say where an app runs, and that help is real on the laptop:

```
ana@laptop:~/azure$ az functionapp create --help | grep -E '^    --(image|plan|flexconsumption-location|consumption-plan-location|environment) '
    --consumption-plan-location -c                 : Geographic location where function app will be
    --environment                        [Preview] : Name of the container app environment.
    --flexconsumption-location -f                  : Geographic location where function app will be
    --image -i                                     : Container image, e.g. publisher/image-name:tag.
    --plan -p                                      : Name or resource id of the functionapp app
```

**Not all of them take a container.** The documentation's table of hosting options
says a container runs on the Premium plan, on a Dedicated (App Service) plan, and on Container Apps,
through `--environment`; the Flex Consumption plan and the Consumption plan take code only: the same
files without the `Dockerfile`, deployed as a package. Lesson 16 is about what each plan does to the
start of a function. Whichever it is, the settings this section passed with `-e` become application
settings of the app, and Azure sends requests to port 80 of the container unless the setting
`WEBSITES_PORT` says otherwise.

Leave both containers running. The next section begins by sending this version something it cannot
read.
