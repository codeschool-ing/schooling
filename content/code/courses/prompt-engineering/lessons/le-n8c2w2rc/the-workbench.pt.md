---
title: A bancada, e os dois programas com que ela começa
version: 2
---

Todo comando deste curso roda em um diretório, `~/pe`, na máquina que a seção anterior montou. Esta
seção cria esse diretório: duas bibliotecas, dois programas e um arquivo de texto. Cada lição mais
adiante que precisa de um programa novo o imprime inteiro, na primeira vez em que ele é usado, e diz
onde salvá-lo.

## O diretório e as suas bibliotecas

```sh
mkdir -p ~/pe/bin
cd ~/pe
python3 -m venv .venv
.venv/bin/pip install jsonschema==4.26.0
npm install gpt-tokenizer@4.0.0
```

`.venv` é um **ambiente virtual**: um Python só dele, para que nada aqui mexa no Python em que o
próprio Ubuntu roda. O `jsonschema` confere uma resposta contra um esquema, da lição 15 em diante. O
`gpt-tokenizer` traz os tokenizadores que a OpenAI publica para os seus modelos, e a lição 3 é
construída sobre ele. As duas versões estão fixadas, porque uma mais nova pode imprimir uma linha
diferente das transcrições daqui.

Depois, duas linhas no fim do `~/.bashrc`, para que todo terminal novo encontre os programas em
`~/pe/bin` e o Python em `~/pe/.venv`:

```sh
cat >> ~/.bashrc <<'EOF'
# prompt-engineering
export PATH="$HOME/pe/bin:$HOME/pe/.venv/bin:$PATH"
EOF
```

Abra um terminal novo depois disso. Aquele em que você digitou ainda tem o `PATH` antigo.

Se você ficou com o modelo menor, ou com o de um provedor, as variáveis dele vão logo abaixo dessas
duas linhas, por exemplo `export ASK_MODEL=llama3.2:1b`.

## `toylm`: um modelo de linguagem que dá para ler

O primeiro programa é o modelo que as duas seções de leitura antes desta usaram. Abra um arquivo novo em
`~/pe/bin`, cole o programa nele, salve e saia. Qualquer editor serve; o `nano` está em todo Ubuntu,
salva com Ctrl+O e sai com Ctrl+X:

```sh
nano ~/pe/bin/toylm
```

