---
title: Barrando antes do commit
version: 1
---

O melhor vazamento é o que nunca vira commit. O git consegue rodar um script antes de todo commit, um **hook
de pre-commit**, e recusar o commit se o script disser não. Aqui está um pequeno:

```schooling-example
{"language": "sh", "file": ".git/hooks/pre-commit", "parts": [{"code": "#!/bin/sh\n# Refuse a commit whose added lines look like a secret being assigned.", "note": "O git roda `.git/hooks/pre-commit` antes de todo commit, se ele existir e for executável. Se ele sair com qualquer coisa diferente de 0, o commit não acontece."}, {"code": "if git diff --cached -U0 | grep -inE '^\\+.*(password|secret|token|api_?key)[a-z_]*[[:space:]]*[=:][[:space:]]*[\"'\\''][^\"'\\'']{8,}'; then", "note": "`git diff --cached` é o que está para entrar no commit; `-U0` tira as linhas de contexto. O padrão procura, nas linhas acrescentadas, uma palavra como *password* ou *token*, um `=` ou `:`, e um valor entre aspas de oito caracteres ou mais."}, {"code": "  echo 'pre-commit: that looks like a secret. Keep it in the environment, not the repository.' >&2\n  exit 1\nfi", "note": "Uma frase que diz o que fazer no lugar, e uma saída diferente de zero. O `grep` já imprimiu a linha culpada, então a mensagem não precisa repeti-la."}]}
```

E aqui está ele funcionando, com o mesmo arquivo de antes:

```
ana@laptop:~/loanbook$ cat .git/hooks/pre-commit
#!/bin/sh
# Refuse a commit whose added lines look like a secret being assigned.
if git diff --cached -U0 | grep -inE '^\+.*(password|secret|token|api_?key)[a-z_]*[[:space:]]*[=:][[:space:]]*["'\''][^"'\'']{8,}'; then
  echo 'pre-commit: that looks like a secret. Keep it in the environment, not the repository.' >&2
  exit 1
fi
ana@laptop:~/loanbook$ git add notify.py
ana@laptop:~/loanbook$ git commit -q -m 'Send a reminder the day a loan is due'
8:+SMTP_PASSWORD = "mR7vQ2xL9pT4wZ8k"
pre-commit: that looks like a secret. Keep it in the environment, not the repository.
ana@laptop:~/loanbook$ git log --oneline -1
ff1a9d1 Read the database path and port from the environment
```

O commit não aconteceu: o `grep` imprimiu a linha que casou, o hook imprimiu a sua frase, e o `git log` ainda
mostra o commit de antes. Reescrito para ler do ambiente, o arquivo passa:

```
ana@laptop:~/loanbook$ cat notify.py
import os

SMTP_HOST = os.environ["SMTP_HOST"]
SMTP_PASSWORD = os.environ["SMTP_PASSWORD"]
ana@laptop:~/loanbook$ git add notify.py
ana@laptop:~/loanbook$ git commit -q -m 'Send a reminder the day a loan is due'
ana@laptop:~/loanbook$ git log --oneline -1
bfb3fbe Send a reminder the day a loan is due
```

Dois limites honestos. **Um hook mora em `.git/hooks`, que não faz parte do repositório**, então protege o
seu clone e o de mais ninguém. Ferramentas como o *pre-commit* compartilham hooks por um arquivo de
configuração com commit, e os sites de hospedagem oferecem varredura no servidor: a *push protection* do
GitHub recusa um push contendo um tipo conhecido de chave. E **um padrão pega os formatos que conhece**:
uma chave atribuída a uma variável chamada `x` passa direto. O hook é uma rede, não uma garantia, e a
garantia continua sendo o hábito de nunca digitar um segredo num arquivo que o git enxerga.
