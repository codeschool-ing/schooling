---
title: Where a local server runs
version: 1
---

`probe_mcp.py` has one tool, `where_am_i`, which reports the server's own process: its parent, its user id, its working directory and the **names** of its environment variables. It never prints a value.

```python
"""An MCP server with one tool that reports where it is running. It prints variable NAMES, never values."""
import json
import os

from mcp.server.mcpserver import MCPServer

server = MCPServer("probe")


@server.tool()
def where_am_i() -> str:
    """Report this server's process: its parent, its user, its directory and the names of its environment variables."""
    parent = open(f"/proc/{os.getppid()}/cmdline").read().replace("\0", " ").strip()
    return json.dumps({"parent": parent[:70], "uid": os.getuid(), "cwd": os.getcwd(),
                       "pid": os.getpid(), "env": sorted(os.environ)})


if __name__ == "__main__":
    server.run()
```

`probed.py` finds that report in labllm's log, inside whichever provider's format the host used:

```python
"""Print what where_am_i reported, from the tool result in labllm's log, wherever each provider's format put it."""
import json
import re

log = open("/var/log/labllm/requests.jsonl").read()
found = re.search(r'parent[\\"]+: [\\"]+(.*?)[\\"]+, [\\"]+uid[\\"]+: (\d+), [\\"]+cwd[\\"]+: [\\"]+(.*?)[\\"]+,.*?env[\\"]+: \[(.*?)\]', log)
parent, uid, cwd, env = found.groups()
names = [n for n in re.split(r'[\\", ]+', env) if n]
print(f"parent: {parent}\nuid:    {uid}\ncwd:    {cwd}\nenv:    {len(names)} variables")
print("        " + " ".join(names))
```

Each host was asked *"Where are you running?"*, and the course's rule had the model call `where_am_i`:

```
ana@lab:~/agents$ python hosts.py OpenAI 'Where are you running?' probe > /dev/null 2>&1; python probed.py
parent: python hosts.py OpenAI Where are you running? probe
uid:    30033
cwd:    /home/ana/agents
env:    4 variables
        HOME LC_CTYPE PATH USER
ana@lab:~/agents$ python hosts.py Claude 'Where are you running?' probe > /dev/null 2>&1; python probed.py
parent: /opt/agents/lib/python3.11/site-packages/claude_agent_sdk/_bundled/cla
uid:    30033
cwd:    /home/ana/agents
env:    35 variables
        AI_AGENT ANTHROPIC_API_KEY ANTHROPIC_BASE_URL CLAUDECODE CLAUDE_AGENT_SDK_VERSION CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC CLAUDE_CODE_ENTRYPOINT CLAUDE_CODE_MESSAGING_SOCKET CLAUDE_CODE_MESSAGING_TOKEN CLAUDE_CODE_SESSION_ID CLAUDE_PROJECT_DIR COREPACK_ENABLE_AUTO_PIN GEMINI_API_KEY HOME LAB_TODAY LANG LC_ALL MINILM_DIR NIX_PROFILES NIX_SSL_CERT_FILE NoDefaultCurrentDirectoryInExePath OLDPWD OPENAI_API_KEY OPENAI_BASE_URL PATH PWD PYTHONDONTWRITEBYTECODE PYTHONWARNINGS SHLVL TIKTOKEN_CACHE_DIR TZ USER XDG_DATA_DIRS _ __ETC_PROFILE_NIX_SOURCED
ana@lab:~/agents$ python hosts.py Google 'Where are you running?' probe > /dev/null 2>&1; python probed.py
parent: python hosts.py Google Where are you running? probe
uid:    30033
cwd:    /home/ana/agents
env:    4 variables
        HOME LC_CTYPE PATH USER
```

**The server is a child of its host.** With the OpenAI and Google hosts its parent is the Python program itself; with the Claude host its parent is the Claude Code CLI, the subprocess of lesson 9, because that is where the MCP client lives. In every case it ran as ana (uid 30033) in her working directory, so **it can read and write everything ana can**, which `ai-dev` lesson 7 said and this shows.

**What it inherited depends on the host.** The OpenAI and Google hosts both use the `mcp` SDK's stdio client, and the server got four variables: `HOME`, `LC_CTYPE`, `PATH` and `USER`. The SDK passes a short default list and nothing else. The Claude host's server got **35**, the whole environment of the CLI, including `ANTHROPIC_API_KEY`, `OPENAI_API_KEY` and `GEMINI_API_KEY`, and a few that are not in the lab's environment file at all (`NIX_PROFILES`, `XDG_DATA_DIRS`), which the CLI picked up from the machine. In this lab those keys are fake, `lab-…-key-0001`. On a developer's laptop they would not be, and a server installed into that host would hold them from its first second, whatever its tools do.

The Claude Agent SDK's server configuration accepts an `env` dictionary, and the obvious fix is to pass one. `probe:env` passes `{"ONLY_THIS": "1"}`; `probe:clean` starts the server through `env -i`, which clears the environment and sets only what is named:

```
ana@lab:~/agents$ python hosts.py Claude 'Where are you running?' probe:env > /dev/null 2>&1; python probed.py
parent: /opt/agents/lib/python3.11/site-packages/claude_agent_sdk/_bundled/cla
uid:    30033
cwd:    /home/ana/agents
env:    36 variables
        AI_AGENT ANTHROPIC_API_KEY ANTHROPIC_BASE_URL CLAUDECODE CLAUDE_AGENT_SDK_VERSION CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC CLAUDE_CODE_ENTRYPOINT CLAUDE_CODE_MESSAGING_SOCKET CLAUDE_CODE_MESSAGING_TOKEN CLAUDE_CODE_SESSION_ID CLAUDE_PROJECT_DIR COREPACK_ENABLE_AUTO_PIN GEMINI_API_KEY HOME LAB_TODAY LANG LC_ALL MINILM_DIR NIX_PROFILES NIX_SSL_CERT_FILE NoDefaultCurrentDirectoryInExePath OLDPWD ONLY_THIS OPENAI_API_KEY OPENAI_BASE_URL PATH PWD PYTHONDONTWRITEBYTECODE PYTHONWARNINGS SHLVL TIKTOKEN_CACHE_DIR TZ USER XDG_DATA_DIRS _ __ETC_PROFILE_NIX_SOURCED
ana@lab:~/agents$ python hosts.py Claude 'Where are you running?' probe:clean > /dev/null 2>&1; python probed.py
parent: /opt/agents/lib/python3.11/site-packages/claude_agent_sdk/_bundled/cla
uid:    30033
cwd:    /home/ana/agents
env:    3 variables
        HOME LC_CTYPE PATH
```

The `env` dictionary **adds** to what the server inherits: 36 names, the same 35 plus `ONLY_THIS`. Only `env -i` replaced it.

With `env -i`: three variables, no keys. The rule this teaches is broader than one host: **find out what a local server inherits before you install it, and give it only what it needs**. The protocol says nothing about environments; the host decides, and two hosts in this course decided differently.