```python
#!/usr/bin/env python3
"""toylm: a language model small enough to read in one sitting.

It counts which word follows which pair of words in corpus.txt, and predicts
the next word from those counts. That is a trigram model: the same job a large
language model does (given the text so far, a probability for every possible
next token) done with a table instead of a neural network, and with words
instead of pieces of words.

Generation applies the same controls a model API exposes, in the order most
implementations apply them: penalties, then temperature, then top-k, then
top-p, then a draw.

  toylm info                         the size of the model
  toylm tokens TEXT                  how toylm splits TEXT
  toylm next TEXT [--show N]         the next-word probabilities after TEXT
  toylm dist TEXT [controls]         the same, after the sampling controls
  toylm generate TEXT [controls]     write a continuation
  toylm save FILE                    write the model's counts to FILE

  controls: --temperature T  --top-k K  --top-p P  --max-tokens N
            --stop TEXT (repeatable)  --frequency-penalty F
            --presence-penalty P  --seed S  --samples N
"""
import argparse
import collections
import json
import math
import os
import random
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
CORPUS = os.environ.get("TOYLM_CORPUS", os.path.join(HERE, "..", "corpus.txt"))
START, END = "<s>", "</s>"
TOKEN = re.compile(r"[a-zé']+|[0-9]+|[.,!?:;]")


def tokens(text):
    return TOKEN.findall(text.lower())


def detok(words):
    out = ""
    for w in words:
        if w in ".,!?:;" or not out:
            out += w
        else:
            out += " " + w
    return out


class Model:
    def __init__(self, path):
        self.tri = collections.defaultdict(collections.Counter)
        self.bi = collections.defaultdict(collections.Counter)
        self.uni = collections.Counter()
        self.size = 0
        with open(path, encoding="utf-8") as f:
            for line in f:
                words = tokens(line)
                if not words:
                    continue
                seq = [START, START] + words + [END]
                self.size += len(words)
                for a, b, c in zip(seq, seq[1:], seq[2:]):
                    self.tri[(a, b)][c] += 1
                    self.bi[b][c] += 1
                    self.uni[c] += 1

    def table(self, context):
        """The counts that decide the next word, and which table they came from."""
        ctx = ([START, START] + context)[-2:]
        if self.tri.get(tuple(ctx)):
            return self.tri[tuple(ctx)], "trigram after '%s %s'" % tuple(ctx)
        if self.bi.get(ctx[-1]):
            return self.bi[ctx[-1]], "bigram after '%s'" % ctx[-1]
        return self.uni, "unigram: every word in the corpus"

    def probs(self, context):
        counts, source = self.table(context)
        total = sum(counts.values())
        return {w: n / total for w, n in counts.items()}, source


def controlled(p, generated, a):
    """Apply penalties, temperature, top-k and top-p to a distribution."""
    logits = {w: math.log(q) for w, q in p.items()}
    seen = collections.Counter(generated)
    for w in logits:
        if seen[w]:
            logits[w] -= a.frequency_penalty * seen[w] + a.presence_penalty
    ranked = sorted(logits.items(), key=lambda kv: (-kv[1], kv[0]))
    if a.temperature == 0:
        return {ranked[0][0]: 1.0}
    scaled = [(w, l / a.temperature) for w, l in ranked]
    top = max(l for _, l in scaled)
    weights = [(w, math.exp(l - top)) for w, l in scaled]
    total = sum(x for _, x in weights)
    dist = [(w, x / total) for w, x in weights]
    if a.top_k:
        dist = dist[: a.top_k]
    if a.top_p < 1:
        kept, cum = [], 0.0
        for w, q in dist:
            kept.append((w, q))
            cum += q
            if cum >= a.top_p - 1e-12:
                break
        dist = kept
    total = sum(q for _, q in dist)
    return {w: q / total for w, q in dist}


def bars(dist, show):
    rows = sorted(dist.items(), key=lambda kv: (-kv[1], kv[0]))
    for w, q in rows[:show]:
        print("  %-8s %5.1f%%  %s" % (w, 100 * q, "#" * round(40 * q)))
    if len(rows) > show:
        rest = sum(q for _, q in rows[show:])
        print("  (%d more, %.1f%% together)" % (len(rows) - show, 100 * rest))


def generate(m, prompt, a, rng):
    context = tokens(prompt)
    out = []
    finish = "length"
    while len(out) < a.max_tokens:
        p, _ = m.probs(context + out)
        dist = controlled(p, out, a)
        words = sorted(dist, key=lambda w: (-dist[w], w))
        w = rng.choices(words, weights=[dist[x] for x in words])[0]
        if w == END:
            finish = "end"
            break
        out.append(w)
        text = detok(out)
        hit = [s for s in a.stop if s in text]
        if hit:
            cut = min(text.index(s) for s in hit)
            return text[:cut].rstrip(), "stop", len(out), context
    return detok(out), finish, len(out), context


def main():
    ap = argparse.ArgumentParser(prog="toylm", add_help=True)
    ap.add_argument("command")
    ap.add_argument("text", nargs="?", default="")
    ap.add_argument("--show", type=int, default=8)
    ap.add_argument("--temperature", type=float, default=1.0)
    ap.add_argument("--top-k", type=int, default=0)
    ap.add_argument("--top-p", type=float, default=1.0)
    ap.add_argument("--max-tokens", type=int, default=30)
    ap.add_argument("--stop", action="append", default=[])
    ap.add_argument("--frequency-penalty", type=float, default=0.0)
    ap.add_argument("--presence-penalty", type=float, default=0.0)
    ap.add_argument("--seed", type=int, default=1)
    ap.add_argument("--samples", type=int, default=1)
    a = ap.parse_args()
    if a.temperature < 0:
        sys.exit("toylm: temperature cannot be negative")
    m = Model(CORPUS)

    if a.command == "info":
        print("corpus:        %d words in %s" % (m.size, os.path.basename(CORPUS)))
        print("vocabulary:    %d distinct words" % len(m.uni))
        print("trigram rows:  %d contexts, %d counts" % (len(m.tri), sum(len(c) for c in m.tri.values())))
        print("bigram rows:   %d contexts, %d counts" % (len(m.bi), sum(len(c) for c in m.bi.values())))
        n = sum(len(c) for c in m.tri.values()) + sum(len(c) for c in m.bi.values()) + len(m.uni)
        print("parameters:    %d stored counts" % n)
    elif a.command == "tokens":
        t = tokens(a.text)
        print(" | ".join(t))
        print("%d tokens" % len(t))
    elif a.command == "next":
        p, source = m.probs(tokens(a.text))
        print("context: %s" % source)
        bars(p, a.show)
    elif a.command == "dist":
        p, source = m.probs(tokens(a.text))
        print("context: %s" % source)
        bars(controlled(p, [], a), a.show)
    elif a.command == "generate":
        for i in range(a.samples):
            rng = random.Random(a.seed + i)
            text, finish, n, ctx = generate(m, a.text, a, rng)
            if a.samples > 1:
                print("[seed %d] %s" % (a.seed + i, text))
            else:
                print(text)
                print("-- finish: %s, prompt %d tokens, output %d tokens" % (finish, len(ctx), n))
    elif a.command == "save":
        model = {
            "trigram": {" ".join(k): dict(v) for k, v in sorted(m.tri.items())},
            "bigram": {k: dict(v) for k, v in sorted(m.bi.items())},
            "unigram": dict(sorted(m.uni.items())),
        }
        with open(a.text, "w", encoding="utf-8") as f:
            json.dump(model, f, ensure_ascii=False, sort_keys=True)
    else:
        sys.exit("toylm: unknown command %r (try --help)" % a.command)


if __name__ == "__main__":
    main()
```

