---
title: Your lab, in brief
version: 1
---

**This course is practised against Microsoft's own emulators, on your own computer, with the real
Azure command line and no Azure account.** It is the environment the four Azure courses share, and
lesson 1 of `azure-foundations` builds its common part step by step: the command line, Docker,
Azurite and Terraform. If you did that lesson and kept the lab, read only "Three more, for this
course" and "Every time you open a terminal" below. If you did not, the steps are here in brief. The
platform runs nothing for you: no machine, no shell in the browser, no account.

**Ubuntu 24.04 is where every transcript was recorded**, and there are three ways to have it.
Installed is the one recommended, either as your system or under WSL on Windows (`wsl --install -d
Ubuntu-24.04` in an administrator PowerShell, and Docker installed inside Ubuntu as below). A virtual
machine is the path on a Mac: Ubuntu Server 24.04 in UTM, VirtualBox or Multipass, with 4 processors,
8 GB of memory and 40 GB of disk, because SQL Server alone asks for 2 GB of memory. An online shell
rented by the hour works too, as long as it lets you run Docker, but no lesson depends on any
company's free allowance. On your own disk the whole lab comes to about 7 GB, most of it the
container images, and nothing in it runs unless you start it.

## The packages from Ubuntu

```sh
sudo apt-get update
sudo apt-get install -y docker.io docker-compose-v2 python3 python3-venv curl unzip jq
sudo usermod -aG docker "$USER"
```

The last line lets you run `docker` without `sudo`. It takes effect at your next login, so log out
and back in once before going on.

## The Azure command line

Version 2.91.0, from the Python package index, into a directory of its own so that nothing else you
install can disturb it:

```sh
mkdir -p ~/azure ~/.local/bin
python3 -m venv ~/.local/azure-cli
~/.local/azure-cli/bin/pip install -q azure-cli==2.91.0
ln -sf ~/.local/azure-cli/bin/az ~/.local/bin/az
```

It takes a few minutes and about 700 MB. **The command line is the same program that manages a real
subscription**; here it will only ever talk to the emulators, because every command this course
gives it names the emulator's address.

## Terraform

Version 1.17.1, as one file. The second half tells Terraform to keep the providers it downloads in
one shared cache, so that each lesson's directory does not download the 250 MB Azure provider again:

```sh
cd ~/azure
curl -sSfO https://releases.hashicorp.com/terraform/1.17.1/terraform_1.17.1_linux_amd64.zip
unzip -oq terraform_1.17.1_linux_amd64.zip terraform -d ~/.local/bin
rm terraform_1.17.1_linux_amd64.zip
mkdir -p ~/.terraform.d/plugin-cache
printf 'plugin_cache_dir = "%s/.terraform.d/plugin-cache"\n' "$HOME" > ~/.terraformrc
```

On an Arm processor, which includes a virtual machine on a Mac with Apple silicon, the file is
`terraform_1.17.1_linux_arm64.zip`. **Terraform never creates anything in this course.** It reads
the files that would declare a storage account or a database and says whether Azure's provider
accepts them, which is the one question about the control plane that can be answered without an
account.

## Three more, for this course

**This is the part `azure-foundations` does not have.** First, the Python libraries the lessons'
programs use: Microsoft's software development kits for Blob Storage, Cosmos DB and Event Hubs, and
three for the analytics lessons. DuckDB is a database engine that lives inside a Python program,
PyArrow reads and writes Parquet, and `deltalake` reads and writes Delta tables:

```sh
python3 -m venv ~/azure/venv
~/azure/venv/bin/pip install -q azure-storage-blob==12.30.0 azure-cosmos==4.17.1 \
  azure-eventhub==5.15.1 azure-eventhub-checkpointstoreblob==1.2.0 \
  duckdb==2.0.0 pyarrow==26.0.0 deltalake==1.6.6
```

**Blob Storage's library is one version behind on purpose.** Each release of it speaks the newest
version of the storage protocol, and Azurite 3.37.0 understands versions up to `2026-06-06`, which is
what 12.30.0 speaks. The release after it asks for a newer one and Azurite refuses every request.

Second, one file that names every emulator the course uses and how to start it. Save this as
`compose.yaml`, in `~/azure`:

`compose.yaml`:

