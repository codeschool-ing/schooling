---
title: The machine you will type on
version: 2
---

Nothing in this course runs on a machine we host. **You build a Linux machine with a language model,
an embedding model and a database on it, and from this section on every command is typed there.**
Every transcript in the course was recorded on one: Ubuntu 24.04, a user called `ana` and a machine
called `vm`. Your prompt will carry your own names.

The person at the keyboard in the transcripts is ana, a developer at Marginalia, an online bookshop
that does not exist. This course builds the assistant that answers Marginalia's customers from the
shop's own documents.

## What runs on it

| | what it is | why this one |
| --- | --- | --- |
| **Ollama** | a program that downloads open models and serves them on your own machine, on port 11434 | free, no account and no card, and it speaks the same wire format as OpenAI's API and Anthropic's, so the companies' own SDKs talk to it unchanged |
| **llama3.2:3b** | Meta's Llama 3.2 with three billion parameters, the model that writes every answer | small enough to run without a graphics card, good enough to answer from a source and cite it |
| **all-minilm** | all-MiniLM-L6-v2, the embedding model `embeddings-vectors` used, served by Ollama | 384 numbers per text, and fast on any processor |
| **PostgreSQL 16 with pgvector** | the database that stores the chunks and their vectors, from lesson 5 on | Ubuntu packages both, and it is the database `embeddings-vectors` used |
| **Python 3.12** | the language of every program, in a virtual environment of its own | Ubuntu 24.04 ships it |

**Every reply in this course came from llama3.2:3b on that machine, and yours will differ in
wording.** A model picks each word with some randomness. The programs here ask for `temperature=0`,
which removes most of it, so the same program run twice on one machine usually prints the same reply.
Not always: Ollama reuses the work of an earlier request that began the same way, and arithmetic that
takes a different path can change a word, and every word after it. A different processor, a
different version of Ollama or a different model changes more.
What a lesson draws from a reply is a pattern: a citation that is there or missing, a number quoted
or a number invented. The pattern is what to look for in yours.

## Three ways to have the machine

| | what it is | what it costs your computer |
| --- | --- | --- |
| **a virtual machine** (recommended) | Ubuntu Server 24.04 LTS in a VM made with Multipass, and everything installed inside it | 4 processors, 8 GB of memory and 30 GB of disk while it runs; on your own system, only the hypervisor |
| installed | the same commands on a computer that already runs Ubuntu 24.04; or Ollama's own installer for Windows or macOS, beside PostgreSQL and Python installed by hand | the same disk, and the model's memory comes out of what you use for everything else |
| online | a virtual machine rented from a cloud provider, or a GitHub Codespace | nothing on your computer; an hourly price, or a monthly allowance the company offering it decides, and no graphics card, so it is as slow as a VM |

**The virtual machine is the same shape as the machine the transcripts came from**, so when your
output differs from the lesson's, the difference is the model's and not the setup's. It is also
disposable: a database dropped by mistake in lesson 14 costs nothing that the commands below cannot
put back.

**Installed is faster if your computer has a graphics card.** Ollama on Windows, on macOS with Apple
silicon and on Linux uses the card when it finds one, and a reply that takes seconds in a VM arrives
almost at once. On Ubuntu 24.04 the commands below are all of it. On Windows or macOS, install Ollama
from ollama.com, and PostgreSQL with pgvector and Python 3.12 from their own installers; the rest of
the course is the same.

**Online is named so that you know it exists, not recommended.** Every lesson needs the model, the
model needs several gigabytes of memory, and a free allowance large enough for that is a decision a
company makes and can change. No lesson here depends on one.

## The virtual machine

Install Multipass from Canonical's site. It drives a hypervisor the system already has: Hyper-V on
Windows, or VirtualBox on editions without Hyper-V; QEMU over Apple's own hypervisor on macOS; and
QEMU with KVM on Linux. Then, in your computer's own terminal:

