---
title: Onde um servidor local roda
version: 1
---

O `probe_mcp.py` tem uma ferramenta, `where_am_i`, que descreve o próprio processo do servidor: o pai, o id de usuário, o diretório de trabalho e os **nomes** das variáveis de ambiente. Ele nunca imprime um valor.

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

O `probed.py` acha esse relato no log do labllm, dentro do formato de fornecedor que o hospedeiro usou:

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

Cada hospedeiro recebeu a pergunta *"Where are you running?"*, e a regra do curso fez o modelo chamar `where_am_i`:

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

**O servidor é filho do hospedeiro.** Com os hospedeiros da OpenAI e do Google o pai é o próprio programa Python; com o hospedeiro do Claude o pai é o CLI do Claude Code, o subprocesso da aula 9, porque é lá que o cliente MCP mora. Em todos os casos ele rodou como ana (uid 30033) no diretório de trabalho dela, então **ele consegue ler e escrever tudo o que a ana consegue**, o que a aula 7 de `ai-dev` disse e isto mostra.

**O que ele herdou depende do hospedeiro.** Os hospedeiros da OpenAI e do Google usam o cliente stdio do SDK `mcp`, e o servidor recebeu quatro variáveis: `HOME`, `LC_CTYPE`, `PATH` e `USER`. O SDK passa uma lista padrão curta e mais nada. O servidor do hospedeiro do Claude recebeu **35**, o ambiente inteiro do CLI, incluindo `ANTHROPIC_API_KEY`, `OPENAI_API_KEY` e `GEMINI_API_KEY`, e algumas que nem estão no arquivo de ambiente do laboratório (`NIX_PROFILES`, `XDG_DATA_DIRS`), que o CLI pegou da máquina. Neste laboratório essas chaves são falsas, `lab-…-key-0001`. No laptop de um desenvolvedor não seriam, e um servidor instalado nesse hospedeiro as teria desde o primeiro segundo, façam as ferramentas dele o que fizerem.

A configuração de servidor do Claude Agent SDK aceita um dicionário `env`, e a correção óbvia é passar um. O `probe:env` passa `{"ONLY_THIS": "1"}`; o `probe:clean` inicia o servidor por `env -i`, que limpa o ambiente e define só o que for nomeado:

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

O dicionário `env` **soma** ao que o servidor herda: 36 nomes, os mesmos 35 mais `ONLY_THIS`. Só o `env -i` o substituiu.

Com `env -i`: três variáveis, nenhuma chave. A regra que isto ensina é mais ampla que um hospedeiro: **descubra o que um servidor local herda antes de instalá-lo, e dê a ele só o que ele precisa**. O protocolo não diz nada sobre ambientes; quem decide é o hospedeiro, e dois hospedeiros deste curso decidiram diferente.
