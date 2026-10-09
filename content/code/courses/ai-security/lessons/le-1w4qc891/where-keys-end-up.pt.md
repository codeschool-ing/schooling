---
title: Onde as credenciais vão parar quando ninguém está olhando
version: 1
---

O assistente da Tarefa funciona com credenciais: uma chave do fornecedor do modelo, uma chave do
sistema de pagamentos que emite reembolsos, uma senha do banco de pedidos, uma chave do armazenamento
onde o log é gravado. Cada uma é uma permissão que alguém pode usar sem ser a Tarefa. **Uma credencial
está segura exatamente onde ninguém além do código que precisa dela consegue lê-la**, e uma aplicação
com LLM tem mais lugares por onde ela pode vazar que uma aplicação comum: o prompt, o log de prompts, o
erro que uma ferramenta devolve, e o código-fonte que monta os três.

A primeira defesa é mecânica. Antes que qualquer coisa chegue ao repositório, um programa lê cada
arquivo procurando algo com formato de credencial. O repositório abaixo é o da Tarefa em miniatura,
escrito pelo curso. **Todas as chaves nele são falsas**: as que começam com `sk-lab-` foram inventadas
para esta aula, e a que começa com `AKIA` é o exemplo que a Amazon imprime na própria documentação, que
não abre nada. Cole:

```sh
mkdir -p ~/guard/data/repo/app ~/guard/data/repo/prompts ~/guard/data/repo/deploy ~/guard/data/repo/logs ~/guard/data/repo/docs
cat > ~/guard/data/repo/app/config.py <<'EOF'
import os

PROVIDER_URL = "https://api.provider.example/v1"
PROVIDER_KEY = os.environ["PROVIDER_KEY"]
EOF
cat > ~/guard/data/repo/app/payments.py <<'EOF'
PAYMENTS_URL = "https://payments.example/v2"
PAYMENTS_KEY = "sk-lab-payments-00000000000000000000"
EOF
cat > ~/guard/data/repo/prompts/support.txt <<'EOF'
You are Tarefa's support assistant. Answer from the help centre.
When a refund is approved, call the payments API with the key
sk-lab-payments-00000000000000000000 and the job number.
EOF
cat > ~/guard/data/repo/deploy/.env <<'EOF'
DB_HOST=orders.internal
DB_PASSWORD=correct-horse-lab-only
EOF
cat > ~/guard/data/repo/logs/2026-10-01.log <<'EOF'
14:02:11 POST /v1/chat/completions 200 Authorization: Bearer sk-lab-provider-11111111111111111111
EOF
cat > ~/guard/data/repo/docs/storage.md <<'EOF'
The storage client reads its key from the environment. The example key in
Amazon's own documentation is AKIAIOSFODNN7EXAMPLE, and it opens nothing.
EOF
cat > ~/guard/data/keyscan-allow.txt <<'EOF'
# One line per accepted finding: the file, the fingerprint, and why.
docs/storage.md  1a5d44a2dca1  Amazon's documented example key; it opens nothing
EOF
```

O verificador usa os formatos de chave que o `detect.py` já conhece da aula 11, e acrescenta uma regra:
uma atribuição cujo nome diz que guarda um segredo. Salve-o como `~/guard/tools/keyscan.py`:

```python
# keyscan.py: credentials written into files, before they reach a repository.
#
#   guard keyscan DIR [--allow FILE]
#
# It walks DIR and reports every line holding something shaped like a
# credential: the provider and cloud key shapes detect.py knows (lesson 11),
# and an assignment whose name says it is a secret. It prints the file, the
# line, the kind, the value MASKED and its fingerprint, the first twelve hex
# digits of its SHA-256: a scanner that prints the secret it found has just
# copied it into the build log, and a fingerprint names one value exactly
# without revealing it.
#
# --allow names a file of accepted findings, one per line: the path, the
# fingerprint and the reason. A finding listed there is reported as ALLOWED
# with its reason, so an exception is a written decision rather than a
# silence. The exit status is 1 while any finding is not allowed.
import argparse
import hashlib
import os
import re

from detect import SECRET

ASSIGNED = re.compile(r"(?i)\b\w*(?:password|passwd|secret|token|api_key)\w*\s*[=:]\s*['\"]?([^\s'\"]{8,})")


def mask(value):
    return value[:4] + "****"


def fingerprint(value):
    return hashlib.sha256(value.encode()).hexdigest()[:12]


def findings(text):
    for n, line in enumerate(text.splitlines(), 1):
        seen = set()
        for m in SECRET.finditer(line):
            seen.add(m.group())
            yield n, "key", m.group()
        for m in ASSIGNED.finditer(line):
            if m.group(1) not in seen:
                yield n, "assignment", m.group(1)


p = argparse.ArgumentParser(prog="guard keyscan")
p.add_argument("dir")
p.add_argument("--allow")
a = p.parse_args()

allowed = {}
if a.allow:
    with open(a.allow, encoding="utf-8") as f:
        for line in f:
            if line.strip() and not line.startswith("#"):
                path, fp, why = line.split(None, 2)
                allowed[(path, fp)] = why.strip()

bad = ok = 0
for root, dirs, files in sorted(os.walk(a.dir)):
    dirs.sort()
    for name in sorted(files):
        full = os.path.join(root, name)
        rel = os.path.relpath(full, a.dir)
        with open(full, encoding="utf-8", errors="replace") as f:
            text = f.read()
        for n, kind, value in findings(text):
            fp = fingerprint(value)
            why = allowed.get((rel, fp))
            if why:
                ok += 1
                print("%-20s %2d  %-10s %-9s %s  ALLOWED  %s" % (rel, n, kind, mask(value), fp, why))
            else:
                bad += 1
                print("%-20s %2d  %-10s %-9s %s  FOUND" % (rel, n, kind, mask(value), fp))
print("%d finding(s), %d allowed, %d to remove" % (bad + ok, ok, bad))
raise SystemExit(1 if bad else 0)
```

```
ana@lab:~/guard$ guard keyscan data/repo; echo "exit status $?"
app/payments.py       2  key        sk-l****  9f8dfa2fe8d2  FOUND
deploy/.env           2  assignment corr****  d16dce059b1f  FOUND
docs/storage.md       2  key        AKIA****  1a5d44a2dca1  FOUND
logs/2026-10-01.log   1  key        sk-l****  015ed8aa2e80  FOUND
prompts/support.txt   3  key        sk-l****  9f8dfa2fe8d2  FOUND
5 finding(s), 0 allowed, 5 to remove
exit status 1
```

Cinco achados em seis arquivos, e o verificador não imprimiu nenhum inteiro. **Um verificador que
imprime o segredo que achou acabou de copiá-lo para o log do build**, que é lido por mais gente que o
código. A máscara mostra o bastante para reconhecer o tipo; a impressão digital nomeia o valor exato
sem revelá-lo, e é isso que permite comparar dois achados. O `app/payments.py` e o
`prompts/support.txt` têm a mesma impressão digital, `9f8dfa2fe8d2`: **a mesma chave de pagamentos
está escrita em dois lugares**, então tirá-la de um e esquecer o outro não resolve nada.

## Uma exceção é uma decisão escrita

O `docs/storage.md` guarda a chave de exemplo da Amazon de propósito, como documentação. O verificador
não tem como saber disso, e uma pessoa tem, então a pessoa anota: o arquivo, a impressão digital e o
motivo. A lista de exceções faz parte do que foi colado acima, e com ela o exemplo documentado deixa de
reprovar o build:

```
ana@lab:~/guard$ guard keyscan data/repo --allow data/keyscan-allow.txt; echo "exit status $?"
app/payments.py       2  key        sk-l****  9f8dfa2fe8d2  FOUND
deploy/.env           2  assignment corr****  d16dce059b1f  FOUND
docs/storage.md       2  key        AKIA****  1a5d44a2dca1  ALLOWED  Amazon's documented example key; it opens nothing
logs/2026-10-01.log   1  key        sk-l****  015ed8aa2e80  FOUND
prompts/support.txt   3  key        sk-l****  9f8dfa2fe8d2  FOUND
5 finding(s), 1 allowed, 4 to remove
exit status 1
```

A exceção está presa a um valor num arquivo. Uma chave real colada no mesmo documento tem outra
impressão digital e falha como antes, e essa é a diferença entre uma exceção e um buraco. **Uma lista
de exceções sem motivos é uma lista de coisas que ninguém lembra de ter decidido**, e ela só cresce.

O status de saída continua 1: quatro achados são reais, e o resto desta aula é sobre onde cada um deve
ficar.
