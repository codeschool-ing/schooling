---
title: Onde um servidor local roda
version: 2
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

O `probed.py` acha esse relato no log do gravador, dentro do formato de API que o hospedeiro usou:

```python
"""Print what where_am_i reported, from the tool result in the recorder's log, wherever each API's format put it."""
import json
import re

log = open("requests.jsonl").read()
found = re.search(r'parent[\\"]+: [\\"]+(.*?)[\\"]+, [\\"]+uid[\\"]+: (\d+), [\\"]+cwd[\\"]+: [\\"]+(.*?)[\\"]+,.*?env[\\"]+: \[(.*?)\]', log)
parent, uid, cwd, env = found.groups()
names = [n for n in re.split(r'[\\", ]+', env) if n]
print(f"parent: {parent}\nuid:    {uid}\ncwd:    {cwd}\nenv:    {len(names)} variables")
print("        " + " ".join(names))
```

O gravador da aula 1 roda em segundo plano e os três SDKs apontam para ele, como na aula 11. Cada hospedeiro recebeu a pergunta *"Where are you running?"*, e cada modelo chamou `where_am_i`; o `rm -f requests.jsonl` antes de cada execução deixa para o `probed.py` só o relato daquela execução:

```
ana@lab:~/agents$ python recorder.py &
ana@lab:~/agents$ export ANTHROPIC_BASE_URL=http://127.0.0.1:11435 OPENAI_BASE_URL=http://127.0.0.1:11435/v1 OLLAMA_API_BASE=http://127.0.0.1:11435 CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1
ana@lab:~/agents$ rm -f requests.jsonl
ana@lab:~/agents$ python hosts.py OpenAI 'Where are you running?' probe > /dev/null 2>&1; python probed.py
parent: python hosts.py OpenAI Where are you running? probe
uid:    30033
cwd:    /home/ana/agents
env:    4 variables
        HOME LC_CTYPE PATH USER
ana@lab:~/agents$ rm -f requests.jsonl
ana@lab:~/agents$ python hosts.py Claude 'Where are you running?' probe > /dev/null 2>&1; python probed.py
parent: /home/ana/agents/.venv/lib/python3.12/site-packages/claude_agent_sdk/_
uid:    30033
cwd:    /home/ana/agents
env:    31 variables
        AI_AGENT ANTHROPIC_API_KEY ANTHROPIC_BASE_URL CLAUDECODE CLAUDE_AGENT_SDK_VERSION CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC CLAUDE_CODE_ENTRYPOINT CLAUDE_CODE_MESSAGING_SOCKET CLAUDE_CODE_MESSAGING_TOKEN CLAUDE_CODE_SESSION_ID CLAUDE_PROJECT_DIR COREPACK_ENABLE_AUTO_PIN HOME LANG LC_ALL NoDefaultCurrentDirectoryInExePath OLDPWD OLLAMA_API_BASE OPENAI_API_KEY OPENAI_BASE_URL PATH PS1 PWD PYTHONDONTWRITEBYTECODE PYTHONUNBUFFERED SHLVL TZ USER VIRTUAL_ENV VIRTUAL_ENV_PROMPT _
ana@lab:~/agents$ rm -f requests.jsonl
ana@lab:~/agents$ python hosts.py Google 'Where are you running?' probe > /dev/null 2>&1; python probed.py
parent: python hosts.py Google Where are you running? probe
uid:    30033
cwd:    /home/ana/agents
env:    4 variables
        HOME LC_CTYPE PATH USER
```

**O servidor é filho do hospedeiro.** Com os hospedeiros da OpenAI e do Google o pai é o próprio programa Python; com o hospedeiro do Claude o pai é o CLI do Claude Code, o subprocesso da aula 9, porque é lá que o cliente MCP mora. Em todos os casos ele rodou como ana (uid 30033) no diretório de trabalho dela, então **ele consegue ler e escrever tudo o que a ana consegue**, o que a aula 7 de `ai-dev` disse e isto mostra.

**O que ele herdou depende do hospedeiro.** Os hospedeiros da OpenAI e do Google usam o cliente stdio do SDK `mcp`, e o servidor recebeu quatro variáveis: `HOME`, `LC_CTYPE`, `PATH` e `USER`. O SDK passa uma lista padrão curta e mais nada. O servidor do hospedeiro do Claude recebeu **31**, o ambiente inteiro do CLI: tudo o que estava no shell da ana, `ANTHROPIC_API_KEY` e `OPENAI_API_KEY` entre elas, e por cima as variáveis do próprio CLI, um `CLAUDE_CODE_MESSAGING_TOKEN` entre elas. Aqui as chaves são a palavra `ollama`, que o Ollama ignora. No laptop de um desenvolvedor seriam chaves de verdade, e um servidor instalado nesse hospedeiro as teria desde o primeiro segundo, façam as ferramentas dele o que fizerem.

A configuração de servidor do Claude Agent SDK aceita um dicionário `env`, e a correção óbvia é passar um. O `probe:env` passa `{"ONLY_THIS": "1"}`; o `probe:clean` inicia o servidor por `env -i`, que limpa o ambiente e define só o que for nomeado:

```
ana@lab:~/agents$ rm -f requests.jsonl
ana@lab:~/agents$ python hosts.py Claude 'Where are you running?' probe:env > /dev/null 2>&1; python probed.py
parent: /home/ana/agents/.venv/lib/python3.12/site-packages/claude_agent_sdk/_
uid:    30033
cwd:    /home/ana/agents
env:    32 variables
        AI_AGENT ANTHROPIC_API_KEY ANTHROPIC_BASE_URL CLAUDECODE CLAUDE_AGENT_SDK_VERSION CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC CLAUDE_CODE_ENTRYPOINT CLAUDE_CODE_MESSAGING_SOCKET CLAUDE_CODE_MESSAGING_TOKEN CLAUDE_CODE_SESSION_ID CLAUDE_PROJECT_DIR COREPACK_ENABLE_AUTO_PIN HOME LANG LC_ALL NoDefaultCurrentDirectoryInExePath OLDPWD OLLAMA_API_BASE ONLY_THIS OPENAI_API_KEY OPENAI_BASE_URL PATH PS1 PWD PYTHONDONTWRITEBYTECODE PYTHONUNBUFFERED SHLVL TZ USER VIRTUAL_ENV VIRTUAL_ENV_PROMPT _
ana@lab:~/agents$ rm -f requests.jsonl
ana@lab:~/agents$ python hosts.py Claude 'Where are you running?' probe:clean > /dev/null 2>&1; python probed.py
parent: /home/ana/agents/.venv/lib/python3.12/site-packages/claude_agent_sdk/_
uid:    30033
cwd:    /home/ana/agents
env:    3 variables
        HOME LC_CTYPE PATH
```

O dicionário `env` **soma** ao que o servidor herda: 32 nomes, os mesmos 31 mais `ONLY_THIS`. Só o `env -i` o substituiu.

Com `env -i`: três variáveis, nenhuma chave. A regra que isto ensina é mais ampla que um hospedeiro: **descubra o que um servidor local herda antes de instalá-lo, e dê a ele só o que ele precisa**. O protocolo não diz nada sobre ambientes; quem decide é o hospedeiro, e dois hospedeiros deste curso decidiram diferente.