Um programa em `~/pe/bin` precisa ser marcado como programa antes de o shell aceitar rodá-lo:

```sh
chmod +x ~/pe/bin/toylm
```

Você não precisa lê-lo agora. São umas duzentas linhas, e a função que transforma contagens em
porcentagens ocupa quatro delas, o último método da classe `Model`.

Ele aprende com o `corpus.txt`, 98 linhas curtas sobre um café. Cole este bloco inteiro no terminal:
a primeira linha abre o arquivo, e a linha `EOF` no fim o fecha.

```sh
cat > ~/pe/corpus.txt <<'EOF'
the coffee is strong .
the soup of the day is tomato .
the cake is gone by noon .
bruno orders a coffee .
the coffee is hot .
the coffee is strong .
the bread is fresh .
it is raining and the café is full .
the cat sleeps on the chair by the window .
the soup of the day is pumpkin .
the menu has soup , bread and cake .
question : is the coffee hot ? answer : yes . question : is the bread fresh ? answer : yes .
question : when does the café open ? answer : at seven . question : when does it close ? answer : at six .
the coffee is hot .
ana orders a tea .
the cat sleeps and the cat sleeps and the cat wakes .
the tea is hot .
the café opens at eight on sunday .
ana orders a tea .
the bread is warm .
the coffee is hot .
question : what is the soup of the day ? answer : tomato . question : is there cake ? answer : yes .
bruno orders a coffee .
ana orders a coffee and a slice of cake .
the bread is fresh .
the bread comes out of the oven at six .
the café closes at six .
the coffee is hot and the bread is fresh .
question : when does the café open ? answer : at seven . question : when does it close ? answer : at six .
the coffee is cold .
the coffee is ready .
the tea is ready .
the cake is sweet .
it is sunny and the terrace is open .
the café closes at noon on sunday .
the cat sat on the mat .
bruno pays at the counter .
the coffee is strong .
the coffee is hot and the bread is fresh .
the tea is ready .
it is cold and the coffee is hot .
the bread is warm .
the café opens at seven .
the cat sleeps on the chair by the window .
question : is the coffee hot ? answer : yes . question : is the bread fresh ? answer : yes .
the coffee is hot .
the cake is gone by noon .
the café closes at six .
the café opens at seven .
bruno orders a coffee .
the coffee is hot .
the coffee is strong .
the café opens at eight on sunday .
the coffee is hot .
the coffee is hot and the bread is fresh .
the cake is sweet .
the soup of the day is lentil .
it is raining and the café is full .
the café opens at seven .
the cat sleeps and the cat sleeps and the cat wakes .
the tea is hot .
the coffee is ready .
the bread is fresh .
the café opens at seven .
the coffee is hot .
the cat sat on the mat .
the bread is fresh and the coffee is hot .
the bread is fresh .
it is sunny and the terrace is open .
the coffee is bitter .
the cat sleeps and the cat sleeps and the cat wakes .
the cat sleeps on the counter .
the tea is hot .
the bread is warm .
the menu has soup , bread and cake .
the coffee is strong .
the bread is fresh .
the café opens at seven .
the café closes at noon on sunday .
the tea is green .
the coffee is hot .
the bread is fresh and the coffee is hot .
the cake is sweet .
the café opens at seven .
the tea is hot .
the tea is green .
the coffee is cold .
the coffee is hot .
it is cold and the coffee is hot .
the cat sleeps on the chair by the window .
the café closes at six .
question : what is the soup of the day ? answer : tomato . question : is there cake ? answer : yes .
the soup of the day is tomato .
the bread comes out of the oven at six .
bruno pays at the counter .
ana orders a coffee and a slice of cake .
the coffee is ready .
the café closes at six .
EOF
```

