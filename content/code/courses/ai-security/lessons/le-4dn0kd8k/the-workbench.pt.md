---
title: A bancada, e o único comando que toda aula usa
version: 1
---

Todo comando deste curso roda num diretório, o `~/guard`, na máquina que a seção anterior montou. Esta
seção o cria. Ele guarda três coisas:

- `tools/`, um programa pequeno em Python por defesa. **Cada aula imprime inteiros os programas que
  usa, na primeira vez que os usa**, e diz onde salvá-los;
- `data/`, os arquivos que esses programas leem. Cada aula dá os seus, pequenos o bastante para colar;
- `bin/guard`, um script curto que roda um programa de `tools/` pelo nome, de modo que o programa salvo
  como `tools/surface.py` é o comando `guard surface`.

## O diretório e o comando

Cole este bloco inteiro no terminal. A linha do `cat` abre um arquivo, e a linha `EOF` o fecha:

```sh
mkdir -p ~/guard/bin ~/guard/tools ~/guard/data
cat > ~/guard/bin/guard <<'EOF'
#!/bin/sh
# guard NAME [ARGS...] runs ~/guard/tools/NAME.py, the program a lesson
# printed under that name, with the rest of the line as its arguments.
tool="$HOME/guard/tools/$1.py"
if [ ! -f "$tool" ]; then
  echo "guard: no tool named '$1' in ~/guard/tools" >&2
  exit 2
fi
shift
exec python3 "$tool" "$@"
EOF
chmod +x ~/guard/bin/guard
```

Depois duas linhas no fim do `~/.bashrc`, para que todo terminal novo encontre o `guard`:

```sh
cat >> ~/.bashrc <<'EOF'
# ai-security
export PATH="$HOME/guard/bin:$PATH"
EOF
```

Abra um terminal novo depois disso. Aquele em que você digitou ainda tem o `PATH` antigo.

Se você ficou com o modelo menor, ou com o de um provedor, as variáveis dele vão embaixo dessas duas
linhas, por exemplo `export ASK_MODEL=llama3.2:1b`.

## `ask`: uma pergunta ao modelo

A maioria das aulas confere texto em vez de produzi-lo, e não precisa de modelo. As poucas que precisam
perguntam por meio de um programa. Abra um arquivo novo, cole o programa nele, salve e saia. Qualquer
editor serve; o `nano` está em todo Ubuntu, salva com Ctrl+O e sai com Ctrl+X:

```sh
nano ~/guard/tools/ask.py
```

```python
# ask.py: send one question to a language model and print the reply.
#
#   guard ask QUESTION [--system TEXT] [--temperature T] [--seed S] [--json]
#
# It speaks chat completions, the protocol Ollama serves on your own computer
# and most paid providers serve too. With nothing set it asks llama3.2:3b on
# this machine. Three variables point it elsewhere: ASK_URL, ASK_MODEL and
# ASK_KEY. Later tools import ask() from here rather than repeat it.
import argparse
import json
import os
import sys
import urllib.error
import urllib.request

URL = os.environ.get("ASK_URL", "http://localhost:11434/v1")
MODEL = os.environ.get("ASK_MODEL", "llama3.2:3b")
KEY = os.environ.get("ASK_KEY", "")


def ask(question, system=None, temperature=0.0, seed=1, json_only=False):
    """The model's reply to QUESTION, as text."""
    messages = [{"role": "user", "content": question}]
    if system:
        messages.insert(0, {"role": "system", "content": system})
    body = {"model": MODEL, "messages": messages,
            "temperature": temperature, "seed": seed}
    if json_only:
        body["response_format"] = {"type": "json_object"}
    req = urllib.request.Request(URL + "/chat/completions",
                                 json.dumps(body).encode(),
                                 {"Content-Type": "application/json"})
    if KEY:
        req.add_header("Authorization", "Bearer " + KEY)
    try:
        with urllib.request.urlopen(req, timeout=600) as r:
            reply = json.load(r)
    except urllib.error.HTTPError as e:
        sys.exit("ask: %s answered %d: %s" % (URL, e.code, e.read().decode().strip()))
    except urllib.error.URLError as e:
        sys.exit("ask: cannot reach %s (%s). Is Ollama running?" % (URL, e.reason))
    return reply["choices"][0]["message"]["content"]


if __name__ == "__main__":
    p = argparse.ArgumentParser(prog="guard ask")
    p.add_argument("question")
    p.add_argument("--system")
    p.add_argument("--temperature", type=float, default=0.0)
    p.add_argument("--seed", type=int, default=1)
    p.add_argument("--json", action="store_true")
    a = p.parse_args()
    print(ask(a.question, a.system, a.temperature, a.seed, a.json))
```

O `guard` o encontra pelo nome, então o programa agora é um comando:

```
ana@lab:~/guard$ guard ask "Say hello in five words."
Hello, how are you today?
ana@lab:~/guard$ guard ask "Say hello in five words."
Hello, how are you today?
ana@lab:~/guard$ guard ask "Say hello in five words." --temperature 0.8 --seed 3
Hello there, it's nice to meet you.
ana@lab:~/guard$ guard ask "Say hello in five words." --temperature 0.8 --seed 4
Hello, it's nice to meet you!
```

As duas primeiras execuções deram as mesmas palavras, e é para isso que serve o `--temperature 0`, o
padrão aqui: a cada passo o modelo pega a palavra mais provável, então a mesma pergunta dá a mesma
resposta. As duas últimas sobem a temperatura e mudam só a semente, o número de onde o sorteio parte, e a
resposta muda junto. Uma aula que cita uma resposta fixa as duas coisas, para você ver o que ela viu; o
`prompt-engineering` é o curso sobre o que essas configurações fazem.

As três variáveis são para os outros caminhos da seção anterior. `ASK_MODEL` nomeia outro modelo, como
o `llama3.2:1b`. `ASK_URL` é o endereço da API de um provedor, e `ASK_KEY` é a sua chave lá; a
documentação do provedor dá os dois.

## Como ler as transcrições

Todo comando deste curso foi rodado, e toda linha embaixo dele é o que o comando imprimiu. Uma
transcrição tem o prompt `ana@lab:~/guard$` na frente de cada comando: `ana` é a pessoa, `lab` é a
máquina, e a sua imprime os seus próprios nomes.

- O que os programas de `tools/` imprimem é igual na sua máquina, linha por linha, depois que você
  salvou os mesmos programas e colou os mesmos dados.
- **O que o modelo respondeu foi capturado do `llama3.2:3b`, servido pelo Ollama 0.40.0, em 7 de
  outubro de 2026**, num computador sem placa de vídeo. Rode o mesmo comando e você pode receber as
  mesmas palavras, ou outras: outro processador faz as contas em outra ordem, e uma versão mais nova do
  modelo escreve outra coisa. Isso não é sinal de que algo está errado. Julgue uma resposta pelo que a
  aula confere nela, nunca por bater ou não com esta página.