```yaml
name: azure
services:
  azurite:
    image: mcr.microsoft.com/azure-storage/azurite:3.37.0
    command: >-
      azurite --blobHost 0.0.0.0 --queueHost 0.0.0.0 --tableHost 0.0.0.0
      --inMemoryPersistence --disableTelemetry
    ports:
      - "127.0.0.1:10000-10002:10000-10002"

  cosmos:
    image: mcr.microsoft.com/cosmosdb/linux/azure-cosmos-emulator:vnext-EN20261019
    command: --protocol http
    ports:
      - "127.0.0.1:8081:8081"
    profiles: [cosmos]

  sql:
    image: mcr.microsoft.com/mssql/server:2025-CU9-ubuntu-24.04
    environment:
      ACCEPT_EULA: "Y"
      MSSQL_SA_PASSWORD: "Quitanda-Lab-2026"
      MSSQL_AGENT_ENABLED: "true"
    ports:
      - "127.0.0.1:1433:1433"
    profiles: [sql]

  eventhubs:
    image: mcr.microsoft.com/azure-messaging/eventhubs-emulator:2.2.1
    environment:
      ACCEPT_EULA: "Y"
      BLOB_SERVER: azurite
      METADATA_SERVER: azurite
    volumes:
      - ./eventhubs/config.json:/Eventhubs_Emulator/ConfigFiles/Config.json:ro
    ports:
      - "127.0.0.1:5672:5672"
    depends_on: [azurite]
    profiles: [eventhubs]

  postgres:
    image: postgres:17.6
    environment:
      POSTGRES_PASSWORD: "Quitanda-Lab-2026"
    ports:
      - "127.0.0.1:5432:5432"
    profiles: [postgres]

  redis:
    image: redis:8.2.2
    ports:
      - "127.0.0.1:6379:6379"
    profiles: [redis]
```

Every port is published on `127.0.0.1` only, so nothing on your network can reach the emulators,
and the password is a lab password that protects nothing. `--inMemoryPersistence` makes Azurite
forget everything when it stops, like the other emulators here. `--disableTelemetry` matters more
than it looks: without it Azurite reports its use to Microsoft over the internet. **A profile is a
group of services that only starts when asked for**, so a plain `docker compose up -d` starts
Azurite alone, and a lesson that needs Cosmos DB says `--profile cosmos`.

Third, the Event Hubs emulator reads the hubs it should create from a file. Save this as
`eventhubs/config.json`, also in `~/azure`:

`eventhubs/config.json`:

```json
{
  "UserConfig": {
    "NamespaceConfig": [
      {
        "Type": "EventHub",
        "Name": "emulatorNs1",
        "Entities": [
          {
            "Name": "clicks",
            "PartitionCount": 4,
            "ConsumerGroups": [{ "Name": "fraud" }]
          }
        ]
      }
    ],
    "LoggingConfig": { "Type": "File" }
  }
}
```

Then download every image once, so that no lesson waits for one:

```sh
docker compose --profile '*' pull
```

The images come to about 6 GB. SQL Server is published for Intel processors only; on a Mac with
Apple silicon, Docker Desktop runs it through its emulation layer, slowly but correctly.

## Starting what a lesson needs

Each part of the course names the emulators it uses, and you start them with one line in `~/azure`.
The storage lessons need Azurite alone:

```sh
docker compose up -d
```

**Stopping is `docker compose --profile '*' down`, and it forgets everything**: every container,
blob, document and event the emulators held. Each lesson starts from empty emulators and builds what
it needs, so you can stop at the end of a sitting and lose nothing a lesson does not rebuild.

## Every time you open a terminal

In the terminal you type into for the rest of the course:

```sh
cd ~/azure
export PATH="$HOME/.local/bin:$PATH" && source venv/bin/activate
export AZURE_STORAGE_CONNECTION_STRING="UseDevelopmentStorage=true"
export AZURE_CORE_COLLECT_TELEMETRY=false
```

The first line is where the course's files go. The second puts `az` and `terraform` on the path and
switches to the virtual environment. **The third is the whole trick**: every `az storage` command
reads that variable, and `UseDevelopmentStorage=true` is a short name the Azure libraries expand to
Azurite's address on `127.0.0.1` and its fixed, published account name and key. The fourth stops the
command line from reporting its own use to Microsoft, the same thing `--disableTelemetry` does for
Azurite.

## Check that it answers

```
ana@laptop:~/azure$ az version --query '"azure-cli"' -o tsv
2.91.0
ana@laptop:~/azure$ terraform version | head -1
Terraform v1.17.1
ana@laptop:~/azure$ docker compose ps --format '{{.Service}} {{.State}}'
azurite running
ana@laptop:~/azure$ az storage container list -o table

ana@laptop:~/azure$ az storage container create -n smoke-test
{
  "created": true
}
ana@laptop:~/azure$ az storage container list --query '[].name' -o tsv
smoke-test
ana@laptop:~/azure$ az storage account show-connection-string -n devstoreaccount1 2>&1 | tail -1
ERROR: Please run 'az login' to setup account.
```

**The empty first list is an empty Azurite, and the container that appears after it is the proof
the command line reached it.** The last command is the one worth remembering. It asks about a
storage *account*, which is the control plane: Azure Resource Manager, behind a login, in a
subscription. No emulator answers that, so the command line stops before sending anything and asks
you to log in, which you will not do in this course. Everything inside an account, its containers
and blobs, is the data plane, and that is what Azurite answers.