Depois pergunte ao modelo qual é o tamanho dele:

```
ana@lab:~/pe$ toylm info
corpus:        761 words in corpus.txt
vocabulary:    72 distinct words
trigram rows:  152 contexts, 212 counts
bigram rows:   72 contexts, 152 counts
parameters:    436 stored counts
ana@lab:~/pe$ head -4 corpus.txt
the coffee is strong .
the soup of the day is tomato .
the cake is gone by noon .
bruno orders a coffee .
```

A lição 8 volta à linha `parameters`, e ao que a mesma palavra quer dizer num modelo com bilhões
delas.

**O café, e tudo o que as lições seguintes escrevem sobre ele, foi inventado para o curso.** O Café
Aurora não existe, e os endereços de e-mail terminam em `example.com`, o domínio reservado para
exemplos.

## `ask`: uma pergunta a um modelo de verdade

O `ollama run` serve para uma conversa. As lições precisam de mais controle do que isso: a
temperatura, uma semente, uma mensagem de sistema, um limite de tamanho. Esses são os ajustes que a
interface de programação de todo modelo aceita, e o Ollama serve a mesma interface que a maioria dos
provedores pagos serve. O `ask` manda um prompt para ela e imprime a resposta. Ele não usa nada além
da biblioteca do próprio Python:

```sh
nano ~/pe/bin/ask
```

```python
#!/usr/bin/env python3
"""ask: send one prompt to a language model and print what it replied.

It speaks the chat-completions protocol, which Ollama serves on your own
computer and most paid providers serve too, so the same program works with
either. With nothing set, it asks llama3.2:3b on this machine.

  ask PROMPT [options]        PROMPT, or - to read it from standard input
    --system TEXT             a system message, sent before the prompt
    --chat FILE               send the conversation in FILE, a JSON list of
                              {"role", "content"}; PROMPT, if given, is added
                              as the last user turn
    --temperature T  --top-p P  --seed S  --max-tokens N
    --stop TEXT               (repeatable)
    --json                    ask for a JSON object and nothing else
    --samples N               N replies, with seeds S, S+1, ...
    --plain                   the reply only, without the line under it

  ASK_URL    where to send it   (default http://localhost:11434/v1)
  ASK_MODEL  which model        (default llama3.2:3b)
  ASK_KEY    a provider's API key; Ollama needs none
"""
import argparse
import json
import os
import sys
import urllib.error
import urllib.request

URL = os.environ.get("ASK_URL", "http://localhost:11434/v1")
MODEL = os.environ.get("ASK_MODEL", "llama3.2:3b")
KEY = os.environ.get("ASK_KEY", "")


def ask(messages, a, seed):
    body = {"model": MODEL, "messages": messages}
    for name in ("temperature", "top_p", "max_tokens"):
        if getattr(a, name) is not None:
            body[name] = getattr(a, name)
    if seed is not None:
        body["seed"] = seed
    if a.stop:
        body["stop"] = a.stop
    if a.json:
        body["response_format"] = {"type": "json_object"}
    req = urllib.request.Request(URL + "/chat/completions", json.dumps(body).encode(),
                                 {"Content-Type": "application/json"})
    if KEY:
        req.add_header("Authorization", "Bearer " + KEY)
    try:
        with urllib.request.urlopen(req, timeout=600) as r:
            return json.load(r)
    except urllib.error.HTTPError as e:
        sys.exit("ask: %s answered %d: %s" % (URL, e.code, e.read().decode(errors="replace").strip()))
    except urllib.error.URLError as e:
        sys.exit("ask: cannot reach %s (%s). Is the model server running?" % (URL, e.reason))


def main():
    ap = argparse.ArgumentParser(prog="ask")
    ap.add_argument("prompt", nargs="?")
    ap.add_argument("--system")
    ap.add_argument("--chat")
    ap.add_argument("--temperature", type=float)
    ap.add_argument("--top-p", type=float)
    ap.add_argument("--seed", type=int)
    ap.add_argument("--max-tokens", type=int)
    ap.add_argument("--stop", action="append", default=[])
    ap.add_argument("--json", action="store_true")
    ap.add_argument("--samples", type=int, default=1)
    ap.add_argument("--plain", action="store_true")
    a = ap.parse_args()
    messages = []
    if a.chat:
        with open(a.chat, encoding="utf-8") as f:
            messages = json.load(f)
    elif a.prompt is None:
        ap.error("give a PROMPT, or a conversation with --chat")
    if a.prompt is not None:
        prompt = sys.stdin.read() if a.prompt == "-" else a.prompt
        messages.append({"role": "user", "content": prompt})
    if a.system:
        messages.insert(0, {"role": "system", "content": a.system})
    for i in range(a.samples):
        seed = None if a.seed is None else a.seed + i
        r = ask(messages, a, seed)
        text = r["choices"][0]["message"]["content"]
        if a.samples > 1:
            print("[seed %s] %s" % (seed, " ".join(text.split())))
            continue
        print(text)
        if not a.plain:
            u = r.get("usage", {})
            print("-- %s, finish: %s, prompt %s tokens, output %s tokens" % (
                r.get("model", MODEL), r["choices"][0].get("finish_reason"),
                u.get("prompt_tokens", "?"), u.get("completion_tokens", "?")))


main()
```

