---
title: When the setup does not work
version: 2
---

These are the failures met while this course was being recorded, each with what it printed. Most of them are one forgotten step, and the message says which once you know how to read it.

```
ana@lab:~/agents$ ANTHROPIC_BASE_URL=http://127.0.0.1:11435 python agent.py "Which ways can I pay?" 2>&1 | tail -n 1
anthropic.APIConnectionError: Connection error.
ana@lab:~/agents$ env -u ANTHROPIC_API_KEY -u ANTHROPIC_BASE_URL python agent.py "Which ways can I pay?" 2>&1 | tail -n 1
TypeError: "Could not resolve authentication method. Expected one of api_key, auth_token, or credentials to be set. Or for one of the `X-Api-Key` or `Authorization` headers to be explicitly omitted"
ana@lab:~/agents$ python3.11 -c "import shop; print(shop.search_help(\"returns\"))" 2>&1 | tail -n 1
AttributeError: module 'math' has no attribute 'sumprod'
ana@lab:~/agents$ ollama run llama3.2:3x "Hello"
pulling manifest pulling manifest pulling manifest pulling manifest pulling manifest pulling manifest pulling manifest 
Error: pull model manifest: file does not exist
ana@lab:~/agents$ ollama ps
NAME                 ID              SIZE      PROCESSOR          CONTEXT    RUNNER      UNTIL              
all-minilm:latest    1b226e2802db    48 MB     56%/44% CPU/GPU    256        llamacpp    4 minutes from now    
llama3.2:3b          a80c4f17acd5    3.5 GB    41%/59% CPU/GPU    8192       llamacpp    4 minutes from now    
```

**`APIConnectionError: Connection error.`** Nothing answered at the address the program was given. Here the address was the recorder's, and the recorder was not running; the same line appears when Ollama itself is stopped, and then `ollama --version` says so too, with `Warning: could not connect to a running Ollama instance` under the version. On Linux, `sudo systemctl start ollama` starts it; on macOS and Windows, open the Ollama application.

**`Could not resolve authentication method`.** The library found no key, which means `ollama.env` did not reach this shell. Either the environment was activated before the file was appended to `.venv/bin/activate`, or this is a new terminal where `. .venv/bin/activate` was never typed. Without the base URL the program would also have gone to the provider's real address rather than to Ollama.

**`module 'math' has no attribute 'sumprod'`.** A Python older than 3.12. `shop.py` uses `math.sumprod`, which arrived in 3.12; the line above ran 3.11 on purpose to show it. Inside the activated environment, `python --version` should say 3.12 or newer. On an older Ubuntu, install a newer Python before creating `.venv`, because a virtual environment keeps the Python it was created with.

**`pull model manifest: file does not exist`.** Ollama has no model by that name, and here the name was mistyped: `3x` for `3b`. `ollama list` shows the names you have, exactly as a program must spell them.

**The `CONTEXT` column of `ollama ps` says 4096.** The context setting did not take. Ollama reads it when it starts, so the service has to be restarted after the setting is written, and on Linux the setting has to be in the service's environment rather than your shell's. The symptom without this check is worse than an error: a long conversation loses its start, and the model answers as if Bia had never said who she was.

**A download stops halfway.** A model is a few gigabytes, and a connection that drops during `ollama pull` ends it with an error. Run the same `ollama pull` again: it resumes from what is already on the disk.

**Installing Ollama by hand from its archive.** On Linux, the archive at `ollama.com/download` is compressed with zstd, and on a system without the `zstd` program `tar` stops with an error naming `unzstd`. `sudo apt install zstd` fixes it. The install script needs none of this, which is why it is the route above.
