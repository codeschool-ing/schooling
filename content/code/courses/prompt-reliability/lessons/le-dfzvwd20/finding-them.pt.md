---
title: Encontrando-as antes do modelo
version: 2
---

Você achou a contradição do `v2-long.txt` lendo, porque o prompt é curto e as duas linhas usam
palavras óbvias. Um prompt de sessenta linhas, editado por quatro pessoas ao longo de um ano, não é
lido por ninguém de ponta a ponta. **Um linter lê cada linha toda vez**, e é barato o bastante para
rodar antes de cada mudança. Este aqui é umas poucas listas de palavras e padrões. Salve-o como
`lint.py`:

```python
"""lint: lines of a prompt worth a second look. It reads words, not meaning."""
import re
import sys

# Pairs of patterns that pull one decision in opposite directions.
OPPOSITES = [
    (r"\b(brief|concise|short|one sentence)\b", r"\b(in (full )?detail|thorough|everything)\b", "length"),
    (r"\bformal\b", r"\b(casual|friendly|chatty)\b", "tone"),
]
SHOUT = r"\b(IMPORTANT|MUST|NEVER|ALWAYS|CRITICAL)\b"
NEGATIVE = r"^\s*[-*]?\s*(do not|don't|never|avoid)\b"


def lint(path):
    lines = open(path, encoding="utf-8").read().splitlines()
    found = []

    def where(pattern):
        return [n for n, line in enumerate(lines, 1) if re.search(pattern, line, re.I)]

    for one, other, what in OPPOSITES:
        x, y = where(one), where(other)
        if x and y:
            found.append((min(x + y), "contradiction (%s): lines %s against lines %s"
                          % (what, ",".join(map(str, x)), ",".join(map(str, y)))))
    seen = {}
    for n, line in enumerate(lines, 1):
        words = re.sub(r"\W+", " ", line.lower()).strip()
        if len(words.split()) >= 4:
            if words in seen:
                found.append((n, "repeats line %d" % seen[words]))
            seen.setdefault(words, n)
    negative = where(NEGATIVE)
    if len(negative) >= 3:
        found.append((negative[0], "%d rules say only what not to do: lines %s"
                      % (len(negative), ",".join(map(str, negative)))))
    rules = [n for n in where(r"^\s*([-*]|\d+\.)\s") if not re.search(r'^\s*-\s*"\w+":', lines[n - 1])]
    if len(rules) > 8:
        found.append((rules[0], "%d separate rules; a reader keeps fewer" % len(rules)))
    shouting = where(SHOUT)
    if len(shouting) >= 2:
        found.append((shouting[0], "%d lines shout: %s" % (len(shouting), ",".join(map(str, shouting)))))
    for n, text in sorted(found):
        print("%s:%d: %s" % (path, n, text))
    if not found:
        print("%s: nothing found" % path)


for path in sys.argv[1:]:
    lint(path)
```

```
ana@lab:~/triage$ python3 lint.py prompts/v2-long.txt prompts/v2-json.txt
prompts/v2-long.txt:4: contradiction (length): lines 4 against lines 16
prompts/v2-long.txt:11: 3 lines shout: 11,13,14
prompts/v2-long.txt:14: repeats line 11
prompts/v2-json.txt: nothing found
```

Três achados para o prompt longo e nenhum para o curto. Cada achado aponta uma linha, então pode
ser corrigido onde está:

| achado | o que significa |
|---|---|
| `contradiction (length)` | uma linha pedindo brevidade e uma pedindo detalhe, no mesmo prompt |
| `3 lines shout` | linhas com palavras como IMPORTANT ou NEVER, que põem algumas regras acima das outras |
| `repeats line 11` | a mesma instrução duas vezes, palavra por palavra |

## O que o linter está lendo

O `lint.py` sabe que *brief*, *concise*, *short* e *one sentence* puxam para um lado e *in detail*,
*thorough* e *everything* para o outro, e aponta um prompt que contém os dois. **Ele não entende
nenhuma das instruções.** Duas consequências vêm daí, e as duas aparecem aqui.

Ele deixa passar uma contradição escrita com outras palavras:

```
ana@lab:~/triage$ printf 'Keep the summary to one line.\nLeave nothing out of the summary.\n' > /tmp/two-lines.txt
ana@lab:~/triage$ python3 lint.py /tmp/two-lines.txt
/tmp/two-lines.txt: nothing found
```

Essas duas linhas discordam exatamente como as linhas 4 e 16, e o linter não acha nada, porque *one
line* e *leave nothing out* não estão em nenhuma das listas dele.

E parte do que ele aponta não é o que o nome do achado diz. As linhas 11 e 14 começam com
`IMPORTANT:`, e a linha 13 começa com *Never*, uma palavra comum com inicial maiúscula no começo de
uma frase. A `where()` busca com `re.I`, que ignora maiúsculas e minúsculas, então contou a linha
13 como gritando. **Um achado é uma linha para olhar, não um veredito sobre ela.**

Então `nothing found` quer dizer que nenhum padrão casou, o que é mais fraco do que dizer que o
prompt está claro. O linter vale a pena porque os erros que ele pega são os que entram sem ninguém
notar: uma regra colada uma segunda vez, uma palavra em maiúsculas acrescentada com pressa, uma
linha nova que inverte uma antiga sem alarde. A aula 5 roda o linter num prompt com treze regras.