```sh
chmod +x ~/pe/bin/ask
```

```
ana@lab:~/pe$ ask "the café opens at" --temperature 0
I'm not sure what time the café opens at. Can you provide more context or information about the café you're referring to?
-- llama3.2:3b, finish: stop, prompt 29 tokens, output 27 tokens
ana@lab:~/pe$ ask "When does a café usually open? Answer in one sentence." --temperature 0
A typical café usually opens between 7:00 AM and 11:00 AM, with peak hours often between 8:00 AM and 10:00 AM, when customers are looking for a morning coffee or breakfast.
-- llama3.2:3b, finish: stop, prompt 37 tokens, output 47 tokens
```

O primeiro prompt é o texto que o `toylm generate` continuou com `seven.` no começo desta lição. O modelo
de chat não o continuou. Ele leu as quatro palavras como alguém falando com ele, disse que não sabia
e devolveu uma pergunta. É o que o fim da seção sobre escrever uma palavra por vez disse que um
modelo de chat é treinado para fazer: o próximo turno mais provável depois de uma mensagem é uma resposta a ela. Ele
também acertou em não chutar, já que nada no prompt diz que café é esse. A lição 5 trata das
respostas que chutam mesmo assim.

O segundo prompt perguntou algo que ele sabe responder com o que aprendeu, e disse o tamanho da
resposta. Veio uma frase. Com `--temperature 0` o modelo pega a palavra mais provável a cada passo,
então perguntar de novo costuma dar a mesma resposta; a lição 13 trata do que esse número muda.

A linha embaixo de cada resposta é a contabilidade que toda API de modelo devolve de algum jeito:
qual modelo respondeu, **por que parou**, e quantos tokens entraram e saíram. O `toylm generate`
imprime a mesma linha, e a lição 3 explica por que uma contagem de tokens é o que você paga.

## Como ler as transcrições

Todo comando deste curso foi executado, e cada linha embaixo dele é o que o comando imprimiu. Uma
transcrição tem o prompt `ana@lab:~/pe$` na frente de cada comando: `ana` é a pessoa, `lab` é a
máquina, e a sua imprime os seus próprios nomes.

- O que o `toylm`, o `tok` e os outros programas pequenos imprimem é igual na sua máquina, linha por
  linha, depois que você salvar os mesmos programas.
- **O que um modelo grande respondeu foi capturado do `llama3.2:3b`, servido pelo Ollama 0.40.0, em
  7 de outubro de 2026**, num computador sem placa de vídeo. Rode o mesmo comando e você pode receber
  as mesmas palavras, ou outras: um processador diferente faz a conta em outra ordem, e outro modelo,
  ou uma versão mais nova deste, escreve outra coisa. Isso não é sinal de que algo deu errado. Julgue
  uma resposta pelo que você pediu, nunca por bater ou não com esta página.

::: track ai security
Os programas são Python e JavaScript, e você conheceu Python no curso `python`. Ler um deles é um
bom jeito de conferir o que uma lição afirma sobre ele.
:::

::: track *
Você não precisa ler nem escrever código neste curso. Cada lição diz o que um comando faz e o que
olhar no que ele imprimiu. Os programas estão aí, inteiros, para quem quiser conferir uma afirmação
contra o código que a produziu.
:::