```sh
multipass launch 24.04 --name vm --cpus 4 --memory 8G --disk 30G
multipass shell vm
```

**These two commands were not run for this course**, because the machine it was recorded on is
itself a virtual machine and cannot start another. The first creates the VM and the second opens a
shell inside it. Everything after this point happens in that shell. Any other hypervisor works in
place of Multipass, VirtualBox, UTM on an Apple-silicon Mac, Hyper-V or GNOME Boxes, with an Ubuntu
Server 24.04 LTS installer and the same sizes. It costs half an hour of installer screens instead of
one command.

## The packages, and Ollama

```sh
sudo apt-get update
sudo apt-get install -y zstd python3-venv postgresql-16 postgresql-16-pgvector
curl -fsSL https://ollama.com/install.sh | sh
```

The first two lines install the database, its vector extension, Python's virtual environments and
`zstd`, which Ollama's installer needs to unpack itself and does not install. The third is Ollama's
own installer, from Ollama's site: it puts `ollama` in `/usr/local/bin` and starts it as a service.
Read a script before you pipe it into a shell. This one is a few hundred lines and says what each
step does.

Then the two models. The first is a two-gigabyte download:

```sh
ollama pull llama3.2:3b
ollama pull all-minilm
```

## The database

```sh
sudo -u postgres createuser --superuser $USER
createdb rag
psql -d rag -c "CREATE EXTENSION vector"
```

PostgreSQL knows only its own administrator, `postgres`, until you give it a role with your login's
name. Superuser is too much for anything but a machine of your own. Here it is what lets lesson 14
create the roles it tests with.

## The working directory

Everything the course writes lives in `~/rag`, with a Python of its own:

```sh
mkdir ~/rag && cd ~/rag
python3 -m venv .venv
```

Save the next block as `~/rag/requirements.txt`. It names every library a lesson imports, at the
version the transcripts were recorded with:

```
# requirements.txt: the libraries this course imports, at the versions it was recorded with
numpy==2.4.6
tiktoken==0.14.0
psycopg[binary]==3.3.6
pgvector==0.3.6
openai==2.54.0
anthropic==1.11.0
rank-bm25==0.2.2
langchain-core==1.6.6
langchain-text-splitters==1.1.3
langchain-openai==1.6.7
langchain-postgres==0.0.18
llama-index-core==0.14.25
llama-index-embeddings-openai==0.7.0
llama-index-llms-openai==0.8.2
llama-index-llms-openai-like==0.8.1
haystack-ai==3.3.0
```

And this one as `~/rag/env.sh`. Every program in the course finds the model and the database through
it:

```sh
# env.sh: where this course's programs find the model and the database
. ~/rag/.venv/bin/activate
export OPENAI_BASE_URL=http://localhost:11434/v1
export OPENAI_API_KEY=ollama
export ANTHROPIC_BASE_URL=http://localhost:11434
export ANTHROPIC_API_KEY=ollama
export PGDATABASE=rag
export HAYSTACK_TELEMETRY_ENABLED=False
```

The two base URLs send OpenAI's SDK and Anthropic's SDK to Ollama instead of the companies' servers.
Ollama ignores the keys, and the SDKs refuse to start without one, so each gets a word. The last line
stops Haystack, lesson 11's framework, from reporting usage to its makers. Then:

```sh
. ./env.sh
pip install -r requirements.txt
echo '. ~/rag/env.sh' >> ~/.bashrc
```

The last line runs `env.sh` in every terminal you open from now on. The installation takes a few
minutes and about 400 MB.

## One module every lesson imports

The embedding model is called through the same SDK as the generator. `vectors.py` wraps that call so
that the rest of the course can write `embed(texts)` and get numbers it can multiply. Save it as
`~/rag/vectors.py`:

