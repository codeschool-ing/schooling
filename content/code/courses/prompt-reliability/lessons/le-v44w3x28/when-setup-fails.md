---
title: When the setup fails
version: 1
---

Most setups fail at one of four places: the install, the server, the model, or the wait. Each has a
message, and every message below was printed on the machine this course was captured on.

## The install stops: zstd

The first install on that machine stopped before it had installed anything:

```
$ curl -fsSL https://ollama.com/install.sh | sh
>>> Installing ollama to /usr/local
ERROR: This version requires zstd for extraction. Please install zstd and try again:
  - Debian/Ubuntu: sudo apt-get install zstd
  - RHEL/CentOS/Fedora: sudo dnf install zstd
  - Arch: sudo pacman -S zstd
```

Ollama is published compressed with zstd, and a minimal Linux may not have the program that
unpacks it. **The message says exactly what to do**, which is the case to hope for:

```sh
sudo apt-get install -y zstd
curl -fsSL https://ollama.com/install.sh | sh
```

## Nothing is listening

`pl` talks to Ollama over the network, at `127.0.0.1:11434`, even though both are on your computer.
If the server is not running, there is nobody at that address:

```
ana@lab:~/triage$ pl run prompts/v1-bare.txt cases/dev.jsonl --out runs/v1.jsonl
pl: cannot reach Ollama at http://127.0.0.1:11434 ([Errno 111] Connection refused). Is it running?
```

`Connection refused` means the address answered that no program is listening there. On Linux the
install set Ollama up as a service, and this starts it:

```sh
sudo systemctl start ollama
```

On a system without services, such as WSL on some versions of Windows, start it by hand in a
terminal of its own and leave that terminal open:

```sh
ollama serve
```

On macOS and Windows the Ollama application is the server: open it, and it sits in the menu bar
or the notification area while it runs.

## The model is missing

A model you never pulled cannot answer, and Ollama says so by name:

```
ana@lab:~/triage$ pl run prompts/v1-bare.txt cases/dev.jsonl --out runs/v1.jsonl --set model=llama3.2:1b
pl: Ollama answered 404: {"error":"model 'llama3.2:1b' not found"}
ana@lab:~/triage$ ollama list
NAME           ID              SIZE      MODIFIED               
llama3.2:1b    baf6a787fdff    1.3 GB    Less than a second ago    
llama3.2:3b    a80c4f17acd5    2.0 GB    57 minutes ago            
```

The fix is `ollama pull` with the same name. The name has to match to the letter: `llama3.2:3b`
and `llama3.2` are both names Ollama knows, and they are not written the same.

**A model you did pull can also be missing**, and that one is harder to see. Ollama keeps its
models in a directory under the home of whoever started the server. The service on Linux runs as a
user of its own, `ollama`, with its models in `/usr/share/ollama/.ollama`. Start `ollama serve`
yourself, as yourself, and that second server looks in your own home, finds nothing, and answers
as if you had never downloaded anything:

```
ana@lab:~/triage$ ollama list
NAME    ID    SIZE    MODIFIED 
ana@lab:~/triage$ pl run prompts/v1-bare.txt cases/dev.jsonl --out runs/v1.jsonl
pl: Ollama answered 404: {"error":"model 'llama3.2:3b' not found"}
```

Empty `ollama list`, and the model `ollama list` showed a minute earlier is "not found". **Two
servers, two model directories**, and only one of them can hold the address at a time. Stop the one
you started (Ctrl-C in its terminal) and start the service instead, or pull the model again into
the server you are using, at the price of a second copy on the disk.

## The first answer is slow

The first call after the server starts loads the model into memory, and that takes seconds before a
single word comes back. In the first run of this lesson the first reply took 34.8 seconds and the
next one 12.7. After five idle minutes Ollama unloads the model to give the memory back, and the
next call pays to load it again. `ollama ps` shows what is loaded, how much memory it takes and
until when.

If **every** call is slow, more than half a minute for a reply of one line, the computer is short of
memory or of processor for this model. Use `llama3.2:1b`, as *Your lab, and three ways to build it*
described: it took 2.0 GB of memory where `llama3.2:3b` took 2.9, and it is a weaker model. If even
that will not run, the online path is the one left.