```schooling-example
{
  "language": "python",
  "file": "vectors.py",
  "parts": [
    {
      "code": "\"\"\"vectors: the embedding model, all-MiniLM-L6-v2, as Ollama serves it.\"\"\"\nimport numpy as np\nfrom openai import OpenAI\n\nMODEL = \"all-minilm\"\nclient = OpenAI()",
      "note": "The client reads `OPENAI_BASE_URL` from the environment, so it talks to Ollama. `all-minilm` is Ollama's name for all-MiniLM-L6-v2."
    },
    {
      "code": "def embed(texts):\n    \"\"\"One unit-length vector of 384 numbers per text, as the rows of a matrix.\"\"\"\n    if isinstance(texts, str):\n        texts = [texts]\n    data = client.embeddings.create(model=MODEL, input=list(texts)).data\n    vectors = np.array([d.embedding for d in data], dtype=np.float32)\n    return vectors / np.linalg.norm(vectors, axis=1, keepdims=True)",
      "note": "One request for any number of texts. Every vector is divided by its length, so the product of two of them is their cosine similarity, the measure `embeddings-vectors` used throughout."
    }
  ]
}
```

## Checking it works

Four checks, one for each piece. If one of them prints something else, the section after the next
is about exactly that.

```
ana@vm:~/rag$ ollama list
NAME                 ID              SIZE      MODIFIED       
all-minilm:latest    1b226e2802db    45 MB     52 minutes ago    
llama3.2:3b          a80c4f17acd5    2.0 GB    52 minutes ago    
llama3.2:1b          baf6a787fdff    1.3 GB    55 minutes ago    
ana@vm:~/rag$ ollama run --nowordwrap llama3.2:3b "In one sentence, what are you?"
I'm an artificial intelligence model designed to provide information, answer questions, and engage in conversation to the best of my abilities, based on my training data and knowledge.

ana@vm:~/rag$ python -c "from vectors import embed; v = embed(\"hello\"); print(v.shape, round(float((v ** 2).sum()), 3))"
(1, 384) 1.0
ana@vm:~/rag$ psql -c "SELECT extversion FROM pg_extension WHERE extname = 'vector'"
 extversion 
------------
 0.6.0
(1 row)
```

`ollama list` is what is on disk: the generator at 2.0 GB and the embedding model at 45 MB. The
machine the course was recorded on also has the smaller `llama3.2:1b`, which the last part of this
section is about. The vector has 384 numbers and a length of 1, which is what `vectors.py` promised.
The database has pgvector 0.6.0.

```
ana@vm:~/rag$ ollama ps
NAME                 ID              SIZE      PROCESSOR    CONTEXT    RUNNER      UNTIL              
llama3.2:1b          baf6a787fdff    1.5 GB    100% CPU     4096       llamacpp    4 minutes from now    
all-minilm:latest    1b226e2802db    48 MB     100% CPU     256        llamacpp    4 minutes from now    
llama3.2:3b          a80c4f17acd5    2.6 GB    100% CPU     4096       llamacpp    4 minutes from now    
```

**`ollama ps` is what a loaded model takes from memory**: 2.6 GB
for llama3.2:3b, with the room Ollama keeps for the prompt. The first request after a pause loads
the model, which is why that reply takes several seconds longer than the next. After five minutes
with no request, Ollama unloads it and gives the memory back.

## With less, or with a key

**A computer with less than 8 GB of memory** gives the VM 6 and uses `llama3.2:1b`, at
1.5 GB in memory and 1.3 GB on disk: `ollama pull llama3.2:1b`,
and change the model's name where a program names it. It follows instructions less reliably than
the 3b. The retrieval half of every lesson is identical, because the embedding model is the same.

**With your own paid API key**, every program in this course runs against a provider: change
`OPENAI_BASE_URL` and `OPENAI_API_KEY` in `env.sh`, and the model's name in the program. The bill is
yours, and small at this corpus's size. The embedding model is the one thing that should not move
with it. A provider's embedding model makes vectors of a different length, so keep `all-minilm` on
Ollama by giving `vectors.py` a client of its own, `OpenAI(base_url="http://localhost:11434/v1")`,
or change 384 wherever lesson 5 creates the table.
